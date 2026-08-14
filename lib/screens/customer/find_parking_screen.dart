import 'package:flutter/material.dart';
import '../../models/parking_lot.dart';
import '../../services/parking_data_service.dart';
import 'parking_details_screen.dart';
import 'slot_selection_screen.dart';

class FindParkingScreen extends StatefulWidget {
  const FindParkingScreen({super.key});

  @override
  State<FindParkingScreen> createState() => _FindParkingScreenState();
}

class _FindParkingScreenState extends State<FindParkingScreen> {
  final ParkingDataService _dataService = ParkingDataService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Nearest'; // 'Nearest', 'Price', 'Availability', 'Rating'
  String _searchQuery = '';

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

  List<ParkingLot> _getFilteredAndSortedLots(List<ParkingLot> rawLots) {
    var list = rawLots.where((lot) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return lot.name.toLowerCase().contains(q) || lot.address.toLowerCase().contains(q);
    }).toList();

    switch (_selectedFilter) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF005DAC)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Find Parking', style: TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final displayLots = _getFilteredAndSortedLots(_dataService.lots);

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                decoration: const InputDecoration(
                                  hintText: 'Search destination or lot...',
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
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
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF005DAC)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // List / Map Toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 60),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.format_list_bulleted, size: 18, color: Color(0xFF005DAC)),
                            SizedBox(width: 8),
                            Text('List', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 18, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text('Map', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Horizontal Sort Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSmallFilterChip('Nearest'),
                    _buildSmallFilterChip('Price'),
                    _buildSmallFilterChip('Availability'),
                    _buildSmallFilterChip('Rating'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Results List / Loading / Error
              Expanded(
                child: _dataService.isLoading && _dataService.lots.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : displayLots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 8),
                                const Text('No parking lots match your criteria', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedFilter = 'Nearest';
                                    });
                                    _dataService.loadLots();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC)),
                                  child: const Text('Reset Filters', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _dataService.loadLots(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: displayLots.length,
                              itemBuilder: (context, index) {
                                final lot = displayLots[index];
                                final avail = lot.availableSlotsCount;
                                final total = lot.totalSlotsCount;
                                final ratio = total > 0 ? (avail / total) : 0.0;

                                Color accentColor;
                                String availabilityBadge;
                                if (avail == 0) {
                                  accentColor = const Color(0xFFEF4444);
                                  availabilityBadge = '🔴 Full ($avail free)';
                                } else if (ratio < 0.20) {
                                  accentColor = const Color(0xFFF59E0B);
                                  availabilityBadge = '🟡 Limited ($avail free)';
                                } else {
                                  accentColor = const Color(0xFF22C55E);
                                  availabilityBadge = '🟢 Available ($avail free)';
                                }

                                return _buildSearchLotCard(context, lot, accentColor, availabilityBadge);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmallFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF005DAC) : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchLotCard(BuildContext context, dynamic lot, Color accentColor, String availabilityText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_parking, size: 36, color: Color(0xFF005DAC)),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 12),
                              const SizedBox(width: 2),
                              Text('${lot.rating}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(lot.distance, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          const Text(' away', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${lot.hourlyRate.toInt()}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
                              ),
                              const Text('/hour', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                availabilityText,
                                style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _dataService.addRecentSearch(lot.name);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ParkingDetailsScreen(lot: lot)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
                      foregroundColor: const Color(0xFF005DAC),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _dataService.addRecentSearch(lot.name);
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reserve Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
