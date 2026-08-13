import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';
import '../../models/parking_lot.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'Upcoming';
  String _searchQuery = '';
  final Set<String> _loadingCheckIns = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(String bookingId, ParkingDataService dataService) async {
    setState(() {
      _loadingCheckIns.add(bookingId);
    });

    final success = await dataService.checkInBookingApi(bookingId);

    if (!mounted) return;

    setState(() {
      _loadingCheckIns.remove(bookingId);
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pass $bookingId Checked In Successfully!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Booking> _getFilteredBookings(List<Booking> allBookings) {
    return allBookings.where((b) {
      // Tab Filter
      bool tabMatch = true;
      if (_selectedTab == 'Upcoming') {
        tabMatch = b.status == 'Confirmed' || b.status == 'PENDING';
      } else if (_selectedTab == 'Checked In') {
        tabMatch = b.status == 'CheckedIn' || b.status == 'CHECKED_IN';
      } else if (_selectedTab == 'Completed') {
        tabMatch = b.status == 'Completed' || b.status == 'COMPLETED' || b.status == 'Cancelled';
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final idMatch = b.bookingId.toLowerCase().contains(query);
        final nameMatch = (b.customerName ?? '').toLowerCase().contains(query);
        final slotMatch = b.slotId.toLowerCase().contains(query);
        final carMatch = (b.carPlate ?? '').toLowerCase().contains(query);
        return tabMatch && (idMatch || nameMatch || slotMatch || carMatch);
      }

      return tabMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final rawBookings = dataService.userBookings;
        final filteredBookings = _getFilteredBookings(rawBookings);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DAC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                const Text('ParkPilot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Text(
                  'Customer Bookings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by Booking ID, Customer Name, or Slot',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterTab('Upcoming'),
                    const SizedBox(width: 10),
                    _buildFilterTab('Checked In'),
                    const SizedBox(width: 10),
                    _buildFilterTab('Completed'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_selectedTab.toLowerCase()} bookings found.',
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _buildBookingCard(booking, dataService);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005DAC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, ParkingDataService dataService) {
    final bool isLoading = _loadingCheckIns.contains(booking.bookingId);
    final bool isCheckedIn = booking.status == 'CheckedIn' || booking.status == 'CHECKED_IN';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: isCheckedIn ? const Color(0xFF16A34A) : const Color(0xFF005DAC),
            width: 4,
          ),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.customerName ?? 'Customer Reservation',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(booking.bookingId, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCheckedIn ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    color: isCheckedIn ? const Color(0xFF166534) : const Color(0xFF005DAC),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(booking.timeRange, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(booking.slotId.startsWith('Slot') ? booking.slotId : 'Slot ${booking.slotId}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (!isCheckedIn && booking.status != 'Cancelled') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleCheckIn(booking.bookingId, dataService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DAC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Check In Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
