import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageStorageService {
  ProfileImageStorageService({FirebaseStorage? storage, FirebaseAuth? auth})
      : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// Uploads to a UID-scoped Firebase Storage path and returns only its URL.
  /// The image bytes never go through the ParkPilot API or PostgreSQL.
  Future<String> uploadProfileImage(XFile image) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in again before updating your profile photo.');
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) throw StateError('The selected image is empty.');
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Choose an image smaller than 5 MB.');
    }

    final reference = _storage.ref('profile-images/${user.uid}/profile.jpg');
    await reference.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg', cacheControl: 'no-cache'),
    );
    return reference.getDownloadURL();
  }
}
