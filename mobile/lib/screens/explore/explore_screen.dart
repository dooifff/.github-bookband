import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/studio_provider.dart';
import '../../widgets/studio_card.dart';
import '../studio/studio_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String? _selectedProvince;
  double? _minRating;
  double? _maxPrice;
  double? _minPrice;
  String? _sortBy;

  final List<String> _cities = ['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Semarang', 'Medan'];
  final List<String> _provinces = ['DKI Jakarta', 'Jawa Barat', 'Jawa Timur', 'DI Yogyakarta', 'Jawa Tengah', 'Sumatera Utara'];
  final List<Map<String, String>> _sortOptions = [
    {'value': 'rating', 'label': 'Rating Tertinggi'},
    {'value': 'price_low', 'label': 'Harga Terendah'},
    {'value': 'price_high', 'label': 'Harga Tertinggi'},
    {'value': 'newest', 'label': 'Terbaru'},
    {'value': 'popular', 'label': 'Terpopuler'},
  ];

  @override
  void initState() {
    super.initState();
    // Deferred: the provider notifies its listeners synchronously, which is
    // not allowed while the first build is still running.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudios() async {
    final studioProvider = context.read<StudioProvider>();
    await studioProvider.getStudios(refresh: true);
  }

  void _applyFilters() {
    final studioProvider = context.read<StudioProvider>();
    studioProvider.filterByCity(_selectedCity);
    studioProvider.filterByProvince(_selectedProvince);
    studioProvider.filterByRating(_minRating);
    studioProvider.filterByPrice(min: _minPrice, max: _maxPrice);
    studioProvider.sortStudios(_sortBy);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedProvince = null;
      _minRating = null;
      _maxPrice = null;
      _minPrice = null;
      _sortBy = null;
    });
    context.read<StudioProvider>().clearFilters();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedCity: _selectedCity,
        selectedProvince: _selectedProvince,
        minRating: _minRating,
        maxPrice: _maxPrice,
        minPrice: _minPrice,
        sortBy: _sortBy,
        cities: _cities,
        provinces: _provinces,
        sortOptions: _sortOptions,
        onApply: (filters) {
          setState(() {
            _selectedCity = filters['city'];
            _selectedProvince = filters['province'];
            _minRating = filters['min_rating'];
            _maxPrice = filters['max_price'];
            _minPrice = filters['min_price'];
            _sortBy = filters['sort_by'];
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onClear: () {
          _clearFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedCity != null || _selectedProvince != null || _minRating != null || _maxPrice != null || _minPrice != null || _sortBy != null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Studios',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or location...',
                            hintStyle: TextStyle(color: AppTheme.textMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (value == _searchController.text) {
                                context.read<StudioProvider>().searchStudios(value);
                              }
                            });
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<StudioProvider>().searchStudios('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.filter_list, color: AppTheme.textSecondary, size: 20),
                        onPressed: _showFilterBottomSheet,
                      ),
                    ],
                  ),
                ),
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (_selectedCity != null)
                          _buildFilterChip('Kota: $_selectedCity', () => setState(() { _selectedCity = null; _applyFilters(); })),
                        if (_selectedProvince != null)
                          _buildFilterChip('Provinsi: $_selectedProvince', () => setState(() { _selectedProvince = null; _applyFilters(); })),
                        if (_minRating != null)
                          _buildFilterChip('Rating: ${_minRating}+', () => setState(() { _minRating = null; _applyFilters(); })),
                        if (_minPrice != null || _maxPrice != null)
                          _buildFilterChip(
                            'Harga: ${_minPrice != null ? "Rp${(_minPrice! / 1000).toInt()}K" : "0"} - ${_maxPrice != null ? "Rp${(_maxPrice! / 1000).toInt()}K" : "∞"}',
                            () => setState(() { _minPrice = null; _maxPrice = null; _applyFilters(); }),
                          ),
                        if (_sortBy != null)
                          _buildFilterChip(
                            'Urutkan: ${_sortOptions.firstWhere((s) => s['value'] == _sortBy)['label']}',
                            () => setState(() { _sortBy = null; _applyFilters(); }),
                          ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Hapus Semua', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<StudioProvider>(
              builder: (context, studioProvider, child) {
                if (studioProvider.isLoading && studioProvider.studios.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                }
                if (studioProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: AppTheme.danger),
                        const SizedBox(height: 16),
                        Text('Terjadi kesalahan', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(studioProvider.error!, style: const TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadStudios, child: const Text('Coba Lagi')),
                      ],
                    ),
                  );
                }
                if (studioProvider.studios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore, size: 56, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        const Text('Tidak ada studio ditemukan', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Coba ubah filter atau kata kunci', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadStudios,
                  color: AppTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: studioProvider.studios.length + (studioProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == studioProvider.studios.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                        );
                      }
                      final studio = studioProvider.studios[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StudioCard(
                          studio: studio,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => StudioDetailScreen(studioSlug: studio.slug)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
      deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.textMuted),
      onDeleted: onDelete,
      backgroundColor: AppTheme.surfaceLighter,
      side: const BorderSide(color: AppTheme.border, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}

// ═══════════════════════════════════════════════
// Filter Bottom Sheet — Dark Luxury Theme
// ═══════════════════════════════════════════════

class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCity;
  final String? selectedProvince;
  final double? minRating;
  final double? maxPrice;
  final double? minPrice;
  final String? sortBy;
  final List<String> cities;
  final List<String> provinces;
  final List<Map<String, String>> sortOptions;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.selectedCity,
    required this.selectedProvince,
    required this.minRating,
    required this.maxPrice,
    required this.minPrice,
    required this.sortBy,
    required this.cities,
    required this.provinces,
    required this.sortOptions,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _tempCity;
  String? _tempProvince;
  double? _tempMinRating;
  double? _tempMaxPrice;
  double? _tempMinPrice;
  String? _tempSortBy;

  @override
  void initState() {
    super.initState();
    _tempCity = widget.selectedCity;
    _tempProvince = widget.selectedProvince;
    _tempMinRating = widget.minRating;
    _tempMaxPrice = widget.maxPrice;
    _tempMinPrice = widget.minPrice;
    _tempSortBy = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Studio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClear,
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Filter Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City
                  _buildSectionTitle('Kota'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.cities.map((city) {
                      final isSelected = _tempCity == city;
                      return ChoiceChip(
                        label: Text(city),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _tempCity = selected ? city : null);
                        },
                        selectedColor: AppTheme.accent,
                        backgroundColor: AppTheme.surfaceLighter,
                        side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.border, width: 0.5),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Province
                  _buildSectionTitle('Provinsi'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.provinces.map((province) {
                      final isSelected = _tempProvince == province;
                      return ChoiceChip(
                        label: Text(province),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _tempProvince = selected ? province : null);
                        },
                        selectedColor: AppTheme.accent,
                        backgroundColor: AppTheme.surfaceLighter,
                        side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.border, width: 0.5),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Rating
                  _buildSectionTitle('Rating Minimum'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppTheme.accent,
                            inactiveTrackColor: AppTheme.surfaceLighter,
                            thumbColor: AppTheme.accent,
                            overlayColor: AppTheme.goldGlow,
                          ),
                          child: Slider(
                            value: _tempMinRating ?? 0,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            label: _tempMinRating?.toStringAsFixed(1) ?? 'Semua',
                            onChanged: (value) {
                              setState(() => _tempMinRating = value > 0 ? value : null);
                            },
                          ),
                        ),
                      ),
                      Text(
                        _tempMinRating != null ? '${_tempMinRating!.toStringAsFixed(1)}+' : 'Semua',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Price Range
                  _buildSectionTitle('Range Harga (per jam)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Minimum',
                            labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixText: 'Rp ',
                            prefixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            filled: true,
                            fillColor: AppTheme.surfaceLighter.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _tempMinPrice = double.tryParse(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Maksimum',
                            labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            prefixText: 'Rp ',
                            prefixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            filled: true,
                            fillColor: AppTheme.surfaceLighter.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _tempMaxPrice = double.tryParse(value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sort By
                  _buildSectionTitle('Urutkan Berdasarkan'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.sortOptions.map((option) {
                      final isSelected = _tempSortBy == option['value'];
                      return ChoiceChip(
                        label: Text(option['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _tempSortBy = selected ? option['value'] : null);
                        },
                        selectedColor: AppTheme.accent,
                        backgroundColor: AppTheme.surfaceLighter,
                        side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.border, width: 0.5),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply({
                    'city': _tempCity,
                    'province': _tempProvince,
                    'min_rating': _tempMinRating,
                    'max_price': _tempMaxPrice,
                    'min_price': _tempMinPrice,
                    'sort_by': _tempSortBy,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Terapkan Filter',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        letterSpacing: 0.02,
      ),
    );
  }
}
