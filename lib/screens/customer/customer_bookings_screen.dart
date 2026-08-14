import 'package:flutter/material.dart';
import '../../models/parking_lot.dart';
import '../../services/parking_data_service.dart';
import 'reservation_pass_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> with SingleTickerProviderStateMixin {
  final ParkingDataService _dataService = ParkingDataService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dataService.loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Booking> _filterBookings(List<Booking> list, int tabIndex) {
    switch (tabIndex) {
      case 0: // Upcoming
        return list.where((b) => b.status.toLowerCase() == 'confirmed').toList();
      case 1: // Past
        return list.where((b) {
          final s = b.status.toLowerCase();
          return s == 'completed' || s == 'checked_in' || s == 'checkedin';
        }).toList();
      case 2: // Cancelled
        return list.where((b) => b.status.toLowerCase() == 'cancelled').toList();
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF005DAC)),
            onPressed: () => _dataService.loadBookings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF005DAC),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF005DAC),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          if (_dataService.isLoading && _dataService.userBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(_filterBookings(_dataService.userBookings, 0), 'No upcoming reservations found.'),
              _buildBookingList(_filterBookings(_dataService.userBookings, 1), 'No past parking history.'),
              _buildBookingList(_filterBookings(_dataService.userBookings, 2), 'No cancelled reservations.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _dataService.loadBookings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bookmark_border_rounded, size: 64, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _dataService.loadBookings(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _dataService.loadBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final isConfirmed = booking.status.toLowerCase() == 'confirmed';
          final statusColor = isConfirmed
              ? const Color(0xFF005DAC)
              : (booking.status.toLowerCase() == 'cancelled' ? Colors.red : const Color(0xFF16A34A));

          return Dismissible(
            key: Key('booking-${booking.bookingId}-$index'),
            direction: isConfirmed ? DismissDirection.endToStart : DismissDirection.none,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text('Cancel Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Cancel Reservation?'),
                  content: Text('Are you sure you want to cancel your parking booking at ${booking.lotName}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Booking')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              try {
                await _dataService.cancelBookingApi(booking.bookingId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking ${booking.bookingId} cancelled.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservationPassScreen(booking: booking),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.lotName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.lotAddress,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildInfo(Icons.grid_view, 'Slot ${booking.slotId}'),
                        const SizedBox(width: 16),
                        _buildInfo(Icons.access_time, booking.timeRange),
                        const Spacer(),
                        Text(
                          '₹${booking.totalAmount.toInt()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 4),
                            Text('Tap for Pass', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                        if (isConfirmed)
                          const Row(
                            children: [
                              Icon(Icons.swipe_left_outlined, size: 14, color: Colors.redAccent),
                              SizedBox(width: 4),
                              Text('Swipe to Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF005DAC)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155), fontSize: 13)),
      ],
    );
  }
}
