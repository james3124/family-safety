import 'package:family_safety_tracker/models/location_point.dart';

class Geofence {
  final String id;
  final String familyId;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool triggerOnEnter;
  final bool triggerOnExit;

  Geofence({
    required this.id, required this.familyId, required this.name,
    required this.lat, required this.lng, required this.radiusMeters,
    required this.triggerOnEnter, required this.triggerOnExit,
  });

  factory Geofence.fromMap(Map<String, dynamic> map, String id) {
    return Geofence(
      id: id,
      familyId: map['familyId'] as String,
      name: map['name'] as String,
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      radiusMeters: map['radius'] as double,
      triggerOnEnter: map['triggerOnEnter'] as bool,
      triggerOnExit: map['triggerOnExit'] as bool,
    );
  }

  bool containsPoint(LocationPoint point) {
    const earthRadius = 6371000;
    final dLat = _toRadians(point.lat - lat);
    final dLng = _toRadians(point.lng - lng);
    final a = _sinSquared(dLat / 2) +
        _cos(_toRadians(lat)) * _cos(_toRadians(point.lat)) * _sinSquared(dLng / 2);
    final c = 2 * _asin(_sqrt(a));
    final distance = earthRadius * c;
    return distance <= radiusMeters;
  }

  Map<String, dynamic> toMap() => {
    'familyId': familyId, 'name': name, 'lat': lat, 'lng': lng,
    'radius': radiusMeters, 'triggerOnEnter': triggerOnEnter,
    'triggerOnExit': triggerOnExit,
  };

  static double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  static double _sinSquared(double x) {
    final s = x.sin; return s * s;
  }
  static double _cos(double x) => x.cos;
  static double _asin(double x) => x.asin;
  static double _sqrt(double x) => x.sqrt;
}
