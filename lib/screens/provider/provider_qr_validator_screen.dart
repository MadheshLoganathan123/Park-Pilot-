import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';
import '../../models/parking_lot.dart';

class ProviderQrValidatorScreen extends StatefulWidget {
  const ProviderQrValidatorScreen({super.key});

  @override
  State<ProviderQrValidatorScreen> createState() => _ProviderQrValidatorScreenState();
}

class _ProviderQrValidatorScreenState extends State<ProviderQrValidatorScreen> {
  final TextEditingController _codeController = TextEditingController();
  Booking? _scannedBooking;
  String? _errorMessage;

  void _validateCode(String code) {
    final dataService = ParkingDataService();
    final match = dataService.userBookings.firstWhere(
      (b) => b.bookingId.toLowerCase() == code.trim().toLowerCase() || b.qrData.contains(code.trim()),
      orElse: () => Booking(
        bookingId: '',
        lotName: '',
        lotAddress: '',
        slotId: '',
        date: DateTime.now(),
        timeRange: '',
        totalAmount: 0,
        qrData: '',
        status: 'NotFound',
      ),
    );

    setState(() {
      if (match.bookingId.isNotEmpty) {
        _scannedBooking = match;
        _errorMessage = null;
      } else {
        _scannedBooking = null;
        _errorMessage = 'Invalid or expired reservation pass code.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gate Entry Pass Validator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scan or enter customer pass code to grant entry',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 20),

                // Simulated Scanner View Finder Container
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, size: 60, color: Color(0xFF38BDF8)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005DAC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // Quick test fill
                          if (dataService.userBookings.isNotEmpty) {
                            final sampleCode = dataService.userBookings.first.bookingId;
                            _codeController.text = sampleCode;
                            _validateCode(sampleCode);
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        label: const Text('Simulate Camera Scan', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Manual Input Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: 'Enter booking code',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005DAC),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _validateCode(_codeController.text),
                      child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Validation Result View
                if (_scannedBooking != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF16A34A), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                            SizedBox(width: 10),
                            Text(
                              'VALID RESERVATION PASS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Booking ID:', style: TextStyle(color: Color(0xFF64748B))),
                            Text(_scannedBooking!.bookingId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reserved Slot:', style: TextStyle(color: Color(0xFF64748B))),
                            Text('Slot ${_scannedBooking!.slotId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF005DAC))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Facility:', style: TextStyle(color: Color(0xFF64748B))),
                            Text(_scannedBooking!.lotName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gate Barrier Opened! Checked in Pass ${_scannedBooking!.bookingId}'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                              setState(() {
                                _scannedBooking = null;
                                _codeController.clear();
                              });
                            },
                            child: const Text('Approve & Open Gate Barrier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        ),
                      ],
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
