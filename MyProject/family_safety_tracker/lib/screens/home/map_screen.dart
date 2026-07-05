import 'package:flutter/material.dart';
import 'package:family_safety_tracker/widgets/location_map.dart';
import 'package:family_safety_tracker/screens/sos/sos_screen.dart';

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
