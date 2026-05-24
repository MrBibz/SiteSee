import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _firebaseUidController = TextEditingController();
  final _xpController = TextEditingController();

  String? _avatarPath;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = ProfileService.instance.profile;
    _displayNameController.text = profile.displayName;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio;
    _firebaseUidController.text = profile.firebaseUid ?? '';
    _xpController.text = profile.xp.toString();
    _avatarPath = profile.avatarPath;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _firebaseUidController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _avatarPath = picked.path);
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();
    final firebaseUid = _firebaseUidController.text.trim();
    final xpValue = int.tryParse(_xpController.text.trim());

    if (displayName.isEmpty || username.isEmpty) {
      setState(() => _errorMessage = 'Nom et pseudo sont obligatoires.');
      return;
    }
    if (xpValue == null || xpValue < 0) {
      setState(() => _errorMessage = 'XP invalide.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final current = ProfileService.instance.profile;
    final updated = current.copyWith(
      displayName: displayName,
      username: username,
      bio: bio,
      avatarPath: _avatarPath,
      firebaseUid: firebaseUid.isEmpty ? null : firebaseUid,
      xp: xpValue,
    );

    await ProfileService.instance.save(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileService.instance.profile;
    final level = profile.level;
    final avatarFile = _avatarPath != null && File(_avatarPath!).existsSync()
        ? File(_avatarPath!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        avatarFile != null ? FileImage(avatarFile) : null,
                    child: avatarFile == null
                        ? Icon(Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('@${profile.username}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('Niveau $level',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'Changer l\'avatar',
                  ),
                  if (_avatarPath != null)
                    IconButton(
                      onPressed: () => setState(() => _avatarPath = null),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Retirer l\'avatar',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Identité'),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom affiché',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Pseudo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Niveau & XP'),
              TextField(
                controller: _xpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'XP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'UID Firebase (optionnel)'),
              TextField(
                controller: _firebaseUidController,
                decoration: const InputDecoration(
                  labelText: 'Firebase UID',
                  hintText: 'Renseigne ton UID si dispo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Identifiants locaux'),
              _buildReadonlyRow('Local ID', profile.localId),
              const SizedBox(height: 8),
              _buildReadonlyRow('Owner ID', profile.ownerId),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildReadonlyRow(String label, String value) {
    return Row(
      children: [
        Text('$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
