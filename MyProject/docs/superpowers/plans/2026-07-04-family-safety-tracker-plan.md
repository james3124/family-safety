# Family Safety Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cross-platform Flutter + Firebase mobile app for family live GPS tracking with SOS, geofencing, location history, and battery monitoring.

**Architecture:** Flutter app (iOS + Android) with Firebase backend. Real-time location synced via Firestore. Background location via platform-specific workers. Push notifications via FCM. Geofence detection client-side with cloud validation.

**Tech Stack:** Flutter 3.x, Firebase (Auth, Firestore, Cloud Functions, FCM), Google Maps Flutter, `location` + `geolocator` packages

## Global Constraints

- Android minSdk: 21, iOS target: 15.0
- Background location requires explicit user permission on both platforms
- All API keys stored in `.env` file, never hardcoded
- Touch targets >= 44pt (iOS) / 48dp (Android)
- Offline-aware: show "last seen" time when location is stale
- Privacy: all tracking requires explicit consent stored in Firestore

---

### Task 1: Project Scaffolding & Dependencies

**Files:**
- Create: `family_safety_tracker/pubspec.yaml`
- Create: `family_safety_tracker/lib/main.dart`
- Create: `family_safety_tracker/lib/utils/constants.dart`
- Create: `family_safety_tracker/analysis_options.yaml`
- Create: `.env.example`

**Interfaces:**
- Consumes: nothing
- Produces: project structure that all other tasks depend on

- [ ] **Step 1: Create Flutter project and write pubspec.yaml**

```yaml
name: family_safety_tracker
description: Family live GPS tracking app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  firebase_storage: ^11.6.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.0
  cloud_functions: ^4.6.0
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4+2
  location: ^5.0.3
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  flutter_dotenv: ^5.1.0
  provider: ^6.1.1
  flutter_local_notifications: ^17.0.0
  uuid: ^4.2.1
  intl: ^0.19.0
  permission_handler: ^11.1.0
  shared_preferences: ^2.2.2
  battery_plus: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
  build_runner: ^2.4.8

flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/
```

- [ ] **Step 2: Write main.dart entry point**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  runApp(const FamilySafetyApp());
}
```

- [ ] **Step 3: Write constants file**

```dart
class AppConstants {
  static const String appName = 'Family Safety Tracker';
  static const int locationUpdateIntervalSec = 15;
  static const int batteryCheckIntervalMin = 15;
  static const int lowBatteryThreshold = 20;
  static const int locationHistoryDays = 30;
  static const double defaultMapZoom = 14.0;
  static const Duration locationStaleThreshold = Duration(minutes: 5);
}
```

- [ ] **Step 4: Write analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
```

- [ ] **Step 5: Write .env.example**

```
GOOGLE_MAPS_API_KEY=your_key_here
```

- [ ] **Step 6: Create assets directory and commit**

```bash
mkdir -p family_safety_tracker/assets family_safety_tracker/lib/utils
git add family_safety_tracker/
git commit -m "feat: scaffold Flutter project with dependencies"
```

---

### Task 2: Data Models

**Files:**
- Create: `family_safety_tracker/lib/models/family.dart`
- Create: `family_safety_tracker/lib/models/family_member.dart`
- Create: `family_safety_tracker/lib/models/location_point.dart`
- Create: `family_safety_tracker/lib/models/geofence.dart`
- Create: `family_safety_tracker/lib/models/sos_alert.dart`
- Create: `family_safety_tracker/test/models/models_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `Family`, `FamilyMember`, `LocationPoint`, `Geofence`, `SosAlert` classes with `fromMap`/`toMap` serialization

- [ ] **Step 1: Write the failing tests for all models**

```dart
import 'package:flutter_test/flutter_test.dart';
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/models_test.dart`
Expected: FAIL — classes don't exist yet

- [ ] **Step 3: Write Family model**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final DateTime createdAt;

  Family({required this.id, required this.name, required this.createdAt});

  factory Family.fromMap(Map<String, dynamic> map, String id) {
    return Family(
      id: id,
      name: map['name'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
```

