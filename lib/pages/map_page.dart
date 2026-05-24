import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/site_photo.dart';
import '../services/photo_service.dart';
import '../widgets/user_location_marker.dart';
import '../widgets/gps_status_banner.dart';

/// Page Map — gère la logique GPS et délègue l'UI à ses widgets.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final PhotoService _photoService = PhotoService();
  static const Duration _refreshInterval = Duration(seconds: 3);
  static const double _hiddenDistanceMeters = 15;

  LatLng? _userLocation;
  List<SitePhoto> _visiblePhotos = [];
  String _statusMessage = 'Recherche de ta position...';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _refreshPhotos();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshPhotos());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<LatLng?> _getUserLocation({bool moveMap = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _statusMessage = 'Service GPS désactivé');
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _statusMessage = 'Permission GPS refusée');
        }
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _statusMessage = 'Permission GPS refusée définitivement');
      }
      return null;
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings:
      const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final userPos = LatLng(position.latitude, position.longitude);
    if (mounted) {
      setState(() {
        _userLocation = userPos;
        _statusMessage = 'Position mise à jour';
      });
    }
    if (moveMap) {
      _mapController.move(userPos, 13);
    }
    return userPos;
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 13);
    } else {
      _getUserLocation(moveMap: true);
    }
  }

  Future<void> _refreshPhotos() async {
    final userPos = await _getUserLocation();
    final allPhotos = await _photoService.fetchPhotos();
    final filtered = _filterPhotos(allPhotos, userPos);
    if (mounted) {
      setState(() => _visiblePhotos = filtered);
    }
  }

  List<SitePhoto> _filterPhotos(List<SitePhoto> photos, LatLng? userPos) {
    return photos.where((photo) {
      switch (photo.visibility) {
        case 'public':
          return true;
        case 'hidden':
          if (userPos == null) return false;
          final distance = Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            photo.latitude,
            photo.longitude,
          );
          return distance <= _hiddenDistanceMeters;
        case 'private':
          return photo.ownerId == _photoService.currentOwnerId;
        default:
          return false;
      }
    }).toList();
  }

  void _showPhotoDetails(SitePhoto photo) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final imageBytes = photo.imageBase64.isNotEmpty
            ? base64Decode(photo.imageBase64)
            : null;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(imageBytes, height: 220, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_not_supported),
                  ),
                const SizedBox(height: 12),
                Text(photo.description.isEmpty ? 'Aucune description' : photo.description),
                const SizedBox(height: 6),
                Text('Visibilité : ${photo.visibility}'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte'), centerTitle: true),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(20, 0),
              initialZoom: _userLocation != null ? 13 : 2,
              minZoom: 2,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_demo',
              ),
              // Widget extrait : marqueur de position
              if (_userLocation != null)
                UserLocationMarker(position: _userLocation!),
              if (_visiblePhotos.isNotEmpty)
                MarkerLayer(
                  markers: _visiblePhotos.map((photo) {
                    final color = photo.visibility == 'private'
                        ? Colors.deepPurple
                        : (photo.visibility == 'hidden'
                        ? Colors.orange
                        : Colors.blue);
                    return Marker(
                      point: LatLng(photo.latitude, photo.longitude),
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => _showPhotoDetails(photo),
                        child: Icon(Icons.photo, color: color, size: 32),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Widget extrait : bannière GPS
          if (_userLocation == null)
            GpsStatusBanner(message: _statusMessage),

          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerOnUser,
              tooltip: 'Ma position',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}