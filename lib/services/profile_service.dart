import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  static const String _keyLocalId = 'profile.localId';
  static const String _keyDisplayName = 'profile.displayName';
  static const String _keyUsername = 'profile.username';
  static const String _keyBio = 'profile.bio';
  static const String _keyAvatarPath = 'profile.avatarPath';
  static const String _keyFirebaseUid = 'profile.firebaseUid';
  static const String _keyXp = 'profile.xp';

  SharedPreferences? _prefs;
  UserProfile? _profile;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final localId = prefs.getString(_keyLocalId) ??
        'local-${DateTime.now().millisecondsSinceEpoch}';
    if (!prefs.containsKey(_keyLocalId)) {
      await prefs.setString(_keyLocalId, localId);
    }

    _profile = UserProfile(
      localId: localId,
      displayName: prefs.getString(_keyDisplayName) ?? 'Bibz',
      username: prefs.getString(_keyUsername) ?? 'bibz',
      bio: prefs.getString(_keyBio) ?? 'Explorateur urbain en mission.',
      avatarPath: prefs.getString(_keyAvatarPath),
      firebaseUid: prefs.getString(_keyFirebaseUid),
      xp: prefs.getInt(_keyXp) ?? 120,
    );
  }

  UserProfile get profile {
    return _profile ?? UserProfile.defaults(localId: 'local-user');
  }

  String get ownerId => profile.ownerId;

  Future<void> save(UserProfile updated) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _profile = updated;

    await prefs.setString(_keyLocalId, updated.localId);
    await prefs.setString(_keyDisplayName, updated.displayName);
    await prefs.setString(_keyUsername, updated.username);
    await prefs.setString(_keyBio, updated.bio);
    if (updated.avatarPath == null || updated.avatarPath!.isEmpty) {
      await prefs.remove(_keyAvatarPath);
    } else {
      await prefs.setString(_keyAvatarPath, updated.avatarPath!);
    }
    if (updated.firebaseUid == null || updated.firebaseUid!.isEmpty) {
      await prefs.remove(_keyFirebaseUid);
    } else {
      await prefs.setString(_keyFirebaseUid, updated.firebaseUid!);
    }
    await prefs.setInt(_keyXp, updated.xp);
  }
}
