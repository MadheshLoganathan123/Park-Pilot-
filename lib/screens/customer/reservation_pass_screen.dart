import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/parking_lot.dart';
import '../../services/parking_data_service.dart';

class ReservationPassScreen extends StatelessWidget {
  final Booking booking;

  const ReservationPassScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final isCancelled = booking.status == 'Cancelled';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            foregroundColor: Colors.white,
            title: const Text('Digital Entry Pass', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  final passText = 'PARKPILOT::BOOKING::${booking.bookingId}';
                  Clipboard.setData(ClipboardData(text: passText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pass code copied to clipboard: ${booking.bookingId}'),
                      backgroundColor: const Color(0xFF005DAC),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Digital Ticket Main Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Ticket Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF005DAC),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PARKPILOT PASS',
                                    style: TextStyle(
                                      color: Color(0xFFBAE6FD),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.bookingId,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isCancelled ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                booking.status.toUpperCase(),
                                style: TextStyle(
                                  color: isCancelled ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // QR Code Section
                      if (!isCancelled) ...[
                        Center(
                          child: QrImageView(
                            data: booking.qrData,
                            version: QrVersions.auto,
                            size: 180.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan at parking gate terminal',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.cancel_outlined, size: 60, color: Color(0xFFDC2626)),
                              SizedBox(height: 10),
                              Text(
                                'This pass has been cancelled.',
                                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Ticket Divider line with semi-circles
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: DashDivider(),
                          ),
                          Container(
                            width: 12,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Details Section
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _PassDetailRow(
                              icon: Icons.storefront_rounded,
                              label: 'Facility',
                              value: booking.lotName,
                            ),
                            const SizedBox(height: 14),
                            _PassDetailRow(
                              icon: Icons.space_dashboard_rounded,
                              label: 'Assigned Slot',
                              value: 'Slot ${booking.slotId}',
                              valueColor: const Color(0xFF005DAC),
                            ),
                            const SizedBox(height: 14),
                            _PassDetailRow(
                              icon: Icons.timer_rounded,
                              label: 'Reserved Duration',
                              value: booking.timeRange,
                            ),
                            const SizedBox(height: 14),
                            _PassDetailRow(
                              icon: Icons.payments_rounded,
                              label: 'Amount Paid',
                              value: '₹${booking.totalAmount.toStringAsFixed(0)}',
                              valueColor: const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (!isCancelled) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005DAC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Navigation to Parking Facility...')),
                        );
                      },
                      icon: const Icon(Icons.near_me_rounded, color: Colors.white),
                      label: const Text(
                        'Navigate to Parking Lot',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Reservation?'),
                            content: const Text('Are you sure you want to cancel this booking? The slot will be released back to live vacancy.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Keep Reservation'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                onPressed: () {
                                  dataService.cancelBooking(booking.bookingId);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Cancel Reservation',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PassDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _PassDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class DashDivider extends StatelessWidget {
  const DashDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }
}
