import 'package:flutter/material.dart';
import '../models/parking_lot.dart';

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

  AppUserRole _currentRole = AppUserRole.customer;
  AppUserRole get currentRole => _currentRole;

  void toggleRole(AppUserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  // Provider Settings & Selected Lot
  int _selectedLotIndex = 0;
  int get selectedLotIndex => _selectedLotIndex;
  
  ParkingLot get currentProviderLot => _lots[_selectedLotIndex];

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

  final List<ParkingLot> _lots = [
    ParkingLot(
      id: 'lot_1',
      name: 'City Center Parking',
      address: 'Anna Nagar, Chennai',
      distance: '1.2 km',
      hourlyRate: 40.0,
      rating: 4.7,
      isPopular: true,
      type: 'Covered',
      hasEv: true,
      isOpen: true,
      amenities: ['CCTV', 'Security guards', 'Covered', 'EV Charging'],
      slots: [
        ParkingSlot(id: 'A-01', floor: 'Floor 1', status: SlotStatus.available),
        ParkingSlot(id: 'A-02', floor: 'Floor 1', status: SlotStatus.occupied),
        ParkingSlot(id: 'A-03', floor: 'Floor 1', status: SlotStatus.reserved),
        ParkingSlot(id: 'A-04', floor: 'Floor 1', status: SlotStatus.available),
        ParkingSlot(id: 'A-05', floor: 'Floor 1', status: SlotStatus.occupied),
        ParkingSlot(id: 'A-06', floor: 'Floor 1', status: SlotStatus.maintenance),
        ParkingSlot(id: 'A-07', floor: 'Floor 1', status: SlotStatus.available),
        ParkingSlot(id: 'A-08', floor: 'Floor 1', status: SlotStatus.available),
        ParkingSlot(id: 'B-01', floor: 'Floor 2', status: SlotStatus.occupied),
        ParkingSlot(id: 'B-02', floor: 'Floor 2', status: SlotStatus.occupied),
        ParkingSlot(id: 'B-03', floor: 'Floor 2', status: SlotStatus.available),
        ParkingSlot(id: 'B-04', floor: 'Floor 2', status: SlotStatus.available),
        ParkingSlot(id: 'B-05', floor: 'Floor 2', status: SlotStatus.reserved),
        ParkingSlot(id: 'B-06', floor: 'Floor 2', status: SlotStatus.available),
      ],
    ),
    ParkingLot(
      id: 'lot_2',
      name: 'Metro Station Lot B',
      address: 'Koyambedu, Chennai',
      distance: '2.5 km',
      hourlyRate: 30.0,
      rating: 4.2,
      isPopular: false,
      type: 'Open',
      hasEv: false,
      isOpen: true,
      amenities: ['Security guards', 'CCTV'],
      slots: List.generate(10, (i) => ParkingSlot(id: 'M-${i+1}', floor: 'Ground', status: i % 3 == 0 ? SlotStatus.occupied : SlotStatus.available)),
    ),
    ParkingLot(
      id: 'lot_3',
      name: 'Green Park Residence',
      address: 'T. Nagar, Chennai',
      distance: '2.0 km',
      hourlyRate: 30.0,
      rating: 4.5,
      isPopular: true,
      type: 'Covered',
      hasEv: true,
      isOpen: true,
      amenities: ['CCTV', 'Security guards', 'Covered'],
      slots: List.generate(15, (i) => ParkingSlot(id: 'G-${i+1}', floor: 'P1', status: i % 4 == 0 ? SlotStatus.occupied : SlotStatus.available)),
    ),
    ParkingLot(
      id: 'lot_4',
      name: 'Tech Park Parking',
      address: 'OMR, Chennai',
      distance: '2.8 km',
      hourlyRate: 50.0,
      rating: 4.2,
      isPopular: false,
      type: 'Multi-level',
      hasEv: true,
      isOpen: true,
      amenities: ['CCTV', 'Security guards', 'EV Charging', 'Covered'],
      slots: List.generate(20, (i) => ParkingSlot(id: 'T-${i+1}', floor: 'L1', status: i % 5 == 0 ? SlotStatus.occupied : SlotStatus.available)),
    ),
  ];

  List<ParkingLot> get lots => _lots;

  final List<Booking> _bookings = [
    Booking(
      bookingId: 'PP-2026-00125',
      lotName: 'City Center Parking',
      lotAddress: 'Anna Nagar, Chennai',
      slotId: 'A-12',
      date: DateTime(2026, 10, 24),
      timeRange: '14:00 - 18:00',
      totalAmount: 120.0,
      qrData: 'PP-2026-00125',
      status: 'Confirmed',
    ),
    Booking(
      bookingId: 'PP-2026-00126',
      lotName: 'City Center Parking',
      lotAddress: 'Anna Nagar, Chennai',
      slotId: 'A-12',
      date: DateTime(2026, 10, 24),
      timeRange: '14:00 - 16:00',
      totalAmount: 80.0,
      qrData: 'PP-2026-00126',
      status: 'Awaiting',
      customerName: 'Rajesh Kumar',
      carPlate: 'TN-01-AB-1234',
    ),
    Booking(
      bookingId: 'PP-2026-00127',
      lotName: 'City Center Parking',
      lotAddress: 'Anna Nagar, Chennai',
      slotId: 'B-04',
      date: DateTime(2026, 10, 24),
      timeRange: '14:30 - 18:00',
      totalAmount: 105.0,
      qrData: 'PP-2026-00127',
      status: 'Awaiting',
      customerName: 'Priya Sharma',
      carPlate: 'KA-05-MN-9876',
    ),
    Booking(
      bookingId: 'PP-2026-00128',
      lotName: 'City Center Parking',
      lotAddress: 'Anna Nagar, Chennai',
      slotId: 'A-02',
      date: DateTime(2026, 10, 24),
      timeRange: '15:00 - 17:00',
      totalAmount: 80.0,
      qrData: 'PP-2026-00128',
      status: 'Awaiting',
      customerName: 'Amit Patel',
      carPlate: 'MH-12-PQ-5566',
    ),
  ];

  List<Booking> get userBookings => _bookings.where((b) => b.customerName == null).toList();
  List<Booking> get providerBookings => _bookings.where((b) => b.customerName != null).toList();

  Booking? get activeBooking => _bookings.firstWhere(
        (b) => b.status == 'Confirmed' && b.customerName == null,
        orElse: () => _bookings.first,
      );

  void addBooking(Booking booking) {
    _bookings.insert(0, booking);
    // Mark slot occupied or reserved
    for (var lot in _lots) {
      if (lot.name == booking.lotName) {
        for (var slot in lot.slots) {
          if (slot.id == booking.slotId) {
            slot.status = SlotStatus.reserved;
          }
        }
      }
    }
    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      booking.status = 'Cancelled';
      for (var lot in _lots) {
        if (lot.name == booking.lotName) {
          for (var slot in lot.slots) {
            if (slot.id == booking.slotId) {
              slot.status = SlotStatus.available;
            }
          }
        }
      }
      notifyListeners();
    }
  }

  void updateSurge(bool enabled, double multiplier) {
    isSurgePricingEnabled = enabled;
    surgeMultiplier = multiplier;
    notifyListeners();
  }

  double calculateEffectiveRate(double baseRate) {
    return isSurgePricingEnabled ? (baseRate * surgeMultiplier) : baseRate;
  }

  double get todayRevenue => 4250.0;
  int get activeBookingsCount => 18;
  int get totalSlotsCount => 120;
  int get occupiedSlotsCount => 102;
  double get currentOccupancy => 85.0;
}
