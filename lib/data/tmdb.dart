import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'catalog.dart';
import 'models.dart';

class TmdbException implements Exception {
  TmdbException(this.status);
  final int status;
  @override
  String toString() => 'TMDB error $status';
}

/// One place that builds TMDB requests, checks errors, and remembers answers
/// so going back and forth between pages is instant.
class Tmdb {
  Tmdb({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _cache = <String, Future<Map<String, dynamic>>>{};

  /// One request, no caching (used for search, where every query is new).
  Future<Map<String, dynamic>> get(String path, [Map<String, String> params = const {}]) async {
    final url = Uri.parse('$tmdbBase$path').replace(queryParameters: {'api_key': tmdbKey, ...params});
    final res = await _client.get(url);
    if (res.statusCode != 200) throw TmdbException(res.statusCode);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Same as [get], but remembers the answer. Failures are not remembered.
  Future<Map<String, dynamic>> cached(String path, [Map<String, String> params = const {}]) {
    final key = '$path?${jsonEncode(params)}';
    return _cache.putIfAbsent(key, () {
      final request = get(path, params);
      request.then((_) {}, onError: (_) {
        _cache.remove(key);
      });
      return request;
    });
  }

  List<MediaItem> _items(Object? results, {MediaType? fallback}) =>
      (results as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdb(m, fallback: fallback))
          .whereType<MediaItem>()
          .where((i) => i.posterPath != null)
          .toList() ??
      [];

  /// The titles for one row.
  Future<List<MediaItem>> row(RowDef def) async {
    final data = await cached(def.path, def.params);
    return _items(data['results'], fallback: def.type);
  }

  /// One search across movies and shows.
  Future<List<MediaItem>> search(String query) async {
    final data = await get('/search/multi', {'query': query, 'include_adult': 'false'});
    return _items(data['results']);
  }

  Future<MediaDetails> details(MediaType type, int id) async {
    final data = await cached('/${type.name}/$id', {'append_to_response': 'credits,recommendations'});
    return MediaDetails.fromTmdb(data, type);
  }

  Future<List<MediaItem>> recommendations(MediaType type, int id) async {
    final data = await cached('/${type.name}/$id/recommendations');
    return _items(data['results'], fallback: type);
  }

  /// Episodes of one season. If the request fails, falls back to plain
  /// numbers 1..[count] so the episodes can still be played.
  Future<List<Episode>> episodes(int showId, int season, int count) async {
    try {
      final data = await cached('/tv/$showId/season/$season');
      final list = (data['episodes'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
      if (list.isNotEmpty) {
        return [
          for (final ep in list)
            Episode(
              number: (ep['episode_number'] as int?) ?? 0,
              name: (ep['name'] ?? '').toString(),
              overview: (ep['overview'] ?? '').toString(),
              stillPath: ep['still_path'] as String?,
              runtime: ep['runtime'] as int?,
            ),
        ];
      }
    } catch (_) {
      // fall through to the numbered list
    }
    return [for (var n = 1; n <= count; n++) Episode(number: n)];
  }

  /// Art for the billboard: a poster with no words on it, plus the title's
  /// logo (PNG) to lay over it. Either can be null. A normal poster already
  /// has the title printed on it, so the logo is only used with a clean one.
  Future<({String? cleanPoster, String? logo})> billboardArt(MediaType type, int id) async {
    final data = await cached('/${type.name}/$id/images', {'include_image_language': 'en,null'});
    List<Map<String, dynamic>> maps(String key) =>
        (data[key] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];

    // TMDB marks artwork that has no text with a null language
    final clean = maps('posters').where((p) => p['iso_639_1'] == null && p['file_path'] != null);
    final logos = maps('logos').where((l) => (l['file_path'] ?? '').toString().toLowerCase().endsWith('.png')).toList();
    final english = logos.where((l) => l['iso_639_1'] == 'en');

    return (
      cleanPoster: clean.isEmpty ? null : clean.first['file_path'].toString(),
      logo: logos.isEmpty ? null : (english.isNotEmpty ? english.first : logos.first)['file_path'].toString(),
    );
  }

  /// { genreId: "Name" } for movies or shows.
  Future<Map<int, String>> genreNames(MediaType type) async {
    final data = await cached('/genre/${type.name}/list');
    return {
      for (final g in (data['genres'] as List?)?.whereType<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[])
        if (g['id'] is int) g['id'] as int: (g['name'] ?? '').toString(),
    };
  }

  /// Everything in one category, movies and shows taking turns.
  /// [only] limits it to one type.
  Future<List<MediaItem>> category(GenreCategory category, {MediaType? only}) async {
    final types = [
      for (final type in MediaType.values)
        if (category.idFor(type) != null && (only == null || only == type)) type,
    ];
    final lists = await Future.wait([
      for (final type in types)
        row(RowDef('', '/discover/${type.name}',
            type: type, params: {'with_genres': category.idFor(type)!, 'vote_count.gte': '100'})),
    ]);
    final longest = lists.fold<int>(0, (max, list) => list.length > max ? list.length : max);
    return [
      for (var i = 0; i < longest; i++)
        for (final list in lists)
          if (i < list.length) list[i],
    ];
  }

  /// Average colour of a small image, darkened. Used as the glow behind the
  /// billboard. Returns null if the image can't be read.
  Future<Color?> ambientColor(String url) async {
    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(res.bodyBytes, targetWidth: 8, targetHeight: 8);
      final frame = await codec.getNextFrame();
      final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      frame.image.dispose();
      if (bytes == null) return null;

      var r = 0, g = 0, b = 0;
      final count = bytes.lengthInBytes ~/ 4;
      for (var i = 0; i < count; i++) {
        r += bytes.getUint8(i * 4);
        g += bytes.getUint8(i * 4 + 1);
        b += bytes.getUint8(i * 4 + 2);
      }
      const dim = 0.6; // average, then darken
      return Color.fromARGB(255, (r / count * dim).round(), (g / count * dim).round(), (b / count * dim).round());
    } catch (_) {
      return null;
    }
  }
}

/// The one client the whole app shares.
final tmdb = Tmdb();
