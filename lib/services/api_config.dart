import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URLs for different target environments
  static const String androidEmulatorUrl = 'http://10.0.2.2:5000/api';
  static const String localhostUrl = 'http://localhost:5000/api';

  /// Dynamically resolves the base URL based on platform.
  static String get baseUrl {
    if (kIsWeb) {
      return localhostUrl;
    }
    if (Platform.isAndroid) {
      return androidEmulatorUrl;
    }
    return localhostUrl;
  }
}
