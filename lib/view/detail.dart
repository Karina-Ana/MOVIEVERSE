import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../model/movie.dart';
import 'app_colors.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  const MovieDetailPage({
    super.key,
    required this.movie,
  });
  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  static const String _baseUrl = 'https://v3-cinemeta.strem.io';
  static const String _wikipediaUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary/';
  Map<String, dynamic>? _details;
  final Map<String, String?> _castImages = {};
  bool _isLoading = true;
  bool _showFullDescription = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }
  Future<void> _loadDetails() async {
    setState(() {
      _isLoading =true;
      _errorMessage=null;
    });

    try {
      final id=widget.movie.id.trim();
      if (!RegExp(r'^tt\d+$').hasMatch(id)) {
        throw Exception('IMDb ID film tidak valid.');
      }
      final response = await http
          .get(
        Uri.parse('$_baseUrl/meta/movie/$id.json'),
        headers: const {'Accept': 'application/json'},
      )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil detail film (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format respons API tidak valid.');
      }
      final meta = decoded['meta'];
      if (meta is! Map<String, dynamic>) {
        throw Exception('Detail film tidak ditemukan.');
      }
      if (!mounted ) return;
      setState(() {
        _details = meta;
        _isLoading= false ;
      });
      _loadCastImages();
    } catch (error ) {
      if (!mounted) return;

      setState(() {
        _errorMessage =error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      }) ;
    }
  }

  String _stringValue(dynamic value) {
    if(value==null) return '';
    return value.toString().trim();
  }

  List<String> _stringList(dynamic value) {
    if(value is! List) return[];
    final result=<String>[];
    final seen=<String>{};
    for (final item in value) {
      final name=_stringValue(item) ;
      if (name.isNotEmpty&&seen.add(name.toLowerCase())){
        result.add(name);
      }
    }
    return result;
  }

  String _getFirstValue(List<String> keys) {
    final details=_details;
    if (details==null)return '';
    for (final key in keys) {
      final value=_stringValue(details[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  List<String> _getNames(List<String> keys) {
    final details = _details;
    if (details == null) return[];

    for (final key in keys) {
      final values = _stringList(details[key]);
      if ( values.isNotEmpty ) return values;
    }
    return[];
  }
  List<String>get _cast=>_getNames(['cast']);
  List<String>get _directors=>_getNames(['director','directors']);
  List<String>get _genres=>_getNames(['genres']);
  String get _description => _getFirstValue(['description', 'overview']);
  String get _title {
    final value=_getFirstValue(['name']);
    return value.isNotEmpty?value:widget.movie.title;
  }
  String get _poster{
    final value=_getFirstValue(['poster']);
    if (value.isNotEmpty) return value;
    return widget.movie.poster ?? '';
  }
  String get _background => _getFirstValue(['background']);
  String get _year{
    final value = _getFirstValue(['releaseInfo','year']);
    if (value.isNotEmpty) return value;
    final released = _getFirstValue(['released']);
    if (released.length >= 4) {
      return released.substring(0, 4);
    }
    return widget.movie.year.toString();
  }

  String get _rating {
    final value = _getFirstValue(['imdbRating', 'rating']);
    return value.isNotEmpty ? value : widget.movie.ratingText;
  }
  String get _released {
    final value = _getFirstValue(['released']);
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Future<void> _loadCastImages() async {
    final cast = _cast;

    await Future.wait(
      cast.map((actor) async {
        if( _castImages.containsKey(actor) ) return;
        String? imageUrl;
        try {
          final pageName = actor.trim().replaceAll(' ','_');
          final uri = Uri.parse(
            '$_wikipediaUrl${Uri.encodeComponent(pageName)}',
          );
          final response = await http
              .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'MOVIEVERSE/1.0',
            },
          )
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if ( decoded is Map<String,dynamic>) {
              final thumbnail = decoded['thumbnail'];
              if (thumbnail is Map<String,dynamic>) {
                final source = thumbnail['source'];
                if (source is String&&source.isNotEmpty) {
                  imageUrl =source;
                }
              }
              if (imageUrl == null) {
                final original =decoded['originalimage'];
                if (original is Map<String, dynamic>){
                  final source= original['source'];
                  if (source is String && source.isNotEmpty){
                    imageUrl=source;
                  }
                }
              }
            }
          }
        } catch (_) {
        }

        if (!mounted) return;
        setState(() {
          _castImages[actor] = imageUrl;
        });
      }),
    );
  }

  List<Map<String, String>> get _trailers {
    final details = _details;
    if (details == null) return [];
    final result = <Map<String, String>>[];
    final seen = <String> {};
    final rawTrailers = details['trailers'];
    if(rawTrailers is List) {
      for(final item in rawTrailers) {
        if(item is! Map) continue;
        final source = _stringValue(item['source']);
        final type = _stringValue(item['type']);
        if(source.isEmpty || !seen.add(source)) continue;

        result.add({
          'source': source,
          'type': type.isEmpty ? 'Trailer' : type,
        });
      }
    }
    final rawStreams = details['trailerStreams'];
    if (rawStreams is List){
      for(final item in rawStreams){
        if(item is! Map) continue;
        final source = _stringValue(item['ytId']).isNotEmpty
            ? _stringValue(item['ytId'])
            : _stringValue(item['url']);
        if (source.isEmpty || !seen.add(source)) continue;

        result.add({
          'source': source,
          'type': 'Trailer',
        });
      }
    }
    return result;
  }
  Future<void> _openTrailer(String source) async {
    final url = source.startsWith('http://') || source.startsWith('https://')
        ? source : 'https://www.youtube.com/watch?v=$source';
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Link trailer tidak valid.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Tidak dapat membuka trailer.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Tidak dapat membuka trailer.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar (
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Detail film gagal dimuat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHero()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildTitleSection(),
              const SizedBox(height: 24),
              _buildOverview(),
              if (_genres.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildGenres(),
              ],
              const SizedBox(height: 28),
              _buildInformation(),
              if (_directors.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildTextSection(
                  title: 'Director',
                  icon: Icons.movie_creation_outlined,
                  content: _directors.join(', '),
                ),
              ],
              if (_cast.isNotEmpty) ...[
                const SizedBox(height: 30),
                _buildCast(),
              ],
              if (_trailers.isNotEmpty) ...[
                const SizedBox(height: 30),
                _buildTrailers(),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Stack(
      children: [
        SizedBox(
          height: 390,
          width: double.infinity,
          child: _background.isNotEmpty
              ? Image.network(
            _background,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPosterBackground(),
          )
              : _buildPosterBackground(),
        ),
        Container(
          height: 390,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                AppColors.background.withValues(alpha: 0.72),
                AppColors.background,
              ],
              stops: const [0.0, 0.65, 1.0],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          child: _circleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 125,
                  height: 185,
                  child: _poster.isNotEmpty
                      ? Image.network(
                    _poster,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _posterPlaceholder(),
                  )
                      : _posterPlaceholder(),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_rating.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                                size: 17,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _rating,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'IMDb',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        _year,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPosterBackground() {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        size: 80,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }
  Widget _posterPlaceholder() {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_outlined,
        size: 42,
        color: AppColors.textSecondary,
      ),
    );
  }
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _smallInfo(Icons.calendar_today_rounded, _year) ,
            if(_released.isNotEmpty)
              _smallInfo(Icons.event_rounded, _released),
            _smallInfo(Icons.fingerprint_rounded, widget.movie.id),
          ],
        ),
      ],
    );
  }
  Widget _smallInfo(IconData icon, String text){
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildOverview() {
    final description = _description ;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Overview', icon: Icons.subject_rounded),
        const SizedBox(height: 12),
        if (description.isEmpty)
          const Text(

            'Deskripsi film belum tersedia dari API Cinemeta.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          )
        else ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Text(
              description,
              maxLines: _showFullDescription ? null : 4,
              overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
          if (description.length > 180) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _showFullDescription = !_showFullDescription;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showFullDescription ? 'See less' : 'See more',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _showFullDescription ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
  Widget _buildGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Genres', icon: Icons.category_outlined),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.13),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                genre,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildInformation() {
    final items = <MapEntry<String, String>>[
      MapEntry('IMDb ID', widget.movie.id),
      MapEntry('Year', _year),
      MapEntry('Released', _released),
      MapEntry('Runtime', _getFirstValue(['runtime'] )),
      MapEntry('Country', _getFirstValue(['country'])),
      MapEntry('Language', _getFirstValue(['language'])),
      MapEntry(
        'Certification',
        _getFirstValue(['certification', 'contentRating']),
      ),
      MapEntry('Awards', _getFirstValue(['awards'])),
      MapEntry('Website', _getFirstValue(['website'])),
      MapEntry('Writer', _getFirstValue(['writer', 'writers'])),
      MapEntry('Popularity', _getFirstValue(['popularity'])),
    ].where((item) => item.value.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Movie Information', icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 105,
                          child: Text(
                            item.key,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.value,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != items.length - 1)
                    Divider(height: 1, color: AppColors.divider),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(title, icon: icon),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ],
    );
  }
  Widget _buildCast() {
    final cast = _cast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Cast',
          icon: Icons.people_alt_outlined,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (context, index) =>
            const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final actor = cast[index];
              final imageUrl = _castImages[actor];

              return SizedBox(
                width: 92,
                child: Column(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (
                              context, error, stackTrace,
                              ) =>
                              _actorPlaceholder(actor),
                        )
                            : _actorPlaceholder(actor),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Expanded(
                      child: Center(
                        child: Text(
                          actor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actorPlaceholder(String actor) {
    final initial = actor.trim().isEmpty
        ? '?' : actor.trim()[0].toUpperCase();

    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  Widget _buildTrailers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Trailers',
          icon: Icons.play_circle_outline_rounded,
        ),
        const SizedBox(height: 12),
        ..._trailers.map((trailer) {
          final source = trailer['source'] ?? '';
          final type = trailer['type'] ?? 'Trailer';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 32,
              ),
              title: Text(
                type,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Tonton di YouTube',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              onTap: () => _openTrailer(source),
            ),
          );
        }),
      ],
    );
  }
  Widget _sectionHeading(
      String title, {
        required IconData icon,
      }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

}
