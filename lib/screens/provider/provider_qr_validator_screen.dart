import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/parking_data_service.dart';
import '../../models/parking_lot.dart';

class ScanLogEntry {
  final DateTime timestamp;
  final String code;
  final String? customerName;
  final String? slotNumber;
  final bool isSuccess;
  final String message;

  ScanLogEntry({
    required this.timestamp,
    required this.code,
    this.customerName,
    this.slotNumber,
    required this.isSuccess,
    required this.message,
  });
}

class ProviderQrValidatorScreen extends StatefulWidget {
  const ProviderQrValidatorScreen({super.key});

  @override
  State<ProviderQrValidatorScreen> createState() => _ProviderQrValidatorScreenState();
}

class _ProviderQrValidatorScreenState extends State<ProviderQrValidatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late MobileScannerController _scannerController;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  Booking? _scannedBooking;
  String? _errorMessage;
  String? _lastScannedCode;
  bool _isCheckingIn = false;
  bool _isTorchOn = false;
  bool _showManualEntry = false;
  bool _showSuccessOverlay = false;
  Booking? _lastCheckedInBooking;

  final List<ScanLogEntry> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _addHistoryLog({
    required String code,
    String? customerName,
    String? slotNumber,
    required bool isSuccess,
    required String message,
  }) {
    setState(() {
      _scanHistory.insert(
        0,
        ScanLogEntry(
          timestamp: DateTime.now(),
          code: code,
          customerName: customerName,
          slotNumber: slotNumber,
          isSuccess: isSuccess,
          message: message,
        ),
      );
    });
  }

  Future<void> _validateCode(String rawCode) async {
    var cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) return;

    if (cleanCode.startsWith('PARKPILOT::BOOKING::')) {
      cleanCode = cleanCode.replaceFirst('PARKPILOT::BOOKING::', '');
    }

    final dataService = ParkingDataService();

    // Check in-memory/fallback bookings first for instant responsiveness
    Booking? match;
    try {
      match = dataService.userBookings.firstWhere(
        (b) =>
            b.bookingId.toLowerCase() == cleanCode.toLowerCase() ||
            b.qrData.toLowerCase() == cleanCode.toLowerCase() ||
            b.qrData.contains(cleanCode),
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
      _addHistoryLog(
        code: cleanCode,
        isSuccess: false,
        message: 'Invalid or expired pass code',
      );

      setState(() {
        _scannedBooking = null;
        _errorMessage = 'Invalid or expired reservation pass code.';
      });
    }
  }

  Future<void> _handleConfirmCheckIn() async {
    if (_scannedBooking == null || _isCheckingIn) return;

    final bookingToCheckIn = _scannedBooking!;

    setState(() {
      _isCheckingIn = true;
    });

    final dataService = ParkingDataService();
    final success = await dataService.checkInBookingApi(bookingToCheckIn.bookingId);

    if (!mounted) return;

    setState(() {
      _isCheckingIn = false;
    });

    if (success) {
      _addHistoryLog(
        code: bookingToCheckIn.bookingId,
        customerName: bookingToCheckIn.customerName ?? 'Customer',
        slotNumber: bookingToCheckIn.slotId,
        isSuccess: true,
        message: 'Checked In Successfully',
      );

      // Trigger Celebration Overlay
      setState(() {
        _lastCheckedInBooking = bookingToCheckIn;
        _showSuccessOverlay = true;
        _scannedBooking = null;
        _errorMessage = null;
        _lastScannedCode = null;
        _codeController.clear();
      });

      // Auto dismiss celebration overlay after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _showSuccessOverlay = false;
          });
        }
      });
    } else {
      _addHistoryLog(
        code: bookingToCheckIn.bookingId,
        isSuccess: false,
        message: 'Check-in request failed on server',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Failed to complete check-in on backend.')),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'QR Gate Pass Validator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                tooltip: _isTorchOn ? 'Turn Off Flashlight' : 'Turn On Flashlight',
                icon: Icon(
                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isTorchOn ? const Color(0xFFEAB308) : const Color(0xFF64748B),
                ),
                onPressed: () async {
                  await _scannerController.toggleTorch();
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                  });
                },
              ),
              IconButton(
                tooltip: 'Switch Camera',
                icon: const Icon(Icons.cameraswitch_rounded, color: Color(0xFF64748B)),
                onPressed: () => _scannerController.switchCamera(),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subheader
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Point camera at reservation QR',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                              SizedBox(width: 5),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Custom-bracket Camera Viewfinder
                    Container(
                      height: 270,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final String? rawValue = barcode.rawValue;
                                if (rawValue != null &&
                                    rawValue.isNotEmpty &&
                                    rawValue != _lastScannedCode) {
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
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF005DAC), width: 2),
                                        ),
                                        child: const Icon(Icons.qr_code_scanner, size: 36, color: Color(0xFF38BDF8)),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Camera Scanner Standby',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Use the manual entry or quick fill button below to test pass validation.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Animated Corner Brackets & Laser Scan Line
                          AnimatedBuilder(
                            animation: _scanLineAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _CornerBracketViewfinderPainter(
                                  scanProgress: _scanLineAnimation.value,
                                  bracketColor: const Color(0xFF38BDF8),
                                  laserColor: const Color(0xFF00D4FF),
                                ),
                              );
                            },
                          ),

                          // Overlay Hint Text
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Align QR inside corner brackets',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Toggle Button for Collapsible Manual Code Entry
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showManualEntry = !_showManualEntry;
                            });
                          },
                          icon: Icon(
                            _showManualEntry ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_alt_outlined,
                            size: 18,
                            color: const Color(0xFF005DAC),
                          ),
                          label: Text(
                            _showManualEntry ? 'Hide manual entry' : "Can't scan? Enter code manually",
                            style: const TextStyle(
                              color: Color(0xFF005DAC),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (dataService.userBookings.isNotEmpty) {
                              final sample = dataService.userBookings.first.bookingId;
                              _codeController.text = sample;
                              _validateCode(sample);
                            }
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                          label: const Text(
                            'Demo Quick-Fill',
                            style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    // Collapsible Manual Text Entry Box
                    AnimatedCrossFade(
                      firstChild: Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'e.g. PK-98214 or UUID',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal, fontSize: 13),
                                  prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF005DAC), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () => _validateCode(_codeController.text),
                              child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                      crossFadeState: _showManualEntry ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 250),
                    ),

                    // Validation Result Card
                    if (_scannedBooking != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.08),
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'VALID PASS VERIFIED',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF16A34A),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        _scannedBooking!.customerName ?? 'Madhesh Loganathan',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _scannedBooking!.slotId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF005DAC),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            _detailRow('Booking ID', _scannedBooking!.bookingId),
                            _detailRow('Facility', _scannedBooking!.lotName),
                            _detailRow('Scheduled Time', _scannedBooking!.timeRange),
                            _detailRow('Amount Paid', '₹${_scannedBooking!.totalAmount.toInt()}'),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: _isCheckingIn ? null : _handleConfirmCheckIn,
                                icon: _isCheckingIn
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                                label: Text(
                                  _isCheckingIn ? 'Opening Barrier...' : 'Confirm & Check In Vehicle',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // QR Scan History Log
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 18, color: Color(0xFF0F172A)),
                            const SizedBox(width: 6),
                            const Text(
                              'Scan Activity History',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_scanHistory.length}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                        if (_scanHistory.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _scanHistory.clear();
                              });
                            },
                            child: const Text('Clear', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_scanHistory.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.qr_code_2_rounded, color: Color(0xFFCBD5E1), size: 36),
                            SizedBox(height: 8),
                            Text(
                              'No scans in this session yet',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scanHistory.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _scanHistory[index];
                          final timeStr =
                              '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: item.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '#${item.code}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.isSuccess
                                            ? '${item.customerName ?? "Customer"} • Slot ${item.slotNumber ?? "S-1"}'
                                            : item.message,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: item.isSuccess ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Full Screen / Modal Success Celebration Overlay
              if (_showSuccessOverlay && _lastCheckedInBooking != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 32),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDCFCE7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF16A34A),
                                        size: 52,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'GATE BARRIER OPENED!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF166534),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Booking #${_lastCheckedInBooking!.bookingId}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_lastCheckedInBooking!.customerName ?? "Customer"}  •  Slot ${_lastCheckedInBooking!.slotId}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Status updated in database',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

