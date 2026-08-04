import 'package:flutter/material.dart';
import '../../models/parking_lot.dart';
import '../../services/parking_data_service.dart';
import 'confirmation_screen.dart';

class SlotSelectionScreen extends StatefulWidget {
  final ParkingLot lot;

  const SlotSelectionScreen({
    super.key,
    required this.lot,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  String? _selectedSlotId;
  int _durationHours = 2;
  String _selectedFloor = 'All Floors';

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final lot = widget.lot;
        final effectiveRate = dataService.calculateEffectiveRate(lot.hourlyRate);

        // Group slots by floor
        final floors = ['All Floors', ...{for (var slot in lot.slots) slot.floor}];

        final displayedSlots = _selectedFloor == 'All Floors'
            ? lot.slots
            : lot.slots.where((s) => s.floor == _selectedFloor).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF005DAC),
            elevation: 0,
            foregroundColor: Colors.white,
            title: Text(
              lot.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: Column(
            children: [
              // Top Banner Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF005DAC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFBAE6FD)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lot.address,
                            style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${lot.availableSlotsCount}/${lot.totalSlotsCount} Available',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (dataService.isSurgePricingEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Surge Rate: ₹${effectiveRate.toInt()}/hr',
                                  style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '₹${effectiveRate.toInt()}/hr',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Body Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Floor Filter Bar
                      const Text(
                        'Select Floor & Parking Slot',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: floors.map((fl) {
                            final isSel = fl == _selectedFloor;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(fl),
                                selected: isSel,
                                selectedColor: const Color(0xFF005DAC),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : const Color(0xFF475569),
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                ),
                                onSelected: (val) {
                                  setState(() {
                                    _selectedFloor = fl;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visual Slot Status Legend
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _LegendItem(color: Colors.white, borderColor: Color(0xFFCBD5E1), label: 'Available'),
                            _LegendItem(color: Color(0xFF005DAC), borderColor: Color(0xFF005DAC), label: 'Selected'),
                            _LegendItem(color: Color(0xFFF1F5F9), borderColor: Color(0xFFCBD5E1), label: 'Occupied'),
                            _LegendItem(color: Color(0xFFDCFCE7), borderColor: Color(0xFF16A34A), label: 'EV Zone'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Interactive Slot Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: displayedSlots.length,
                        itemBuilder: (context, index) {
                          final slot = displayedSlots[index];
                          final isOccupied = slot.status == SlotStatus.occupied;
                          final isSelected = _selectedSlotId == slot.id;

                          Color bgColor = Colors.white;
                          Color borderColor = const Color(0xFFCBD5E1);
                          Color textColor = const Color(0xFF0F172A);

                          if (isOccupied) {
                            bgColor = const Color(0xFFF1F5F9);
                            borderColor = const Color(0xFFCBD5E1);
                            textColor = const Color(0xFF94A3B8);
                          } else if (isSelected) {
                            bgColor = const Color(0xFF005DAC);
                            borderColor = const Color(0xFF005DAC);
                            textColor = Colors.white;
                          } else if (slot.isEv) {
                            bgColor = const Color(0xFFDCFCE7);
                            borderColor = const Color(0xFF16A34A);
                          } else if (slot.isHandicapped) {
                            bgColor = const Color(0xFFFEF3C7);
                            borderColor = const Color(0xFFD97706);
                          }

                          return GestureDetector(
                            onTap: isOccupied
                                ? null
                                : () {
                                    setState(() {
                                      _selectedSlotId = slot.id;
                                    });
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF005DAC).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          slot.id,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          slot.floor.split(' ').first,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (slot.isEv)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.bolt,
                                        size: 14,
                                        color: isSelected ? Colors.white : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  if (slot.isHandicapped)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.accessible,
                                        size: 14,
                                        color: isSelected ? Colors.white : const Color(0xFFD97706),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Duration Picker Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration:',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  'Hourly billing rate',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _durationHours > 1
                                      ? () {
                                          setState(() {
                                            _durationHours--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF005DAC)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_durationHours hr${_durationHours > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF005DAC),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _durationHours < 12
                                      ? () {
                                          setState(() {
                                            _durationHours++;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF005DAC)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Total Cost Calculation Card
                      if (_selectedSlotId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Selected Slot', style: TextStyle(color: Color(0xFF94A3B8))),
                                  Text(_selectedSlotId!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Rate (${_durationHours} hrs)', style: const TextStyle(color: Color(0xFF94A3B8))),
                                  Text('₹${(effectiveRate * _durationHours).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 20, color: Color(0xFF334155)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Payable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    '₹${(effectiveRate * _durationHours).toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedSlotId != null ? const Color(0xFF005DAC) : const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _selectedSlotId == null
                        ? null
                        : () {
                            final totalAmount = effectiveRate * _durationHours;
                            final newBooking = Booking(
                              bookingId: 'PK-${(10000 + (DateTime.now().millisecondsSinceEpoch % 89999))}',
                              lotName: lot.name,
                              lotAddress: lot.address,
                              slotId: _selectedSlotId!,
                              date: DateTime.now(),
                              timeRange: '${DateTime.now().hour}:00 - ${DateTime.now().hour + _durationHours}:00',
                              durationHours: _durationHours,
                              totalAmount: totalAmount,
                              qrData: 'PARKPILOT-${lot.id}-${_selectedSlotId!}',
                            );

                            dataService.addBooking(newBooking);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reserved Slot $_selectedSlotId at ${lot.name}!'),
                                backgroundColor: const Color(0xFF005DAC),
                              ),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConfirmationScreen(booking: newBooking),
                              ),
                            );
                          },
                    child: Text(
                      _selectedSlotId == null
                          ? 'Select a Parking Slot'
                          : 'Confirm Booking (₹${(effectiveRate * _durationHours).toInt()})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
