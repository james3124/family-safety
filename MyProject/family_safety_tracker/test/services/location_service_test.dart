import 'package:flutter_test/flutter_test.dart';
import 'package:family_safety_tracker/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('initially not tracking', () {
      final service = LocationService();
      expect(service.isTracking, false);
    });
  });
}