/// CustomPainter that draws 4 rounded corner brackets and a moving horizontal scan line.
class _CornerBracketViewfinderPainter extends CustomPainter {
  final double scanProgress;
  final Color bracketColor;
  final Color laserColor;

  _CornerBracketViewfinderPainter({
    required this.scanProgress,
    required this.bracketColor,
    required this.laserColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxSize = size.width * 0.58;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final right = left + boxSize;
    final bottom = top + boxSize;

    final bracketLength = boxSize * 0.22;
    const radius = 12.0;

    final bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(left, top + bracketLength)
      ..lineTo(left, top + radius)
      ..arcToPoint(Offset(left + radius, top), radius: const Radius.circular(12.0))
      ..lineTo(left + bracketLength, top);
    canvas.drawPath(tlPath, bracketPaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(right - bracketLength, top)
      ..lineTo(right - radius, top)
      ..arcToPoint(Offset(right, top + radius), radius: const Radius.circular(12.0))
      ..lineTo(right, top + bracketLength);
    canvas.drawPath(trPath, bracketPaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(left, bottom - bracketLength)
      ..lineTo(left, bottom - radius)
      ..arcToPoint(Offset(left + radius, bottom), radius: const Radius.circular(12.0))
      ..lineTo(left + bracketLength, bottom);
    canvas.drawPath(blPath, bracketPaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(right - bracketLength, bottom)
      ..lineTo(right - radius, bottom)
      ..arcToPoint(Offset(right, bottom - radius), radius: const Radius.circular(12.0))
      ..lineTo(right, bottom - bracketLength);
    canvas.drawPath(brPath, bracketPaint);

    // Bouncing Laser Scan Line
    final laserY = top + (boxSize * scanProgress);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          laserColor.withValues(alpha: 0.0),
          laserColor.withValues(alpha: 0.9),
          laserColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(left, laserY, right, laserY + 3))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(left + 8, laserY), Offset(right - 8, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketViewfinderPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
