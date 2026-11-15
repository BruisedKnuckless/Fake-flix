import 'package:fakeflix/data/models.dart';
import 'package:fakeflix/state/profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const movie = MediaItem(id: 550, type: MediaType.movie, title: 'Fight Club');
const show = MediaItem(id: 1396, type: MediaType.tv, title: 'Breaking Bad');

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('a guest can use the app but nothing is saved', () {
    final store = ProfileStore(prefs);
    expect(store.isGuest, isTrue);

    expect(store.toggleList(movie), isFalse);
    expect(store.toggleLike(movie), isFalse);
    store.recordWatch(show, season: 1, episode: 2);

    expect(store.list, isEmpty);
    expect(store.resume, isEmpty);
    expect(store.history, isEmpty);
    expect(prefs.getKeys(), isEmpty);
  });

  test('a profile keeps its list, likes, resume point and history across restarts', () {
    final store = ProfileStore(prefs);
    store.setActive(store.create('Alex', 1));

    expect(store.toggleList(movie), isTrue);
    expect(store.toggleLike(show), isTrue);
    store.recordWatch(show, season: 1, episode: 2);
    store.recordWatch(show, season: 1, episode: 3);
    store.recordWatch(movie);

    // "Restart": a new store reading the same storage
    final again = ProfileStore(prefs);
    expect(again.active?.name, 'Alex');
    expect(again.inList(movie), isTrue);
    expect(again.isLiked(show), isTrue);
    expect(again.isLiked(movie), isFalse);

    // newest first, one entry per title, pointing at the latest episode
    expect(again.resume.map((i) => i.title), ['Fight Club', 'Breaking Bad']);
    final resume = again.resumeFor(show)!;
    expect((resume.season, resume.episode), (1, 3));
    expect(again.historyFor(show)!.episodes, ['1x2', '1x3']);
    expect(again.resumeFor(movie)!.season, isNull);
  });

  test('toggling twice removes the title again', () {
    final store = ProfileStore(prefs);
    store.setActive(store.create('Alex', 0));
    store.toggleList(movie);
    expect(store.toggleList(movie), isFalse);
    expect(store.inList(movie), isFalse);
  });

  test('profiles are kept separate', () {
    final store = ProfileStore(prefs);
    final alex = store.create('Alex', 0);
    final sam = store.create('Sam', store.freeAvatar(8));
    expect(sam.avatar, 1); // first colour Alex isn't using

    store.setActive(alex);
    store.toggleList(movie);

    store.setActive(sam);
    expect(store.list, isEmpty);
    store.toggleList(show);

    store.setActive(alex);
    expect(store.list.map((i) => i.title), ['Fight Club']);

    store.setActive(null); // back to guest
    expect(store.list, isEmpty);
    expect(ProfileStore(prefs).isGuest, isTrue);
  });

  test('removing from Continue Watching and clearing history', () {
    final store = ProfileStore(prefs);
    store.setActive(store.create('Alex', 0));
    store.recordWatch(movie);
    store.recordWatch(show, season: 2, episode: 1);

    store.removeResume(movie);
    expect(store.resume.map((i) => i.title), ['Breaking Bad']);
    expect(store.history, hasLength(2)); // history is untouched

    store.clearHistory();
    expect(store.history, isEmpty);
    expect(store.resume, hasLength(1)); // Continue Watching is kept
  });

  test('deleting a profile deletes its data and signs it out', () {
    final store = ProfileStore(prefs);
    final alex = store.create('Alex', 0);
    store.setActive(alex);
    store.toggleList(movie);
    expect(prefs.getString(ProfileStore.dataKey(alex.id)), isNotNull);

    store.delete(alex);
    expect(store.profiles, isEmpty);
    expect(store.isGuest, isTrue);
    expect(prefs.getString(ProfileStore.dataKey(alex.id)), isNull);
  });

  test('names must be unique, ignoring case', () {
    final store = ProfileStore(prefs);
    final alex = store.create('Alex', 0);
    expect(store.nameTaken('alex'), isTrue);
    expect(store.nameTaken('alex', except: alex), isFalse); // renaming yourself is fine
    expect(store.nameTaken('Sam'), isFalse);
  });
}
