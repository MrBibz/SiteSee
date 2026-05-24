import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente une photo sauvegardée avec ses métadonnées.
/// Correspond à un document dans la collection Firestore "photos".
class SitePhoto {
  final String id;
  final String imageBase64;  // Image encodée (base64) stockée dans Firestore
  final String description;
  final String visibility;
  final String ownerId;
  final double latitude;
  final double longitude;
  final DateTime takenAt;

  SitePhoto({
    required this.id,
    required this.imageBase64,
    required this.description,
    required this.visibility,
    required this.ownerId,
    required this.latitude,
    required this.longitude,
    required this.takenAt,
  });

  /// Sérialise vers Firestore
  Map<String, dynamic> toFirestore() => {
    'imageBase64': imageBase64,
    'description': description,
    'visibility': visibility,
    'ownerId': ownerId,
    'latitude': latitude,
    'longitude': longitude,
    'takenAt': Timestamp.fromDate(takenAt),
  };

  /// Désérialise depuis un snapshot Firestore
  factory SitePhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imageBase64Value = data['imageBase64'];
    final descriptionValue = data['description'];
    final visibilityValue = data['visibility'];
    final ownerIdValue = data['ownerId'];
    return SitePhoto(
      id: doc.id,
      imageBase64: imageBase64Value is String ? imageBase64Value : '',
      description: descriptionValue is String ? descriptionValue : '',
      visibility: visibilityValue is String ? visibilityValue : 'public',
      ownerId: ownerIdValue is String ? ownerIdValue : '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      takenAt: (data['takenAt'] as Timestamp).toDate(),
    );
  }
}
