import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/parking_lot.dart';
import '../../services/osm_map_service.dart';
import '../../services/parking_data_service.dart';
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
    final occupancy = (total - available) / total;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image / Gradient Banner
                Stack(
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF005DAC), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _currentLot.type.contains('Multi') ? Icons.apartment_rounded : Icons.local_parking_rounded,
                          size: 90,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleIconButton(Icons.arrow_back, onTap: () => Navigator.pop(context)),
                            Row(
                              children: [
                                _buildCircleIconButton(Icons.refresh_rounded, onTap: _refreshLotData),
                                const SizedBox(width: 12),
                                _buildCircleIconButton(Icons.favorite_border),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Details Card
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _currentLot.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFF005DAC), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_currentLot.rating}',
                                      style: const TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_currentLot.address} • ${_currentLot.distance} away',
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Animated Capacity Status & Occupancy Ring
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border(
                                left: BorderSide(
                                  color: available > 10
                                      ? const Color(0xFF22C55E)
                                      : (available > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TweenAnimationBuilder<int>(
                                      tween: IntTween(begin: 0, end: available),
                                      duration: const Duration(milliseconds: 1000),
                                      builder: (context, val, _) {
                                        return Text(
                                          '$val / $total Slots Available',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Live occupancy: ${(occupancy * 100).toInt()}% full',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    children: [
                                      CircularProgressIndicator(
                                        value: (total - available) / total,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          available > 10
                                              ? const Color(0xFF22C55E)
                                              : (available > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                        ),
                                        strokeWidth: 5,
                                      ),
                                      Center(
                                        child: Text(
                                          '$available',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Info Boxes
                          Row(
                            children: [
                              _buildInfoBox(Icons.payments_outlined, 'Price', '₹${effectiveRate.toInt()}/hr'),
                              const SizedBox(width: 12),
                              _buildInfoBox(Icons.access_time, 'Hours', '24/7'),
                              const SizedBox(width: 12),
                              _buildInfoBox(Icons.verified_user_outlined, 'Security', 'Guarded'),
                            ],
                          ),
                          const SizedBox(height: 28),

                          const Text(
                            'Amenities',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildAmenityChip(Icons.videocam_outlined, 'CCTV Surveillance'),
                              _buildAmenityChip(Icons.shield_outlined, 'Security Guards'),
                              _buildAmenityChip(Icons.home_outlined, 'Covered Parking'),
                              _buildAmenityChip(Icons.bolt, 'EV Fast Charging'),
                            ],
                          ),
                          const SizedBox(height: 28),

                          const Text(
                            'Booking Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),

                          // Date Picker Button
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, color: Color(0xFF005DAC), size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (Today)',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.edit_calendar_rounded, color: Color(0xFF64748B), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Duration Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: Color(0xFF005DAC), size: 20),
                                    SizedBox(width: 12),
                                    Text('Duration', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _durationHours > 1 ? () => setState(() => _durationHours--) : null,
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF005DAC)),
                                    ),
                                    Text(
                                      '$_durationHours hr${_durationHours > 1 ? 's' : ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF005DAC)),
                                    ),
                                    IconButton(
                                      onPressed: _durationHours < 12 ? () => setState(() => _durationHours++) : null,
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF005DAC)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Total Price Summary Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Estimated Cost ($_durationHours hrs)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${(effectiveRate * _durationHours).toInt()}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '₹${effectiveRate.toInt()}/hr',
                                    style: const TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Location & Navigation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(16),
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
                                            child: const Icon(Icons.location_on, color: Color(0xFF005DAC), size: 36),
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
                                      icon: const Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                                      label: const Text('Open in Live Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF005DAC),
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
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Reserve Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0), Colors.white],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SlotSelectionScreen(lot: _currentLot),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DAC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Select Parking Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF005DAC), size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF005DAC)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
