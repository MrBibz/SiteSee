import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Appelle le canal natif Android pour la caméra.
/// Aucun plugin tiers — pure MethodChannel vers MainActivity.java.
class NativeCamera {
  static const _channel = MethodChannel('com.sitesee.site_see/camera');

  /// Lance la caméra Android native. Retourne le chemin du fichier ou null si annulé.
  static Future<String?> takePhoto() async {
    return await _channel.invokeMethod<String>('takePhoto');
  }
}

/// Menu bas pour lancer la caméra.
/// Callback [onPathSelected] reçoit le chemin absolu de l'image.
class PhotoPickerSheet extends StatelessWidget {
  final ValueChanged<String> onPathSelected;

  const PhotoPickerSheet({super.key, required this.onPathSelected});

  static void show(BuildContext context, ValueChanged<String> onPathSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoPickerSheet(onPathSelected: onPathSelected),
    );
  }

  Future<void> _handle(BuildContext context, Future<String?> call) async {
    Navigator.pop(context);
    final path = await call;
    if (path != null) onPathSelected(path);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Prendre une photo',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ouvrir la caméra'),
              onTap: () => _handle(context, NativeCamera.takePhoto()),
            ),
          ],
        ),
      ),
    );
  }
}
