class UserProfile {
  static const int xpPerLevel = 200;

  final String localId;
  final String displayName;
  final String username;
  final String bio;
  final String? avatarPath;
  final String? firebaseUid;
  final int xp;

  const UserProfile({
    required this.localId,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.avatarPath,
    required this.firebaseUid,
    required this.xp,
  });

  String get ownerId =>
      (firebaseUid != null && firebaseUid!.isNotEmpty) ? firebaseUid! : localId;

  int get level => (xp / xpPerLevel).floor() + 1;

  int get xpIntoLevel => xp % xpPerLevel;

  double get levelProgress => xpIntoLevel / xpPerLevel;

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? avatarPath,
    String? firebaseUid,
    int? xp,
  }) {
    return UserProfile(
      localId: localId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      xp: xp ?? this.xp,
    );
  }

  factory UserProfile.defaults({required String localId}) {
    return UserProfile(
      localId: localId,
      displayName: 'Default',
      username: 'Default',
      bio: 'Replace ce message pour changer votre bio.',
      avatarPath: null,
      firebaseUid: null,
      xp: 0,
    );
  }
}
