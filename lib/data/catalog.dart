/// Which rows each page shows, and the Categories list.
/// Same tables as the website (ROWS and CATEGORIES in script.js).
library;

import 'models.dart';

class RowDef {
  const RowDef(this.title, this.path, {this.type, this.params = const {}, this.top10 = false});
  final String title;
  final String path;

  /// Set when the endpoint returns only movies or only shows.
  final MediaType? type;
  final Map<String, String> params;
  final bool top10;
}

const _movie = MediaType.movie;
const _tv = MediaType.tv;

const browseRows = <String, List<RowDef>>{
  'home': [
    RowDef('Trending Now', '/trending/all/week'),
    RowDef('Top 10 Today', '/trending/all/day', top10: true),
    RowDef('Popular Movies', '/movie/popular', type: _movie),
    RowDef('Popular TV Shows', '/discover/tv', type: _tv, params: {'vote_count.gte': '300'}),
    RowDef('Top Rated Movies', '/movie/top_rated', type: _movie),
    RowDef('Action & Adventure', '/discover/movie', type: _movie, params: {'with_genres': '28'}),
    RowDef('Comedies', '/discover/movie', type: _movie, params: {'with_genres': '35'}),
    RowDef('Sci-Fi & Fantasy TV', '/discover/tv', type: _tv, params: {'with_genres': '10765', 'vote_count.gte': '100'}),
    RowDef('Horror', '/discover/movie', type: _movie, params: {'with_genres': '27'}),
    RowDef('Critically Acclaimed TV', '/tv/top_rated', type: _tv),
    RowDef('Documentaries', '/discover/movie', type: _movie, params: {'with_genres': '99'}),
  ],
  'movies': [
    RowDef('Trending Movies', '/trending/movie/week', type: _movie),
    RowDef('Top 10 Movies Today', '/trending/movie/day', type: _movie, top10: true),
    RowDef('Popular', '/movie/popular', type: _movie),
    RowDef('In Theaters Now', '/movie/now_playing', type: _movie),
    RowDef('Top Rated', '/movie/top_rated', type: _movie),
    RowDef('Action', '/discover/movie', type: _movie, params: {'with_genres': '28'}),
    RowDef('Comedy', '/discover/movie', type: _movie, params: {'with_genres': '35'}),
    RowDef('Thrillers', '/discover/movie', type: _movie, params: {'with_genres': '53'}),
    RowDef('Sci-Fi', '/discover/movie', type: _movie, params: {'with_genres': '878'}),
    RowDef('Horror', '/discover/movie', type: _movie, params: {'with_genres': '27'}),
    RowDef('Romance', '/discover/movie', type: _movie, params: {'with_genres': '10749'}),
    RowDef('Animation', '/discover/movie', type: _movie, params: {'with_genres': '16'}),
  ],
  'tv': [
    RowDef('Trending Shows', '/trending/tv/week', type: _tv),
    RowDef('Top 10 Shows Today', '/trending/tv/day', type: _tv, top10: true),
    RowDef('Popular', '/discover/tv', type: _tv, params: {'vote_count.gte': '300'}),
    RowDef('Top Rated', '/tv/top_rated', type: _tv),
    RowDef('Drama', '/discover/tv', type: _tv, params: {'with_genres': '18', 'vote_count.gte': '100'}),
    RowDef('Comedy', '/discover/tv', type: _tv, params: {'with_genres': '35', 'vote_count.gte': '100'}),
    RowDef('Crime', '/discover/tv', type: _tv, params: {'with_genres': '80', 'vote_count.gte': '100'}),
    RowDef('Sci-Fi & Fantasy', '/discover/tv', type: _tv, params: {'with_genres': '10765', 'vote_count.gte': '100'}),
    RowDef('Animation', '/discover/tv', type: _tv, params: {'with_genres': '16', 'vote_count.gte': '100'}),
    RowDef('Mystery', '/discover/tv', type: _tv, params: {'with_genres': '9648', 'vote_count.gte': '100'}),
    RowDef('Docuseries', '/discover/tv', type: _tv, params: {'with_genres': '99', 'vote_count.gte': '50'}),
  ],
  'new': [
    RowDef("Everyone's Watching", '/trending/all/day'),
    RowDef('Top 10 Movies Today', '/trending/movie/day', type: _movie, top10: true),
    RowDef('Top 10 Shows Today', '/trending/tv/day', type: _tv, top10: true),
    RowDef('Coming Soon', '/movie/upcoming', type: _movie),
    RowDef('New in Theaters', '/movie/now_playing', type: _movie),
    RowDef('New Episodes This Week', '/tv/on_the_air', type: _tv),
    RowDef('Airing Today', '/tv/airing_today', type: _tv),
  ],
};

/// Which type of title each page is limited to (null = both).
/// Only these three pages show the profile's own rows.
const viewType = <String, MediaType?>{'home': null, 'movies': _movie, 'tv': _tv};

const viewTitles = <String, String>{
  'home': 'Home',
  'tv': 'TV Shows',
  'movies': 'Movies',
  'new': 'New & Hot',
};

/// TMDB uses different genre ids for movies and TV, and some genres only
/// exist for movies ([tv] is null).
class GenreCategory {
  const GenreCategory(this.name, {required this.movie, this.tv});
  final String name;
  final String movie;
  final String? tv;

  String? idFor(MediaType type) => type == MediaType.movie ? movie : tv;
}

const categories = <GenreCategory>[
  GenreCategory('Action', movie: '28', tv: '10759'),
  GenreCategory('Animation', movie: '16', tv: '16'),
  GenreCategory('Comedies', movie: '35', tv: '35'),
  GenreCategory('Crime', movie: '80', tv: '80'),
  GenreCategory('Documentaries', movie: '99', tv: '99'),
  GenreCategory('Dramas', movie: '18', tv: '18'),
  GenreCategory('Kids & Family', movie: '10751', tv: '10751'),
  GenreCategory('Fantasy', movie: '14'),
  GenreCategory('Horror', movie: '27'),
  GenreCategory('Mysteries', movie: '9648', tv: '9648'),
  GenreCategory('Romance', movie: '10749'),
  GenreCategory('Sci-Fi', movie: '878', tv: '10765'),
  GenreCategory('Thrillers', movie: '53'),
];
