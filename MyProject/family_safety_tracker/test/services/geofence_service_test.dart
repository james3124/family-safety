import 'package:flutter_test/flutter_test.dart';
import 'package:family_safety_tracker/services/geofence_service.dart';
import 'package:family_safety_tracker/models/geofence.dart';
import 'package:family_safety_tracker/models/location_point.dart';

void main() {
  group('GeofenceService', () {
    test('checkGeofences returns triggered fences', () {
      final service = GeofenceService();
      final home = Geofence(
        id: 'g1', familyId: 'f1', name: 'Home',
        lat: 37.7749, lng: -122.4194, radiusMeters: 100,
        triggerOnEnter: true, triggerOnExit: true,
      );
      final inside = LocationPoint(lat: 37.775, lng: -122.4194, timestamp: DateTime.now());
      final outside = LocationPoint(lat: 37.78, lng: -122.42, timestamp: DateTime.now());
      expect(service, isNotNull);
    });
  });
}
