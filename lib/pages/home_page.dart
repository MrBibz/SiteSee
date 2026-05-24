import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/site_photo.dart';
import '../models/user_profile.dart';
import '../services/photo_service.dart';
import '../services/profile_service.dart';
import 'profile_page.dart';
import '../widgets/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PhotoService _photoService = PhotoService();
  final ProfileService _profileService = ProfileService.instance;

  Future<void> _openProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
    if (updated == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SiteSee'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _IconButton(
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileCard(profile: profile, onTap: _openProfile),
              const SizedBox(height: 10),
              _LevelCard(profile: profile),
              const SizedBox(height: 20),
              _SectionLabel('Publications récentes'),
              const SizedBox(height: 10),
              _RecentPostsCard(
                ownerId: profile.ownerId,
                photoService: _photoService,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarFile = profile.avatarPath != null &&
        File(profile.avatarPath!).existsSync()
        ? File(profile.avatarPath!)
        : null;

    return _SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          _Avatar(avatarFile: avatarFile, initials: _initials(profile.displayName)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: SiteFonts.heading(size: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${profile.username}',
                  style: SiteFonts.mono(size: 11),
                ),
                const SizedBox(height: 6),
                _StatusBadge(
                  label: profile.firebaseUid == null || profile.firebaseUid!.isEmpty
                      ? 'Compte local'
                      : 'UID lié',
                  color: SiteColors.green,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: SiteColors.muted, size: 18),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Level / XP card ──────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final UserProfile profile;

  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final xpInto  = profile.xpIntoLevel;
    final xpTotal = UserProfile.xpPerLevel;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Niv. ${profile.level}',
                style: SiteFonts.heading(size: 28).copyWith(color: SiteColors.amber),
              ),
              const Spacer(),
              Text(
                '$xpInto / $xpTotal XP',
                style: SiteFonts.mono(size: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Thin progress track
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: profile.levelProgress,
              minHeight: 4,
              backgroundColor: const Color(0xFF1C2230),
              valueColor: const AlwaysStoppedAnimation(SiteColors.amber),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Publie ${_postsNeeded(profile)} photo${_postsNeeded(profile) > 1 ? 's' : ''} '
                'pour atteindre le niveau ${profile.level + 1}.',
            style: SiteFonts.mono(size: 11),
          ),
        ],
      ),
    );
  }

  int _postsNeeded(UserProfile profile) {
    const xpPerPost = 40;
    final remaining = UserProfile.xpPerLevel - profile.xpIntoLevel;
    return (remaining / xpPerPost).ceil();
  }
}

// ─── Recent posts card ────────────────────────────────────────────────────────

class _RecentPostsCard extends StatelessWidget {
  final String ownerId;
  final PhotoService photoService;

  const _RecentPostsCard({required this.ownerId, required this.photoService});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: StreamBuilder<List<SitePhoto>>(
        stream: photoService.watchPhotosByOwner(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: SiteColors.amber, strokeWidth: 2,
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erreur de chargement.',
                style: SiteFonts.mono(size: 12, color: SiteColors.red),
              ),
            );
          }

          final photos = (snapshot.data ?? []).take(3).toList();
          if (photos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Aucune publication pour le moment.',
                style: SiteFonts.mono(size: 12),
              ),
            );
          }

          return Column(
            children: List.generate(photos.length, (i) {
              final photo = photos[i];
              final isLast = i == photos.length - 1;
              return _PostRow(photo: photo, showDivider: !isLast);
            }),
          );
        },
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final SitePhoto photo;
  final bool showDivider;

  const _PostRow({required this.photo, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _PhotoThumb(base64Image: photo.imageBase64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.description.isEmpty ? 'Sans description' : photo.description,
                      style: SiteFonts.body(size: 13).copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _VisPill(visibility: photo.visibility),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(photo.takenAt),
                          style: SiteFonts.mono(size: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SiteColors.muted, size: 16),
            ],
          ),
        ),
        if (showDivider)
          const Divider(indent: 14, endIndent: 14),
      ],
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60)  return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24)  return 'Il y a ${diff.inHours} h';
    if (diff.inDays    < 7)   return 'Il y a ${diff.inDays} j';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ─── Shared primitives ────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const _SurfaceCard({required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SiteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiteColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      )
          : Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final File? avatarFile;
  final String initials;

  const _Avatar({required this.avatarFile, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SiteColors.amberDim,
        border: Border.all(color: SiteColors.amber, width: 2),
        image: avatarFile != null
            ? DecorationImage(image: FileImage(avatarFile!), fit: BoxFit.cover)
            : null,
      ),
      child: avatarFile == null
          ? Center(
        child: Text(initials, style: SiteFonts.heading(size: 18).copyWith(color: SiteColors.amber)),
      )
          : null,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: SiteFonts.mono(size: 10, color: color)),
        ],
      ),
    );
  }
}

class _VisPill extends StatelessWidget {
  final String visibility;
  const _VisPill({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg, bdr) = switch (visibility) {
      'public'  => ('Public',  SiteColors.blue,   SiteColors.publicBg,  SiteColors.publicBdr),
      'hidden'  => ('Masqué',  SiteColors.amber,  SiteColors.hiddenBg,  SiteColors.hiddenBdr),
      'private' => ('Privé',   SiteColors.purple, SiteColors.privateBg, SiteColors.privateBdr),
      _         => (visibility, SiteColors.muted, Colors.transparent,   SiteColors.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Text(label, style: SiteFonts.mono(size: 10, color: fg)),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String base64Image;
  const _PhotoThumb({required this.base64Image});

  @override
  Widget build(BuildContext context) {
    Widget child = const Icon(Icons.image_outlined, color: SiteColors.muted, size: 20);
    if (base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        child = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        child = const Icon(Icons.broken_image_outlined, color: SiteColors.muted, size: 20);
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 46, height: 46,
        color: SiteColors.surface2,
        alignment: Alignment.center,
        child: child,
      ),
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: SiteColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SiteColors.border, width: 0.5),
        ),
        child: Icon(icon, color: SiteColors.muted, size: 18),
      ),
    );
  }
}