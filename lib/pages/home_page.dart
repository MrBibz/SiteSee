import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/site_photo.dart';
import '../models/user_profile.dart';
import '../services/photo_service.dart';
import '../services/profile_service.dart';
import 'profile_page.dart';

/// Page d'accueil — écran entier, pas de logique métier ici.
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
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Menu d\'accueil',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Retrouve ton profil, ton niveau et tes dernières publications.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _ProfileCard(profile: profile, onTap: _openProfile),
              const SizedBox(height: 16),
              _LevelCard(profile: profile),
              const SizedBox(height: 16),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage:
                    avatarFile != null ? FileImage(avatarFile) : null,
                child: avatarFile == null
                    ? Icon(Icons.person,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.verified,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          profile.firebaseUid == null ||
                                  profile.firebaseUid!.isEmpty
                              ? 'Compte local'
                              : 'UID lié',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserProfile profile;

  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final xpIntoLevel = profile.xpIntoLevel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progression',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Niveau ${profile.level}',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('$xpIntoLevel / ${UserProfile.xpPerLevel} XP',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: profile.levelProgress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Objectif : publier ${_remainingPostsHint(profile)} nouvelles photos pour passer niveau ${profile.level + 1}.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  int _remainingPostsHint(UserProfile profile) {
    const xpPerPost = 40;
    final remainingXp = UserProfile.xpPerLevel - profile.xpIntoLevel;
    return (remainingXp / xpPerPost).ceil();
  }
}

class _RecentPostsCard extends StatelessWidget {
  final String ownerId;
  final PhotoService photoService;

  const _RecentPostsCard({
    required this.ownerId,
    required this.photoService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publications récentes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Basé sur les photos associées à ton UID/local ID.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<SitePhoto>>(
              stream: photoService.watchPhotosByOwner(ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Erreur de chargement des photos.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  );
                }
                final photos = snapshot.data ?? [];
                if (photos.isEmpty) {
                  return Text(
                    'Aucune publication pour le moment.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  );
                }
                final recent = photos.take(3).toList();
                return Column(
                  children: recent.map((photo) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          _PhotoThumb(base64Image: photo.imageBase64),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photo.description.isEmpty
                                      ? 'Sans description'
                                      : photo.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatVisibility(photo.visibility)} · ${_formatRelativeTime(photo.takenAt)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[500]),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatVisibility(String value) {
    switch (value) {
      case 'public':
        return 'Public';
      case 'hidden':
        return 'Masqué';
      case 'private':
        return 'Privé';
      default:
        return value;
    }
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    }
    if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} j';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _PhotoThumb extends StatelessWidget {
  final String base64Image;

  const _PhotoThumb({required this.base64Image});

  @override
  Widget build(BuildContext context) {
    Widget content = const Icon(Icons.image_outlined);
    if (base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        content = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        content = const Icon(Icons.broken_image_outlined);
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
