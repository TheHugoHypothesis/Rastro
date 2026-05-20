import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import 'app_state_provider.dart';

/// **UserProfileNotifier (ViewModel)**
///
/// Gerencia e notifica reativamente o estado do perfil do ciclista ativo na aplicação.
/// Faz a ponte entre a View (Configurações/Perfil) e o Model/Service (`PreferencesService`).
class UserProfileNotifier extends Notifier<UserProfile> {
  /// Inicializa o estado padrão do perfil do usuário e dispara o carregamento assíncrono das preferências físicas.
  ///
  /// Retorno:
  /// - `UserProfile`: O perfil inicial ativo.
  @override
  UserProfile build() {
    Future.microtask(_loadFromPrefs);
    return UserProfile(name: 'Ciclista Urbano', age: 28);
  }

  /// Carrega as informações persistidas de perfil em `SharedPreferences` de forma assíncrona.
  Future<void> _loadFromPrefs() async {
    final prefs = ref.read(preferencesServiceProvider);
    final profile = prefs.loadUserProfile();
    if (profile != null) state = profile;
  }

  /// Atualiza o perfil ativo e dispara a persistência local no `PreferencesService`.
  ///
  /// Parâmetros:
  /// - [profile]: A nova instância de perfil do usuário (`UserProfile`).
  void updateProfile(UserProfile profile) {
    state = profile;
    ref.read(preferencesServiceProvider).saveUserProfile(profile);
  }
}

/// Provedor global para injeção e observação do estado de perfil [UserProfile].
final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
