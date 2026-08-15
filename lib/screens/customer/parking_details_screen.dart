import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/parking_lot.dart';
import '../../services/osm_map_service.dart';
import '../../services/parking_data_service.dart';
import '../../theme/app_theme.dart';
import 'slot_selection_screen.dart';
import 'live_parking_map_screen.dart';

class ParkingDetailsScreen extends StatefulWidget {
  final ParkingLot lot;

  const ParkingDetailsScreen({super.key, required this.lot});

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  final ParkingDataService _dataService = ParkingDataService();
  late ParkingLot _currentLot;
  int _durationHours = 2;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentLot = widget.lot;
    _refreshLotData();
  }

  void _refreshLotData() async {
    final fresh = await _dataService.fetchLotDetails(widget.lot.id);
    if (fresh != null && mounted) {
      setState(() {
        _currentLot = fresh;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRate = _dataService.calculateEffectiveRate(_currentLot.hourlyRate);
    final available = _currentLot.availableSlotsCount;
    final total = _currentLot.totalSlotsCount > 0 ? _currentLot.totalSlotsCount : 10;
    final occupancy = ((total - available) / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Header with Gradient & Floating Actions
                Stack(
                  children: [
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _currentLot.type.contains('Multi') ? Icons.apartment_rounded : Icons.local_parking_rounded,
                          size: 84,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeaderIconButton(Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                            Row(
                              children: [
                                _buildHeaderIconButton(Icons.refresh_rounded, onTap: _refreshLotData),
                                const SizedBox(width: 10),
                                _buildHeaderIconButton(Icons.bookmark_border_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Main Details Card Container
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Facility Title & Star Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _currentLot.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppTheme.warning, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_currentLot.rating}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_currentLot.address} • ${_currentLot.distance} away',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Live Occupancy Card (Elevated White Surface)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Stack(
                                    children: [
                                      CircularProgressIndicator(
                                        value: occupancy,
                                        backgroundColor: AppTheme.surfaceMuted,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          available > 10 ? AppTheme.success : AppTheme.warning,
                                        ),
                                        strokeWidth: 7,
                                        strokeCap: StrokeCap.round,
                                      ),
                                      Center(
                                        child: Text(
                                          '${(occupancy * 100).toInt()}%',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$available Spots Free',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: available > 0 ? AppTheme.success : AppTheme.error,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Out of $total standard & EV slots',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Amenities Section
                          const Text('Facility Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildAmenityPill(Icons.videocam_outlined, '24/7 CCTV'),
                              _buildAmenityPill(Icons.shield_outlined, 'Security Guard'),
                              _buildAmenityPill(Icons.roofing_rounded, 'Covered Roof'),
                              _buildAmenityPill(Icons.bolt_rounded, 'EV Fast Charging'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Duration Selector Card
                          const Text('Reservation Time & Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 14)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (Today)',
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                        ),
                                      ),
                                      const Icon(Icons.edit_calendar_rounded, color: AppTheme.textMuted, size: 18),
                                    ],
                                  ),
                                ),
                                const Divider(color: AppTheme.borderLight, height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.timer_outlined, color: AppTheme.primary, size: 20),
                                        SizedBox(width: 12),
                                        Text('Duration', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _durationHours > 1 ? () => setState(() => _durationHours--) : null,
                                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                                        ),
                                        Text(
                                          '$_durationHours hr${_durationHours > 1 ? 's' : ''}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary),
                                        ),
                                        IconButton(
                                          onPressed: _durationHours < 12 ? () => setState(() => _durationHours++) : null,
                                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Location & OSM Preview
                          const Text('Location & Live Navigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.border),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(_currentLot.latitude, _currentLot.longitude),
                                      initialZoom: 14.5,
                                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: OsmMapService.tileUrlTemplate,
                                        userAgentPackageName: 'com.parkpilot.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(_currentLot.latitude, _currentLot.longitude),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 36),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LiveParkingMapScreen(initialFocusLot: _currentLot),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.navigation_rounded, size: 14, color: Colors.white),
                                      label: const Text('Open in Live Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Reserve Floating Checkout Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total ($_durationHours hrs)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                        Text(
                          '₹${(effectiveRate * _durationHours).toInt()}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: available > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SlotSelectionScreen(lot: _currentLot)),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: const Text('Select Slot & Reserve'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, {VoidCallback? onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: AppTheme.cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.textPrimary, size: 18),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAmenityPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
