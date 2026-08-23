import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/studio_repository.dart';
import '../../widgets/studio_card.dart';
import '../studio/studio_detail_screen.dart';
import '../explore/explore_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studioRepository = context.read<StudioRepository>();
      final favorites = await studioRepository.getFavorites();
      
      setState(() {
        _favorites = List<Map<String, dynamic>>.from(favorites['data'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(int studioId) async {
    try {
      final studioRepository = context.read<StudioRepository>();
      await studioRepository.toggleFavorite(studioId);
      
      // Remove from list after toggling
      setState(() {
        _favorites.removeWhere((f) => f['id'] == studioId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari favorit'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Studio Favorit'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _favorites.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final studio = _favorites[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StudioCard(
                              name: studio['name'] ?? '',
                              slug: studio['slug'] ?? '',
                              city: studio['city'] ?? '',
                              address: studio['address'] ?? '',
                              rating: (studio['rating'] ?? 0).toDouble(),
                              totalReviews: studio['total_reviews'] ?? 0,
                              priceFrom: studio['min_price'] ?? 0,
                              onTap: () {
                                final slug = studio['slug'];
                                if (slug != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudioDetailScreen(studioSlug: slug),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Terjadi kesalahan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFavorites,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada favorit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simpan studio favorit Anda\nuntuk akses cepat',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
            // Navigate to explore
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          );
          },
            icon: const Icon(Icons.explore),
            label: const Text('Jelajahi Studio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
