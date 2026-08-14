import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';

class ProviderControlsScreen extends StatefulWidget {
  const ProviderControlsScreen({super.key});

  @override
  State<ProviderControlsScreen> createState() => _ProviderControlsScreenState();
}

class DaySchedule {
  final String dayName;
  bool isOpen;
  TimeOfDay openTime;
  TimeOfDay closeTime;

  DaySchedule({
    required this.dayName,
    this.isOpen = true,
    this.openTime = const TimeOfDay(hour: 8, minute: 0),
    this.closeTime = const TimeOfDay(hour: 23, minute: 0),
  });
}

class _ProviderControlsScreenState extends State<ProviderControlsScreen> {
  late bool _surgeEnabled;
  late double _surgeMultiplier;
  bool _isSaving = false;

  final List<DaySchedule> _schedules = [
    DaySchedule(dayName: 'Monday', isOpen: true, openTime: const TimeOfDay(hour: 8, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 0)),
    DaySchedule(dayName: 'Tuesday', isOpen: true, openTime: const TimeOfDay(hour: 8, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 0)),
    DaySchedule(dayName: 'Wednesday', isOpen: true, openTime: const TimeOfDay(hour: 8, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 0)),
    DaySchedule(dayName: 'Thursday', isOpen: true, openTime: const TimeOfDay(hour: 8, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 0)),
    DaySchedule(dayName: 'Friday', isOpen: true, openTime: const TimeOfDay(hour: 8, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 30)),
    DaySchedule(dayName: 'Saturday', isOpen: true, openTime: const TimeOfDay(hour: 7, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 59)),
    DaySchedule(dayName: 'Sunday', isOpen: true, openTime: const TimeOfDay(hour: 7, minute: 0), closeTime: const TimeOfDay(hour: 23, minute: 59)),
  ];

  @override
  void initState() {
    super.initState();
    final dataService = ParkingDataService();
    _surgeEnabled = dataService.isSurgePricingEnabled;
    _surgeMultiplier = dataService.surgeMultiplier;
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _saveSettings(ParkingDataService dataService) async {
    setState(() => _isSaving = true);

    final openDays = _schedules.where((s) => s.isOpen).map((s) => s.dayName.substring(0, 3)).join(', ');
    final operatingHoursSummary = openDays.isEmpty ? 'Closed' : '$openDays (08:00 - 23:00)';

    final success = await dataService.updateProviderSettingsApi(
      surgeEnabled: _surgeEnabled,
      surgeMultiplierVal: _surgeMultiplier,
      operatingHours: operatingHoursSummary,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider settings and operating hours saved successfully!'),
          backgroundColor: Color(0xFF005DAC),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();
    final baseRate = dataService.currentProviderLot.hourlyRate;
    final effectiveRate = _surgeEnabled ? (baseRate * _surgeMultiplier) : baseRate;

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
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Controls & Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surge Pricing Section
            const Text(
              'Dynamic Surge Pricing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Automatically adjust rates during peak demand hours',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _surgeEnabled ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              color: _surgeEnabled ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Enable Surge Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                              Text(
                                _surgeEnabled ? 'Surge is active (+${((_surgeMultiplier - 1.0) * 100).toInt()}%)' : 'Standard flat rate applies',
                                style: TextStyle(color: _surgeEnabled ? const Color(0xFFD97706) : const Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _surgeEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF005DAC),
                        onChanged: (val) {
                          setState(() {
                            _surgeEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),

                  if (_surgeEnabled) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Surge Multiplier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_surgeMultiplier.toStringAsFixed(1)}× Multiplier',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005DAC), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Slider(
                      value: _surgeMultiplier,
                      min: 1.0,
                      max: 3.0,
                      divisions: 20,
                      activeColor: const Color(0xFF005DAC),
                      inactiveColor: const Color(0xFFE2E8F0),
                      label: '${_surgeMultiplier.toStringAsFixed(1)}×',
                      onChanged: (val) {
                        setState(() {
                          _surgeMultiplier = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),
                    // Rate Preview Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Base Hourly Rate', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                              Text('₹${baseRate.toInt()}/hr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Surge Effective Rate', style: TextStyle(color: Color(0xFF005DAC), fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('₹${effectiveRate.toInt()}/hr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF005DAC))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Operating Hours Manager Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operating Hours Manager',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text('Configure daily availability & open/close times', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var s in _schedules) {
                        s.isOpen = true;
                      }
                    });
                  },
                  icon: const Icon(Icons.all_inclusive, size: 16, color: Color(0xFF005DAC)),
                  label: const Text('24/7 All', style: TextStyle(color: Color(0xFF005DAC), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedules.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = _schedules[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            item.dayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: item.isOpen ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Switch(
                          value: item.isOpen,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF22C55E),
                          onChanged: (val) {
                            setState(() {
                              item.isOpen = val;
                            });
                          },
                        ),
                        const SizedBox(width: 8),

                        if (item.isOpen)
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: item.openTime);
                                    if (picked != null) {
                                      setState(() => item.openTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(_formatTimeOfDay(item.openTime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF005DAC))),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('–', style: TextStyle(color: Color(0xFF94A3B8))),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: item.closeTime);
                                    if (picked != null) {
                                      setState(() => item.closeTime = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(_formatTimeOfDay(item.closeTime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF005DAC))),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Closed',
                                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Save Settings Action Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveSettings(dataService),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSaving ? 'Saving Controls...' : 'Save Pricing & Operating Schedule',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005DAC),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
