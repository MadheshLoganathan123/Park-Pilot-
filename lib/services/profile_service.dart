import '../models/user_profile.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<UserProfile> sync({required String role}) async {
    final data = await _apiClient.post('/auth/sync', body: {'role': role});
    return UserProfile.fromJson((data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> getProfile() async {
    final data = await _apiClient.get('/profile');
    return UserProfile.fromJson((data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
    bool clearProfileImage = false,
    String? role,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) {
      final trimmedPhone = phone.trim();
      body['phone'] = trimmedPhone.isEmpty ? null : trimmedPhone;
    }
    if (clearProfileImage) {
      body['profileImage'] = null;
    } else if (profileImage != null) {
      body['profileImage'] = profileImage;
    }
    if (role != null) body['role'] = role;
    final data = await _apiClient.put('/profile', body: body);
    return UserProfile.fromJson((data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }
}
