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
          final loading = _dataService.isProfileLoading && profile == null;

          return Scaffold(
            appBar: AppBar(
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('P', style: TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold, fontSize: 24)),
              ),
              title: const Text('Lot Settings', style: TextStyle(color: Color(0xFF005DAC), fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: profile == null || _savingProfile
                      ? null
                      : () async {
                          final res = await Navigator.push<bool?>(context, MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)));
                          if (res == true) _loadProfile();
                        },
                  tooltip: 'Edit account profile',
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAccountCard(profile),
                          const SizedBox(height: 20),
                          _buildLotHeaderCard(lot),
                          const SizedBox(height: 24),
                          _buildSectionHeader(Icons.info_outline, 'Lot Details'),
                          const SizedBox(height: 12),
                          _buildSettingsItem(Icons.directions_car_outlined, 'Total Slots', '120'),
                          _buildSettingsItem(Icons.payments_outlined, 'Base Rate', '₹40/hr'),
                          _buildSettingsItem(Icons.access_time, 'Operational Hours', '24/7', valueColor: const Color(0xFF005DAC), valueBg: const Color(0xFFDBEAFE)),
                          const SizedBox(height: 24),
                          _buildSectionHeader(Icons.layers_outlined, 'Amenities'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                _buildToggleItem(Icons.ev_station, 'EV Charging', true),
                                _buildToggleItem(Icons.videocam_outlined, 'CCTV', true),
                                _buildToggleItem(Icons.home_outlined, 'Covered Parking', false),
                                _buildToggleItem(Icons.shield_outlined, 'Security Guards', true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                _buildLinkItem(Icons.account_balance_wallet_outlined, 'Payouts'),
                                _buildLinkItem(Icons.badge_outlined, 'Staff Management'),
                                _buildLinkItem(Icons.description_outlined, 'Terms of Service'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_savingProfile) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
                          TextButton(
                            onPressed: () async {
                              await _dataService.logout();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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
                      ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(profile.email, style: const TextStyle(color: Color(0xFF64748B))),
                      if (profile.phone?.isNotEmpty ?? false) Text(profile.phone!, style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(onPressed: _savingProfile ? null : _editProfile, icon: const Icon(Icons.edit_outlined, color: Color(0xFF005DAC))),
              ],
            ),
    );
  }

  Widget _buildLotHeaderCard(lot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Color(0xFF005DAC), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lot.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(lot.address, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                      ],
                    ),
                  ],
                ),
              ),
                IconButton(onPressed: () async {
                  final profile = _dataService.profile;
                  if (profile == null) return;
                  final res = await Navigator.push<bool?>(context, MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)));
                  if (res == true) _loadProfile();
                }, icon: const Icon(Icons.edit_outlined, color: Color(0xFF005DAC))),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_city, size: 64, color: Color(0xFF005DAC)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active Lot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF005DAC), size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String label, String value, {Color? valueColor, Color? valueBg}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueBg ?? Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF005DAC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
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
      tileColor: Colors.white,
      leading: Icon(icon, color: const Color(0xFF005DAC), size: 20),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
      onTap: () {},
    );
  }
}
