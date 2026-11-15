import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

class Profile {
  Profile({required this.id, required this.name, required this.avatar});
  final String id;
  String name;
  int avatar; // index into avatarColors

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar};

  static Profile? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['name'] is! String) return null;
    return Profile(id: json['id'] as String, name: json['name'] as String, avatar: (json['avatar'] as int?) ?? 0);
  }
}

/// Profiles and everything saved on them. All of it lives on this device
/// (in the app's own storage) and nowhere else.
///
/// Profiles are optional. With no profile picked you are a guest:
/// everything still plays, but nothing is remembered.
///
/// Each profile keeps four lists:
///   list     My List
///   likes    titles given a thumbs up
///   resume   Continue Watching (which episode you were on)
///   history  everything played, newest first
class ProfileStore extends ChangeNotifier {
  ProfileStore(this._prefs) {
    profiles = _readProfiles();
    final activeId = _prefs.getString(activeKey);
    active = profiles.where((p) => p.id == activeId).firstOrNull;
    _readSaved();
  }

  static const profilesKey = 'fakeflix.profiles';
  static const activeKey = 'fakeflix.activeProfile';
  static String dataKey(String profileId) => 'fakeflix.data.$profileId';
  static const maxProfiles = 5;

  static Future<ProfileStore> load() async => ProfileStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  List<Profile> profiles = [];
  Profile? active;

  List<MediaItem> list = [];
  List<MediaItem> likes = [];
  List<MediaItem> resume = [];
  List<MediaItem> history = [];

  bool get isGuest => active == null;

  // ---------- reading and writing ----------

  List<Profile> _readProfiles() {
    try {
      final raw = jsonDecode(_prefs.getString(profilesKey) ?? '[]');
      return (raw as List).map(Profile.fromJson).whereType<Profile>().toList();
    } catch (_) {
      return [];
    }
  }

  void _readSaved() {
    list = [];
    likes = [];
    resume = [];
    history = [];
    final profile = active;
    if (profile == null) return; // guests always start empty
    try {
      final raw = jsonDecode(_prefs.getString(dataKey(profile.id)) ?? '{}') as Map;
      List<MediaItem> read(String kind) =>
          (raw[kind] as List?)?.map(MediaItem.fromJson).whereType<MediaItem>().toList() ?? [];
      list = read('list');
      likes = read('likes');
      resume = read('resume');
      history = read('history');
    } catch (_) {
      // unreadable data: start this profile fresh rather than crash
    }
  }

  void _persist() {
    final profile = active;
    if (profile != null) {
      _prefs.setString(
        dataKey(profile.id),
        jsonEncode({
          'list': [for (final i in list) i.toJson()],
          'likes': [for (final i in likes) i.toJson()],
          'resume': [for (final i in resume) i.toJson()],
          'history': [for (final i in history) i.toJson()],
        }),
      );
    }
    notifyListeners();
  }

  void _persistProfiles() {
    _prefs.setString(profilesKey, jsonEncode([for (final p in profiles) p.toJson()]));
  }

  // ---------- profiles ----------

  void setActive(Profile? profile) {
    active = profile;
    if (profile == null) {
      _prefs.remove(activeKey);
    } else {
      _prefs.setString(activeKey, profile.id);
    }
    _readSaved();
    notifyListeners();
  }

  bool nameTaken(String name, {Profile? except}) =>
      profiles.any((p) => p != except && p.name.toLowerCase() == name.toLowerCase());

  /// The first colour no other profile is using.
  int freeAvatar(int colourCount) {
    final used = profiles.map((p) => p.avatar).toSet();
    for (var i = 0; i < colourCount; i++) {
      if (!used.contains(i)) return i;
    }
    return 0;
  }

  Profile create(String name, int avatar) {
    final id = 'p${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';
    final profile = Profile(id: id, name: name, avatar: avatar);
    profiles.add(profile);
    _persistProfiles();
    notifyListeners();
    return profile;
  }

  void update(Profile profile, String name, int avatar) {
    profile.name = name;
    profile.avatar = avatar;
    _persistProfiles();
    notifyListeners();
  }

  void delete(Profile profile) {
    profiles.remove(profile);
    _persistProfiles();
    _prefs.remove(dataKey(profile.id)); // its lists go with it
    if (active == profile) {
      setActive(null);
    } else {
      notifyListeners();
    }
  }

  // ---------- saved titles ----------

  bool inList(MediaItem item) => list.any(item.sameTitle);
  bool isLiked(MediaItem item) => likes.any(item.sameTitle);
  MediaItem? resumeFor(MediaItem item) => resume.where(item.sameTitle).firstOrNull;
  MediaItem? historyFor(MediaItem item) => history.where(item.sameTitle).firstOrNull;

  bool _toggle(List<MediaItem> target, MediaItem item) {
    final index = target.indexWhere(item.sameTitle);
    if (index == -1) {
      target.insert(0, item.saved());
    } else {
      target.removeAt(index);
    }
    _persist();
    return index == -1; // true when it was just added
  }

  /// Guests can't save: these do nothing and return false for them.
  bool toggleList(MediaItem item) => isGuest ? false : _toggle(list, item);
  bool toggleLike(MediaItem item) => isGuest ? false : _toggle(likes, item);

  void removeResume(MediaItem item) {
    resume.removeWhere(item.sameTitle);
    _persist();
  }

  void clearHistory() {
    history = [];
    _persist();
  }

  /// Something started playing: remember where to resume and add it to the history.
  void recordWatch(MediaItem item, {int? season, int? episode}) {
    if (isGuest) return; // guests leave no trace

    resume = [
      item.saved(season: season, episode: episode),
      ...resume.where((x) => !x.sameTitle(item)),
    ].take(20).toList();

    final watched = [...?historyFor(item)?.episodes];
    if (season != null && episode != null && !watched.contains(episodeTag(season, episode))) {
      watched.add(episodeTag(season, episode));
    }
    history = [
      item.saved(watchedAt: DateTime.now().millisecondsSinceEpoch, episodes: watched),
      ...history.where((x) => !x.sameTitle(item)),
    ].take(200).toList();

    _persist();
  }
}

/// The one store the whole app shares. Set in main() before the app starts.
late ProfileStore store;
