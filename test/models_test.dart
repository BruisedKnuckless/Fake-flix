import 'package:fakeflix/config.dart';
import 'package:fakeflix/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextEpisode', () {
    const seasons = [SeasonInfo(1, 7), SeasonInfo(2, 13), SeasonInfo(4, 3)];

    test('moves to the next episode in the same season', () {
      expect(nextEpisode(seasons, 1, 3), (season: 1, episode: 4));
    });

    test('rolls over to the first episode of the next season', () {
      expect(nextEpisode(seasons, 1, 7), (season: 2, episode: 1));
    });

    test('skips season numbers that do not exist', () {
      expect(nextEpisode(seasons, 2, 13), (season: 4, episode: 1));
    });

    test('is null after the last episode and for unknown seasons', () {
      expect(nextEpisode(seasons, 4, 3), isNull);
      expect(nextEpisode(seasons, 9, 1), isNull);
    });
  });

  group('MediaItem', () {
    test('reads a movie and a show from TMDB results', () {
      final movie = MediaItem.fromTmdb({
        'id': 550,
        'title': 'Fight Club',
        'release_date': '1999-10-15',
        'vote_average': 8.4,
        'poster_path': '/p.jpg',
      }, fallback: MediaType.movie)!;
      expect((movie.type, movie.title, movie.year, movie.matchPercent), (MediaType.movie, 'Fight Club', '1999', 84));

      final show = MediaItem.fromTmdb({'id': 1396, 'media_type': 'tv', 'name': 'Breaking Bad', 'first_air_date': '2008-01-20'})!;
      expect((show.type, show.title, show.year), (MediaType.tv, 'Breaking Bad', '2008'));
    });

    test('skips people and results with no usable type', () {
      expect(MediaItem.fromTmdb({'id': 1, 'media_type': 'person', 'name': 'Someone'}), isNull);
      expect(MediaItem.fromTmdb({'id': 1, 'name': 'No type'}), isNull);
    });

    test('survives being saved and read back', () {
      const item = MediaItem(id: 1396, type: MediaType.tv, title: 'Breaking Bad', posterPath: '/p.jpg', vote: 9);
      final saved = item.saved(season: 2, episode: 5, watchedAt: 1234, episodes: const ['2x5']);
      final back = MediaItem.fromJson(saved.toJson())!;
      expect(back.sameTitle(item), isTrue);
      expect((back.season, back.episode, back.watchedAt), (2, 5, 1234));
      expect(back.episodes, ['2x5']);
      expect(back.posterPath, '/p.jpg');
    });
  });

  test('seasons skip specials and empty seasons', () {
    final details = MediaDetails.fromTmdb({
      'id': 1,
      'name': 'Show',
      'seasons': [
        {'season_number': 0, 'episode_count': 4},
        {'season_number': 2, 'episode_count': 8},
        {'season_number': 1, 'episode_count': 10},
        {'season_number': 3, 'episode_count': 0},
      ],
    }, MediaType.tv);
    expect(details.seasons.map((s) => s.number), [1, 2]);
  });

  test('embed addresses match the website', () {
    expect(movieUrl(550), 'https://vidsrc.mov/embed/movie/550');
    expect(tvUrl(1396, 3, 13), 'https://vidsrc.mov/embed/tv/1396/3/13');
  });

  test('runtimeText', () {
    expect(runtimeText(112), '1h 52m');
    expect(runtimeText(45), '45m');
    expect(runtimeText(null), '');
  });
}
