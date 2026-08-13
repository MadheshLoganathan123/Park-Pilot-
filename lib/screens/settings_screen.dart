import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(leading: const Icon(Icons.notifications_outlined, color: Color(0xFF005DAC)), title: const Text('Notifications'), onTap: () {}),
            ListTile(leading: const Icon(Icons.lock_outline, color: Color(0xFF005DAC)), title: const Text('Privacy'), onTap: () {}),
            ListTile(leading: const Icon(Icons.help_outline, color: Color(0xFF005DAC)), title: const Text('Help & Support'), onTap: () {}),
          ],
        ),
      ),
    );
  }
}
