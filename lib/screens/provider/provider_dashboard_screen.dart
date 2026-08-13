import 'package:flutter/material.dart';
import '../../services/parking_data_service.dart';
import 'provider_qr_validator_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ParkingDataService().loadProviderStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final double occupancyRatio = (dataService.currentOccupancy / 100).clamp(0.0, 1.0);
        final int occupied = dataService.occupiedSlotsCount;
        final int total = dataService.totalSlotsCount;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manager Terminal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
                    Text(dataService.currentProviderLot.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
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
                // Revenue Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today's Revenue", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const Icon(Icons.payments_outlined, color: Color(0xFF94A3B8)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${dataService.todayRevenue.toInt()}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Live API Revenue',
                          style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Occupancy & Bookings Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Current Occupancy',
                        '${dataService.currentOccupancy.toInt()}%',
                        Icons.people_outline,
                        showProgress: true,
                        progress: occupancyRatio,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Bookings',
                        '${dataService.activeBookingsCount}',
                        Icons.calendar_today_outlined,
                        subtitle: '${dataService.activeBookingsCount} confirmed active',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Live Lot Status
                const Text('Live Lot Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border(left: BorderSide(color: Color(0xFF005DAC), width: 4)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: occupancyRatio,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFFF1F5F9),
                                color: const Color(0xFF005DAC),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$occupied',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '/$total',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildSmallStatBox('${(total * 0.6).toInt()}', 'Standard'),
                          const SizedBox(width: 12),
                          _buildSmallStatBox('${(total * 0.3).toInt()}', 'Covered'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildSmallStatBox('${(total * 0.1).toInt()}', 'EV Charging'),
                          const SizedBox(width: 12),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Quick Actions
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProviderQrValidatorScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005DAC),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner),
                      SizedBox(width: 12),
                      Text('Scan QR Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    dataService.updateSurge(!dataService.isSurgePricingEnabled, 1.25);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          dataService.isSurgePricingEnabled
                              ? 'Surge Pricing Enabled (1.25x)'
                              : 'Standard Pricing Restored',
                        ),
                        backgroundColor: const Color(0xFF005DAC),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF005DAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_document, color: Color(0xFF005DAC)),
                      const SizedBox(width: 12),
                      Text(
                        dataService.isSurgePricingEnabled ? 'Disable Surge Pricing' : 'Enable Surge (+25%)',
                        style: const TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Recent Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dataService.recentActivities.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final activity = dataService.recentActivities[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(activity.initial, style: const TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(activity.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(activity.plate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(activity.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(activity.action, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {bool showProgress = false, double progress = 0.0, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500))),
              Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
          if (showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1F5F9),
                color: const Color(0xFF005DAC),
                minHeight: 4,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
