import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:geolocator/geolocator.dart';

class RoutingResult {
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final double durationMinutes;
  final String summary;

  RoutingResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.summary,
  });
}

class OsmMapService {
  static final OsmMapService _instance = OsmMapService._internal();
  factory OsmMapService() => _instance;
  OsmMapService._internal();

  /// Default user location (e.g. Chennai Central / T. Nagar)
  static const LatLng defaultUserLocation = LatLng(13.0827, 80.2707);

  /// Determine user's real GPS position or gracefully fallback to default
  Future<LatLng> determineCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return defaultUserLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return defaultUserLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return defaultUserLocation;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Geolocator location retrieval fallback: $e');
      return defaultUserLocation;
    }
  }

  /// OpenStreetMap standard tile URL template
  static const String tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// High-contrast / Modern CartoDB Positron style tile URL (great for sleek UI)
  static const String cartoPositronTileUrl = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Calculate real turn-by-turn driving route via OSRM (Open Source Routing Machine) - Free, no API key
  Future<RoutingResult?> getDrivingRoute(LatLng start, LatLng destination) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final points = coordinates.map<LatLng>((coord) {
            return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
          }).toList();

          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;

          return RoutingResult(
            polylinePoints: points,
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: durationSeconds / 60.0,
            summary: route['legs'] != null && (route['legs'] as List).isNotEmpty
                ? (route['legs'][0]['summary']?.toString() ?? 'Fastest Route')
                : 'Fastest Route',
          );
        }
      }
    } catch (e) {
      debugPrint('OSRM routing fallback: $e');
    }

    // Direct line fallback if network/OSRM is slow
    return RoutingResult(
      polylinePoints: [start, destination],
      distanceKm: const Distance().as(LengthUnit.Kilometer, start, destination),
      durationMinutes: const Distance().as(LengthUnit.Kilometer, start, destination) * 2.5,
      summary: 'Direct Route',
    );
  }
}
