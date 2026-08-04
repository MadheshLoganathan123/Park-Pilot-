enum SlotStatus {
  available,
  occupied,
  reserved,
  maintenance
}

class ParkingSlot {
  final String id;
  final String floor;
  SlotStatus status;
  bool isEv;
  bool isHandicapped;

  ParkingSlot({
    required this.id,
    required this.floor,
    this.status = SlotStatus.available,
    this.isEv = false,
    this.isHandicapped = false,
  });

  bool get isOccupied => status == SlotStatus.occupied;
}

class ParkingLot {
  final String id;
  final String name;
  final String address;
  final String distance;
  double hourlyRate;
  final double rating;
  final bool isPopular;
  final String type;
  final bool hasEv;
  final List<ParkingSlot> slots;
  bool isOpen;
  final List<String> amenities;
  final String? imageUrl;

  ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.hourlyRate,
    required this.rating,
    this.isPopular = false,
    required this.type,
    this.hasEv = true,
    required this.slots,
    this.isOpen = true,
    this.amenities = const [],
    this.imageUrl,
  });

  int get availableSlotsCount => slots.where((s) => s.status == SlotStatus.available).length;
  int get totalSlotsCount => slots.length;
  double get occupancyPercentage => totalSlotsCount > 0 
      ? ((totalSlotsCount - availableSlotsCount) / totalSlotsCount) * 100 
      : 0.0;
}

class Booking {
  final String bookingId;
  final String lotName;
  final String lotAddress;
  final String slotId;
  final DateTime date;
  final String timeRange;
  final double totalAmount;
  final String qrData;
  String status; // 'Confirmed', 'CheckedIn', 'Completed', 'Cancelled'
  final String? customerName;
  final String? carPlate;
  final int durationHours; // Added back for compatibility

  Booking({
    required this.bookingId,
    required this.lotName,
    required this.lotAddress,
    required this.slotId,
    required this.date,
    required this.timeRange,
    required this.totalAmount,
    required this.qrData,
    this.status = 'Confirmed',
    this.customerName,
    this.carPlate,
    this.durationHours = 2,
  });
}
