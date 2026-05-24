import 'package:flutter/material.dart';

/// Bannière affichée sur la carte pendant la recherche GPS.
/// Disparaît une fois la position trouvée (widget non affiché par la page).
class GpsStatusBanner extends StatelessWidget {
  final String message;

  const GpsStatusBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}