import 'package:flutter/material.dart';
import '../model/movie.dart';
import '../viewmodel/fetchmovie.dart';
import 'app_colors.dart';
import 'detail.dart';

class FavoritesPage extends StatefulWidget{
  final int refreshToken;
  const FavoritesPage({super.key,this.refreshToken = 0} );

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}
class _FavoritesPageState extends State<FavoritesPage>{
  late Future<List<Movie>> _favoritesFuture;

  @override
  void initState(){
    super.initState();
    _favoritesFuture=FetchMovie.fetchFavoriteMovies();
  }

  @override
  void didUpdateWidget(covariant FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _favoritesFuture=FetchMovie.fetchFavoriteMovies();
    }
  }
  Future<void> _reload() async{
    final future = FetchMovie.fetchFavoriteMovies();
    setState(() {
      _favoritesFuture=future;
    });
    try {
      await future;
    } catch (_) {
    }
  }
  Future<void> _openMovie(Movie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
    );
    if(!mounted) return;
    await _reload();
  }
  Future<void> _removeFavorite(Movie movie) async{
    try {
      await FetchMovie.toggleFavorite(movie.id);
      if(!mounted) return;
      await _reload();
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} removed from favorites.'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove movie from favorites.')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _reload,
          child: FutureBuilder<List<Movie>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if(snapshot.hasError) {
                return _buildMessageState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load favorites',
                  subtitle: 'Check your internet connection and try again.',
                  action: 'Try again',
                  onPressed: _reload,
                );
              }
              if(snapshot.connectionState==ConnectionState.waiting && snapshot.data==null){
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 250),
                    Center(child: CircularProgressIndicator()),
                    SizedBox(height: 16),
                    Center(child: Text('Loading favorite movies...')),
                  ],
                );
              }
              final movies = snapshot.data ?? [];
              if(movies.isEmpty){
                return _buildMessageState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Your favorites list is empty',
                  subtitle: 'Save movies you love and they will appear here.',
                );
              }
              return _buildMovieList(movies);
            },
          ),
        ),
      ),
    );
  }
  Widget _buildMovieList(List<Movie> movies) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20,22,20,20),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular( 15),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY FAVORITES',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${movies.length} saved movies',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _reload,
                  tooltip: 'Refresh favorites',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index)  {
              final movie = movies[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FavoriteMovieTile(
                  movie: movie,
                  onTap: () => _openMovie(movie),
                  onRemove: () => _removeFavorite(movie),
                ),
              );
            }, childCount: movies.length),
          ),
        ),
      ],
    );
  }
  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onPressed,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.17),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(icon, size: 58, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (action != null && onPressed != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onPressed, child: Text(action)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
class _FavoriteMovieTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _FavoriteMovieTile({
    required this.movie,
    required this.onTap,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context){
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 112,
                  width: 76,
                  child: movie.hasPoster
                      ? Image.network(
                          movie.poster!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _posterFallback(),
                        )
                      : _posterFallback(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        if(movie.year.isNotEmpty)
                          Text(
                            movie.year,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        if (movie.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie.ratingText,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.genres.take(2).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Tap to view details',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove from favorites',
                icon: const Icon(Icons.favorite, color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _posterFallback() {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, color: AppColors.textSecondary),
    );
  }
}
