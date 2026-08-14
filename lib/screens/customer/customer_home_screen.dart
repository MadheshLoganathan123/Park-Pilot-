import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';
import 'parking_details_screen.dart';
import 'slot_selection_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ParkingDataService _dataService = ParkingDataService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dataService.loadLots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _dataService,
          builder: (context, _) {
            final lotsList = _dataService.lots;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // App Bar (ParkPilot, Notification, Profile)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005DAC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'P',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ParkPilot',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005DAC),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 28, color: Color(0xFF1E293B)),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF005DAC),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Greeting
                  const Text(
                    'Good Morning, Madhesh!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    'Ready to find your spot today?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Color(0xFF94A3B8)),
                              SizedBox(width: 12),
                              Text(
                                'Where do you want to park?',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),

                  // Recent Search Chips
                  if (_dataService.recentSearches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Recent:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _dataService.recentSearches.map((name) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InputChip(
                                    label: Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF005DAC))),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    onPressed: () {
                                      final matched = lotsList.firstWhere(
                                        (l) => l.name.toLowerCase() == name.toLowerCase(),
                                        orElse: () => lotsList.isNotEmpty ? lotsList.first : _dataService.lots.first,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ParkingDetailsScreen(lot: matched),
                                        ),
                                      );
                                    },
                                    onDeleted: () {
                                      _dataService.removeRecentSearch(name);
                                    },
                                    deleteIconColor: const Color(0xFF94A3B8),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Find Parking', isSelected: true),
                        _buildFilterChip('Nearby'),
                        _buildFilterChip('Reservations'),
                        _buildFilterChip('EV Charging'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Map Preview Card
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.map_rounded, size: 48, color: Color(0xFF005DAC)),
                            SizedBox(height: 12),
                            Text(
                              'Live Map Discovery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Explore real-time slot availability in Chennai',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Parking Near You Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Parking Near You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _dataService.loadLots(),
                        child: const Text('Refresh', style: TextStyle(color: Color(0xFF005DAC))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Parking Cards List
                  if (_dataService.isLoading && lotsList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_dataService.errorMessage != null && lotsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load parking lots',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _dataService.loadLots(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...lotsList.take(4).map((lot) {
                      final avail = lot.availableSlotsCount;
                      final borderColor = avail > 20
                          ? const Color(0xFF22C55E)
                          : (avail > 5 ? const Color(0xFFF97316) : const Color(0xFFEF4444));
                      final statusText = '$avail Slots Available';

                      return _buildParkingCard(
                        context,
                        lot,
                        borderColor: borderColor,
                        status: statusText,
                        statusColor: borderColor,
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF005DAC).withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildParkingCard(BuildContext context, dynamic lot, {required Color borderColor, required String status, required Color statusColor}) {
    return GestureDetector(
      onTap: () {
        _dataService.addRecentSearch(lot.name);
        Navigator.push(context, MaterialPageRoute(builder: (context) => ParkingDetailsScreen(lot: lot)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: borderColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lot.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${lot.address} • ${lot.distance}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${lot.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        Text(
                          '₹${lot.hourlyRate.toInt()}/hr',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005DAC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SlotSelectionScreen(lot: lot),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005DAC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reserve', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_outlined, color: Color(0xFF005DAC)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
