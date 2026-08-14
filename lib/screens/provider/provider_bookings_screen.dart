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
  String _selectedTab = 'Today'; // 'Today', 'This Week', 'All Time'
  String _searchQuery = '';
  final Set<String> _loadingCheckIns = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ParkingDataService().loadProviderBookings();
    });
  }

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
          content: Text('Booking $bookingId Checked In Successfully!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Booking> _getFilteredBookings(List<Booking> allBookings) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    return allBookings.where((b) {
      // Date Filter
      bool dateMatch = true;
      if (_selectedTab == 'Today') {
        dateMatch = b.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            b.date.isBefore(todayStart.add(const Duration(days: 1)));
      } else if (_selectedTab == 'This Week') {
        dateMatch = b.date.isAfter(weekStart.subtract(const Duration(seconds: 1)));
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final idMatch = b.bookingId.toLowerCase().contains(query);
        final nameMatch = (b.customerName ?? '').toLowerCase().contains(query);
        final slotMatch = b.slotId.toLowerCase().contains(query);
        final carMatch = (b.carPlate ?? '').toLowerCase().contains(query);
        final lotMatch = b.lotName.toLowerCase().contains(query);
        return dateMatch && (idMatch || nameMatch || slotMatch || carMatch || lotMatch);
      }

      return dateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final rawBookings = dataService.providerBookings;
        final filteredBookings = _getFilteredBookings(rawBookings);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005DAC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Customer Reservations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF005DAC)),
                onPressed: () => dataService.loadProviderBookings(),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            hintText: 'Search by Booking ID, Name, or Slot...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
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

              // Filter Tabs (Today | This Week | All Time)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildFilterTab('Today')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildFilterTab('This Week')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildFilterTab('All Time')),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bookings List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => dataService.loadProviderBookings(),
                  child: filteredBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No ${_selectedTab.toLowerCase()} reservations found.',
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _buildBookingCard(booking, dataService);
                          },
                        ),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005DAC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, ParkingDataService dataService) {
    final bool isLoading = _loadingCheckIns.contains(booking.bookingId);
    final status = booking.status.toUpperCase();

    // Lifecycle Status Workflow Colors:
    // PENDING -> Amber | CONFIRMED -> Blue | CHECKED_IN -> Green | COMPLETED -> Slate | CANCELLED -> Red
    Color badgeBg;
    Color badgeTextColor;
    IconData statusIcon;

    switch (status) {
      case 'CHECKED_IN':
      case 'CHECKEDIN':
        badgeBg = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'COMPLETED':
        badgeBg = const Color(0xFFF1F5F9);
        badgeTextColor = const Color(0xFF475569);
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'CANCELLED':
        badgeBg = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFFDC2626);
        statusIcon = Icons.cancel_rounded;
        break;
      case 'PENDING':
        badgeBg = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFFD97706);
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'CONFIRMED':
      default:
        badgeBg = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF005DAC);
        statusIcon = Icons.verified_rounded;
        break;
    }

    final isCheckInEligible = status == 'CONFIRMED' || status == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
                      booking.customerName ?? 'Customer Reservation',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${booking.bookingId}',
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF005DAC)),
                    const SizedBox(width: 6),
                    Text(
                      booking.slotId.startsWith('Slot') ? booking.slotId : 'Slot ${booking.slotId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      booking.timeRange,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${booking.totalAmount.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
              ),
            ],
          ),

          if (isCheckInEligible) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _handleCheckIn(booking.bookingId, dataService),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Check In Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DAC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
