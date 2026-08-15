import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/parking_lot.dart';
import '../../services/osm_map_service.dart';
import '../../services/parking_data_service.dart';
import '../../theme/app_theme.dart';
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
  LatLng _userPosition = OsmMapService.defaultUserLocation;
  bool _showRoute = false;
  String _filterAvailability = 'All'; // 'All', 'Available', 'EV Fast'

  @override
  void initState() {
    super.initState();
    _selectedLot = widget.initialFocusLot;
    _initUserLocationAndRoute();
  }

  Future<void> _initUserLocationAndRoute() async {
    final currentLoc = await _mapService.determineCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = currentLoc;
      });
      if (widget.initialFocusLot == null) {
        _mapController.move(_userPosition, 14.0);
      }
    }
    if (_selectedLot != null) {
      _loadRouteToLot(_selectedLot!);
    }
  }

  Future<void> _loadRouteToLot(ParkingLot lot) async {
    setState(() {
      _showRoute = true;
    });

    final dest = LatLng(lot.latitude, lot.longitude);
    final route = await _mapService.getDrivingRoute(_userPosition, dest);

    if (mounted) {
      setState(() {
        _currentRoute = route;
      });

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
      return lots.where((l) => l.availableEvSlotsCount > 0).toList();
    }
    return lots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final allLots = _dataService.lots;
          final displayLots = _getFilteredLots(allLots);

          return Stack(
            children: [
              // 1. Live FlutterMap Base View Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialFocusLot != null
                      ? LatLng(widget.initialFocusLot!.latitude, widget.initialFocusLot!.longitude)
                      : _userPosition,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: OsmMapService.tileUrlTemplate,
                    userAgentPackageName: 'com.parkpilot.app',
                  ),

                  // Route Polyline Layer
                  if (_showRoute && _currentRoute != null) ...[
                    PolylineLayer(
                      polylines: [
                        // Casing / Glow outline
                        Polyline(
                          points: _currentRoute!.polylinePoints,
                          strokeWidth: 8.0,
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                        // Sharp inner driving line
                        Polyline(
                          points: _currentRoute!.polylinePoints,
                          strokeWidth: 4.5,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],

                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // User Current Location Pulse Marker
                      Marker(
                        point: _userPosition,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.navigation, color: Colors.white, size: 14),
                          ),
                        ),
                      ),

                      // Interactive Parking Lot Markers
                      ...displayLots.map((lot) {
                        final isSelected = _selectedLot?.id == lot.id;
                        final avail = lot.availableSlotsCount;
                        final isFull = avail == 0;
                        final isLimited = avail > 0 && avail <= 5;

                        Color pinColor = AppTheme.success;
                        if (isFull) {
                          pinColor = AppTheme.error;
                        } else if (isLimited) {
                          pinColor = AppTheme.warning;
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

              // 2. Top Glass Header & Filter Bar
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
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
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
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.map_rounded, color: AppTheme.primary, size: 20),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Chennai Live Map',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${displayLots.length} active',
                                      style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
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
                            _buildFilterChip('🟢 Available', _filterAvailability == 'Available', () {
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
                    const SizedBox(height: 10),
                    _buildFloatingButton(
                      icon: Icons.add_rounded,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                      },
                    ),
                    const SizedBox(height: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.textPrimary, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildParkingMarker(ParkingLot lot, Color pinColor, bool isSelected) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.primaryGlow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_parking, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                lot.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pinColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: pinColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_parking, color: Colors.white, size: 14),
          const SizedBox(width: 2),
          Text(
            '${lot.availableSlotsCount}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedLotBottomSheet(ParkingLot lot) {
    final avail = lot.availableSlotsCount;
    final isAvailable = avail > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lot.address} • ${lot.distance}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                onPressed: () => setState(() {
                  _selectedLot = null;
                  _showRoute = false;
                }),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Time & Distance Banner
          if (_currentRoute != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_filled_rounded, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentRoute!.durationMinutes.toInt()} mins drive • ${_currentRoute!.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                  Text(
                    '₹${lot.hourlyRate.toInt()}/hr',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Details'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Book Spot'),
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