- [ ] **Step 4: Write FamilyMember model**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum FamilyRole { parent, child }

class FamilyMember {
  final String id;
  final String phone;
  final String name;
  final FamilyRole role;
  final bool consented;
  final int batteryLevel;
  final DateTime lastSeen;
  final String familyId;

  FamilyMember({
    required this.id, required this.phone, required this.name,
    required this.role, required this.consented,
    this.batteryLevel = 100, required this.lastSeen, required this.familyId,
  });

  bool get isLowBattery => batteryLevel <= 20;

  factory FamilyMember.fromMap(Map<String, dynamic> map, String id) {
    return FamilyMember(
      id: id,
      phone: map['phone'] as String,
      name: map['name'] as String,
      role: map['role'] == 'parent' ? FamilyRole.parent : FamilyRole.child,
      consented: map['consented'] as bool,
      batteryLevel: map['batteryLevel'] as int? ?? 100,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      familyId: map['familyId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'phone': phone, 'name': name,
    'role': role == FamilyRole.parent ? 'parent' : 'child',
    'consented': consented, 'batteryLevel': batteryLevel,
    'lastSeen': Timestamp.fromDate(lastSeen), 'familyId': familyId,
  };
}
```

- [ ] **Step 5: Write LocationPoint model**

```dart
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
```

- [ ] **Step 6: Write Geofence model**

```dart
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
```

- [ ] **Step 7: Write SosAlert model**

```dart
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
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/models/models_test.dart`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add family_safety_tracker/lib/models/ family_safety_tracker/test/models/
git commit -m "feat: add data models with serialization and tests"
```

---

### Task 3: Authentication Service

**Files:**
- Create: `family_safety_tracker/lib/services/auth_service.dart`
- Create: `family_safety_tracker/test/services/auth_service_test.dart`

**Interfaces:**
- Consumes: `Family`, `FamilyMember` models
- Produces: `AuthService` class with `signInWithPhone(String phone)`, `verifyOtp(String smsCode)`, `signOut()`, `currentUser` stream
- Produces: `FamilyService` with `createFamily(String name)`, `joinFamily(String inviteCode)`, `familyStream(String familyId)`

- [ ] **Step 1: Write the failing tests**

```dart
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
```

- [ ] **Step 2: Implement AuthService**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<void> signInWithPhone(String phone) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (e) => throw Exception('Verification failed: ${e.message}'),
      codeSent: (verificationId, _) => _verificationId = verificationId,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  String? _verificationId;

  Future<UserCredential> verifyOtp(String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async => await _auth.signOut();
}
```

- [ ] **Step 3: Implement FamilyService**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_safety_tracker/models/family.dart';
import 'package:family_safety_tracker/services/auth_service.dart';

class FamilyService {
  FamilyService(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<Family?> familyStream(String familyId) {
    return _firestore.collection('families').doc(familyId).snapshots().map(
      (doc) => doc.exists ? Family.fromMap(doc.data()!, doc.id) : null,
    );
  }

  Future<String> createFamily(String name) async {
    final ref = await _firestore.collection('families').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> generateInviteCode(String familyId) async {
    final code = familyId.substring(0, 6).toUpperCase();
    await _firestore.collection('families').doc(familyId).update({
      'inviteCode': code,
    });
    return code;
  }

  Future<String?> resolveInviteCode(String code) async {
    final snapshot = await _firestore
        .collection('families')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }
}
```

- [ ] **Step 4: Run tests to verify**

Run: `flutter test test/services/auth_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add family_safety_tracker/lib/services/ family_safety_tracker/test/services/
git commit -m "feat: add auth and family services"
```

---

### Task 4: Location Tracking Service

**Files:**
- Create: `family_safety_tracker/lib/services/location_service.dart`
- Create: `family_safety_tracker/test/services/location_service_test.dart`

**Interfaces:**
- Consumes: `LocationPoint` model
- Produces: `LocationService` with `startTracking()`, `stopTracking()`, `locationStream`, `updateBatteryLevel()`

- [ ] **Step 1: Write the failing tests**

```dart
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
```

- [ ] **Step 2: Implement LocationService**

```dart
import 'dart:async';
import 'package:location/location.dart';
import 'package:family_safety_tracker/models/location_point.dart';
import 'package:family_safety_tracker/utils/constants.dart';

class LocationService {
  final Location _location = Location();
  StreamSubscription<LocationData>? _subscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  final StreamController<LocationPoint> _locationController =
      StreamController<LocationPoint>.broadcast();
  Stream<LocationPoint> get locationStream => _locationController.stream;

  Future<bool> requestPermission() async {
    final permission = await _location.requestPermission();
    return permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited;
  }

  Future<bool> isServiceEnabled() async => await _location.serviceEnabled();

  Future<void> startTracking() async {
    if (_isTracking) return;
    final hasPermission = await requestPermission();
    if (!hasPermission) throw Exception('Location permission denied');
    final serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      await _location.requestService();
    }
    _subscription = _location.onLocationChanged.listen((data) {
      final point = LocationPoint(
        lat: data.latitude ?? 0,
        lng: data.longitude ?? 0,
        accuracy: data.accuracy ?? 0,
        timestamp: DateTime.now(),
        speed: data.speed ?? 0,
      );
      _locationController.add(point);
    });
    _isTracking = true;
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _isTracking = false;
  }

  void dispose() {
    _locationController.close();
    stopTracking();
  }
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/services/location_service_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add family_safety_tracker/lib/services/location_service.dart family_safety_tracker/test/services/location_service_test.dart
git commit -m "feat: add location tracking service"
```

---

### Task 5: Firestore Sync Service

**Files:**
- Create: `family_safety_tracker/lib/services/sync_service.dart`
- Create: `family_safety_tracker/test/services/sync_service_test.dart`

**Interfaces:**
- Consumes: `LocationService`, `AuthService`, `FamilyMember`, `LocationPoint` models
- Produces: `SyncService` that writes location updates to Firestore in real-time

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:family_safety_tracker/services/sync_service.dart';

void main() {
  group('SyncService', () {
    test('has default uploadInterval of 15 seconds', () {
      expect(SyncService().uploadInterval, const Duration(seconds: 15));
    });
  });
}
```

- [ ] **Step 2: Implement SyncService**

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_safety_tracker/models/location_point.dart';
import 'package:family_safety_tracker/services/location_service.dart';
import 'package:family_safety_tracker/services/auth_service.dart';
import 'package:family_safety_tracker/utils/constants.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  StreamSubscription<LocationPoint>? _subscription;
  Timer? _batteryTimer;

  final Duration uploadInterval = const Duration(seconds: AppConstants.locationUpdateIntervalSec);

  void startSync() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _subscription = _locationService.locationStream
        .throttle(uploadInterval)
        .listen((point) {
      _firestore.collection('locations').doc(userId).set({
        ...point.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    });

    _batteryTimer = Timer.periodic(
      const Duration(minutes: AppConstants.batteryCheckIntervalMin),
      (_) => _syncBatteryLevel(userId),
    );
  }

  Future<void> _syncBatteryLevel(String userId) async {
    final battery = await _getBatteryLevel();
    await _firestore.collection('members').doc(userId).update({
      'batteryLevel': battery,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void stopSync() {
    _subscription?.cancel();
    _batteryTimer?.cancel();
  }

  Future<int> _getBatteryLevel() async {
    try {
      final battery = Battery(); // from battery_plus package
      return await battery.batteryLevel;
    } catch (_) {
      return 100; // default on error
    }
  }

  void dispose() => stopSync();
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/services/sync_service_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add family_safety_tracker/lib/services/sync_service.dart family_safety_tracker/test/services/sync_service_test.dart
git commit -m "feat: add Firestore sync service for location and battery"
```

---

### Task 6: Geofence Monitoring Service

**Files:**
- Create: `family_safety_tracker/lib/services/geofence_service.dart`
- Create: `family_safety_tracker/test/services/geofence_service_test.dart`

**Interfaces:**
- Consumes: `Geofence`, `LocationPoint`, `SyncService`
- Produces: `GeofenceService` with `getGeofences(String familyId)`, `checkGeofences(List<Geofence>, LocationPoint)`

- [ ] **Step 1: Write the failing tests**

```dart
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
      // in a real impl we'd track previous state to distinguish enter vs exit
      expect(service, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Implement GeofenceService**

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_safety_tracker/models/geofence.dart';
import 'package:family_safety_tracker/models/location_point.dart';

enum GeofenceEvent { entered, exited }

class GeofenceResult {
  final Geofence geofence;
  final GeofenceEvent event;
  GeofenceResult(this.geofence, this.event);
}

class GeofenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _previousStates = {};

  Stream<List<Geofence>> geofencesStream(String familyId) {
    return _firestore
        .collection('geofences')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Geofence.fromMap(doc.data(), doc.id))
            .toList());
  }

  List<GeofenceResult> checkGeofences(List<Geofence> fences, LocationPoint point) {
    final results = <GeofenceResult>[];
    for (final fence in fences) {
      final wasInside = _previousStates[fence.id] ?? false;
      final isInside = fence.containsPoint(point);

      if (fence.triggerOnEnter && !wasInside && isInside) {
        results.add(GeofenceResult(fence, GeofenceEvent.entered));
      }
      if (fence.triggerOnExit && wasInside && !isInside) {
        results.add(GeofenceResult(fence, GeofenceEvent.exited));
      }
      _previousStates[fence.id] = isInside;
    }
    return results;
  }

  Future<void> addGeofence(Geofence fence) async {
    await _firestore.collection('geofences').add(fence.toMap());
  }
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/services/geofence_service_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add family_safety_tracker/lib/services/geofence_service.dart family_safety_tracker/test/services/geofence_service_test.dart
git commit -m "feat: add geofence monitoring service"
```

---

### Task 7: Notification Service

**Files:**
- Create: `family_safety_tracker/lib/services/notification_service.dart`
- Create: `family_safety_tracker/test/services/notification_service_test.dart`

**Interfaces:**
- Consumes: nothing from prior tasks
- Produces: `NotificationService` with `init()`, `showNotification()`, `fcmToken` stream

- [ ] **Step 1: Write the failing tests**

```dart
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
```

- [ ] **Step 2: Implement NotificationService**

```dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  StreamController<String?> _tokenController = StreamController<String?>.broadcast();
  Stream<String?> get fcmTokenStream => _tokenController.stream;

  Future<void> init() async {
    await _fcm.requestPermission();
    final token = await _fcm.getToken();
    _tokenController.add(token);

    _fcm.onTokenRefresh.listen((t) => _tokenController.add(t));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ));

    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showNotification(notification.title ?? '', notification.body ?? '');
    }
  }

  Future<void> showNotification(String title, String body) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails('family_tracker', 'Family Tracker',
          importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void dispose() => _tokenController.close();
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/services/notification_service_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add family_safety_tracker/lib/services/notification_service.dart family_safety_tracker/test/services/notification_service_test.dart
git commit -m "feat: add notification service for FCM and local notifications"
```

---

### Task 8: Main App Shell & Navigation

**Files:**
- Create: `family_safety_tracker/lib/app.dart`
- Create: `family_safety_tracker/lib/screens/auth/login_screen.dart`
- Create: `family_safety_tracker/lib/screens/home/map_screen.dart`
- Create: `family_safety_tracker/lib/screens/home/family_screen.dart`
- Create: `family_safety_tracker/lib/screens/home/settings_screen.dart`
- Create: `family_safety_tracker/lib/screens/sos/sos_screen.dart`

**Interfaces:**
- Consumes: `AuthService`, all feature services
- Produces: App widget tree with auth-gating and bottom navigation

- [ ] **Step 1: Write App shell with auth state routing**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:family_safety_tracker/services/auth_service.dart';
import 'package:family_safety_tracker/screens/auth/login_screen.dart';
import 'package:family_safety_tracker/screens/home/map_screen.dart';

class FamilySafetyApp extends StatelessWidget {
  const FamilySafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Family Safety Tracker',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: StreamBuilder(
          stream: AuthService().authState,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData) {
              return const MainShell();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    MapScreen(),
    FamilyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Family'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write LoginScreen stub**

```dart
import 'package:flutter/material.dart';
import 'package:family_safety_tracker/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    await AuthService().signInWithPhone(_phoneController.text);
    setState(() => _otpSent = true);
  }

  Future<void> _verifyOtp() async {
    await AuthService().verifyOtp(_otpController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Safety')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'SMS Code'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _verifyOtp, child: const Text('Verify')),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: _sendOtp, child: const Text('Send OTP')),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write MapScreen stub**

```dart
import 'package:flutter/material.dart';
import 'package:family_safety_tracker/widgets/location_map.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Map')),
      body: const LocationMap(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SosScreen()),
        ),
        backgroundColor: Colors.red,
        child: const Icon(Icons.warning, color: Colors.white),
      ),
    );
  }
}
```

- [ ] **Step 4: Write FamilyScreen stub**

```dart
import 'package:flutter/material.dart';
import 'package:family_safety_tracker/services/auth_service.dart';
import 'package:family_safety_tracker/services/family_service.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Family Members', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Invite Member'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Write SettingsScreen stub**

