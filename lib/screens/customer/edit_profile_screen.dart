import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/parking_data_service.dart';
import '../../services/profile_image_storage_service.dart';
import '../login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.initial});

  final UserProfile initial;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _dataService = ParkingDataService();
  final _imageStorage = ProfileImageStorageService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _selectedImage;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initial.name;
    _phoneCtrl.text = widget.initial.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _removeImage = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name with at least 2 characters.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final imageUrl = _selectedImage == null ? null : await _imageStorage.uploadProfileImage(_selectedImage!);
      await _dataService.updateProfile(
        name: name,
        phone: _phoneCtrl.text.trim(),
        profileImage: imageUrl,
        clearProfileImage: _removeImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save profile: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.initial;
    final imageUrl = profile.profileImage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFF005DAC),
                      backgroundImage: _selectedImage == null
                          ? (imageUrl == null ? null : NetworkImage(imageUrl) as ImageProvider)
                          : FileImage(File(_selectedImage!.path)),
                      child: (_selectedImage == null && imageUrl == null)
                          ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera, color: Color(0xFF005DAC)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name', filled: true, fillColor: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number', filled: true, fillColor: Colors.white),
              ),
              const SizedBox(height: 12),
              Text('Email is managed by Firebase: ${profile.email}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _removeImage = true);
                        await _save();
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005DAC), foregroundColor: Colors.white),
                child: const Text('Remove Photo'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await _dataService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  }
                },
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
