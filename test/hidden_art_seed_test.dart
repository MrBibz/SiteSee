import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Seed hidden art (manual)', () async {
    await Firebase.initializeApp();

    await FirebaseFirestore.instance.collection('photos').add({
      'imageBase64': '',
      'description': 'The art of programming in 2026',
      'visibility': 'hidden',
      'ownerId': 'manual-test',
      'latitude': 0.0,
      'longitude': 0.0,
      'takenAt': Timestamp.fromDate(DateTime.now()),
    });
  }, skip: 'Manual test — run when you want to seed a hidden art item.');
}
