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
