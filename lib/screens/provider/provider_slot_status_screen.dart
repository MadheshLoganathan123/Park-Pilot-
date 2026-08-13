import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';
import '../../models/parking_lot.dart';

class ProviderSlotStatusScreen extends StatefulWidget {
  const ProviderSlotStatusScreen({super.key});

  @override
  State<ProviderSlotStatusScreen> createState() => _ProviderSlotStatusScreenState();
}

class _ProviderSlotStatusScreenState extends State<ProviderSlotStatusScreen> {
  String _selectedFilter = 'All';

  List<ParkingSlot> _filterSlots(List<ParkingSlot> slots) {
    if (_selectedFilter == 'Available') {
      return slots.where((s) => s.status == SlotStatus.available).toList();
    }
    if (_selectedFilter == 'Occupied') {
      return slots.where((s) => s.status == SlotStatus.occupied || s.status == SlotStatus.reserved).toList();
    }
    return slots;
  }

  void _showSlotStatusDialog(BuildContext context, ParkingSlot slot, ParkingDataService dataService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Slot ${slot.id}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                'Current Status: ${slot.status.name.toUpperCase()}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E)),
                title: const Text('Mark as Available', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  dataService.updateSlotStatus(slot.id, SlotStatus.available);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car_filled_outlined, color: Color(0xFFEF4444)),
                title: const Text('Mark as Occupied', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  dataService.updateSlotStatus(slot.id, SlotStatus.occupied);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.build_outlined, color: Color(0xFF3B82F6)),
                title: const Text('Mark as Maintenance', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  dataService.updateSlotStatus(slot.id, SlotStatus.maintenance);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final lot = dataService.currentProviderLot;

        final floor1Slots = _filterSlots(lot.slots.where((s) => s.floor == 'Floor 1').toList());
        final floor2Slots = _filterSlots(lot.slots.where((s) => s.floor == 'Floor 2' || s.floor != 'Floor 1').toList());

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
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
                        _buildLegendItem(const Color(0xFF3B82F6), 'Maintenance'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFilterTab('All')),
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
                    if (floor1Slots.isNotEmpty)
                      _buildFloorSection('Floor 1 - Premium Covered', floor1Slots, dataService),
                    if (floor2Slots.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildFloorSection('Floor 2 - Standard Open', floor2Slots, dataService),
                    ],
                    if (floor1Slots.isEmpty && floor2Slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text('No slots match the selected filter.', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildFloorSection(String title, List<ParkingSlot> slots, ParkingDataService dataService) {
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
            return GestureDetector(
              onTap: () => _showSlotStatusDialog(context, slot, dataService),
              child: _buildSlotCard(slot),
            );
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
