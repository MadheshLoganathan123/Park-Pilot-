import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/parking_lot.dart';
import '../../services/osm_map_service.dart';
import '../../services/parking_data_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/logo_data.dart';
import 'parking_details_screen.dart';
import 'live_parking_map_screen.dart';
import 'slot_selection_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ParkingDataService _dataService = ParkingDataService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortFilter = 'Nearest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dataService.loadLots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ParkingLot> _getFilteredLots(List<ParkingLot> lots) {
    var list = List<ParkingLot>.from(lots);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((lot) =>
              lot.name.toLowerCase().contains(q) || lot.address.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedCategory == 'Available') {
      list = list.where((l) => l.availableSlotsCount > 0).toList();
    } else if (_selectedCategory == 'EV Fast') {
      list = list.where((l) => l.availableEvSlotsCount > 0).toList();
    }

    final sortBy = _selectedCategory == 'Top Rated' ? 'Rating' : _sortFilter;
    switch (sortBy) {
      case 'Price':
        list.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
        break;
      case 'Availability':
        list.sort((a, b) => b.availableSlotsCount.compareTo(a.availableSlotsCount));
        break;
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Nearest':
      default:
        break;
    }

    return list;
  }

  void _showSortFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how nearby parking spaces are ordered',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Nearest', Icons.near_me_outlined),
              _buildSortOption('Price', Icons.payments_outlined),
              _buildSortOption('Availability', Icons.local_parking_outlined),
              _buildSortOption('Rating', Icons.star_outline_rounded),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _sortFilter = 'Nearest';
                      _selectedCategory = 'All';
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Reset All Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, IconData icon) {
    final isSelected = _sortFilter == label;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
      onTap: () {
        setState(() => _sortFilter = label);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _dataService,
          builder: (context, _) {
            final lotsList = _dataService.lots;
            final filteredLots = _getFilteredLots(lotsList);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Modern Top App Bar Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                kAppLogoBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ParkPilot',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Chennai Central • Live',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, size: 20, color: AppTheme.textPrimary),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Center(
                              child: Text(
                                'M',
                                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Greeting Section
                  const Text(
                    'Find Your Ideal Spot 🚗',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Instant reservations with real-time occupancy updates',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 18),

                  // Search bar — filters list in place
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value.trim()),
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Search destination, mall, or street...',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: _sortFilter != 'Nearest' ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                          tooltip: 'Sort & filter',
                          onPressed: _showSortFilterSheet,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryChip('All', Icons.grid_view_rounded),
                        _buildCategoryChip('Available', Icons.check_circle_outline_rounded),
                        _buildCategoryChip('EV Fast', Icons.bolt_rounded),
                        _buildCategoryChip('Top Rated', Icons.star_outline_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Live Interactive Map Radar Card (Airy Light Container)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LiveParkingMapScreen()),
                      );
                    },
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            // Live OSM FlutterMap Tile Layer
                            FlutterMap(
                              options: const MapOptions(
                                initialCenter: OsmMapService.defaultUserLocation,
                                initialZoom: 13.0,
                                interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: OsmMapService.tileUrlTemplate,
                                  userAgentPackageName: 'com.parkpilot.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    // User location pin
                                    Marker(
                                      point: OsmMapService.defaultUserLocation,
                                      width: 24,
                                      height: 24,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primary.withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Real lot pins
                                    ...filteredLots.take(4).map((lot) {
                                      final isFull = lot.availableSlotsCount == 0;
                                      final color = isFull ? AppTheme.error : AppTheme.success;
                                      return Marker(
                                        point: LatLng(lot.latitude, lot.longitude),
                                        width: 52,
                                        height: 32,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withValues(alpha: 0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.local_parking, size: 12, color: Colors.white),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${lot.availableSlotsCount}',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),

                            // Ambient gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.60),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),

                            // Top Live Badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.radar_rounded, size: 14, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Live Parking Radar',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom Navigation Trigger
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Live Map View',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        '${filteredLots.length} parking spaces nearby',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: AppTheme.primaryGlow,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Open Map', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nearby Spaces Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby Parking Spaces',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _dataService.loadLots(),
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primary),
                        label: const Text('Refresh', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List of Parking Lots
                  if (_dataService.isLoading && lotsList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    )
                  else if (_dataService.errorMessage != null && lotsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            const Text('Unable to connect to backend', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _dataService.loadLots(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredLots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            const Text(
                              'No parking spaces match your search',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try a different keyword or reset filters',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _selectedCategory = 'All';
                                  _sortFilter = 'Nearest';
                                });
                              },
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredLots.map((lot) => _buildModernParkingCard(context, lot)),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernParkingCard(BuildContext context, ParkingLot lot) {
    final avail = lot.availableSlotsCount;
    final isAvailable = avail > 0;
    final statusColor = avail > 15
        ? AppTheme.success
        : (avail > 0 ? AppTheme.warning : AppTheme.error);

    return GestureDetector(
      onTap: () {
        _dataService.addRecentSearch(lot.name);
        Navigator.push(context, MaterialPageRoute(builder: (context) => ParkingDetailsScreen(lot: lot)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${lot.address} • ${lot.distance}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${lot.rating}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Feature Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAvailable ? '$avail spots left' : 'Fully booked',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (lot.availableEvSlotsCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${lot.availableEvSlotsCount} EV Bays',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderLight, height: 1),
            const SizedBox(height: 14),

            // Pricing & Booking Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hourly Rate', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${lot.hourlyRate.toInt()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Text('/hr', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LiveParkingMapScreen(initialFocusLot: lot)),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, color: AppTheme.primary, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isAvailable
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SlotSelectionScreen(lot: lot)),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text('Book Spot'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
