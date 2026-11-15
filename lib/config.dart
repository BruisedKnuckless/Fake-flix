/// Streaming embed + TMDB settings. Same values as the website (script.js).
library;

const apiBase = 'https://vidsrc.mov';
String movieUrl(int id) => '$apiBase/embed/movie/$id';
String tvUrl(int id, int season, int ep) => '$apiBase/embed/tv/$id/$season/$ep';

const tmdbKey = '67efa981973baa37ef02e529456ba057';
const tmdbBase = 'https://api.themoviedb.org/3';
const imageBase = 'https://image.tmdb.org/t/p';

/// Full image address for a TMDB path, e.g. imageUrl('/abc.jpg', 'w342').
/// Returns '' when the title has no image.
String imageUrl(String? path, String size) =>
    (path == null || path.isEmpty) ? '' : '$imageBase/$size$path';
