import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/movie.dart';
class RecentMoviesResult {
  final List<Movie> movies;
  final String periodLabel;
  final String description;

  const RecentMoviesResult({
    required this.movies, required this.periodLabel,
    required this.description,
  });
}

class FetchMovie {
  static const String catalogUrl='https://cinemeta-catalogs.strem.io/top/catalog/movie/top.json';
  static const String apiBaseUrl ='https://v3-cinemeta.strem.io';
  static const String detailBaseUrl= '$apiBaseUrl/meta/movie/';
  static const String favoriteKey ='movieverse_favorite_ids';
  static const Duration timeout= Duration(seconds:20);
  static const int minimumRecentMovies=3;
  static const int maxCatalogPages=3;
  static const int catalogPageSize=100;
  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response=await http.get(
      uri, headers: const {
        'Accept': 'application/json',
      },
    )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception (
        'Request failed: HTTP ${response.statusCode}',
      );
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid API response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static List<Map<String, dynamic>> _getMetas(
      Map<String,dynamic> json,
      ) {
    final dynamic metas=json['metas'];
    if (metas is! List) {
      return[];
    }
    return metas
        .whereType<Map>()
        .map((item) => Map<String,dynamic>.from(item))
        .toList();
  }
  static List<Movie> _parseMovies(
      Map<String, dynamic> json,
      ) {
    return _getMetas(json)
        .map(Movie.fromCatalogJson)
        .where((movie) => movie.id.isNotEmpty)
        .toList();
  }
  static Future<List<Movie>> fetchMovies() async {
    final json = await _getJson(Uri.parse(catalogUrl));
    return _parseMovies(json);
  }
  static Future<List<Movie>> searchMovies(String query) async {
    final cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty) {
      return fetchMovies();
    }
    final encodedQuery = Uri.encodeComponent(cleanedQuery);
    final uri = Uri.parse(
      '$apiBaseUrl/catalog/movie/top/search=$encodedQuery.json',
    );
    final json = await _getJson(uri);
    return _parseMovies(json);
  }
  static Future<Movie> fetchMovieDetail(String imdbId) async {
    final id = imdbId.trim();
    if (!RegExp(r'^tt\d+$').hasMatch(id)) {
      throw Exception('Invalid IMDb ID: $id');
    }
    final uri = Uri.parse('$detailBaseUrl$id.json');
    final json = await _getJson(uri);
    final dynamic rawMeta = json['meta'];
    if (rawMeta is! Map) {
      throw Exception('Movie details were not found.');
    }
    final meta = Map<String, dynamic>.from(rawMeta);
    return Movie.fromJson({
      ...meta,
      'id': meta['id'] ?? id,
    });
  }
  static Future<List<Movie>> _fetchMoviesByYear(
      int year,
      ) async {
    final List<Movie> collected = [];
    final Set<String> seenIds = {};
    for (int page = 0; page < maxCatalogPages; page++) {
      final skip = page * catalogPageSize;
      final extra = skip == 0
          ? 'genre=$year' : 'genre=$year&skip=$skip';
      final uri = Uri.parse(
        '$apiBaseUrl/catalog/movie/year/$extra.json',
      );

      try {
        final json = await _getJson(uri);
        final pageMovies = _parseMovies(json);
        for (final movie in pageMovies) {
          if (seenIds.add(movie.id)) {
            collected.add(movie);
          }
        }
        if (pageMovies.length < catalogPageSize) {
          break;
        }

      } catch (_) {
        if (page == 0 && collected.isEmpty) {
          rethrow;
        }
        break;
      }
    }
    return collected;
  }

  static DateTime? _releaseDate(Movie movie) {
    final released = movie.released?.trim();
    if (released == null || released.isEmpty) {
      return null;
    }
    return DateTime.tryParse(released);
  }

  static List<Movie> _sortByNewest(List<Movie> movies){
    final result = List<Movie>.from(movies);
    result.sort((a, b) {
      final dateA = _releaseDate(a);
      final dateB = _releaseDate(b);
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      final yearA = int.tryParse(a.year) ?? 0;
      final yearB = int.tryParse(b.year) ?? 0 ;
      return yearB.compareTo(yearA);
    });
    return result;
  }
  static List<Movie> _filterByPeriod(
      List<Movie> movies, DateTime start, DateTime end,
      ) {
    return _sortByNewest(
      movies.where((movie) {
        final released = _releaseDate(movie);
        if (released == null) {
          return false;
        }
        return !released.isBefore(start) &&
            !released.isAfter(end);
      }).toList(),
    );
  }

  static RecentMoviesResult _selectRecentMovies(
      List<Movie> movies,
      DateTime now,
      ) {
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    final weekStart = today.subtract(const Duration(days: 6));
    final thisWeek = _filterByPeriod(
      movies,
      weekStart,
      end,
    );

    if (thisWeek.length >= minimumRecentMovies) {
      return RecentMoviesResult(
        movies: thisWeek.take(12).toList(), periodLabel: 'THIS WEEK', description: 'Released in the last 7 days',
      );
    }
    final monthStart = today.subtract(
      const Duration(days: 29),
    );
    final thisMonth = _filterByPeriod(
      movies, monthStart, end,
    );
    if (thisMonth.length >= minimumRecentMovies) {
      return RecentMoviesResult(
        movies: thisMonth.take(12).toList(),
        periodLabel:'LAST 30 DAYS',description:'Recently released movies',
      );
    }
    final thisYear = _sortByNewest(
      movies.where((movie) {
        final released = _releaseDate(movie);
        if (released != null) {
          return released.year == now.year &&
              !released.isAfter(now);
        }
        return movie.year == now.year.toString();
      }).toList(),
    );
    return RecentMoviesResult(
      movies: thisYear.take(12).toList(),
      periodLabel: '${now.year} RELEASES', description: 'Movies released this year',
    );
  }
  static Future<RecentMoviesResult> fetchRecentMovies() async {
    final now=DateTime.now();
    final years = <int>[
      now.year,
      if(now.month == 1)now.year - 1,
    ];
    final List<Movie> allMovies = [];
    final Set<String> seenIds = {};
    for (final year in years) {
      final yearMovies=await _fetchMoviesByYear(year);
      for (final movie in yearMovies) {
        if (seenIds.add(movie.id)) {
          allMovies.add(movie);
        }
      }
    }
    if (allMovies.isEmpty) {
      final popularMovies = await fetchMovies();
      for (final movie in popularMovies) {
        if (seenIds.add(movie.id)) {
          allMovies.add(movie);
        }
      }
    }
    return _selectRecentMovies(allMovies, now);
  }
  static Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(favoriteKey) ?? <String>[];
  }
  static Future<bool> isFavorite(String id) async {
    final ids = await getFavoriteIds();
    return ids.contains(id);
  }
  static Future<bool> toggleFavorite(String id) async {
    final cleanedId = id.trim();
    if (cleanedId.isEmpty) {
      throw Exception( 'Invalid movie ID.' );
    }
    final prefs = await SharedPreferences.getInstance();
    final ids =prefs.getStringList(favoriteKey) ?? <String>[];
    if (ids.contains(cleanedId )) {
      ids.remove(cleanedId);
    } else {
      ids.add(cleanedId);
    }
    final uniqueIds=ids.toSet().toList();
    await prefs.setStringList(favoriteKey, uniqueIds);
    return uniqueIds.contains(cleanedId);
  }
  static Future<List<Movie>> fetchFavoriteMovies() async {
    final ids=await getFavoriteIds();
    if(ids.isEmpty) {
      return[];
    }
    final results= await Future.wait<Movie?>(
      ids.toSet().map((id) async {
        try {
          return await fetchMovieDetail(id);
        } catch(_){
          return null;
        }
      }),
    );
    final movies=results.whereType<Movie>().toList();
    if(movies.isEmpty) {
      throw Exception(
        'Unable to load favorite movies. '
            'Check your connection and try again.',
      );
    }
    return movies;
  }
}
