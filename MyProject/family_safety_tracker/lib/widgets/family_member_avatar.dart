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
