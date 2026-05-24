import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../widgets/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _usernameController    = TextEditingController();
  final _bioController         = TextEditingController();
  final _firebaseUidController = TextEditingController();
  final _xpController          = TextEditingController();

  String? _avatarPath;
  bool    _isSaving     = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = ProfileService.instance.profile;
    _displayNameController.text = p.displayName;
    _usernameController.text    = p.username;
    _bioController.text         = p.bio;
    _firebaseUidController.text = p.firebaseUid ?? '';
    _xpController.text          = p.xp.toString();
    _avatarPath                 = p.avatarPath;
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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _avatarPath = picked.path);
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final username    = _usernameController.text.trim();
    final bio         = _bioController.text.trim();
    final firebaseUid = _firebaseUidController.text.trim();
    final xpValue     = int.tryParse(_xpController.text.trim());

    if (displayName.isEmpty || username.isEmpty) {
      setState(() => _errorMessage = 'Nom et pseudo sont obligatoires.');
      return;
    }
    if (xpValue == null || xpValue < 0) {
      setState(() => _errorMessage = 'XP invalide.');
      return;
    }

    setState(() { _isSaving = true; _errorMessage = null; });

    final current = ProfileService.instance.profile;
    final updated  = current.copyWith(
      displayName: displayName,
      username:    username,
      bio:         bio,
      avatarPath:  _avatarPath,
      firebaseUid: firebaseUid.isEmpty ? null : firebaseUid,
      xp:          xpValue,
    );

    await ProfileService.instance.save(updated);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile   = ProfileService.instance.profile;
    final avatarFile = _avatarPath != null && File(_avatarPath!).existsSync()
        ? File(_avatarPath!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  color: SiteColors.amber, strokeWidth: 2,
                ),
              )
                  : Text(
                'Sauvegarder',
                style: SiteFonts.mono(size: 12, color: SiteColors.amber),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header card ─────────────────────────────────────────────
              _ProfileHeaderCard(
                profile: profile,
                avatarFile: avatarFile,
                onPickAvatar: _pickAvatar,
                onRemoveAvatar: _avatarPath != null
                    ? () => setState(() => _avatarPath = null)
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Identity ─────────────────────────────────────────────────
              _SectionLabel('Identité'),
              const SizedBox(height: 8),
              _FormCard(
                children: [
                  _LabeledField(label: 'Nom affiché', controller: _displayNameController),
                  const SizedBox(height: 10),
                  _LabeledField(label: 'Pseudo',      controller: _usernameController, prefix: '@'),
                  const SizedBox(height: 10),
                  _LabeledField(label: 'Bio', controller: _bioController, maxLines: 3,
                      hint: 'Quelques mots sur toi…'),
                ],
              ),
              const SizedBox(height: 20),

              // ── XP & Firebase UID ────────────────────────────────────────
              _SectionLabel('Niveau & Firebase'),
              const SizedBox(height: 8),
              _FormCard(
                children: [
                  _LabeledField(
                    label: 'XP',
                    controller: _xpController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _LabeledField(
                    label: 'Firebase UID (optionnel)',
                    controller: _firebaseUidController,
                    hint: 'Renseigne ton UID si disponible',
                    monoValue: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Local IDs (read-only) ─────────────────────────────────────
              _SectionLabel('Identifiants locaux'),
              const SizedBox(height: 8),
              _FormCard(
                children: [
                  _ReadonlyRow(label: 'Local ID', value: profile.localId),
                  const Divider(height: 16),
                  _ReadonlyRow(label: 'Owner ID', value: profile.ownerId),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile header card ──────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final UserProfile profile;
  final File? avatarFile;
  final VoidCallback onPickAvatar;
  final VoidCallback? onRemoveAvatar;

  const _ProfileHeaderCard({
    required this.profile,
    required this.avatarFile,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiteColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Avatar + edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SiteColors.amberDim,
                  border: Border.all(color: SiteColors.amber, width: 2.5),
                  image: avatarFile != null
                      ? DecorationImage(image: FileImage(avatarFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: avatarFile == null
                    ? Center(
                  child: Text(
                    _initials(profile.displayName),
                    style: SiteFonts.heading(size: 26).copyWith(color: SiteColors.amber),
                  ),
                )
                    : null,
              ),
              GestureDetector(
                onTap: onPickAvatar,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SiteColors.surface2,
                    border: Border.all(color: SiteColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 13, color: SiteColors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(profile.displayName, style: SiteFonts.heading(size: 18)),
          const SizedBox(height: 3),
          Text('@${profile.username}', style: SiteFonts.mono(size: 12)),
          const SizedBox(height: 16),
          // Stats row
          Container(
            decoration: BoxDecoration(
              color: SiteColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SiteColors.border, width: 0.5),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatCell(value: '${profile.level}',  label: 'Niveau'),
                  _VertDivider(),
                  _StatCell(value: '${profile.xp}',     label: 'XP total'),
                  _VertDivider(),
                  _StatCell(
                    value: '${(profile.levelProgress * 100).round()}%',
                    label: 'Progression',
                  ),
                ],
              ),
            ),
          ),
          if (onRemoveAvatar != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRemoveAvatar,
              child: Text(
                'Retirer l\'avatar',
                style: SiteFonts.mono(size: 11, color: SiteColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(value, style: SiteFonts.heading(size: 17).copyWith(color: SiteColors.amber)),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: SiteFonts.mono(size: 9).copyWith(letterSpacing: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const VerticalDivider(color: SiteColors.border, width: 0.5, thickness: 0.5);
}

// ─── Shared form primitives ───────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiteColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final int maxLines;
  final TextInputType keyboardType;
  final bool monoValue;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.monoValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: SiteFonts.mono(size: 10).copyWith(letterSpacing: 0.1),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: monoValue
              ? SiteFonts.mono(size: 12, color: SiteColors.text)
              : SiteFonts.body(size: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: SiteFonts.mono(size: 13, color: SiteColors.muted),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadonlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: SiteFonts.mono(size: 10).copyWith(letterSpacing: 0.05),
        ),
        const Spacer(),
        Text(
          value,
          style: SiteFonts.mono(size: 11, color: SiteColors.text),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: SiteFonts.mono(size: 10).copyWith(letterSpacing: 0.12),
    );
  }
}