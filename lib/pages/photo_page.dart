import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/photo_picker_sheet.dart';
import '../services/photo_service.dart';
import '../models/site_photo.dart';
import '../widgets/app_theme.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final _photoService          = PhotoService();
  final _descriptionController = TextEditingController();

  static const _visibilities = [
    (value: 'public',  label: 'Public',  icon: Icons.public_outlined),
    (value: 'hidden',  label: 'Masqué',  icon: Icons.location_searching_outlined),
    (value: 'private', label: 'Privé',   icon: Icons.lock_outline),
  ];

  File?      _selectedFile;
  SitePhoto? _lastUploaded;
  String     _visibility   = 'public';
  bool       _isUploading  = false;
  String?    _errorMessage;

  bool get _canSubmit =>
      _selectedFile != null &&
          !_isUploading &&
          _descriptionController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onImageSelected(String path) async {
    setState(() {
      _selectedFile  = File(path);
      _errorMessage  = null;
      _lastUploaded  = null;
    });
  }

  Future<void> _uploadSelected() async {
    final file = _selectedFile;
    if (file == null) return;

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorMessage = 'Ajoute une description avant l\'envoi.');
      return;
    }

    setState(() { _isUploading = true; _errorMessage = null; });

    try {
      final photo = await _photoService.uploadPhoto(
        file,
        description: description,
        visibility:  _visibility,
      );
      setState(() {
        _lastUploaded = photo;
        _selectedFile = null;
        _descriptionController.clear();
        _visibility  = 'public';
        _isUploading = false;
      });
    } catch (e) {
      setState(() { _isUploading = false; _errorMessage = 'Erreur upload : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle photo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImagePreview(
                file: _selectedFile,
                isUploading: _isUploading,
                onPickTap: _isUploading
                    ? null
                    : () => PhotoPickerSheet.show(context, _onImageSelected),
              ),
              const SizedBox(height: 16),

              if (_selectedFile != null) ...[
                _DetailsForm(
                  controller: _descriptionController,
                  visibility: _visibility,
                  visibilities: _visibilities,
                  enabled: !_isUploading,
                  onVisibilityChanged: (v) => setState(() => _visibility = v),
                  onDescriptionChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _canSubmit ? _uploadSelected : null,
                  child: _isUploading
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0D1117),
                    ),
                  )
                      : const Text('Envoyer'),
                ),
                const SizedBox(height: 24),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: SiteColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SiteColors.red.withValues(alpha: 0.3), width: 0.5,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: SiteFonts.mono(size: 12, color: SiteColors.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_lastUploaded != null) ...[
                _MetadataCard(photo: _lastUploaded!),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Image preview ────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final File? file;
  final bool isUploading;
  final VoidCallback? onPickTap;

  const _ImagePreview({
    required this.file,
    required this.isUploading,
    required this.onPickTap,
  });

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              file!,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          if (isUploading)
            Container(
              width: double.infinity, height: 260,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: SiteColors.amber, strokeWidth: 2,
                ),
              ),
            ),
        ],
      );
    }

    // Empty state — tap to pick
    return GestureDetector(
      onTap: onPickTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: SiteColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: SiteColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: SiteColors.amberDim,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: SiteColors.amber,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text('Appuie pour ajouter une photo', style: SiteFonts.body(size: 13)),
            const SizedBox(height: 4),
            Text('Galerie ou caméra', style: SiteFonts.mono(size: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Details form ─────────────────────────────────────────────────────────────

class _DetailsForm extends StatelessWidget {
  final TextEditingController controller;
  final String visibility;
  final List<({String value, String label, IconData icon})> visibilities;
  final bool enabled;
  final ValueChanged<String> onVisibilityChanged;
  final ValueChanged<String> onDescriptionChanged;

  const _DetailsForm({
    required this.controller,
    required this.visibility,
    required this.visibilities,
    required this.enabled,
    required this.onVisibilityChanged,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Description'),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: 3,
          onChanged: onDescriptionChanged,
          style: SiteFonts.body(size: 13),
          decoration: const InputDecoration(
            hintText: 'Décris le lieu en quelques mots…',
          ),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Visibilité'),
        const SizedBox(height: 6),
        _VisibilitySegmented(
          selected: visibility,
          items: visibilities,
          enabled: enabled,
          onChanged: onVisibilityChanged,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: SiteFonts.mono(size: 10).copyWith(letterSpacing: 0.1),
    );
  }
}

class _VisibilitySegmented extends StatelessWidget {
  final String selected;
  final List<({String value, String label, IconData icon})> items;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _VisibilitySegmented({
    required this.selected,
    required this.items,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        final isActive = item.value == selected;
        Color fg, bg, bdr;
        if (isActive) {
          fg  = item.value == 'public'  ? SiteColors.blue
              : item.value == 'hidden'  ? SiteColors.amber
              : SiteColors.purple;
          bg  = item.value == 'public'  ? SiteColors.publicBg
              : item.value == 'hidden'  ? SiteColors.hiddenBg
              : SiteColors.privateBg;
          bdr = item.value == 'public'  ? SiteColors.publicBdr
              : item.value == 'hidden'  ? SiteColors.hiddenBdr
              : SiteColors.privateBdr;
        } else {
          fg  = SiteColors.muted;
          bg  = SiteColors.surface2;
          bdr = SiteColors.border;
        }

        return Expanded(
          child: GestureDetector(
            onTap: enabled ? () => onChanged(item.value) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bdr, width: isActive ? 1 : 0.5),
              ),
              child: Column(
                children: [
                  Icon(item.icon, size: 16, color: fg),
                  const SizedBox(height: 3),
                  Text(item.label, style: SiteFonts.mono(size: 10, color: fg)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Metadata card (post-upload) ──────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  final SitePhoto photo;
  const _MetadataCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiteColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: SiteColors.green, size: 15),
                const SizedBox(width: 7),
                Text('Sauvegardé dans Firestore', style: SiteFonts.mono(size: 11)),
              ],
            ),
          ),
          const Divider(),
          _MetaRow(icon: Icons.schedule_outlined,   label: 'Date',        value: _fmtDate(photo.takenAt)),
          _MetaRow(icon: Icons.description_outlined, label: 'Description', value: photo.description.isEmpty ? 'Aucune' : photo.description),
          _MetaRow(icon: Icons.visibility_outlined,  label: 'Visibilité',  value: _fmtVis(photo.visibility)),
          _MetaRow(icon: Icons.location_on_outlined, label: 'GPS',
            value: '${photo.latitude.toStringAsFixed(5)}, ${photo.longitude.toStringAsFixed(5)}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtVis(String v) => switch (v) {
    'public'  => 'Public',
    'hidden'  => 'Masqué (proche)',
    'private' => 'Privé',
    _         => v,
  };
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 13, color: SiteColors.muted),
              const SizedBox(width: 7),
              Text(
                '$label  ',
                style: SiteFonts.mono(size: 10),
              ),
              Expanded(
                child: Text(
                  value,
                  style: SiteFonts.mono(size: 10, color: SiteColors.text),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(),
      ],
    );
  }
}