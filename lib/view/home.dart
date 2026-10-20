import 'dart:async';
import 'package:flutter/material.dart';
import '../model/movie.dart';
import '../viewmodel/fetchmovie.dart';
import 'app_colors.dart';
import 'detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Movie>> _moviesFuture;
  late Future<RecentMoviesResult> _recentFuture;
  List<Movie> _catalogMovies=[];
  List<Movie> _movies=[];
  List<Movie> _filteredMovies=[];
  Set<String> _favoriteIds={};
  String _selectedGenre = 'All';
  String _sortBy= 'Popular';
  String _searchQuery= '';
  final TextEditingController _searchController =
  TextEditingController();
  Timer? _searchTimer;
  int _searchRequestId = 0;

  final List<String> _sortOptions = [
    'Popular',
    'Top Rated',
    'Title A–Z',
  ];

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadMovies();
    _recentFuture = FetchMovie.fetchRecentMovies();
  }
  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  Future<List<Movie>> _loadMovies() async {
    final results = await Future.wait<Object>([
      FetchMovie.fetchMovies(),
      FetchMovie.getFavoriteIds(),
    ]);
    final movies = results[0] as List<Movie>;
    final favoriteIds = results[1] as List<String>;
    if(!mounted) return movies;
    setState(() {
      _catalogMovies = movies;
      _favoriteIds = favoriteIds.toSet();
      if (_searchQuery.trim().isEmpty) {
        _movies = movies;
      }
      _filteredMovies = _getFilteredMovies();
    });
    return movies;
  }
  Future<void> _refreshMovies() async {
    final moviesFuture = _loadMovies();
    final recentFuture=FetchMovie.fetchRecentMovies();
    setState(() {
      _moviesFuture=moviesFuture;
      _recentFuture=recentFuture;
    });
    try {
      await Future.wait<Object>([
        moviesFuture, recentFuture,
      ]);
    } catch (_) {
    }
  }
  void _onSearchChanged(String value) {
    _searchQuery =value;
    _searchTimer?.cancel();
    if(value.trim().isEmpty) {
      setState(() {
        _movies = _catalogMovies;
        _filteredMovies = _getFilteredMovies();
      });
      return;
    }
    setState(() {
      _filteredMovies = _getFilteredMovies();
    });
    if(value.trim().length < 2) return;
    _searchTimer = Timer(
      const Duration(milliseconds: 500),
          () => _searchFromApi(value.trim()),
    );
  }
  Future<void> _searchFromApi(String query) async {
    final requestId = ++_searchRequestId;
    try {
      final results=await FetchMovie.searchMovies(query);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _movies = results;
        _filteredMovies = _getFilteredMovies();
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Online search failed. Showing available results.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  List<Movie> _getFilteredMovies() {
    List<Movie> result = List<Movie>.from(_movies);
    if (_searchQuery.trim().isNotEmpty){
      final query= _searchQuery.trim().toLowerCase();
      result=result.where((movie){
        return movie.title.toLowerCase().contains(query) || movie.genres.any(
                  (genre) => genre.toLowerCase().contains(query),
            );
      }).toList();
    }
    if (_selectedGenre != 'All') {
      result=result.where((movie) {
        return movie.genres.any(
              (genre) => genre.toLowerCase() == _selectedGenre.toLowerCase(),
        );
      }).toList();
    }
    switch (_sortBy) {
      case 'Top Rated':
        result.sort(
              (a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0),
        );
        break;

      case 'Title A–Z':
        result.sort(
              (a, b) => a.title.toLowerCase().compareTo(
            b.title.toLowerCase(),
          ),
        );
        break;

      case 'Popular':
      default:
        result.sort(
              (a, b) => (b.popularity ?? 0).compareTo(
            a.popularity ?? 0,
          ),
        );
    }
    return result;
  }
  List<String> get _genres {
    final genres = _catalogMovies
        .expand((movie) => movie.genres)
        .where((genre) => genre.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...genres];
  }
  Future<void> _toggleFavorite(Movie movie) async {
    try{
      await FetchMovie.toggleFavorite(movie.id);
      final ids=await FetchMovie.getFavoriteIds();
      if(!mounted) return;
      setState(() {
        _favoriteIds=ids.toSet();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favoriteIds.contains(movie.id)
                ? '${movie.title} added to favorites.'
                : '${movie.title} removed from favorites.',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update favorites.'),
        ),
      );
    }
  }
  Future<void> _openDetails(Movie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailPage(movie: movie),
      ),
    );
    if (!mounted) return;
    final ids = await FetchMovie.getFavoriteIds();
    if(!mounted) return;
    setState(() {
      _favoriteIds = ids.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshMovies,
          child: FutureBuilder<List<Movie>>(
            future: _moviesFuture,
            builder: (context, snapshot) {
              if(snapshot.hasError&&_catalogMovies.isEmpty) {
                return _buildError();
              }
              if (snapshot.connectionState==ConnectionState.waiting&&
                  _catalogMovies.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const[
                    SizedBox(height: 250),
                    Center(
                      child:CircularProgressIndicator(),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child:Text('Loading movies...'),
                    ),
                  ],
                );
              }
              return _buildContent();
            },
          ),
        ),
      ),
    );
  }
  Widget _buildContent() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        SliverToBoxAdapter(
          child: _buildSearch(),
        ),
        if (_searchQuery.trim().isEmpty &&
            _selectedGenre == 'All')
          SliverToBoxAdapter(
            child: _buildRecentReleases(),
          ),
        SliverToBoxAdapter(
          child: _buildSortOptions(),
        ),
        SliverToBoxAdapter(
          child: _buildGenres(),
        ),
        SliverToBoxAdapter(
          child: _buildResultsHeader(),
        ),

        if (_filteredMovies.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmpty(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
                childAspectRatio: width >= 600 ? 0.65 : 0.59,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final movie = _filteredMovies[index];
                  return _MovieCard(
                    movie: movie,
                    isFavorite: _favoriteIds.contains(movie.id),
                    onTap: () => _openDetails(movie),
                    onFavorite: () => _toggleFavorite(movie),
                  );
                },
                childCount: _filteredMovies.length,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.movie_filter_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOVIEVERSE',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                Text(
                  'Discover your next favorite',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh movies',
            onPressed: _refreshMovies,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search movies or genres...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchTimer?.cancel();
              _searchRequestId++;
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _movies = _catalogMovies;
                _filteredMovies = _getFilteredMovies();
              });
            },
            icon: const Icon(Icons.close_rounded),
          )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
  Widget _buildRecentReleases() {
    return FutureBuilder<RecentMoviesResult>(
      future: _recentFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'LATEST RELEASES',
                  Icons.new_releases_rounded,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Recent releases could not be loaded.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState( () {
                      _recentFuture = FetchMovie.fetchRecentMovies();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'LATEST RELEASES',
                  Icons.new_releases_rounded,
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          );
        }

        final result = snapshot.data;
        if (result == null || result.movies.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'LATEST RELEASES',
                  Icons.new_releases_rounded,
                ),
                const SizedBox(height: 10),
                Text(
                  'No release dates are available for ${DateTime.now().year}.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _sectionTitle(
                        'LATEST RELEASES',
                        Icons.new_releases_rounded,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        result.periodLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  result.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 274,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20),
                  itemCount: result.movies.length,
                  separatorBuilder: (_, _) =>
                  const SizedBox(width: 13),
                  itemBuilder: (context, index) {
                    final movie = result.movies[index];
                    return _RecentMovieCard(
                      movie: movie,
                      onTap: () => _openDetails(movie),
                      onFavorite: () => _toggleFavorite(movie),
                      isFavorite: _favoriteIds.contains(movie.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'SORT MOVIES',
            Icons.swap_vert_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: _sortOptions.map((option) {
              final selected = _sortBy == option;
              final icon = option == 'Popular'
                  ? Icons.local_fire_department_rounded
                  : option == 'Top Rated'
                  ? Icons.star_rounded
                  : Icons.sort_by_alpha_rounded;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _sortBy = option;
                        _filteredMovies = _getFilteredMovies();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 19,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenres() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final selected = _selectedGenre == genre;
          return ChoiceChip(
            label: Text(genre),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedGenre = genre;
                _filteredMovies = _getFilteredMovies();
              });
            },
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight:
              selected ? FontWeight.w700 : FontWeight.w500,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: _sectionTitle(
              'EXPLORE MOVIES',
              Icons.grid_view_rounded,
            ),
          ),
          Text(
            '${_filteredMovies.length} movies',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              color: AppColors.textSecondary,
              size: 54,
            ),
            SizedBox(height: 12),
            Text(
              'No movies found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try another search or genre.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 180),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load movies. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshMovies,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _RecentMovieCard extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _RecentMovieCard({
    required this.movie,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });
  String _formatReleaseDate() {
    final value = movie.released?.trim();
    if (value != null && value.isNotEmpty) {
      final date = DateTime.tryParse(value);
      if (date != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    }
    return movie.year.isNotEmpty
        ? movie.year
        : 'Release date unavailable';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: movie.hasPoster
                          ? Image.network(
                        movie.poster!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _posterFallback(),
                      )
                          : _posterFallback(),
                    ),
                  ),
                  Positioned(
                    top: 7, right: 7,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.error : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (movie.rating != null)
                    Positioned(
                      left: 7,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              movie.ratingText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatReleaseDate(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _posterFallback() {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_outlined,
        color: AppColors.textSecondary,
        size: 40,
      ),
    );
  }
}
class _MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _MovieCard({
    required this.movie,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: movie.hasPoster
                        ? Image.network(
                      movie.poster!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _posterFallback(),
                    )
                        : _posterFallback(),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onFavorite,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppColors.error
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                if (movie.rating != null)
                  Positioned(
                    left: 7,
                    bottom: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            movie.ratingText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            movie.year.isNotEmpty ? movie.year : 'Movie',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }


  Widget _posterFallback() {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_outlined,
        color: AppColors.textSecondary,
        size: 40,
      ),
    );
  }
}
