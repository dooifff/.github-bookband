import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/studio_provider.dart';
import '../explore/explore_screen.dart';
import '../bookings/bookings_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../studio/studio_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const ExploreScreen(),
    const BookingsScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, User! 👋',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find your perfect studio',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to notifications - TODO: implement notifications screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifikasi coming soon')),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Search Bar
            GestureDetector(
              onTap: () {
                // Navigate to explore screen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExploreScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.textMuted),
                    const SizedBox(width: 12),
                    Text(
                      'Search studios...',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Categories
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(icon: Icons.mic, label: 'Recording'),
                  _CategoryChip(icon: Icons.piano, label: 'Practice'),
                  _CategoryChip(icon: Icons.headphones, label: 'Mixing'),
                  _CategoryChip(icon: Icons.music_note, label: 'Rehearsal'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Popular Studios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Studios',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    // Switch to Explore tab
                    final homeState = context.findAncestorStateOfType<State>();
                    if (homeState != null && homeState.mounted) {
                      // Navigate to explore screen
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExploreScreen()),
                      );
                    }
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Studio Cards (Placeholder)
            _StudioCard(
              name: 'Studio Melody',
              location: 'Jakarta Selatan',
              rating: 4.8,
              price: 'Rp 150.000/jam',
            ),
            const SizedBox(height: 12),
            _StudioCard(
              name: 'Studio Harmony',
              location: 'Bandung',
              rating: 4.6,
              price: 'Rp 120.000/jam',
            ),
            const SizedBox(height: 12),
            _StudioCard(
              name: 'Studio Rhythm',
              location: 'Surabaya',
              rating: 4.9,
              price: 'Rp 180.000/jam',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _CategoryChip({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;
  final String price;
  final String? slug;
  
  const _StudioCard({
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
    this.slug,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (slug != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudioDetailScreen(studioSlug: slug!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
        children: [
          // Studio Image Placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppTheme.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          
          // Studio Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(location, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppTheme.warning),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          
          // Price
          Text(
            price,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
