import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';

/// Native Android camera bridge — unchanged from original.
class NativeCamera {
  static const _channel = MethodChannel('com.sitesee.site_see/camera');

  static Future<String?> takePhoto() async {
    return await _channel.invokeMethod<String>('takePhoto');
  }
}

/// Dark bottom sheet for picking or capturing a photo.
/// [onPathSelected] receives the absolute file path of the chosen image.
class PhotoPickerSheet extends StatelessWidget {
  final ValueChanged<String> onPathSelected;

  const PhotoPickerSheet({super.key, required this.onPathSelected});

  static void show(BuildContext context, ValueChanged<String> onPathSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoPickerSheet(onPathSelected: onPathSelected),
    );
  }

  Future<String?> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }

  Future<void> _handle(BuildContext context, Future<String?> call) async {
    Navigator.pop(context);
    final path = await call;
    if (path != null) onPathSelected(path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: SiteColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SiteColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ajouter une photo',
                style: SiteFonts.heading(size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisir une source',
                style: SiteFonts.mono(size: 11),
              ),
              const SizedBox(height: 20),
              _PickerOption(
                icon: Icons.photo_library_outlined,
                label: 'Galerie',
                sublabel: 'Choisir depuis la galerie',
                onTap: () => _handle(context, _pickFromGallery()),
              ),
              const SizedBox(height: 10),
              _PickerOption(
                icon: Icons.camera_alt_outlined,
                label: 'Caméra',
                sublabel: 'Ouvrir la caméra native',
                onTap: () => _handle(context, NativeCamera.takePhoto()),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SiteColors.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SiteColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SiteColors.amberDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: SiteColors.amber.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, color: SiteColors.amber, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: SiteFonts.heading(size: 14)),
                    const SizedBox(height: 2),
                    Text(sublabel, style: SiteFonts.mono(size: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SiteColors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}