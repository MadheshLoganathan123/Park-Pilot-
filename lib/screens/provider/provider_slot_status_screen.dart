import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';
import '../../models/parking_lot.dart';

class ProviderSlotStatusScreen extends StatelessWidget {
  const ProviderSlotStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();
    final lot = dataService.currentProviderLot;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF005DAC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Text('ParkPilot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
            const Spacer(),
            const Text('Slot Status', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Legend Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(const Color(0xFF22C55E), 'Available'),
                    _buildLegendItem(const Color(0xFFEF4444), 'Occupied'),
                    _buildLegendItem(const Color(0xFFFBBF24), 'Reserved'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    _buildLegendItem(const Color(0xFF3B82F6), 'Maintenance'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildFilterTab('All', isSelected: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterTab('Available')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterTab('Occupied')),
                  ],
                ),
              ],
            ),
          ),
          // Slots Grid
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFloorSection('Floor 1 - Premium Covered', lot.slots.where((s) => s.floor == 'Floor 1').toList()),
                const SizedBox(height: 24),
                _buildFloorSection('Floor 2 - Standard Open', lot.slots.where((s) => s.floor == 'Floor 2').toList()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildFilterTab(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF005DAC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSection(String title, List<ParkingSlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.layers_outlined, color: Color(0xFF005DAC), size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            return _buildSlotCard(slot);
          },
        ),
      ],
    );
  }

  Widget _buildSlotCard(ParkingSlot slot) {
    Color statusColor;
    IconData icon;
    switch (slot.status) {
      case SlotStatus.available:
        statusColor = const Color(0xFF22C55E);
        icon = Icons.check_circle_outline;
        break;
      case SlotStatus.occupied:
        statusColor = const Color(0xFFEF4444);
        icon = Icons.directions_car_filled_outlined;
        break;
      case SlotStatus.reserved:
        statusColor = const Color(0xFFFBBF24);
        icon = Icons.access_time_rounded;
        break;
      case SlotStatus.maintenance:
        statusColor = const Color(0xFF3B82F6);
        icon = Icons.build_outlined;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: slot.status == SlotStatus.maintenance ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slot.id,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: slot.status == SlotStatus.maintenance ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: statusColor, size: 20),
        ],
      ),
    );
  }
}
