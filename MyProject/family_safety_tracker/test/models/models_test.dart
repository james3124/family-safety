import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_safety_tracker/models/family.dart';
import 'package:family_safety_tracker/models/family_member.dart';
import 'package:family_safety_tracker/models/location_point.dart';
import 'package:family_safety_tracker/models/geofence.dart';
import 'package:family_safety_tracker/models/sos_alert.dart';

void main() {
  group('Family', () {
    test('fromMap and toMap roundtrip', () {
      final map = {
        'id': 'fam1',
        'name': 'Smith Family',
        'createdAt': Timestamp.now(),
      };
      final family = Family.fromMap(map, 'fam1');
      final result = family.toMap();
      expect(result['name'], 'Smith Family');
      expect(family.id, 'fam1');
    });
  });

  group('FamilyMember', () {
    test('fromMap and toMap roundtrip', () {
      final map = {
        'phone': '+1234567890',
        'name': 'John',
        'role': 'parent',
        'consented': true,
        'batteryLevel': 85,
        'lastSeen': Timestamp.now(),
        'familyId': 'fam1',
      };
      final member = FamilyMember.fromMap(map, 'member1');
      expect(member.phone, '+1234567890');
      expect(member.role, FamilyRole.parent);
      expect(member.consented, true);
    });

    test('isLowBattery returns true when battery <= 20%', () {
      final member = FamilyMember(
        id: 'm1', phone: '+1', name: 'Test', role: FamilyRole.child,
        consented: true, batteryLevel: 15, lastSeen: DateTime.now(), familyId: 'f1',
      );
      expect(member.isLowBattery, true);
    });
  });

  group('LocationPoint', () {
    test('fromMap and toMap roundtrip', () {
      final map = {
        'lat': 37.7749,
        'lng': -122.4194,
        'accuracy': 10.0,
        'timestamp': Timestamp.now(),
        'speed': 0.0,
      };
      final point = LocationPoint.fromMap(map);
      expect(point.lat, 37.7749);
      expect(point.lng, -122.4194);
    });
  });

  group('Geofence', () {
    test('containsPoint returns true when point is within radius', () {
      final fence = Geofence(
        id: 'g1', familyId: 'f1', name: 'Home',
        lat: 37.7749, lng: -122.4194, radiusMeters: 100,
        triggerOnEnter: true, triggerOnExit: true,
      );
      final nearby = LocationPoint(lat: 37.775, lng: -122.4194, timestamp: DateTime.now());
      final far = LocationPoint(lat: 37.78, lng: -122.42, timestamp: DateTime.now());
      expect(fence.containsPoint(nearby), true);
      expect(fence.containsPoint(far), false);
    });
  });

  group('SosAlert', () {
    test('fromMap and toMap roundtrip', () {
      final map = {
        'memberId': 'm1',
        'familyId': 'f1',
        'lat': 37.7749,
        'lng': -122.4194,
        'timestamp': Timestamp.now(),
        'resolved': false,
      };
      final alert = SosAlert.fromMap(map, 'alert1');
      expect(alert.memberId, 'm1');
      expect(alert.resolved, false);
    });
  });
}
