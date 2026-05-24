import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/site_photo.dart';
import '../services/photo_service.dart';
import '../services/profile_service.dart';
import '../widgets/user_location_marker.dart';
import '../widgets/gps_status_banner.dart';
import '../widgets/app_theme.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final PhotoService _photoService = PhotoService();
  final Set<String> _notifiedHiddenIds = {};

  static const Duration _refreshInterval    = Duration(seconds: 3);
  static const double   _hiddenDistanceMeters = 100;

  LatLng?        _userLocation;
  List<SitePhoto> _visiblePhotos = [];
  String         _statusMessage  = 'Recherche de ta position…';
  Timer?         _refreshTimer;

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

  void moveMapToCoordinates(double latitude, double longitude) {
    _mapController.move(LatLng(latitude, longitude), 16.0);
    try {
      final matchingPhoto = _visiblePhotos.firstWhere(
            (photo) => photo.latitude == latitude && photo.longitude == longitude,
      );
      _showPhotoDetails(matchingPhoto);
    } catch (_) {
    }
  }

  // ─── GPS ──────────────────────────────────────────────────────────────────

  Future<LatLng?> _getUserLocation({bool moveMap = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _statusMessage = 'Service GPS désactivé');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _statusMessage = 'Permission GPS refusée');
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final userPos = LatLng(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _userLocation  = userPos;
        _statusMessage = 'Position mise à jour';
      });
    }
    if (moveMap) _mapController.move(userPos, 15);
    return userPos;
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    } else {
      _getUserLocation(moveMap: true);
    }
  }

  Future<void> _refreshPhotos() async {
    final userPos   = await _getUserLocation();
    final allPhotos = await _photoService.fetchPhotos();
    final filtered  = _filterPhotos(allPhotos, userPos);
    if (!mounted) return;
    setState(() => _visiblePhotos = filtered);
    await _maybeNotifyHiddenArt(filtered, userPos);
  }

  List<SitePhoto> _filterPhotos(List<SitePhoto> photos, LatLng? userPos) {
    return photos.where((photo) {
      switch (photo.visibility) {
        case 'public':
          return true;
        case 'hidden':
          if (userPos == null) return false;
          final d = Geolocator.distanceBetween(
            userPos.latitude, userPos.longitude,
            photo.latitude,  photo.longitude,
          );
          return d <= _hiddenDistanceMeters;
        case 'private':
          return photo.ownerId == _photoService.currentOwnerId;
        default:
          return false;
      }
    }).toList();
  }

  Future<void> _maybeNotifyHiddenArt(
    List<SitePhoto> visible,
    LatLng? userPos,
  ) async {
    if (!mounted || userPos == null) return;
    final newlyHidden = visible
        .where((photo) =>
            photo.visibility == 'hidden' &&
            !_notifiedHiddenIds.contains(photo.id))
        .toList();
    if (newlyHidden.isEmpty) return;

    for (final photo in newlyHidden) {
      _notifiedHiddenIds.add(photo.id);
      await ProfileService.instance.awardHiddenArtXp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu es proche d\'un art magnifique, 2x EXP'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── Photo detail sheet ───────────────────────────────────────────────────

  void _showPhotoDetails(SitePhoto photo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PhotoDetailSheet(photo: photo),
    );
  }

  // ─── Marker helpers ───────────────────────────────────────────────────────

  ({Color fg, Color bg, Color bdr}) _pinColors(String visibility) {
    return switch (visibility) {
      'hidden'  => (fg: SiteColors.amber,  bg: SiteColors.hiddenBg,  bdr: SiteColors.hiddenBdr),
      'private' => (fg: SiteColors.purple, bg: SiteColors.privateBg, bdr: SiteColors.privateBdr),
      _         => (fg: SiteColors.blue,   bg: SiteColors.publicBg,  bdr: SiteColors.publicBdr),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(20, 0),
              initialZoom:   _userLocation != null ? 15 : 2,
              minZoom: 2,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_demo',
              ),
              if (_userLocation != null)
                UserLocationMarker(position: _userLocation!),
              if (_visiblePhotos.isNotEmpty)
                MarkerLayer(
                  markers: _visiblePhotos.map((photo) {
                    final c = _pinColors(photo.visibility);
                    return Marker(
                      point: LatLng(photo.latitude, photo.longitude),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _showPhotoDetails(photo),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.bdr, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(Icons.photo_camera_outlined, color: c.fg, size: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          if (_userLocation == null)
            GpsStatusBanner(message: _statusMessage),

          // Legend
          Positioned(
            bottom: 80,
            left: 16,
            child: _MapLegend(),
          ),

          // FAB — centre on user
          Positioned(
            bottom: 16,
            right: 16,
            child: SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: _centerOnUser,
                tooltip: 'Ma position',
                child: const Icon(Icons.my_location_outlined, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map legend ───────────────────────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Public',      color: SiteColors.blue),
      (label: 'Masqué',      color: SiteColors.amber),
      (label: 'Privé',       color: SiteColors.purple),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SiteColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.expand((item) => [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: item.color),
          ),
          const SizedBox(width: 4),
          Text(item.label, style: SiteFonts.mono(size: 10)),
          const SizedBox(width: 10),
        ]).toList()..removeLast(),
      ),
    );
  }
}

// ─── Photo detail bottom sheet ────────────────────────────────────────────────

class _PhotoDetailSheet extends StatelessWidget {
  final SitePhoto photo;
  const _PhotoDetailSheet({required this.photo});

  @override
  Widget build(BuildContext context) {
    final imageBytes = photo.imageBase64.isNotEmpty
        ? base64Decode(photo.imageBase64)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: SiteColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: SiteColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBytes != null
                    ? Image.memory(
                  imageBytes,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 220,
                  width: double.infinity,
                  color: SiteColors.surface2,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: SiteColors.muted,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                photo.description.isEmpty ? 'Aucune description' : photo.description,
                style: SiteFonts.heading(size: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _DetailChip(
                    icon: Icons.visibility_outlined,
                    label: _visLabel(photo.visibility),
                  ),
                  const SizedBox(width: 8),
                  _DetailChip(
                    icon: Icons.location_on_outlined,
                    label: '${photo.latitude.toStringAsFixed(4)}, ${photo.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _visLabel(String v) => switch (v) {
    'public'  => 'Public',
    'hidden'  => 'Masqué',
    'private' => 'Privé',
    _         => v,
  };
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SiteColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SiteColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SiteColors.muted),
          const SizedBox(width: 5),
          Text(label, style: SiteFonts.mono(size: 10)),
        ],
      ),
    );
  }
}