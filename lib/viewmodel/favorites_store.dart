import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/movie.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();
  static final FavoritesStore instance =FavoritesStore._();
  static const String _storageKey = 'movieverse_favorites';
  final Map<String, Movie> _favorites = {};
  bool _initialized =false;
  List<Movie> get movies => _favorites.values.toList();
  bool get isInitialized=> _initialized;
  bool contains(String id)=> _favorites.containsKey(id);
  Future<void> init() async{
    if (_initialized) return;
    final preferences=await SharedPreferences.getInstance();
    final storedData=preferences.getString(_storageKey);
    if (storedData != null && storedData.isNotEmpty) {
      try {
        final decoded=jsonDecode(storedData);
        if(decoded is List){
          for(final item in decoded){
            if(item is Map){
              final movie=Movie.fromStorage(Map<String,dynamic>.from(item));
              if (movie.id.isNotEmpty) {
                _favorites[movie.id]=movie;
              }
            }
          }
        }
      } catch (_) {
        _favorites.clear();
      }
    }
    _initialized = true;
    notifyListeners();
  }
  Future<void> toggle(Movie movie) async {
    if (movie.id.isEmpty) return;
    if (_favorites.containsKey(movie.id)) {
      _favorites.remove(movie.id);
    } else {
      _favorites[movie.id] = movie;
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    if (!_favorites.containsKey(id)) return;
    _favorites.remove(id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final preferences=await SharedPreferences.getInstance();
    final data = _favorites.values.map((movie) => movie.toJson()).toList();
    await preferences.setString(_storageKey, jsonEncode(data));
  }
}
