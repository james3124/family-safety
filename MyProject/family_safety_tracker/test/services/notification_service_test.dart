import 'package:flutter_test/flutter_test.dart';
import 'package:family_safety_tracker/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('initializes without error', () {
      final service = NotificationService();
      expect(service, isNotNull);
    });
  });
}
