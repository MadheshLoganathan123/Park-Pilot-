import 'package:flutter/material.dart';

class SlotSelectionScreen extends StatefulWidget {
  final String lotName;
  final double hourlyRate;

  const SlotSelectionScreen({
    super.key,
    required this.lotName,
    required this.hourlyRate,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  String? selectedSlot;
  int durationHours = 2;

  final List<String> slotsFloor1 = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8'];
  final List<String> occupiedSlots = ['A2', 'A5', 'A7'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Select Slot - ${widget.lotName}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Floor 1 - Premium Covered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: slotsFloor1.length,
              itemBuilder: (context, index) {
                final slot = slotsFloor1[index];
                final isOccupied = occupiedSlots.contains(slot);
                final isSelected = selectedSlot == slot;

                Color slotBg = Colors.white;
                Color borderCol = const Color(0xFFCBD5E1);
                if (isOccupied) {
                  slotBg = const Color(0xFFFEF2F2);
                  borderCol = Colors.redAccent;
                } else if (isSelected) {
                  slotBg = const Color(0xFF0284C7);
                  borderCol = const Color(0xFF0284C7);
                }

                return GestureDetector(
                  onTap: isOccupied
                      ? null
                      : () {
                          setState(() {
                            selectedSlot = slot;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: slotBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Duration selector
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
                  const Text(
                    'Parking Duration:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: durationHours > 1
                            ? () {
                                setState(() {
                                  durationHours--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$durationHours hr${durationHours > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            durationHours++;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (selectedSlot != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reserved Slot $selectedSlot successfully for $durationHours hr(s)!'),
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Confirm Reservation (₹${(widget.hourlyRate * durationHours).toInt()})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
