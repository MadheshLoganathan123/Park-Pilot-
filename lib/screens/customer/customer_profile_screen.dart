import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/parking_data_service.dart';
// profile image uploads handled in EditProfileScreen via ProfileImageStorageService
// Profile editor dialog remains available but this screen navigates to full-screen editor.
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_vehicles_screen.dart';
import 'payment_methods_screen.dart';
import '../settings_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _dataService = ParkingDataService();
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await _dataService.refreshProfile();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _errorMessage = null);
        });
      }
    } catch (_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _errorMessage = _dataService.profileError);
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final profile = _dataService.profile;
    if (profile == null) return;
    final result = await Navigator.of(context).push<bool?>(MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)));
    if (result != true) return;
    // refresh profile after successful edit
    await _loadProfile();
  }

  // friendly error helper removed; ApiExceptions are handled inline now.

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final profile = _dataService.profile;
          final loading = _dataService.isProfileLoading && profile == null;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  onPressed: profile == null || _saving ? null : _editProfile,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, profile),
          );
        },
      );

  Widget _buildBody(BuildContext context, UserProfile? profile) {
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'We could not load your profile.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _dataService.isProfileLoading ? null : _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final imageUrl = profile.profileImage;
    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P';
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF005DAC),
              backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
              child: imageUrl == null
                  ? Text(initial, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          Center(child: Text(profile.email, style: const TextStyle(color: Colors.grey))),
          if (profile.phone?.isNotEmpty ?? false)
            Center(child: Text(profile.phone!, style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 8),
          Center(child: Chip(label: Text(profile.role == 'PROVIDER' ? 'Parking Provider' : 'Customer'))),
          const SizedBox(height: 24),
          _profileItem(Icons.person_outline, 'Edit profile', _saving ? null : _editProfile),
          _profileItem(Icons.directions_car_outlined, 'My Vehicles', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVehiclesScreen()))),
          _profileItem(Icons.payment_outlined, 'Payment Methods', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
          _profileItem(Icons.settings_outlined, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const SizedBox(height: 28),
          if (_saving) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
          TextButton(
            onPressed: () async {
              await _dataService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, VoidCallback? onTap) => ListTile(
        tileColor: Colors.white,
        leading: Icon(icon, color: const Color(0xFF005DAC)),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
