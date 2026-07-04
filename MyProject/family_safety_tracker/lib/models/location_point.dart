import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPoint {
  final double lat;
  final double lng;
  final double accuracy;
  final DateTime timestamp;
  final double speed;

  LocationPoint({
    required this.lat, required this.lng,
    this.accuracy = 0, required this.timestamp, this.speed = 0,
  });

  factory LocationPoint.fromMap(Map<String, dynamic> map) => LocationPoint(
    lat: (map['lat'] as num).toDouble(),
    lng: (map['lng'] as num).toDouble(),
    accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    speed: (map['speed'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'lat': lat, 'lng': lng, 'accuracy': accuracy,
    'timestamp': Timestamp.fromDate(timestamp), 'speed': speed,
  };
}
