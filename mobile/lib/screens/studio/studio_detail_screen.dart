import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/studio_model.dart';
import '../../providers/studio_provider.dart';
import '../../utils/formatters.dart';
import '../booking/booking_screen.dart';

class StudioDetailScreen extends StatefulWidget {
  final String studioSlug;

  const StudioDetailScreen({super.key, required this.studioSlug});

  @override
  State<StudioDetailScreen> createState() => _StudioDetailScreenState();
}

class _StudioDetailScreenState extends State<StudioDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudioProvider>().getStudioBySlug(widget.studioSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StudioProvider>(
        builder: (context, studioProvider, _) {
          if (studioProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final studio = studioProvider.selectedStudio;
          if (studio == null) {
            return const Center(child: Text('Studio not found'));
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Images
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    studio.name,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (studio.images.isNotEmpty)
                        Image.network(
                          studio.images.first.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.border,
                            child: const Icon(Icons.studio, size: 100),
                          ),
                        )
                      else
                        Container(
                          color: AppTheme.accent[100],
                          child: const Icon(Icons.studio, size: 100),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.primary.withOpacity(0.85)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {
                      // TODO: Implement favorite toggle with API
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favorite toggle coming soon')),
                      );
                    },
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating & Reviews
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.accent, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            studio.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${studio.totalReviews} reviews)',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: studio.isActive
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: studio.isActive
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              studio.isActive ? 'Open' : 'Closed',
                              style: TextStyle(
                                color: studio.isActive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      _buildInfoRow(
                        Icons.location_on,
                        '${studio.address}, ${studio.city}, ${studio.province}',
                      ),
                      const SizedBox(height: 8),

                      // Phone
                      if (studio.phone != null)
                        _buildInfoRow(Icons.phone, studio.phone!),
                      const SizedBox(height: 8),

                      // Email
                      if (studio.email != null)
                        _buildInfoRow(Icons.email, studio.email!),
                      const SizedBox(height: 24),

                      // Description
                      if (studio.description != null) ...[
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          studio.description!,
                          style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Rooms
                      const Text(
                        'Rooms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...studio.rooms.map((room) => _buildRoomCard(room)),
                      const SizedBox(height: 24),

                      // Equipment
                      if (studio.equipment.isNotEmpty) ...[
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: studio.equipment.map((eq) {
                            return Chip(
                              avatar: const Icon(Icons.mic, size: 18),
                              label: Text(eq.name),
                              backgroundColor: AppTheme.accent[50],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Opening Hours
                      const Text(
                        'Opening Hours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...studio.openingHours.map((hour) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getDayName(hour.dayOfWeek),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                hour.isClosed
                                    ? 'Closed'
                                    : '${hour.openTime} - ${hour.closeTime}',
                                style: TextStyle(
                                  color: hour.isClosed ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final studio = context.read<StudioProvider>().selectedStudio;
              if (studio != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(studio: studio),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(StudioRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formatters.currency(room.pricePerHour),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Capacity: ${room.capacity} people',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
            if (room.description != null) ...[
              const SizedBox(height: 8),
              Text(
                room.description!,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }
}
