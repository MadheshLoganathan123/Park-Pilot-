import 'package:flutter/material.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF005DAC),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('M', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Madhesh', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('madhesh@example.com', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildProfileItem(Icons.person_outline, 'My Account'),
            _buildProfileItem(Icons.directions_car_outlined, 'My Vehicles'),
            _buildProfileItem(Icons.payment_outlined, 'Payment Methods'),
            _buildProfileItem(Icons.settings_outlined, 'Settings'),
            _buildProfileItem(Icons.help_outline, 'Help & Support'),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {},
              child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(icon, color: const Color(0xFF005DAC)),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
