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
