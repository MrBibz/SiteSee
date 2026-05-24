import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'app_theme.dart';

/// Amber dot + soft glow ring showing the user's GPS position on the map.
class UserLocationMarker extends StatefulWidget {
  final LatLng position;

  const UserLocationMarker({super.key, required this.position});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ring, curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ring, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.position,
          width: 60,
          height: 60,
          child: Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated expanding ring
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) => Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SiteColors.amber
                                .withValues(alpha: _fade.value * 0.6),
                            width: 1.5,
                          ),
                          color: SiteColors.amber
                              .withValues(alpha: _fade.value * 0.15),
                        ),
                      ),
                    ),
                  ),
                  // Static inner dot
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SiteColors.amber,
                      border: Border.all(
                        color: SiteColors.bg,
                        width: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}