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
  String? _expandedSlotId;

  List<ParkingSlot> _filterSlots(List<ParkingSlot> slots) {
    if (_selectedFilter == 'Available') {
      return slots.where((s) => s.status == SlotStatus.available).toList();
    }
    if (_selectedFilter == 'Occupied') {
      return slots.where((s) => s.status == SlotStatus.occupied || s.status == SlotStatus.reserved).toList();
    }
    if (_selectedFilter == 'Maintenance') {
      return slots.where((s) => s.status == SlotStatus.maintenance).toList();
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final lot = dataService.currentProviderLot;
        final filteredSlots = _filterSlots(lot.slots);

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
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Slot Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
                    Text('${lot.name} (${lot.availableSlotsCount} free / ${lot.totalSlotsCount} total)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF005DAC)),
                onPressed: () => dataService.loadLots(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Legend & Filter Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _LegendDot(color: Color(0xFF22C55E), label: 'Available'),
                        _LegendDot(color: Color(0xFF005DAC), label: 'Occupied'),
                        _LegendDot(color: Color(0xFFF97316), label: 'Maintenance'),
                        _LegendDot(color: Color(0xFF64748B), label: 'Reserved'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab('All'),
                          const SizedBox(width: 8),
                          _buildFilterTab('Available'),
                          const SizedBox(width: 8),
                          _buildFilterTab('Occupied'),
                          const SizedBox(width: 8),
                          _buildFilterTab('Maintenance'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Slots List
              Expanded(
                child: filteredSlots.isEmpty
                    ? const Center(
                        child: Text('No slots match the selected filter.', style: TextStyle(color: Color(0xFF94A3B8))),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredSlots.length,
                        itemBuilder: (context, index) {
                          final slot = filteredSlots[index];
                          return _buildInteractiveSlotCard(context, lot, slot, dataService);
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF005DAC) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveSlotCard(BuildContext context, ParkingLot lot, ParkingSlot slot, ParkingDataService dataService) {
    final isExpanded = _expandedSlotId == slot.id;
    final isOccupied = slot.status == SlotStatus.occupied;
    final isMaintenance = slot.status == SlotStatus.maintenance;

    Color statusColor;
    switch (slot.status) {
      case SlotStatus.available:
        statusColor = const Color(0xFF22C55E);
        break;
      case SlotStatus.occupied:
        statusColor = const Color(0xFF005DAC);
        break;
      case SlotStatus.reserved:
        statusColor = const Color(0xFF64748B);
        break;
      case SlotStatus.maintenance:
        statusColor = const Color(0xFFF97316);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMaintenance ? const Color(0xFFFFF7ED) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border.all(color: isExpanded ? statusColor : const Color(0xFFE2E8F0), width: isExpanded ? 1.5 : 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOccupied
              ? () {
                  setState(() {
                    _expandedSlotId = isExpanded ? null : slot.id;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Slot ID Badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          slot.id,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Slot Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${slot.floor} • Spot ${slot.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              if (slot.isEv) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.bolt, color: Color(0xFF16A34A), size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (isOccupied)
                            Row(
                              children: [
                                const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  slot.vehiclePlate ?? 'TN 09 BK 4521',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF005DAC)),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  slot.checkInTime ?? '10:15 AM',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            )
                          else
                            Text(
                              isMaintenance ? 'Under Service / Blocked' : 'Ready for reservation',
                              style: TextStyle(color: isMaintenance ? const Color(0xFFF97316) : const Color(0xFF64748B), fontSize: 12),
                            ),
                        ],
                      ),
                    ),

                    // Maintenance Switch Toggle
                    Column(
                      children: [
                        Text(
                          'Maint.',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isMaintenance ? const Color(0xFFF97316) : const Color(0xFF94A3B8)),
                        ),
                        Switch(
                          value: isMaintenance,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFFF97316),
                          onChanged: (val) {
                            final newStatus = val ? SlotStatus.maintenance : SlotStatus.available;
                            dataService.updateSlotStatusApi(lot.id, slot.id, newStatus);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Slot ${slot.id} set to ${newStatus.name.toUpperCase()}'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: val ? const Color(0xFFF97316) : const Color(0xFF22C55E),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // Expandable Details Section for Occupied Slot
                if (isOccupied && isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Customer Name', slot.customerName ?? 'Rahul Sharma'),
                        const SizedBox(height: 6),
                        _buildDetailRow('Vehicle Plate', slot.vehiclePlate ?? 'TN 09 BK 4521'),
                        const SizedBox(height: 6),
                        _buildDetailRow('Entry Check-in', slot.checkInTime ?? '10:15 AM'),
                        const SizedBox(height: 6),
                        _buildDetailRow('Slot Rate', '₹${lot.hourlyRate.toInt()}/hr'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
      ],
    );
  }
}
