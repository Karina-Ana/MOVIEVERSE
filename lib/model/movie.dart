class Movie {
  final String id;
  final String title;
  final String type;
  final String? poster;
  final String? background;
  final String? logo;
  final String? description;
  final String? releaseInfo;
  final String? released;
  final String? runtime;
  final String? director;
  final String? writer;
  final String? country;
  final String? language;
  final String? awards;
  final String? certification;
  final num? rating;
  final num? popularity;
  final List<String> genres;
  final List<String> cast;
  final List<dynamic> trailerStreams;
  final List<dynamic> links;
  final Map<String, dynamic> rawData;

  const Movie({
    required this.id,
    required this.title,
    this.type='movie',
    this.poster,
    this.background,
    this.logo,
    this.description,
    this.releaseInfo,
    this.released,
    this.runtime,
    this.director,
    this.writer,
    this.country,
    this.language,
    this.awards,
    this.certification,
    this.rating,
    this.popularity,
    this.genres=const[],
    this.cast=const[],
    this.trailerStreams= const[],
    this.links =const[],
    this.rawData = const{},
  });

  factory Movie.fromCatalogJson(Map<String,dynamic>json) {
    return Movie.fromJson(json);
  }
  factory Movie.fromStorage(Map<String,dynamic>json ) {
    return Movie.fromJson(json);
  }
  factory Movie.fromJson(Map<String,dynamic> json ) {
    String? itemToText(dynamic value) {
      if (value==null) return null;
      if (value is Map) {
        final name=value['name']??value['title']??value['character'];
        return name?.toString().trim();
      }
      final text=value.toString().trim();
      if (text.isEmpty||text.toLowerCase()=='null') {
        return null;
      }
      return text;
    }

    String? readString(List<String>keys) {
      for(final key in keys) {
        final value=json[key];
        if(value==null) continue;
        if (value is List) {
          final values = value
              .map(itemToText)
              .whereType<String>()
              .where((item) => item.isNotEmpty)
              .toList();
          if (values.isNotEmpty) {
            return values.join(', ');
          }
          continue;
        }
        final text = itemToText(value);
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
      return null;
    }

    num? readNumber(List< String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) {
          return value;
        }
        if (value != null) {
          final parsed=num.tryParse(value.toString());
          if (parsed != null) {
            return parsed;
          }
        }
      }
      return null;
    }

    List<String> readStringList(List<String> keys) {
      for (final key in keys) {
        final value =json[key];
        if (value is List) {
          return value
              .map(itemToText)
              .whereType<String>()
              .where((item) => item.isNotEmpty)
              .toList();
        }
        if (value is String && value.trim().isNotEmpty) {
          return [value.trim()];
        }
      }
      return [];
    }

    List<dynamic> readDynamicList(List<String> keys) {
      for (final key in keys) {
        final value=json[key];
        if (value is List) {
          return List<dynamic>.from(value);
        }
      }
      return [];
    }
    final rawId = readString(['id', 'imdb_id','imdbId'])??'';
    return Movie(
      id: rawId,
      title: readString(['name','title'])??'Untitled Movie',
      type: readString(['type'] )??'movie',
      poster:  readString(['poster','posterUrl']),
      background: readString(['background','backgroundUrl' ,'backdrop']),
      logo:readString(['logo']),
      description:readString(['description','overview']),
      releaseInfo:readString(['releaseInfo','release_info']),
      released:readString(['released']),
      runtime:readString(['runtime']),
      director: readString(['director','directors'] ),
      writer:readString( ['writer','writers']),
      country:readString(['country','countries' ]),
      language:readString(['language','languages']),
      awards:readString(['awards']),
      certification:readString(['certification'] ),
      rating:readNumber(['imdbRating','rating','imdb_rating']) ,
      popularity:readNumber(['popularity']),
      genres:readStringList(['genre', 'genres']),
      cast:readStringList(['cast']),
      trailerStreams:readDynamicList(['trailerStreams']) ,
      links:readDynamicList(['links' ]),
      rawData: Map<String, dynamic>.from(json),
    );
  }

  String get year {
    final info=releaseInfo?.trim();
    if (info != null&&info.isNotEmpty) {
      final match=RegExp(r'\d{4}').firstMatch(info);
      if (match != null) {
        return match.group(0)!;
      }
    }
    final date=released?.trim();
    if (date != null&&date.isNotEmpty) {
      final match=RegExp(r'\d{4}').firstMatch(date);
      if (match!=null) {
        return match.group(0)!;
      }
    }
    return '';
  }

  String get ratingText {
    return rating == null ? 'N/A':rating!.toStringAsFixed(1);
  }
  String get imdbId => id;
  bool get hasPoster => poster != null && poster!.trim().isNotEmpty;
  bool get hasBackground => background != null && background!.trim().isNotEmpty;
  bool get hasDescription =>
      description != null && description!.trim().isNotEmpty;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'type': type,
      'poster': poster,
      'background':background,
      'logo': logo,
      'description': description,
      'releaseInfo': releaseInfo,
      'released':released,
      'runtime': runtime,
      'director': director,
      'writer': writer,
      'country': country,
      'language':language,
      'awards': awards ,
      'certification': certification,
      'imdbRating': rating,
      'popularity': popularity,
      'genres': genres,
      'cast':cast,
      'trailerStreams': trailerStreams,
      'links': links,
    };
  }
}
