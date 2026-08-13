import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_lot.dart';
import 'api_client.dart';

enum AppUserRole { customer, provider }

class RecentActivity {
  final String name;
  final String plate;
  final String time;
  final String action;
  final String initial;

  RecentActivity({
    required this.name,
    required this.plate,
    required this.time,
    required this.action,
    required this.initial,
  });
}

class ParkingDataService extends ChangeNotifier {
  static final ParkingDataService _instance = ParkingDataService._internal();
  factory ParkingDataService() => _instance;
  ParkingDataService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth instance unavailable: $e');
      return null;
    }
  }
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiClient _apiClient = ApiClient();
  
  SharedPreferences? _prefs;
  bool _isLoggedIn = false;
  String? _userId;
  String? _userEmail;
  AppUserRole _currentRole = AppUserRole.customer;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  AppUserRole get currentRole => _currentRole;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
    _userId = _prefs?.getString('userId');
    _userEmail = _prefs?.getString('userEmail');
    final roleString = _prefs?.getString('userRole');
    if (roleString != null) {
      _currentRole = roleString == 'provider' ? AppUserRole.provider : AppUserRole.customer;
    }
    
    if (_isLoggedIn) {
      loadLots();
      loadBookings();
    }
  }

  Future<void> login(String email, String password, AppUserRole role) async {
    try {
      final auth = _auth;
      if (auth != null) {
        final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
        await _saveSession(credential.user?.uid ?? 'user_123', email, role);
      } else {
        await _saveSession('user_123', email, role);
      }
      loadLots();
      loadBookings();
    } on FirebaseAuthException catch (e) {
      debugPrint('Login failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Login fallback error: $e');
      await _saveSession('user_123', email, role);
      loadLots();
      loadBookings();
    }
  }

  Future<void> createAccount(String email, String password, AppUserRole role) async {
    try {
      final auth = _auth;
      if (auth != null) {
        final credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
        await _saveSession(credential.user?.uid ?? 'user_123', email, role);
      } else {
        await _saveSession('user_123', email, role);
      }
      loadLots();
      loadBookings();
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Registration fallback error: $e');
      await _saveSession('user_123', email, role);
      loadLots();
      loadBookings();
    }
  }

  Future<void> signInWithGoogle(AppUserRole role) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth = _auth;
      if (auth != null) {
        final userCredential = await auth.signInWithCredential(credential);
        await _saveSession(userCredential.user?.uid, userCredential.user?.email, role);
      } else {
        await _saveSession('google_user_123', googleUser.email, role);
      }
      loadLots();
      loadBookings();
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> _saveSession(String? uid, String? email, AppUserRole role) async {
    _isLoggedIn = true;
    _userId = uid;
    _userEmail = email;
    _currentRole = role;
    
    await _prefs?.setBool('isLoggedIn', true);
    await _prefs?.setString('userId', uid ?? '');
    await _prefs?.setString('userEmail', email ?? '');
    await _prefs?.setString('userRole', role == AppUserRole.provider ? 'provider' : 'customer');
    
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _auth?.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    
    _isLoggedIn = false;
    _userId = null;
    _userEmail = null;
    
    await _prefs?.clear();
    notifyListeners();
  }

  void toggleRole(AppUserRole role) {
    _currentRole = role;
    _prefs?.setString('userRole', role == AppUserRole.provider ? 'provider' : 'customer');
    notifyListeners();
  }

  // Loading & Error State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Provider Settings & Selected Lot
  int _selectedLotIndex = 0;
  int get selectedLotIndex => _selectedLotIndex;
  
  ParkingLot get currentProviderLot => _lots.isNotEmpty
      ? (_selectedLotIndex < _lots.length ? _lots[_selectedLotIndex] : _lots.first)
      : _fallbackLots.first;

  void selectProviderLot(int index) {
    if (index >= 0 && index < _lots.length) {
      _selectedLotIndex = index;
      notifyListeners();
    }
  }

  bool isSurgePricingEnabled = false;
  double surgeMultiplier = 1.0;

  final List<RecentActivity> _recentActivities = [
    RecentActivity(name: 'Amit Jain', plate: 'DL 01 AB 1234', time: '10:45 AM', action: 'Check-in', initial: 'AJ'),
    RecentActivity(name: 'Sneha Kapoor', plate: 'MH 12 CD 5678', time: '10:30 AM', action: 'Check-in', initial: 'SK'),
    RecentActivity(name: 'Rahul Patel', plate: 'GJ 05 EF 9012', time: '10:15 AM', action: 'Check-in', initial: 'RP'),
  ];

  List<RecentActivity> get recentActivities => List.unmodifiable(_recentActivities);

  List<ParkingLot> _lots = [];
  List<ParkingLot> get lots => _lots.isNotEmpty ? _lots : _fallbackLots;

  List<Booking> _bookings = [];
  List<Booking> get userBookings => _bookings.isNotEmpty ? _bookings : _fallbackBookings;
  List<Booking> get providerBookings => _bookings.where((b) => b.customerName != null && b.customerName!.isNotEmpty && b.customerName != 'Madhesh Loganathan').toList();

  Booking? get activeBooking => _bookings.firstWhere(
        (b) => b.status == 'Confirmed',
        orElse: () => _bookings.isNotEmpty ? _bookings.first : _fallbackBookings.first,
      );

  Future<void> loadLots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.get('/parking');
      if (data is List) {
        _lots = data.map((item) => ParkingLot.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading lots from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookings() async {
    if (_userId == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.get('/bookings/customer/$_userId');
      if (data is List) {
        _bookings = data.map((item) => Booking.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading customer bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Booking?> createBookingApi({
    required String parkingSpaceId,
    required DateTime bookingDate,
    required DateTime startTime,
    required DateTime endTime,
    String paymentMethod = 'UPI',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'parkingSpaceId': parkingSpaceId,
        'bookingDate': bookingDate.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'paymentMethod': paymentMethod,
      };

      final data = await _apiClient.post('/bookings', body: payload);
      if (data is Map<String, dynamic>) {
        final bookingJson = data['booking'] != null ? data['booking'] as Map<String, dynamic> : data;
        final newBooking = Booking.fromJson(bookingJson);
        _bookings.insert(0, newBooking);
        await loadLots();
        return newBooking;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating booking on API: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> cancelBookingApi(String bookingId) async {
    try {
      final data = await _apiClient.put('/bookings/$bookingId/cancel');
      if (data != null) {
        final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
        if (index != -1) {
          _bookings[index].status = 'Cancelled';
        }
        await loadLots();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
    }
    return false;
  }

  Future<bool> checkInBookingApi(String bookingId) async {
    try {
      final data = await _apiClient.put('/bookings/$bookingId/check-in');
      if (data != null) {
        final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
        if (index != -1) {
          _bookings[index].status = 'CheckedIn';
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error checking in booking on API: $e');
      // Fallback local update so UI demo works seamlessly even without backend running
      final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        _bookings[index].status = 'CheckedIn';
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> verifyQrApi(String qrCode) async {
    try {
      final data = await _apiClient.post('/bookings/verify-qr', body: {'qrCode': qrCode});
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      debugPrint('Error verifying QR on API: $e');
    }
    return null;
  }

  void addBooking(Booking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    cancelBookingApi(bookingId);
  }


  void updateSurge(bool enabled, double multiplier) {
    isSurgePricingEnabled = enabled;
    surgeMultiplier = multiplier;
    notifyListeners();
  }

  double calculateEffectiveRate(double baseRate) {
    return isSurgePricingEnabled ? (baseRate * surgeMultiplier) : baseRate;
  }

  Map<String, dynamic>? _providerStats;
  Map<String, dynamic>? get providerStats => _providerStats;

  Future<void> loadProviderStats() async {
    try {
      final pid = _userId ?? 'provider_123';
      final data = await _apiClient.get('/providers/$pid/revenue');
      if (data is Map<String, dynamic>) {
        _providerStats = data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading provider stats from API: $e');
    }
  }

  void updateSlotStatus(String slotId, SlotStatus status) {
    for (var lot in lots) {
      final idx = lot.slots.indexWhere((s) => s.id == slotId);
      if (idx != -1) {
        lot.slots[idx] = ParkingSlot(
          id: slotId,
          floor: lot.slots[idx].floor,
          status: status,
        );
        break;
      }
    }
    notifyListeners();
  }

  double get todayRevenue => (_providerStats?['totalRevenue'] as num?)?.toDouble() ?? 4250.0;
  int get activeBookingsCount => (_providerStats?['activeBookingsCount'] as num?)?.toInt() ?? userBookings.where((b) => b.status == 'Confirmed' || b.status == 'CheckedIn').length;
  int get totalSlotsCount => (_providerStats?['totalSlotsCapacity'] as num?)?.toInt() ?? lots.fold(0, (sum, lot) => sum + lot.totalSlotsCount);
  int get occupiedSlotsCount => (_providerStats?['currentlyOccupiedSlots'] as num?)?.toInt() ?? lots.fold(0, (sum, lot) => sum + (lot.totalSlotsCount - lot.availableSlotsCount));
  double get currentOccupancy => (_providerStats?['occupancyRatePercentage'] as num?)?.toDouble() ?? (totalSlotsCount > 0 ? (occupiedSlotsCount / totalSlotsCount) * 100 : 85.0);

  static final List<ParkingLot> _fallbackLots = [
    ParkingLot(
      id: 'lot_1',
      name: 'Express Avenue Mall Parking',
      address: 'Royapettah, Chennai',
      distance: '1.2 km',
      hourlyRate: 50.0,
      rating: 4.7,
      isPopular: true,
      type: 'Multi-level',
      hasEv: true,
      isOpen: true,
      amenities: ['CCTV', 'Security guards', 'Covered', 'EV Charging'],
      slots: List.generate(10, (i) => ParkingSlot(id: 'A-${i+1}', floor: 'Floor 1', status: i % 3 == 0 ? SlotStatus.occupied : SlotStatus.available)),
    ),
  ];

  static final List<Booking> _fallbackBookings = [
    Booking(
      bookingId: 'PP-2026-00125',
      lotName: 'Express Avenue Mall Parking',
      lotAddress: 'Royapettah, Chennai',
      slotId: 'S-40',
      date: DateTime.now(),
      timeRange: '14:00 - 16:00',
      totalAmount: 100.0,
      qrData: 'PARKPILOT-9470915D',
      status: 'Confirmed',
    ),
  ];
}

