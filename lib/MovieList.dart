import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MovieListScreen extends StatefulWidget {
  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List<dynamic> movies = [];
  List<dynamic> filteredMovies = [];
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int totalMoviesPerPage = 5;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final apiKey = '728dbb65a168c5ae67eb6febf02aefe0'; // Replace with your TMDb API key
    final url = Uri.parse(
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&page=$currentPage&per_page=$totalMoviesPerPage');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData != null && decodedData['results'] != null) {
          setState(() {
            movies.addAll(decodedData['results']);
            filteredMovies = List.from(movies);
            currentPage++;
          });
        } else {
          throw Exception('Invalid response format: Missing "results"');
        }
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      fetchMovies();
    }
  }

  void _filterMovies(String query) {
    List<dynamic> filteredList = movies.where((movie) {
      final title = movie['title'].toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredMovies = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMovies,
              decoration: InputDecoration(
                labelText: 'Search Movies',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredMovies.length,
              itemBuilder: (context, index) {
                final movie = filteredMovies[index];

                return ListTile(
                  leading: movie['poster_path'] != null
                      ? Image.network(
                    'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : SizedBox.shrink(),
                  title: Text(movie['title'] ?? 'Untitled'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Release Year: ${movie['release_date']?.substring(0, 4) ?? 'N/A'}'),
                      Text('IMDb Rating: ${movie['vote_average'] ?? 'N/A'}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
