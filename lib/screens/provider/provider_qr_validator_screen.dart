import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/parking_data_service.dart';
import '../../models/parking_lot.dart';

class ProviderQrValidatorScreen extends StatefulWidget {
  const ProviderQrValidatorScreen({super.key});

  @override
  State<ProviderQrValidatorScreen> createState() => _ProviderQrValidatorScreenState();
}

class _ProviderQrValidatorScreenState extends State<ProviderQrValidatorScreen> {
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Booking? _scannedBooking;
  String? _errorMessage;
  String? _lastScannedCode;
  bool _isCheckingIn = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validateCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    final dataService = ParkingDataService();
    
    // Check local list first
    Booking? match;
    try {
      match = dataService.userBookings.firstWhere(
        (b) => b.bookingId.toLowerCase() == cleanCode.toLowerCase() || b.qrData.toLowerCase() == cleanCode.toLowerCase() || b.qrData.contains(cleanCode),
      );
    } catch (_) {
      match = null;
    }

    if (match != null) {
      setState(() {
        _scannedBooking = match;
        _errorMessage = null;
      });
      return;
    }

    // Try backend verification API
    final apiResult = await dataService.verifyQrApi(cleanCode);
    if (apiResult != null && apiResult['booking'] != null) {
      final bookingData = apiResult['booking'];
      final apiBooking = Booking(
        bookingId: bookingData['id'] ?? cleanCode,
        lotName: bookingData['parkingSpace']?['name'] ?? 'Parking Facility',
        lotAddress: bookingData['parkingSpace']?['address'] ?? '',
        slotId: bookingData['slotNumber'] ?? 'S-1',
        date: DateTime.tryParse(bookingData['bookingDate'] ?? '') ?? DateTime.now(),
        timeRange: '${bookingData['startTime'] ?? ''} - ${bookingData['endTime'] ?? ''}',
        totalAmount: (bookingData['totalAmount'] as num?)?.toDouble() ?? 0.0,
        qrData: cleanCode,
        status: bookingData['status'] ?? 'Confirmed',
        customerName: bookingData['customer']?['name'],
      );

      setState(() {
        _scannedBooking = apiBooking;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _scannedBooking = null;
        _errorMessage = 'Invalid or expired reservation pass code.';
      });
    }
  }

  Future<void> _handleConfirmCheckIn() async {
    if (_scannedBooking == null || _isCheckingIn) return;

    setState(() {
      _isCheckingIn = true;
    });

    final dataService = ParkingDataService();
    final success = await dataService.checkInBookingApi(_scannedBooking!.bookingId);

    if (!mounted) return;

    setState(() {
      _isCheckingIn = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Gate Barrier Opened! Checked in Pass ${_scannedBooking!.bookingId}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {
        _scannedBooking = null;
        _errorMessage = null;
        _lastScannedCode = null;
        _codeController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete check-in on backend.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
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
                  'Scan live QR code or enter customer pass code to grant entry',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 16),

                // Real MobileScanner Camera Finder
                Container(
                  height: 260,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
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
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final String? rawValue = barcode.rawValue;
                            if (rawValue != null && rawValue.isNotEmpty && rawValue != _lastScannedCode) {
                              _lastScannedCode = rawValue;
                              _codeController.text = rawValue;
                              _validateCode(rawValue);
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF38BDF8)),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Camera Scanner Ready',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Camera stream unavailable in emulator mode. Use manual code entry below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Overlay Scanner Box Visual
                      Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.transparent,
                          ),
                        ),
                      ),

                      // Camera Overlay Controls Top Right
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await _scannerController.toggleTorch();
                                  setState(() {
                                    _isTorchOn = !_isTorchOn;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 20),
                                onPressed: () => _scannerController.switchCamera(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Camera Status Label Top Left
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005DAC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('LIVE SCANNER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Simulation & Manual Input Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: 'Enter booking code',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        onSubmitted: (val) => _validateCode(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005DAC),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _validateCode(_codeController.text),
                      child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Simulator / Demo Quick Fill Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      if (dataService.userBookings.isNotEmpty) {
                        final sampleCode = dataService.userBookings.first.bookingId;
                        _codeController.text = sampleCode;
                        _validateCode(sampleCode);
                      }
                    },
                    icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF005DAC)),
                    label: const Text('Quick Demo Code Fill', style: TextStyle(color: Color(0xFF005DAC), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 14),

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
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'VALID RESERVATION PASS',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A)),
                                  ),
                                  if (_scannedBooking!.customerName != null)
                                    Text('Customer: ${_scannedBooking!.customerName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
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
                            Text(_scannedBooking!.bookingId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reserved Slot:', style: TextStyle(color: Color(0xFF64748B))),
                            Text(_scannedBooking!.slotId.startsWith('Slot') ? _scannedBooking!.slotId : 'Slot ${_scannedBooking!.slotId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF005DAC))),
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
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status:', style: TextStyle(color: Color(0xFF64748B))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _scannedBooking!.status == 'CheckedIn'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _scannedBooking!.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _scannedBooking!.status == 'CheckedIn'
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
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
                            onPressed: _isCheckingIn ? null : _handleConfirmCheckIn,
                            child: _isCheckingIn
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Approve & Open Gate Barrier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
