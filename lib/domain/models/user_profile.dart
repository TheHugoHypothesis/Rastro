/// **UserProfile**
///
/// Modela o perfil de identidade e dados pessoais do ciclista.
/// Utilizado na aba de Perfil para personalização da experiência de uso (RF001).
class UserProfile {
  /// Nome completo ou pseudônimo de exibição do usuário.
  final String name;

  /// Idade do usuário para personalizações e estatísticas de esforço físico.
  final int age;

  /// Caminho opcional do arquivo de imagem da foto de perfil.
  final String? photoPath;

  /// Inicializa uma nova instância de perfil do ciclista.
  UserProfile({
    required this.name,
    required this.age,
    this.photoPath,
  });

  /// Gera uma nova instância cópia de [UserProfile] aplicando alterações nos campos informados.
  ///
  /// Parâmetros:
  /// - [name]: Novo nome opcional (`String?`).
  /// - [age]: Nova idade opcional (`int?`).
  /// - [photoPath]: Novo caminho da foto opcional (`String?`).
  /// - [removePhoto]: Se `true`, limpa a foto de perfil definindo-a como nula (`bool`).
  ///
  /// Retorno:
  /// - Uma nova instância mutada de [UserProfile].
  UserProfile copyWith({
    String? name,
    int? age,
    String? photoPath,
    bool removePhoto = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      photoPath: removePhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}
