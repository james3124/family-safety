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
