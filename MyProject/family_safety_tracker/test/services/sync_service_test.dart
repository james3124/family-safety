import 'package:flutter_test/flutter_test.dart';
import 'package:family_safety_tracker/services/sync_service.dart';

void main() {
  group('SyncService', () {
    test('has default uploadInterval of 15 seconds', () {
      expect(SyncService().uploadInterval, const Duration(seconds: 15));
    });
  });
}
