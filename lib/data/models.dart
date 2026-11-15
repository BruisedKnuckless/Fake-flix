/// The plain data classes the app passes around.
library;

enum MediaType {
  movie,
  tv;

  /// TMDB calls them "movie" and "tv" (anything else, e.g. "person", is null).
  static MediaType? parse(Object? value) => switch (value) {
        'movie' => MediaType.movie,
        'tv' => MediaType.tv,
        _ => null,
      };
}

/// One movie or show, as shown on a poster card.
///
/// The last four fields are only filled in for titles saved on a profile:
/// where to resume, when it was watched, and which episodes were watched.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview = '',
    this.date = '',
    this.vote = 0,
    this.genreIds = const [],
    this.season,
    this.episode,
    this.watchedAt,
    this.episodes = const [],
  });

  final int id;
  final MediaType type;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final String date; // release date (movies) or first air date (shows)
  final double vote; // 0 to 10
  final List<int> genreIds;

  final int? season;
  final int? episode;
  final int? watchedAt; // milliseconds since 1970
  final List<String> episodes; // watched episodes as "2x5" = season 2 episode 5

  String get year => date.length >= 4 ? date.substring(0, 4) : '';
  int get matchPercent => (vote * 10).round();
  bool sameTitle(MediaItem other) => other.type == type && other.id == id;

  /// From a TMDB result. Movies use "title" + "release_date", shows use
  /// "name" + "first_air_date". [fallback] is the type for endpoints that
  /// return only movies or only shows (those results carry no media_type).
  static MediaItem? fromTmdb(Map<String, dynamic> json, {MediaType? fallback}) {
    final type = MediaType.parse(json['media_type']) ?? fallback;
    final id = json['id'];
    if (type == null || id is! int) return null;
    return MediaItem(
      id: id,
      type: type,
      title: (json['title'] ?? json['name'] ?? 'Untitled').toString(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: (json['overview'] ?? '').toString(),
      date: (json['release_date'] ?? json['first_air_date'] ?? '').toString(),
      vote: (json['vote_average'] as num?)?.toDouble() ?? 0,
      genreIds: (json['genre_ids'] as List?)?.whereType<int>().toList() ?? const [],
    );
  }

  /// What gets written to the device. Same field names as the website uses.
  Map<String, dynamic> toJson() => {
        'id': id,
        'media_type': type.name,
        'title': title,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'release_date': date,
        'vote_average': vote,
        if (season != null) 'season': season,
        if (episode != null) 'episode': episode,
        if (watchedAt != null) 'watchedAt': watchedAt,
        if (episodes.isNotEmpty) 'episodes': episodes,
      };

  static MediaItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final type = MediaType.parse(json['media_type']);
    final id = json['id'];
    if (type == null || id is! int) return null;
    return MediaItem(
      id: id,
      type: type,
      title: (json['title'] ?? 'Untitled').toString(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      date: (json['release_date'] ?? '').toString(),
      vote: (json['vote_average'] as num?)?.toDouble() ?? 0,
      season: json['season'] as int?,
      episode: json['episode'] as int?,
      watchedAt: json['watchedAt'] as int?,
      episodes: (json['episodes'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  /// A copy with only the fields a saved entry needs, plus the given extras.
  MediaItem saved({int? season, int? episode, int? watchedAt, List<String> episodes = const []}) =>
      MediaItem(
        id: id,
        type: type,
        title: title,
        posterPath: posterPath,
        backdropPath: backdropPath,
        date: date,
        vote: vote,
        season: season,
        episode: episode,
        watchedAt: watchedAt,
        episodes: episodes,
      );
}

/// "2x5" = season 2 episode 5, the form watched episodes are remembered in.
String episodeTag(int season, int episode) => '${season}x$episode';

class SeasonInfo {
  const SeasonInfo(this.number, this.episodeCount);
  final int number;
  final int episodeCount;
}

class Episode {
  const Episode({
    required this.number,
    this.name = '',
    this.overview = '',
    this.stillPath,
    this.runtime,
  });
  final int number;
  final String name;
  final String overview;
  final String? stillPath;
  final int? runtime; // minutes
}

/// Everything the title page shows.
class MediaDetails {
  const MediaDetails({
    required this.item,
    this.tagline = '',
    this.runtime,
    this.genres = const [],
    this.cast = const [],
    this.makers = const [],
    this.seasons = const [],
    this.recommendations = const [],
  });

  final MediaItem item;
  final String tagline;
  final int? runtime; // minutes (movies)
  final List<String> genres;
  final List<String> cast;
  final List<String> makers; // director(s) for movies, creator(s) for shows
  final List<SeasonInfo> seasons;
  final List<MediaItem> recommendations;

  static MediaDetails fromTmdb(Map<String, dynamic> json, MediaType type) {
    List<Map<String, dynamic>> maps(Object? value) =>
        (value as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
    List<String> names(Iterable<Map<String, dynamic>> list) =>
        list.map((m) => (m['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();

    final credits = json['credits'] as Map<String, dynamic>? ?? const {};
    final recs = json['recommendations'] as Map<String, dynamic>? ?? const {};

    // season 0 is usually "Specials", so skip it and any empty seasons
    final seasons = maps(json['seasons'])
        .map((s) => SeasonInfo((s['season_number'] as int?) ?? 0, (s['episode_count'] as int?) ?? 0))
        .where((s) => s.number > 0 && s.episodeCount > 0)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return MediaDetails(
      item: MediaItem.fromTmdb(json, fallback: type)!,
      tagline: (json['tagline'] ?? '').toString(),
      runtime: json['runtime'] as int?,
      genres: names(maps(json['genres'])),
      cast: names(maps(credits['cast']).take(5)),
      makers: type == MediaType.tv
          ? names(maps(json['created_by']))
          : names(maps(credits['crew']).where((p) => p['job'] == 'Director')),
      seasons: type == MediaType.tv ? seasons : const [],
      recommendations: maps(recs['results'])
          .map((m) => MediaItem.fromTmdb(m, fallback: type))
          .whereType<MediaItem>()
          .where((i) => i.posterPath != null)
          .take(12)
          .toList(),
    );
  }
}

/// The episode after season [season] episode [episode], or null at the very end.
({int season, int episode})? nextEpisode(List<SeasonInfo> seasons, int season, int episode) {
  final index = seasons.indexWhere((s) => s.number == season);
  if (index == -1) return null;
  if (episode < seasons[index].episodeCount) return (season: season, episode: episode + 1);
  if (index + 1 < seasons.length) return (season: seasons[index + 1].number, episode: 1);
  return null;
}

/// "1h 52m" or "45m" ('' when unknown).
String runtimeText(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}
