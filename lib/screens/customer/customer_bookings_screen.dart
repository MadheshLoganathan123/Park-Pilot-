import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  final ParkingDataService _dataService = ParkingDataService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dataService.loadBookings();
    });
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
      ),
      body: AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          if (_dataService.isLoading && _dataService.userBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = _dataService.userBookings;
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border, size: 64, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Reservations Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Book a slot to view your active reservations here.', style: TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _dataService.loadBookings(),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC)),
                    child: const Text('Refresh', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _dataService.loadBookings(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final isConfirmed = booking.status == 'Confirmed';
                final statusColor = isConfirmed ? const Color(0xFF005DAC) : (booking.status == 'Cancelled' ? Colors.red : Colors.green);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                      Text(booking.lotAddress, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfo(Icons.grid_view, 'Slot ${booking.slotId}'),
                          const SizedBox(width: 20),
                          _buildInfo(Icons.access_time, booking.timeRange),
                          const Spacer(),
                          Text(
                            '₹${booking.totalAmount.toInt()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
                          ),
                        ],
                      ),
                      if (isConfirmed) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cancel Reservation'),
                                    content: const Text('Are you sure you want to cancel this booking?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _dataService.cancelBookingApi(booking.bookingId);
                                }
                              },
                              child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
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