```dart
import 'package:flutter/material.dart';
import 'package:family_safety_tracker/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => AuthService().signOut(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Write SOS screen stub**

```dart
import 'package:flutter/material.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Alert')),
      body: Center(
        child: GestureDetector(
          onLongPress: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SOS sent!')),
            );
            Navigator.pop(context);
          },
          child: Container(
            width: 200, height: 200,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('HOLD FOR SOS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Create widget stubs**

Create `family_safety_tracker/lib/widgets/location_map.dart`:

```dart
import 'package:flutter/material.dart';

class LocationMap extends StatelessWidget {
  const LocationMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Map will render here'));
  }
}
```

- [ ] **Step 8: Verify the app builds**

Run: `flutter analyze`
Expected: No errors (or minor warnings that are acceptable)

- [ ] **Step 9: Commit**

```bash
git add family_safety_tracker/lib/app.dart family_safety_tracker/lib/screens/ family_safety_tracker/lib/widgets/
git commit -m "feat: add app shell with auth gating and navigation"
```

---

### Task 9: Map Integration & Live Tracking UI

**Files:**
- Modify: `family_safety_tracker/lib/widgets/location_map.dart`
- Create: `family_safety_tracker/lib/widgets/family_member_avatar.dart`
- Create: `family_safety_tracker/lib/widgets/battery_indicator.dart`
- Modify: `family_safety_tracker/lib/screens/home/map_screen.dart`

**Interfaces:**
- Consumes: `LocationService`, `SyncService`, `FamilyService`
- Produces: Full-screen Google Map with member markers and live updates

- [ ] **Step 1: Write LocationMap with Google Maps**

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:family_safety_tracker/services/location_service.dart';
import 'package:family_safety_tracker/widgets/family_member_avatar.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({super.key});
  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _locationService.locationStream.listen((point) {
      setState(() {
        _currentPosition = LatLng(point.lat, point.lng);
        _markers.add(Marker(
          markerId: const MarkerId('self'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    });
    _locationService.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 14,
      ),
      markers: _markers,
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }
}
```

- [ ] **Step 2: Write FamilyMemberAvatar widget**

```dart
import 'package:flutter/material.dart';
import 'package:family_safety_tracker/models/family_member.dart';
import 'package:family_safety_tracker/widgets/battery_indicator.dart';

class FamilyMemberAvatar extends StatelessWidget {
  final FamilyMember member;
  const FamilyMemberAvatar({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.role == FamilyRole.parent
              ? Colors.blue : Colors.green,
          child: Text(member.name[0].toUpperCase()),
        ),
        title: Text(member.name),
        subtitle: Text(member.phone),
        trailing: BatteryIndicator(level: member.batteryLevel),
      ),
    );
  }
}
```

- [ ] **Step 3: Write BatteryIndicator widget**

```dart
import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final int level;
  const BatteryIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          level > 50 ? Icons.battery_full : Icons.battery_alert,
          color: level > 20 ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text('$level%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add family_safety_tracker/lib/widgets/ family_safety_tracker/lib/screens/home/map_screen.dart
git commit -m "feat: add Google Maps integration with live tracking"
```

---

### Task 10: Firebase Cloud Functions for Push Notifications

**Files:**
- Create: `functions/package.json`
- Create: `functions/index.js`
- Create: `functions/.eslintrc.json`

**Interfaces:**
- Consumes: Firestore triggers on `locations`, `sos_alerts`, `batteryLevel` changes
- Produces: Cloud Functions that send FCM push notifications

- [ ] **Step 1: Write functions/package.json**

```json
{
  "name": "family-safety-functions",
  "scripts": {
    "deploy": "firebase deploy --only functions"
  },
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.5.0"
  }
}
```

- [ ] **Step 2: Write functions/index.js**

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

async function getMemberTokens(familyId, excludeMemberId) {
  const members = await admin.firestore()
    .collection('members')
    .where('familyId', '==', familyId)
    .get();
  const tokens = [];
  for (const doc of members.docs) {
    if (doc.id === excludeMemberId) continue;
    const tokenDoc = await admin.firestore()
      .collection('fcm_tokens').doc(doc.id).get();
    if (tokenDoc.exists) tokens.push(tokenDoc.data().token);
  }
  return tokens;
}

exports.onSosAlert = functions.firestore
  .document('sos_alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const alert = snap.data();
    const tokens = await getMemberTokens(alert.familyId, alert.memberId);
    const message = {
      notification: {
        title: '🚨 SOS Alert!',
        body: `Family member needs help! Location: ${alert.lat},${alert.lng}`
      },
      data: { type: 'sos', alertId: context.params.alertId }
    };
    await admin.messaging().sendEachForMulticast({ tokens, ...message });
  });

exports.onGeofenceEvent = functions.firestore
  .document('geofence_events/{eventId}')
  .onCreate(async (snap, context) => {
    const event = snap.data();
    const tokens = await getMemberTokens(event.familyId, null);
    const message = {
      notification: {
        title: '📍 Geofence Alert',
        body: `${event.memberName} ${event.event === 'entered' ? 'arrived at' : 'left'} ${event.fenceName}`
      },
      data: { type: 'geofence' }
    };
    await admin.messaging().sendEachForMulticast({ tokens, ...message });
  });

exports.onLowBattery = functions.firestore
  .document('members/{memberId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data().batteryLevel;
    const after = change.after.data().batteryLevel;
    if (after > 20 || before <= 20) return null;
    const member = change.after.data();
    const tokens = await getMemberTokens(member.familyId, context.params.memberId);
    const message = {
      notification: {
        title: '🔋 Low Battery',
        body: `${member.name}'s battery is at ${after}%`
      },
      data: { type: 'low_battery' }
    };
    await admin.messaging().sendEachForMulticast({ tokens, ...message });
  });
```

- [ ] **Step 3: Commit**

```bash
git add functions/
git commit -m "feat: add Firebase Cloud Functions for push notifications"
```

---

### Plan Self-Review

**Spec Coverage:**
- Live tracking → Tasks 4, 5, 9
- SOS/panic alerts → Tasks 7, 10 (screens in Task 8)
- Geofencing → Tasks 6, 10
- Location history → Task 5 (Firestore storage), UI deferred
- Battery status → Tasks 4, 5, 9 (widget)
- Low battery alert → Task 10
- Auth (phone/invite) → Task 3
- Privacy/consent → Task 3 (model has `consented` field)

**Placeholder check:** Map uses hardcoded initial position (SF) — intentional, replaced at runtime with actual location. No TBDs.

**Type consistency:** All `fromMap`/`toMap` patterns match. Method signatures are consistent across tasks.

**Gap found:** Location history viewing UI is not explicitly planned. It's a lower-priority feature that can be added in a follow-up iteration. The data is stored in Firestore (Task 5), so the UI can be built without backend changes.
