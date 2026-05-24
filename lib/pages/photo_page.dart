import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/photo_picker_sheet.dart';
import '../services/photo_service.dart';
import '../models/site_photo.dart';

/// Page Photo — orchestre la capture, l'upload Firebase et l'affichage.
class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final _photoService = PhotoService();
  final _descriptionController = TextEditingController();

  static const Map<String, String> _visibilityLabels = {
    'public': 'Public',
    'hidden': 'Masqué (proche)',
    'private': 'Privé',
  };

  File? _selectedFile;      // Fichier local sélectionné (avant upload)
  SitePhoto? _lastUploaded; // Dernière photo confirmée dans Firebase
  String _visibility = 'public';
  bool _isUploading = false;
  String? _errorMessage;

  bool get _canSubmit =>
      _selectedFile != null &&
      !_isUploading &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Appelé par PhotoPickerSheet avec le chemin du fichier natif
  Future<void> _onImageSelected(String path) async {
    final file = File(path);
    setState(() {
      _selectedFile = file;
      _errorMessage = null;
      _lastUploaded = null;
    });
  }

  Future<void> _uploadSelected() async {
    final file = _selectedFile;
    if (file == null) return;

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() {
        _errorMessage = 'Ajoute une description avant l\'envoi.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final photo = await _photoService.uploadPhoto(
        file,
        description: description,
        visibility: _visibility,
      );
      setState(() {
        _lastUploaded = photo;
        _selectedFile = null;
        _descriptionController.clear();
        _visibility = 'public';
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Erreur upload : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Aperçu de l'image ─────────────────────────────────────
              _buildImagePreview(),
              if (_selectedFile != null) ...[
                const SizedBox(height: 20),
                _buildDetailsForm(),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _canSubmit ? _uploadSelected : null,
                  icon: _isUploading
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? 'Envoi en cours...' : 'Envoyer sur Firebase'),
                ),
              ],

              const SizedBox(height: 24),

              // ── Métadonnées Firestore (si upload réussi) ──────────────
              if (_lastUploaded != null) _buildMetadataCard(_lastUploaded!),

              // ── Message d'erreur ──────────────────────────────────────
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),

              const SizedBox(height: 8),

              // ── Bouton prendre photo ──────────────────────────────────
              FilledButton.icon(
                onPressed: _isUploading
                    ? null // Désactivé pendant l'upload
                    : () => PhotoPickerSheet.show(context, _onImageSelected),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Prendre une photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedFile != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_selectedFile!,
                width: 300, height: 300, fit: BoxFit.cover),
          ),
          // Overlay de chargement pendant l'upload
          if (_isUploading)
            Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    }

    return Container(
      width: 300, height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Aucune photo sélectionnée',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // Carte affichant les métadonnées sauvegardées dans Firestore
  Widget _buildMetadataCard(SitePhoto photo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.cloud_done,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Sauvegardé dans Firestore',
                  style: Theme.of(context).textTheme.labelLarge),
            ]),
            const Divider(height: 20),
            _metaRow(Icons.schedule,
                'Date', _formatDate(photo.takenAt)),
            const SizedBox(height: 8),
            _metaRow(Icons.description,
                'Description', photo.description.isEmpty ? 'Aucune' : photo.description),
            const SizedBox(height: 8),
            _metaRow(Icons.visibility,
                'Visibilité', _formatVisibility(photo.visibility)),
            const SizedBox(height: 8),
            _metaRow(Icons.location_on,
                'GPS', '${photo.latitude.toStringAsFixed(5)}, ${photo.longitude.toStringAsFixed(5)}'),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatVisibility(String value) {
    return _visibilityLabels[value] ?? value;
  }

  Widget _buildDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _descriptionController,
          enabled: !_isUploading,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Décris la photo en quelques mots',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_visibility),
          initialValue: _visibility,
          decoration: const InputDecoration(
            labelText: 'Visibilité',
            border: OutlineInputBorder(),
          ),
          items: _visibilityLabels.entries
              .map((entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          ))
              .toList(),
          onChanged: _isUploading
              ? null
              : (value) {
            if (value == null) return;
            setState(() => _visibility = value);
          },
        ),
      ],
    );
  }
}
