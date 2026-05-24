import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import '../models/site_photo.dart';
import 'profile_service.dart';

/// Service responsable de :
///   1. Lire la position GPS au moment de l'upload
///   2. Compresser l'image en base64
///   3. Sauvegarder l'image + métadonnées dans Firestore
class PhotoService {
  // Références Firebase
  static const int _maxImageBytes = 700 * 1024; // ~700KB pour rester < 1MB après base64
  final ProfileService _profileService = ProfileService.instance;

  String get currentOwnerId => _profileService.ownerId;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  /// Upload une photo avec ses métadonnées GPS, description et visibilité.
  /// Retourne le [SitePhoto] créé, ou lance une exception en cas d'erreur.
  Future<SitePhoto> uploadPhoto(
    File imageFile, {
    required String description,
    required String visibility,
  }) async {
    if (!_hasFirebase) {
      throw Exception('Firebase non initialisé.');
    }
    // 1. Récupère la position GPS actuelle
    final position = await _getCurrentPosition();

    // 2. Encodage image (base64) pour Firestore
    final imageBase64 = await _encodeImageBase64(imageFile);

    // 3. Timestamp local
    final now = DateTime.now();

    // 4. Crée le document Firestore avec l'image + métadonnées
    final ownerId = currentOwnerId;
    final docRef = await _firestore.collection('photos').add({
      'imageBase64': imageBase64,
      'description': description,
      'visibility': visibility,
      'ownerId': ownerId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'takenAt': Timestamp.fromDate(now),
    });

    return SitePhoto(
      id: docRef.id,
      imageBase64: imageBase64,
      description: description,
      visibility: visibility,
      ownerId: ownerId,
      latitude: position.latitude,
      longitude: position.longitude,
      takenAt: now,
    );
  }

  /// Récupère toutes les photos sauvegardées, triées par date décroissante.
  Stream<List<SitePhoto>> watchPhotos() {
    if (!_hasFirebase) {
      return Stream.value([]);
    }
    return _firestore
        .collection('photos')
        .orderBy('takenAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SitePhoto.fromFirestore).toList());
  }

  Future<List<SitePhoto>> fetchPhotos() async {
    if (!_hasFirebase) {
      return [];
    }
    final snap = await _firestore
        .collection('photos')
        .orderBy('takenAt', descending: true)
        .get();
    return snap.docs.map(SitePhoto.fromFirestore).toList();
  }

  Stream<List<SitePhoto>> watchPhotosByOwner(String ownerId) {
    if (!_hasFirebase) {
      return Stream.value([]);
    }
    return _firestore
        .collection('photos')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final photos = snap.docs.map(SitePhoto.fromFirestore).toList();
      photos.sort((a, b) => b.takenAt.compareTo(a.takenAt));
      return photos;
    });
  }

  Future<List<SitePhoto>> fetchPhotosByOwner(String ownerId) async {
    if (!_hasFirebase) {
      return [];
    }
    final snap = await _firestore
        .collection('photos')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    final photos = snap.docs.map(SitePhoto.fromFirestore).toList();
    photos.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return photos;
  }

  // ── Privé ────────────────────────────────────────────────────────────────

  Future<String> _encodeImageBase64(File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw Exception('Image illisible.');
    }

    const int maxDimension = 1280;
    img.Image processed = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(decoded, width: maxDimension);
      } else {
        processed = img.copyResize(decoded, height: maxDimension);
      }
    }

    int quality = 80;
    List<int> jpegBytes = img.encodeJpg(processed, quality: quality);
    while (jpegBytes.length > _maxImageBytes && quality > 30) {
      quality -= 10;
      jpegBytes = img.encodeJpg(processed, quality: quality);
    }

    if (jpegBytes.length > _maxImageBytes) {
      throw Exception(
        'Image trop lourde pour Firestore. Essaie une photo plus légère.',
      );
    }

    return base64Encode(jpegBytes);
  }

  Future<Position> _getCurrentPosition() async {
    // Vérifie/demande la permission (déjà gérée sur la page Map,
    // mais on re-vérifie ici pour être autonome)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
