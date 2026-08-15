import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/parking_lot.dart';
import '../../services/osm_map_service.dart';
import '../../services/parking_data_service.dart';
import 'parking_details_screen.dart';
import 'slot_selection_screen.dart';

class LiveParkingMapScreen extends StatefulWidget {
  final ParkingLot? initialFocusLot;

  const LiveParkingMapScreen({super.key, this.initialFocusLot});

  @override
  State<LiveParkingMapScreen> createState() => _LiveParkingMapScreenState();
}

class _LiveParkingMapScreenState extends State<LiveParkingMapScreen> {
  final MapController _mapController = MapController();
  final ParkingDataService _dataService = ParkingDataService();
  final OsmMapService _mapService = OsmMapService();

  ParkingLot? _selectedLot;
  RoutingResult? _currentRoute;
  final LatLng _userPosition = OsmMapService.defaultUserLocation;
  bool _showRoute = false;
  String _filterAvailability = 'All'; // 'All', 'Available', 'EV Fast'

  @override
  void initState() {
    super.initState();
    _selectedLot = widget.initialFocusLot;
    if (_selectedLot != null) {
      _loadRouteToLot(_selectedLot!);
    }
  }

  Future<void> _loadRouteToLot(ParkingLot lot) async {
    setState(() {
      _isLoadingRoute = true;
      _showRoute = true;
    });

    final dest = LatLng(lot.latitude, lot.longitude);
    final route = await _mapService.getDrivingRoute(_userPosition, dest);

    if (mounted) {
      setState(() {
        _currentRoute = route;
        _isLoadingRoute = false;
      });

      // Recenter camera to accommodate both points
      _mapController.move(
        LatLng((_userPosition.latitude + dest.latitude) / 2, (_userPosition.longitude + dest.longitude) / 2),
        13.5,
      );
    }
  }

  List<ParkingLot> _getFilteredLots(List<ParkingLot> lots) {
    if (_filterAvailability == 'Available') {
      return lots.where((l) => l.availableSlotsCount > 0).toList();
    } else if (_filterAvailability == 'EV Fast') {
      return lots.where((l) => l.hasEv).toList();
    }
    return lots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final allLots = _dataService.lots;
          final displayLots = _getFilteredLots(allLots);

          return Stack(
            children: [
              // 1. FlutterMap OpenStreetMap Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialFocusLot != null
                      ? LatLng(widget.initialFocusLot!.latitude, widget.initialFocusLot!.longitude)
                      : _userPosition,
                  initialZoom: 13.5,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onTap: (_, __) {
                    setState(() {
                      _selectedLot = null;
                      _showRoute = false;
                    });
                  },
                ),
                children: [
                  // OpenStreetMap Tile Layer (Carto Positron / OSM)
                  TileLayer(
                    urlTemplate: OsmMapService.tileUrlTemplate,
                    userAgentPackageName: 'com.parkpilot.app',
                    maxZoom: 19,
                  ),

                  // Route Polyline Layer (when routing to a lot)
                  if (_showRoute && _currentRoute != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _currentRoute!.polylinePoints,
                          strokeWidth: 5.0,
                          color: const Color(0xFF005DAC),
                          borderColor: const Color(0xFF0284C7),
                          borderStrokeWidth: 2.0,
                        ),
                      ],
                    ),

                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // User Current Location Marker
                      Marker(
                        point: _userPosition,
                        width: 50,
                        height: 50,
                        child: _buildUserLocationMarker(),
                      ),

                      // Parking Space Markers
                      ...displayLots.map((lot) {
                        final isSelected = _selectedLot?.id == lot.id;
                        final isFull = lot.availableSlotsCount == 0;
                        final isLimited = !isFull && (lot.availableSlotsCount <= 5);

                        Color pinColor = const Color(0xFF22C55E); // Green
                        if (isFull) {
                          pinColor = const Color(0xFFEF4444); // Red
                        } else if (isLimited) {
                          pinColor = const Color(0xFFF59E0B); // Amber
                        }

                        return Marker(
                          point: LatLng(lot.latitude, lot.longitude),
                          width: isSelected ? 120 : 64,
                          height: isSelected ? 64 : 48,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLot = lot;
                              });
                              _loadRouteToLot(lot);
                            },
                            child: _buildParkingMarker(lot, pinColor, isSelected),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),

              // 2. Top Header & Search Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF005DAC)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.map_rounded, color: Color(0xFF005DAC), size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Chennai Live Parking Map',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${displayLots.length} spots',
                                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All Spots', _filterAvailability == 'All', () {
                              setState(() => _filterAvailability = 'All');
                            }),
                            const SizedBox(width: 8),
                            _buildFilterChip('🟢 Available Only', _filterAvailability == 'Available', () {
                              setState(() => _filterAvailability = 'Available');
                            }),
                            const SizedBox(width: 8),
                            _buildFilterChip('⚡ EV Charging', _filterAvailability == 'EV Fast', () {
                              setState(() => _filterAvailability = 'EV Fast');
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Floating Map Controls (Recenter / Zoom)
              Positioned(
                right: 16,
                top: 140,
                child: Column(
                  children: [
                    _buildFloatingButton(
                      icon: Icons.my_location_rounded,
                      onPressed: () {
                        _mapController.move(_userPosition, 14.5);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildFloatingButton(
                      icon: Icons.add_rounded,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildFloatingButton(
                      icon: Icons.remove_rounded,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                      },
                    ),
                  ],
                ),
              ),

              // 4. Selected Parking Lot Floating Bottom Card
              if (_selectedLot != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _buildSelectedLotBottomSheet(_selectedLot!),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005DAC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF005DAC), size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF005DAC),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParkingMarker(ParkingLot lot, Color pinColor, bool isSelected) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF005DAC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF005DAC).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_parking_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              '₹${lot.hourlyRate.toInt()} (${lot.availableSlotsCount})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: pinColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_parking_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 2),
              Text(
                '${lot.availableSlotsCount}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_drop_down, color: pinColor, size: 16),
      ],
    );
  }

  Widget _buildSelectedLotBottomSheet(ParkingLot lot) {
    final available = lot.availableSlotsCount;
    final total = lot.totalSlotsCount > 0 ? lot.totalSlotsCount : 10;
    final isFull = available == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_parking_rounded, color: Color(0xFF005DAC), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lot.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () => setState(() {
                            _selectedLot = null;
                            _showRoute = false;
                          }),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lot.address,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route duration / distance badge
          if (_currentRoute != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF005DAC)),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentRoute!.durationMinutes.toInt()} mins drive (${_currentRoute!.distanceKm.toStringAsFixed(1)} km)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF005DAC)),
                  ),
                  const Spacer(),
                  if (lot.hasEv)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('⚡ EV Bay', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Availability and pricing row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${lot.hourlyRate.toInt()}/hr',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
                  ),
                  Text(
                    isFull ? '🔴 Full' : '🟢 $available / $total slots available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFull ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ParkingDetailsScreen(lot: lot)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isFull
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SlotSelectionScreen(lot: lot)),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005DAC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Book Spot', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
