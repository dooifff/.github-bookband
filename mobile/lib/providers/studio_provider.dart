import 'package:flutter/material.dart';
import '../models/studio_model.dart';
import '../repositories/studio_repository.dart';
import '../services/api_service.dart';

class StudioProvider extends ChangeNotifier {
  final StudioRepository _studioRepository;
  
  List<StudioModel> _studios = [];
  StudioModel? _selectedStudio;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Filters
  String? _searchQuery;
  String? _selectedCity;
  String? _selectedProvince;
  double? _minRating;
  double? _maxPrice;
  double? _minPrice;
  String? _sortBy;

  StudioProvider() : _studioRepository = StudioRepository(ApiService());

  List<StudioModel> get studios => _studios;
  StudioModel? get selectedStudio => _selectedStudio;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;

  /// Get studios with filters
  Future<void> getStudios({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _studios = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _studioRepository.getStudios(
        search: _searchQuery,
        city: _selectedCity,
        province: _selectedProvince,
        minRating: _minRating,
        maxPrice: _maxPrice,
        minPrice: _minPrice,
        sortBy: _sortBy,
        page: _currentPage,
      );

      final newStudios = result['studios'] as List<StudioModel>;
      final meta = result['meta'];

      if (refresh) {
        _studios = newStudios;
      } else {
        _studios = [..._studios, ...newStudios];
      }

      _hasMore = _currentPage < (meta['last_page'] ?? 1);
      _currentPage++;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get studio detail
  Future<void> getStudioDetail(String slug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStudio = await _studioRepository.getStudioBySlug(slug);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search studios
  Future<void> searchStudios(String query) async {
    _searchQuery = query;
    await getStudios(refresh: true);
  }

  /// Filter by city
  Future<void> filterByCity(String? city) async {
    _selectedCity = city;
    await getStudios(refresh: true);
  }

  /// Filter by province
  Future<void> filterByProvince(String? province) async {
    _selectedProvince = province;
    await getStudios(refresh: true);
  }

  /// Filter by rating
  Future<void> filterByRating(double? minRating) async {
    _minRating = minRating;
    await getStudios(refresh: true);
  }

  /// Filter by price
  Future<void> filterByPrice({double? min, double? max}) async {
    _minPrice = min;
    _maxPrice = max;
    await getStudios(refresh: true);
  }

  /// Sort studios
  Future<void> sortStudios(String? sortBy) async {
    _sortBy = sortBy;
    await getStudios(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _searchQuery = null;
    _selectedCity = null;
    _selectedProvince = null;
    _minRating = null;
    _maxPrice = null;
    _minPrice = null;
    _sortBy = null;
    await getStudios(refresh: true);
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(int studioId) async {
    try {
      final isFavorited = await _studioRepository.toggleFavorite(studioId);
      
      // Update studio in list
      final index = _studios.indexWhere((s) => s.id == studioId);
      if (index != -1) {
        _studios[index].isFavorited = isFavorited;
        notifyListeners();
      }

      return isFavorited;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear selected studio
  void clearSelectedStudio() {
    _selectedStudio = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
