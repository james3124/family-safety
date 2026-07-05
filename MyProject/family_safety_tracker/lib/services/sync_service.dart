import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_safety_tracker/models/location_point.dart';
import 'package:family_safety_tracker/services/location_service.dart';
import 'package:family_safety_tracker/services/auth_service.dart';
import 'package:family_safety_tracker/utils/constants.dart';
import 'package:battery_plus/battery_plus.dart';

Stream<T> _throttle<T>(Stream<T> source, Duration interval) {
  final controller = source is BroadcastStream<T>
      ? StreamController<T>.broadcast()
      : StreamController<T>();
  var hasValue = false;
  T? latestValue;
  Timer? timer;
  StreamSubscription<T>? sub;

  void emit() {
    if (latestValue != null) {
      controller.add(latestValue!);
      latestValue = null;
    } else {
      timer?.cancel();
      hasValue = false;
    }
  }

  sub = source.listen(
    (value) {
      latestValue = value;
      if (!hasValue) {
        hasValue = true;
        emit();
        timer = Timer.periodic(interval, (_) => emit());
      }
    },
    onError: (e) => controller.addError(e),
    onDone: () => controller.close(),
    cancelOnError: true,
  );

  controller.onCancel = () {
    sub?.cancel();
    timer?.cancel();
  };

  return controller.stream;
}

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final Battery _battery = Battery();
  StreamSubscription<LocationPoint>? _subscription;
  Timer? _batteryTimer;

  final Duration uploadInterval = const Duration(seconds: AppConstants.locationUpdateIntervalSec);

  void startSync() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _subscription = _throttle(_locationService.locationStream, uploadInterval)
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
      return await _battery.batteryLevel;
    } catch (_) {
      return 100;
    }
  }

  void dispose() => stopSync();
}
