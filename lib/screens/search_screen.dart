import 'package:flutter/material.dart';
import 'package:untitled1/constants/colors.dart';
import 'package:untitled1/model/movie_model.dart';
import '../data/movie_data.dart';
import '../uikit/widgets/movie_card.dart';
import '../uikit/widgets/sub_title.dart';
import '../uikit/widgets/top_bar.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<MovieModel> _movies = [];
  Set<int> _movieIds = Set(); // 영화 ID를 저장하는 Set 추가
  List<MovieModel> _filteredMovies = [];
  List<String> _recentSearches = []; // 최근 검색어 저장 리스트
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    // 최근 검색어 초기화(여기를 필요시 파일이나 DB에 저장하여 가져올 수 있음)
    _recentSearches = [];
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchMovies() async {
    // 초기 유저를 위해 데이터 로드
    var data = MovieData();
    List<MovieModel> allMovies = [];

    try {
      for (int page = 1; page <= 10; page++) {
        List<MovieModel> popularMovies = await data.fetchPopularMovies(pageCount: page);
        for (var movie in popularMovies) {
          if (!_movieIds.contains(movie.id)) {
            allMovies.add(movie);
            _movieIds.add(movie.id); // 중복을 피하기 위해 ID 저장
          }
        }
      }
      setState(() {
        _movies = allMovies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching movies: $e");
    }
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredMovies = _movies
          .where((movie) => movie.title.toLowerCase().contains(query))
          .toList(); // 검색 결과를 필터링
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '영화, TV 프로그램, 인물을 검색해보세요',
                prefixIcon: Icon(Icons.search, color: AppColors.textWhite),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: AppColors.textWhite),
            ),
            SizedBox(height: 10),
            // 검색하기 전 최근 검색어
            if (_recentSearches.isNotEmpty) ...[
              SubTitle(title: '최근 검색어'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentSearches.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _recentSearches[index],
                      style: TextStyle(color: AppColors.textWhite),
                    ),
                    onTap: () {
                      _searchController.text = _recentSearches[index];
                      _onSearchChanged();
                    },
                  );
                },
              ),
            ],
            // 영화 리스트를 표시하는 메소드
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredMovies.isEmpty
                  ? Center(
                  child: Text('결과가 없습니다.',
                      style: TextStyle(color: AppColors.textWhite)))
                  : _buildMovieList(),
            ),
          ],
        ),
      ),
    );
  }

  // 영화 리스트를 생성하는 메소드
  Widget _buildMovieList() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200.0, childAspectRatio: 2/3),
      itemCount: _filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = _filteredMovies[index];
        return Container(
          padding: EdgeInsets.all(0),
          child: MovieCard(
            title: movie.title,
            image: Image.network(
              'https://image.tmdb.org/t/p/w500${movie.posterPath}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error);
              },
            ),
            releaseInfo: '${movie.releaseDate}',
            movieId: movie.id,
            onTap: () {
              setState(() {
                if (!_recentSearches.contains(movie.title)) {
                  _recentSearches.add(movie.title);
                }
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movieId: movie.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
