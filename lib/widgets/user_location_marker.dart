import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Couche de marqueur indiquant la position GPS de l'utilisateur sur la carte.
/// Retourne un [MarkerLayer] prêt à être ajouté dans les [children] de FlutterMap.
class UserLocationMarker extends StatelessWidget {
  final LatLng position;

  const UserLocationMarker({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: position,
          width: 60,
          height: 60,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 4,
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