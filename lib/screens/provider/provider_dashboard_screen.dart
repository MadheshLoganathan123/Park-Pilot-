import 'package:flutter/material.dart';
import '../../models/parking_lot.dart';
import '../../services/parking_data_service.dart';
import 'provider_qr_validator_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ParkingDataService().loadProviderStats();
      ParkingDataService().loadLots();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final stats = dataService.providerStatsObj;
        final double occRate = stats.occupancyRate.clamp(0.0, 100.0);
        final double occRatio = (occRate / 100.0).clamp(0.0, 1.0);
        final int occupied = stats.occupiedSlotsCount;
        final int total = stats.totalSlotsCount > 0 ? stats.totalSlotsCount : 150;
        final int available = stats.availableSlotsCount > 0 ? stats.availableSlotsCount : (total - occupied);

        // Color transition: Green (<70%) -> Amber (70-90%) -> Red (>90%)
        Color ringColor;
        if (occRate < 70) {
          ringColor = const Color(0xFF22C55E); // Green
        } else if (occRate <= 90) {
          ringColor = const Color(0xFFF59E0B); // Amber
        } else {
          ringColor = const Color(0xFFEF4444); // Red
        }

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
                  child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Provider Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005DAC))),
                    Text(dataService.currentProviderLot.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF005DAC)),
                onPressed: () => dataService.loadProviderStats(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => dataService.loadProviderStats(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Header Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueCard(
                          title: "Today's Revenue",
                          amount: '₹${stats.todayRevenue.toInt()}',
                          badgeText: 'Today',
                          badgeColor: const Color(0xFFDCFCE7),
                          badgeTextColor: const Color(0xFF16A34A),
                          icon: Icons.payments_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildRevenueCard(
                          title: "Total Revenue",
                          amount: '₹${stats.totalRevenue.toInt()}',
                          badgeText: 'Active Month',
                          badgeColor: const Color(0xFFDBEAFE),
                          badgeTextColor: const Color(0xFF005DAC),
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Occupancy & Bookings Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Occupancy Rate',
                          '${occRate.toInt()}%',
                          Icons.pie_chart_rounded,
                          subtitle: '$occupied of $total occupied',
                          accentColor: ringColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          'Active Bookings',
                          '${stats.activeBookingsCount}',
                          Icons.directions_car_filled_rounded,
                          subtitle: '$available slots free now',
                          accentColor: const Color(0xFF005DAC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 7-Day Revenue Bar Chart
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
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('7-Day Revenue Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                SizedBox(height: 2),
                                Text('Daily gross revenue from slot bookings', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Live', style: TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildWeeklyBarChart(stats.weeklyRevenue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Live Occupancy Circular Ring
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
                        const Text('Live Space Occupancy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Animated Occupancy Ring
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: occRatio),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, val, _) {
                                      return CircularProgressIndicator(
                                        value: val,
                                        strokeWidth: 10,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                                        strokeCap: StrokeCap.round,
                                      );
                                    },
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${occRate.toInt()}%',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ringColor),
                                      ),
                                      const Text('Full', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildOccupancyLegendItem('Occupied Slots', '$occupied', ringColor),
                                  const SizedBox(height: 8),
                                  _buildOccupancyLegendItem('Free Available', '$available', const Color(0xFF22C55E)),
                                  const SizedBox(height: 8),
                                  _buildOccupancyLegendItem('Total Capacity', '$total', const Color(0xFF005DAC)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scanner Action Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProviderQrValidatorScreen()),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                    label: const Text('Open QR Scanner Terminal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005DAC),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Live Check-in Activity
                  const Text('Live Check-in Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  if (dataService.recentActivities.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.directions_car_outlined, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'No recent check-in activity',
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dataService.recentActivities.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final activity = dataService.recentActivities[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(activity.initial, style: const TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activity.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text(activity.plate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(activity.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF005DAC))),
                                Text(activity.action, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required String amount,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
              Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {required String subtitle, required Color accentColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<WeeklyRevenueData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxRev = data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRev > 0 ? maxRev : 1000.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final heightFactor = (item.revenue / effectiveMax).clamp(0.15, 1.0);
        final isHighest = item.revenue == maxRev;

        return Column(
          children: [
            Text(
              '₹${item.revenue.toInt()}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                color: isHighest ? const Color(0xFF005DAC) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 24,
              height: 110 * heightFactor,
              decoration: BoxDecoration(
                color: isHighest ? const Color(0xFF005DAC) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
                color: isHighest ? const Color(0xFF005DAC) : const Color(0xFF64748B),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildOccupancyLegendItem(String label, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ],
        ),
        Text(count, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
