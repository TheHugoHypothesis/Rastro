import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import 'app_state_provider.dart';

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    Future.microtask(_loadFromPrefs);
    return UserProfile(name: 'Ciclista Urbano', age: 28);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = ref.read(preferencesServiceProvider);
    final profile = await prefs.loadUserProfile();
    if (profile != null) state = profile;
  }

  void updateProfile(UserProfile profile) {
    state = profile;
    ref.read(preferencesServiceProvider).saveUserProfile(profile);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
