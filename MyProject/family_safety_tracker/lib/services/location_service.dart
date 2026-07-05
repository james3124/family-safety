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
