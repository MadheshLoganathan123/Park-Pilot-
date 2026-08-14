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
  String? vehiclePlate;
  String? checkInTime;
  String? customerName;

  ParkingSlot({
    required this.id,
    required this.floor,
    this.status = SlotStatus.available,
    this.isEv = false,
    this.isHandicapped = false,
    this.vehiclePlate,
    this.checkInTime,
    this.customerName,
  });

  bool get isOccupied => status == SlotStatus.occupied;

  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    SlotStatus parseStatus(String? statusStr) {
      switch (statusStr?.toUpperCase()) {
        case 'OCCUPIED': return SlotStatus.occupied;
        case 'RESERVED': return SlotStatus.reserved;
        case 'MAINTENANCE': return SlotStatus.maintenance;
        default: return SlotStatus.available;
      }
    }

    return ParkingSlot(
      id: json['id']?.toString() ?? 'A-01',
      floor: json['floor']?.toString() ?? 'Floor 1',
      status: parseStatus(json['status']?.toString()),
      isEv: json['isEv'] == true,
      isHandicapped: json['isHandicapped'] == true,
      vehiclePlate: json['vehiclePlate']?.toString(),
      checkInTime: json['checkInTime']?.toString(),
      customerName: json['customerName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'floor': floor,
    'status': status.name.toUpperCase(),
    'isEv': isEv,
    'isHandicapped': isHandicapped,
    'vehiclePlate': vehiclePlate,
    'checkInTime': checkInTime,
    'customerName': customerName,
  };
}

class WeeklyRevenueData {
  final String day;
  final String date;
  final double revenue;

  WeeklyRevenueData({
    required this.day,
    required this.date,
    required this.revenue,
  });

