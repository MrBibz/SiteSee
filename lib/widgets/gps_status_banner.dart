import 'package:flutter/material.dart';
import 'app_theme.dart';

class GpsStatusBanner extends StatefulWidget {
  final String message;

  const GpsStatusBanner({super.key, required this.message});

  @override
  State<GpsStatusBanner> createState() => _GpsStatusBannerState();
}

class _GpsStatusBannerState extends State<GpsStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: SiteColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SiteColors.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing amber dot — replaces the generic CircularProgressIndicator
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SiteColors.amber
                        .withValues(alpha: 0.4 + 0.6 * _pulse.value),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                widget.message,
                style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 12,
                  color: SiteColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}