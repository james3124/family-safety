import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:family_safety_tracker/services/location_service.dart';

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