  factory WeeklyRevenueData.fromJson(Map<String, dynamic> json) {
    return WeeklyRevenueData(
      day: json['day']?.toString() ?? 'Mon',
      date: json['date']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProviderStats {
  final double todayRevenue;
  final double totalRevenue;
  final int activeBookingsCount;
  final int totalSlotsCount;
  final int occupiedSlotsCount;
  final int availableSlotsCount;
  final double occupancyRate;
  final List<WeeklyRevenueData> weeklyRevenue;

  ProviderStats({
    this.todayRevenue = 0.0,
    this.totalRevenue = 0.0,
    this.activeBookingsCount = 0,
    this.totalSlotsCount = 0,
    this.occupiedSlotsCount = 0,
    this.availableSlotsCount = 0,
    this.occupancyRate = 0.0,
    this.weeklyRevenue = const [],
  });

  factory ProviderStats.fromJson(Map<String, dynamic> json) {
    final weeklyList = (json['weeklyRevenue'] as List?)
            ?.map((w) => WeeklyRevenueData.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [];

    return ProviderStats(
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeBookingsCount: (json['activeBookingsCount'] as num?)?.toInt() ?? 0,
      totalSlotsCount: (json['totalSlotsCount'] as num?)?.toInt() ?? (json['totalSlotsCapacity'] as num?)?.toInt() ?? 0,
      occupiedSlotsCount: (json['occupiedSlotsCount'] as num?)?.toInt() ?? (json['currentlyOccupiedSlots'] as num?)?.toInt() ?? 0,
      availableSlotsCount: (json['availableSlotsCount'] as num?)?.toInt() ?? (json['currentlyAvailableSlots'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? (json['occupancyRatePercentage'] as num?)?.toDouble() ?? 0.0,
      weeklyRevenue: weeklyList,
    );
  }
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

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    final totalSlots = (json['totalSlots'] as num?)?.toInt() ?? 10;
    final availableSlots = (json['availableSlots'] as num?)?.toInt() ?? totalSlots;

    List<ParkingSlot> parsedSlots = [];
    if (json['slots'] is List && (json['slots'] as List).isNotEmpty) {
      parsedSlots = (json['slots'] as List).map((s) => ParkingSlot.fromJson(s as Map<String, dynamic>)).toList();
    } else {
      final platePrefixes = ['TN 01', 'TN 02', 'TN 07', 'TN 09', 'TN 10', 'TN 14', 'TN 22'];
      final customerNames = ['Rahul Sharma', 'Priya Mani', 'Arun Kumar', 'Deepa S', 'Karthik Raja', 'Ananya R'];
      parsedSlots = List.generate(totalSlots, (index) {
        final floorNum = (index ~/ 10) + 1;
        final slotLetter = String.fromCharCode(65 + (index ~/ 20));
        final slotNum = (index % 20) + 1;
        final isAvail = index < availableSlots;
        final status = isAvail ? SlotStatus.available : SlotStatus.occupied;
        final plate = isAvail ? null : '${platePrefixes[index % platePrefixes.length]} ${String.fromCharCode(65 + (index % 26))}${String.fromCharCode(65 + ((index * 3) % 26))} ${(1000 + (index * 137) % 8999)}';
        final checkIn = isAvail ? null : '${(8 + (index % 5)).toString().padLeft(2, '0')}:${((index * 15) % 60).toString().padLeft(2, '0')} AM';
        final cust = isAvail ? null : customerNames[index % customerNames.length];

        return ParkingSlot(
          id: '$slotLetter-${slotNum.toString().padLeft(2, '0')}',
          floor: 'Floor $floorNum',
          status: status,
          isEv: index % 5 == 0,
          vehiclePlate: plate,
          checkInTime: checkIn,
          customerName: cust,
        );
      });
    }

    String formatType(String? typeStr) {
      switch (typeStr?.toUpperCase()) {
        case 'MULTI_LEVEL': return 'Multi-level';
        case 'COVERED': return 'Covered';
        case 'OPEN': return 'Open';
        case 'VALET': return 'Valet';
        default: return typeStr ?? 'Covered';
      }
    }

    final rawDistance = json['distanceKm'] != null 
        ? '${(json['distanceKm'] as num).toStringAsFixed(1)} km'
        : (json['distance']?.toString() ?? '1.2 km');

    return ParkingLot(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Parking Space',
      address: json['address']?.toString() ?? '',
      distance: rawDistance,
      hourlyRate: (json['pricePerHour'] as num?)?.toDouble() ?? 40.0,
      rating: 4.6,
      isPopular: availableSlots < 30,
      type: formatType(json['parkingType']?.toString()),
      hasEv: true,
      slots: parsedSlots,
      isOpen: json['status'] == 'ACTIVE' || json['status'] == null,
      amenities: const ['CCTV', 'Security guards', 'Covered', 'EV Charging'],
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'distance': distance,
    'hourlyRate': hourlyRate,
    'rating': rating,
    'isPopular': isPopular,
    'type': type,
    'hasEv': hasEv,
    'slots': slots.map((s) => s.toJson()).toList(),
    'isOpen': isOpen,
    'amenities': amenities,
    'imageUrl': imageUrl,
  };
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
  final int durationHours;

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

  factory Booking.fromJson(Map<String, dynamic> json) {
    String parseStatus(String? statusStr) {
      switch (statusStr?.toUpperCase()) {
        case 'CONFIRMED': return 'Confirmed';
        case 'CHECKED_IN': return 'CheckedIn';
        case 'COMPLETED': return 'Completed';
        case 'CANCELLED': return 'Cancelled';
        default: return statusStr ?? 'Confirmed';
      }
    }

    final parkingSpace = json['parkingSpace'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;

    final bookingDate = DateTime.tryParse(json['bookingDate']?.toString() ?? '') ?? DateTime.now();
    final startTimeStr = json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) : null;
    final endTimeStr = json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null;

    String formattedTimeRange = '14:00 - 16:00';
    if (startTimeStr != null && endTimeStr != null) {
      final startH = startTimeStr.hour.toString().padLeft(2, '0');
      final startM = startTimeStr.minute.toString().padLeft(2, '0');
      final endH = endTimeStr.hour.toString().padLeft(2, '0');
      final endM = endTimeStr.minute.toString().padLeft(2, '0');
      formattedTimeRange = '$startH:$startM - $endH:$endM';
    }

    return Booking(
      bookingId: json['id']?.toString() ?? json['qrCode']?.toString() ?? '',
      lotName: parkingSpace?['name']?.toString() ?? json['lotName']?.toString() ?? 'Parking Lot',
      lotAddress: parkingSpace?['address']?.toString() ?? json['lotAddress']?.toString() ?? '',
      slotId: json['slotNumber']?.toString() ?? json['slotId']?.toString() ?? 'A-01',
      date: bookingDate,
      timeRange: formattedTimeRange,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      qrData: json['qrCode']?.toString() ?? json['id']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      customerName: customer?['name']?.toString() ?? json['customerName']?.toString(),
      carPlate: json['carPlate']?.toString() ?? 'TN-01-AB-1234',
      durationHours: (json['duration'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': bookingId,
    'lotName': lotName,
    'lotAddress': lotAddress,
    'slotNumber': slotId,
    'bookingDate': date.toIso8601String(),
    'timeRange': timeRange,
    'totalAmount': totalAmount,
    'qrCode': qrData,
    'status': status.toUpperCase(),
    'customerName': customerName,
    'carPlate': carPlate,
    'duration': durationHours,
  };
}
