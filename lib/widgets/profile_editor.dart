import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/parking_data_service.dart';

class ProfileEditorResult {
  const ProfileEditorResult({
    required this.name,
    required this.phone,
    required this.role,
    this.image,
    this.removeImage = false,
  });

  final String name;
  final String phone;
  final AppUserRole role;
  final XFile? image;
  final bool removeImage;
}

Future<ProfileEditorResult?> showProfileEditor(BuildContext context, UserProfile profile) {
  final nameController = TextEditingController(text: profile.name);
  final phoneController = TextEditingController(text: profile.phone ?? '');
  final picker = ImagePicker();
  AppUserRole role = profile.role == 'PROVIDER' ? AppUserRole.provider : AppUserRole.customer;
  XFile? selectedImage;
  bool removeImage = false;

  return showDialog<ProfileEditorResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              DropdownButtonFormField<AppUserRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: AppUserRole.customer, child: Text('Customer')),
                  DropdownMenuItem(value: AppUserRole.provider, child: Text('Parking Provider')),
                ],
                onChanged: (value) => setDialogState(() => role = value ?? role),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setDialogState(() {
                          selectedImage = image;
                          removeImage = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(selectedImage == null ? 'Choose photo' : 'Photo selected'),
                  ),
                  if (profile.profileImage != null || selectedImage != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setDialogState(() {
                        selectedImage = null;
                        removeImage = true;
                      }),
                      child: const Text('Remove photo'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Email is managed by your Firebase account: ${profile.email}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a name with at least 2 characters.')),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                ProfileEditorResult(
                  name: name,
                  phone: phoneController.text.trim(),
                  role: role,
                  image: selectedImage,
                  removeImage: removeImage,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    nameController.dispose();
    phoneController.dispose();
  });
}
