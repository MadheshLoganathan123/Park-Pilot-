import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/parking_data_service.dart';
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
        setState(() => _errorMessage = null);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = _dataService.profileError);
      }
    }
  }

  Future<void> _editProfile() async {
    final profile = _dataService.profile;
    if (profile == null) return;
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)),
    );
    if (result == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final profile = _dataService.profile;
        final loading = _dataService.isProfileLoading && profile == null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'My Profile',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
            ),
            actions: [
              IconButton(
                onPressed: profile == null ? null : _editProfile,
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF005DAC)),
                tooltip: 'Edit profile',
              ),
            ],
          ),
          body: loading
              ? _buildLoadingSkeleton()
              : _buildBody(context, profile),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 180,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile? profile) {
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 14),
              Text(
                _errorMessage ?? 'Unable to connect to profile service.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF005DAC)),
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
    final name = profile.name.isNotEmpty ? profile.name : 'ParkPilot User';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFF005DAC),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header Card with Name-Hashed Gradient Avatar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(imageUrl),
                        )
                      : _buildNameGradientAvatar(name),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                if (profile.phone?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.phone!,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.role == 'PROVIDER' ? 'Parking Provider' : 'Customer Account',
                    style: const TextStyle(
                      color: Color(0xFF005DAC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _profileMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile Information',
                  subtitle: 'Update name, phone and picture',
                  onTap: _editProfile,
                ),
                const Divider(height: 1, indent: 60),
                _profileMenuItem(
                  icon: Icons.directions_car_outlined,
                  label: 'My Saved Vehicles',
                  subtitle: 'Manage license plates for fast booking',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyVehiclesScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 60),
                _profileMenuItem(
                  icon: Icons.payment_outlined,
                  label: 'Payment Methods',
                  subtitle: 'Cards, UPI and wallet options',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 60),
                _profileMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Preferences & Settings',
                  subtitle: 'Notifications and app config',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                'Log Out',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text('Sign out from this device', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFEF4444)),
              onTap: () async {
                await _dataService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // ParkPilot Brand Logo Footer
          Center(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.local_parking_rounded, color: Color(0xFF2563EB), size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ParkPilot v1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const Text(
                  'Smart Mobility & Slot Reservation System',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Unique implementation — Initials Avatar with Name-Hashed Gradient Background using CustomPainter
  Widget _buildNameGradientAvatar(String name) {
    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();
    return CustomPaint(
      size: const Size(92, 92),
      painter: _InitialsAvatarCustomPainter(
        name: name,
        initials: initials.isNotEmpty ? initials : 'P',
      ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF005DAC), size: 22),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}

/// CustomPainter for rendering initials on a deterministic name-hashed gradient circle.
class _InitialsAvatarCustomPainter extends CustomPainter {
  final String name;
  final String initials;

  _InitialsAvatarCustomPainter({
    required this.name,
    required this.initials,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Hash name to derive harmonious HSL gradient colors
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    final hue1 = (hash * 37) % 360;
    final hue2 = (hue1 + 45) % 360;

    final color1 = HSLColor.fromAHSL(1.0, hue1.toDouble(), 0.65, 0.45).toColor();
    final color2 = HSLColor.fromAHSL(1.0, hue2.toDouble(), 0.70, 0.55).toColor();

    // Shadow
    final shadowPaint = Paint()
      ..color = color1.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(0, 4), radius - 2, shadowPaint);

    // Gradient Background Circle
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = LinearGradient(
      colors: [color1, color2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // White Initials Text
    final textSpan = TextSpan(
      text: initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - (textPainter.height / 2),
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _InitialsAvatarCustomPainter oldDelegate) {
    return oldDelegate.name != name || oldDelegate.initials != initials;
  }
}
