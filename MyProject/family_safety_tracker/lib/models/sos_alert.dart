import 'package:cloud_firestore/cloud_firestore.dart';

class SosAlert {
  final String id;
  final String memberId;
  final String familyId;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final bool resolved;

  SosAlert({
    required this.id, required this.memberId, required this.familyId,
    required this.lat, required this.lng,
    required this.timestamp, this.resolved = false,
  });

  factory SosAlert.fromMap(Map<String, dynamic> map, String id) => SosAlert(
    id: id,
    memberId: map['memberId'] as String,
    familyId: map['familyId'] as String,
    lat: (map['lat'] as num).toDouble(),
    lng: (map['lng'] as num).toDouble(),
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    resolved: map['resolved'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'memberId': memberId, 'familyId': familyId,
    'lat': lat, 'lng': lng,
    'timestamp': Timestamp.fromDate(timestamp),
    'resolved': resolved,
  };
}
