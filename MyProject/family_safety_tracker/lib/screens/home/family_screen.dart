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
