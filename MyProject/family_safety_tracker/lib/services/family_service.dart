import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_safety_tracker/models/family.dart';
import 'package:family_safety_tracker/services/auth_service.dart';

class FamilyService {
  FamilyService(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<Family?> familyStream(String familyId) {
    return _firestore.collection('families').doc(familyId).snapshots().map(
      (doc) => doc.exists ? Family.fromMap(doc.data()!, doc.id) : null,
    );
  }

  Future<String> createFamily(String name) async {
    final ref = await _firestore.collection('families').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> generateInviteCode(String familyId) async {
    final code = familyId.substring(0, 6).toUpperCase();
    await _firestore.collection('families').doc(familyId).update({
      'inviteCode': code,
    });
    return code;
  }

  Future<String?> resolveInviteCode(String code) async {
    final snapshot = await _firestore
        .collection('families')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }
}
