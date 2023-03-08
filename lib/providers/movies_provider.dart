import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'  as http;
import 'package:movies/helpers/debouncer.dart';
import 'package:movies/models/models.dart';
import 'package:movies/models/movie.dart';
import 'package:movies/models/now_playing_response.dart';
import 'package:movies/models/popular_response.dart';

class MoviesProvider extends ChangeNotifier {
  
  String _apiKey = 'dfb9b32a7ce3056eb514629b2573477a';
  String _baseUrl = 'api.themoviedb.org';
  String _language = 'es-ES';

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];

  Map<int, List<Cast>> moviesCast = {};

  int _popularPage = 0;

  final debouncer = Debouncer(duration: Duration(milliseconds: 500));
  final StreamController<List<Movie>> _suggestionsStreamController = new StreamController.broadcast();
  Stream<List<Movie>> get suggestionStream => this._suggestionsStreamController.stream;

  MoviesProvider(){
    getOnDisplayMovies();
    getPopularMovies();
  }

  Future<String> _getJsonData(String endpoint, {int page = 1}) async {
    var url = Uri.https(_baseUrl, endpoint,
      {
        'api_key':_apiKey,
        'language': _language,
        'page': '$page'
      }
    );

    final response = await http.get(url);
    return response.body;
  }

  getOnDisplayMovies() async {

    final jsonData = await  _getJsonData('3/movie/now_playing');
    final Map<String, dynamic> decodeData = json.decode(jsonData);
    final  nowPlayingResponse = NowPlayingResponse.fromJson(decodeData);
    
    onDisplayMovies = nowPlayingResponse.results;
    notifyListeners();
    
  }

  getPopularMovies() async {

    _popularPage +=1; 
    final jsonData = await  _getJsonData('3/movie/popular', page: _popularPage);
    final Map<String, dynamic> decodeData = json.decode(jsonData);
    final  popularResponse = PopularResponse.fromJson(decodeData);
    
    popularMovies = [...popularMovies, ...popularResponse.results];
    notifyListeners();
  }

  Future<List<Cast>> getMovieCast(int movieId) async {

    if (moviesCast.containsKey(movieId)) {
       return moviesCast[movieId]!; 
    }
    final jsonData = await _getJsonData('3/movie/$movieId/credits');
    final Map<String, dynamic> decodeData = json.decode(jsonData);
    final creditsResponse = CreditsResponse.fromJson(decodeData);

    moviesCast[movieId] = creditsResponse.cast;

    return creditsResponse.cast;
  }

  Future<List<Movie>> searchMovies(String query) async{
    var url = Uri.https(_baseUrl, '3/search/movie',
      {
        'api_key':_apiKey,
        'language': _language,
        'query': '$query'
      }
    );
    final response = await http.get(url);
    final Map<String, dynamic> decodeData = json.decode(response.body);
    final searchResponse = SearchResponse.fromJson(decodeData);
    return searchResponse.results;
  }

  void getSugesstionByQuery(String searchTerm){
    debouncer.value = '';
    debouncer.onValue = ( value ) async {
        final results = await searchMovies(value);
        _suggestionsStreamController.add(results);
    };

    final timer = Timer.periodic(Duration(milliseconds: 200), (_) {
        debouncer.value = searchTerm;
     });

     Future.delayed(Duration(milliseconds: 301)).then((_) => timer.cancel());
  }

}