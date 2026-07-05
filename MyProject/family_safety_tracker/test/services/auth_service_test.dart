import 'package:flutter_test/flutter_test.dart';
import 'package:family_safety_tracker/services/auth_service.dart';
import 'package:family_safety_tracker/services/family_service.dart';

void main() {
  group('AuthService', () {
    test('should be a singleton', () {
      final a = AuthService();
      final b = AuthService();
      expect(a, same(b));
    });
  });

  group('FamilyService', () {
    test('constructor accepts Firestore instance', () {
      // will verify with mock after implementation
    });
  });
}
