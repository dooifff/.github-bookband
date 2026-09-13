import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/studio_model.dart';
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final studioRepository = context.read<StudioRepository>();
      final favorites = await studioRepository.getFavorites();
      setState(() {
        _favorites = List<Map<String, dynamic>>.from(favorites['favorites'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _toggleFavorite(int studioId) async {
    try {
      final studioRepository = context.read<StudioRepository>();
      await studioRepository.toggleFavorite(studioId);
      setState(() {
        _favorites.removeWhere((f) => (f['studio']?['id'] ?? f['id']) == studioId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dihapus dari favorit')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Studio Favorit'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadFavorites),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? _buildErrorWidget()
              : _favorites.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      color: AppTheme.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          // The API returns favorites as {id, studio: {...}}.
                          final favorite = _favorites[index];
                          final studio = Studio.fromJson(
                            Map<String, dynamic>.from(favorite['studio'] ?? {}),
                          )..isFavorited = true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StudioCard(
                              studio: studio,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudioDetailScreen(studioSlug: studio.slug),
                                  ),
                                );
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
          const Icon(Icons.error_outline, size: 56, color: AppTheme.danger),
          const SizedBox(height: 16),
          const Text('Terjadi kesalahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadFavorites, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Belum ada favorit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const Text('Simpan studio favorit Anda\nuntuk akses cepat', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreScreen()));
            },
            icon: const Icon(Icons.explore, size: 18),
            label: const Text('Jelajahi Studio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
