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
            .map((doc) => Geofence.fromMap(doc.data()!, doc.id))
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
