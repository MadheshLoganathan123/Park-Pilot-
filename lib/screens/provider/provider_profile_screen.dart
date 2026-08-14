import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/parking_data_service.dart';
import '../../services/profile_image_storage_service.dart';
import '../../widgets/profile_editor.dart';
import '../customer/edit_profile_screen.dart';
import '../login_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _dataService = ParkingDataService();
  final _imageStorage = ProfileImageStorageService();
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await _dataService.refreshProfile();
      await _dataService.loadProviderStats();
      await _dataService.loadLots();
    } catch (_) {}
  }

  Future<void> _editProfile() async {
    final profile = _dataService.profile;
    if (profile == null) return;
    final result = await showProfileEditor(context, profile);
    if (result == null) return;

    setState(() => _savingProfile = true);
    try {
      final imageUrl = result.image == null
          ? null
          : await _imageStorage.uploadProfileImage(result.image!);
      await _dataService.updateProfile(
        name: result.name,
        phone: result.phone,
        profileImage: imageUrl,
        clearProfileImage: result.removeImage,
        role: result.role,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your profile: ${_friendlyError(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final lot = _dataService.currentProviderLot;
          final profile = _dataService.profile;
          final stats = _dataService.providerStatsObj;
          final loading = _dataService.isProfileLoading && profile == null;

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
                  onPressed: profile == null || _savingProfile
                      ? null
                      : () async {
                          final res = await Navigator.push<bool?>(
                            context,
                            MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)),
                          );
                          if (res == true) _loadProfile();
                        },
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
                          _buildLotHeaderCard(lot, stats),
                          const SizedBox(height: 20),

                          _buildSectionHeader(Icons.layers_outlined, 'Facility Amenities'),
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
                                _buildToggleItem(Icons.ev_station, 'EV Fast Charging Bays', true),
                                _buildToggleItem(Icons.videocam_outlined, '24/7 CCTV & ANPR Cameras', true),
                                _buildToggleItem(Icons.roofing_rounded, 'Covered Basement Weather Protection', true),
                                _buildToggleItem(Icons.security_rounded, 'Security Guard Patrol', true),
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

                          if (_savingProfile)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),

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
                  onPressed: _savingProfile ? null : _editProfile,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF005DAC)),
                ),
              ],
            ),
    );
  }

  Widget _buildLotHeaderCard(lot, stats) {
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
                    Text(lot.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statPill('Total Capacity', '${stats.totalSlotsCount} Slots', const Color(0xFF005DAC)),
              _statPill('Active Rate', '₹${lot.hourlyRate.toInt()}/hr', const Color(0xFF16A34A)),
              _statPill('Live Status', 'OPEN 24/7', const Color(0xFFD97706)),
            ],
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

  Widget _buildToggleItem(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Switch(
            value: value,
            onChanged: (val) {},
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
