import 'package:flutter/material.dart';
import '../../models/parking_lot.dart';
import '../../services/parking_data_service.dart';
import '../customer/edit_profile_screen.dart';
import '../login_screen.dart';
import 'manage_parking_space_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _dataService = ParkingDataService();

  bool _hasEv = true;
  bool _hasCctv = true;
  bool _hasCovered = true;
  bool _hasSecurity = true;
  bool _updatingAmenities = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await _dataService.refreshProfile();
      await _dataService.loadProviderStats();
      await _dataService.loadProviderSpaces();
      await _dataService.loadLots();
    } catch (_) {}
  }

  Future<void> _toggleAmenity(String label, bool currentVal, Function(bool) setVal) async {
    final lot = _dataService.currentProviderLot;
    final newVal = !currentVal;
    setState(() {
      setVal(newVal);
      _updatingAmenities = true;
    });

    try {
      final success = await _dataService.updateFacilityAmenitiesApi(
        spaceId: lot.id,
        hasEv: _hasEv,
        hasCctv: _hasCctv,
        hasCovered: _hasCovered,
        hasSecurity: _hasSecurity,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label ${newVal ? "enabled" : "disabled"} for ${lot.name}.'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF005DAC),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // revert
      setState(() => setVal(currentVal));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update amenity: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingAmenities = false);
    }
  }

  Future<void> _editProfile() async {
    final profile = _dataService.profile;
    if (profile == null) return;
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)),
    );
    if (result == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final lot = _dataService.currentProviderLot;
          final profile = _dataService.profile;
          final stats = _dataService.providerStatsObj;
          final loading = _dataService.isProfileLoading && profile == null;
          final allSpaces = _dataService.providerSpaces;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Provider Account & Facility',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    final res = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageParkingSpaceScreen()),
                    );
                    if (res == true) _loadProfile();
                  },
                  tooltip: 'Add New Parking Facility',
                  icon: const Icon(Icons.add_business_rounded, color: Color(0xFF005DAC)),
                ),
                IconButton(
                  onPressed: profile == null ? null : _editProfile,
                  tooltip: 'Edit account profile',
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF005DAC)),
                ),
              ],
            ),
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    color: const Color(0xFF005DAC),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildAccountCard(profile),
                          const SizedBox(height: 16),

                          // Provider Financial Summary Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF005DAC), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF005DAC).withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Revenue Summary',
                                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Today's Earnings", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${stats.todayRevenue.toInt()}',
                                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(width: 1, height: 36, color: Colors.white24),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${stats.totalRevenue.toInt()}',
                                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          _buildLotHeaderCard(lot, stats, allSpaces),
                          const SizedBox(height: 20),

                          _buildSectionHeader(Icons.layers_outlined, 'Facility Amenities & Persisted Features'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildToggleItem(
                                  Icons.ev_station,
                                  'EV Fast Charging Bays',
                                  _hasEv,
                                  (val) => _toggleAmenity('EV Charging', _hasEv, (v) => _hasEv = v),
                                ),
                                _buildToggleItem(
                                  Icons.videocam_outlined,
                                  '24/7 CCTV & ANPR Cameras',
                                  _hasCctv,
                                  (val) => _toggleAmenity('24/7 CCTV', _hasCctv, (v) => _hasCctv = v),
                                ),
                                _buildToggleItem(
                                  Icons.roofing_rounded,
                                  'Covered Basement Weather Protection',
                                  _hasCovered,
                                  (val) => _toggleAmenity('Covered Protection', _hasCovered, (v) => _hasCovered = v),
                                ),
                                _buildToggleItem(
                                  Icons.security_rounded,
                                  'Security Guard Patrol',
                                  _hasSecurity,
                                  (val) => _toggleAmenity('Security Guards', _hasSecurity, (v) => _hasSecurity = v),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildLinkItem(Icons.receipt_long_outlined, 'Settlement & Bank Payouts'),
                                const Divider(height: 1, indent: 56),
                                _buildLinkItem(Icons.badge_outlined, 'Staff & Operator Permissions'),
                                const Divider(height: 1, indent: 56),
                                _buildLinkItem(Icons.description_outlined, 'Commercial Terms & Policy'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Logout Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                              title: const Text(
                                'Log Out Provider Session',
                                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Color(0xFFEF4444)),
                              onTap: () async {
                                await _dataService.logout();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          );
        },
      );

  Widget _buildAccountCard(profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: profile == null
          ? Row(
              children: [
                Expanded(
                  child: Text(_dataService.profileError ?? 'Unable to load account profile. Pull down to retry.'),
                ),
                TextButton(onPressed: _dataService.isProfileLoading ? null : _loadProfile, child: const Text('Retry')),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF005DAC),
                  backgroundImage: profile.profileImage == null ? null : NetworkImage(profile.profileImage!),
                  child: profile.profileImage == null
                      ? Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(profile.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      if (profile.phone?.isNotEmpty ?? false)
                        Text(profile.phone!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF005DAC)),
                ),
              ],
            ),
    );
  }

  Widget _buildLotHeaderCard(lot, stats, List<ParkingLot> allSpaces) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_rounded, color: Color(0xFF005DAC), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lot.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF005DAC), size: 22),
                          tooltip: 'Edit Facility Details',
                          onPressed: () async {
                            final res = await Navigator.push<bool?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ManageParkingSpaceScreen(existingLot: lot),
                              ),
                            );
                            if (res == true) _loadProfile();
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lot.address,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Multiple Spaces Dropdown Selector (if provider has > 1 lot)
          if (allSpaces.length > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF005DAC)),
                  const SizedBox(width: 8),
                  const Text('Active Facility:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _dataService.selectedLotIndex < allSpaces.length ? _dataService.selectedLotIndex : 0,
                        isDense: true,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF005DAC)),
                        items: List.generate(allSpaces.length, (idx) {
                          return DropdownMenuItem(
                            value: idx,
                            child: Text(allSpaces[idx].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            _dataService.selectProviderLot(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statPill('Total Capacity', '${stats.totalSlotsCount} Slots', const Color(0xFF005DAC)),
              _statPill('Active Rate', '₹${lot.hourlyRate.toInt()}/hr', const Color(0xFF16A34A)),
              _statPill('Live Status', lot.isOpen ? 'OPEN 24/7' : 'CLOSED', lot.isOpen ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final res = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageParkingSpaceScreen()),
                );
                if (res == true) _loadProfile();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Another Parking Facility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF005DAC),
                side: const BorderSide(color: Color(0xFF005DAC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF005DAC), size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildToggleItem(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Switch(
            value: value,
            onChanged: _updatingAmenities ? null : onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF005DAC),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF005DAC), size: 20),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label settings is active.'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
