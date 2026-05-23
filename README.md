# RASTRO

O **Rastro** é um aplicativo de navegação e segurança colaborativa desenvolvido para ciclistas urbanos.  
Seu objetivo é oferecer rotas mais seguras, acessíveis e adaptáveis, funcionando mesmo sem conexão constante com a internet.

O sistema utiliza navegação guiada por voz e vibração, reduzindo a necessidade de olhar para a tela durante o percurso e aumentando a segurança do ciclista em movimento.

---

# Funcionalidades

## Navegação Inteligente

O aplicativo calcula rotas utilizando diferentes estratégias de deslocamento para bicicletas, permitindo trajetos personalizados conforme o perfil do usuário.

### Tipos de bicicleta suportados
- Bicicleta de corrida
- Bicicleta urbana
- Bicicleta dobrável
- Bicicleta elétrica (E-Bike)

### Estratégias de rota
- Menor distância
- Menor esforço
- Rotas mais suaves para mobilidade urbana

As rotas são calculadas utilizando a API OSRM (Open Source Routing Machine).

---

## Navegação por Voz e Vibração

Durante a rota, o usuário recebe instruções através de:
- Síntese de voz local (TTS)
- Feedback tátil por vibração

Os padrões de vibração auxiliam o ciclista sem exigir atenção visual constante.

### Exemplos
- Mudança de direção
- Alertas de segurança
- Confirmações de ações

---

## Sistema Offline-First

O aplicativo foi projetado para continuar funcionando mesmo sem internet.

Os dados principais ficam armazenados localmente no dispositivo, permitindo:
- Navegação local
- Consulta de dados sincronizados
- Funcionamento parcial offline

---

## Rede Mesh P2P

O Rastro possui um sistema colaborativo de troca de informações entre dispositivos próximos utilizando:
- Bluetooth
- Wi-Fi Direct

Isso permite compartilhar:
- Alertas urbanos
- Informações de segurança
- Dados colaborativos locais

A sincronização ocorre sem necessidade de servidores centrais.

---

## Segurança e Validação de Dados

Os dados trocados entre dispositivos utilizam assinaturas criptográficas baseadas em Ed25519.

O sistema valida:
- Integridade dos dados
- Autenticidade das mensagens
- Parceiros oficiais autenticados

Isso reduz spam e falsificação de informações.

---

## Pontos de Apoio para Ciclistas

O aplicativo possui suporte para estabelecimentos parceiros ("Bike-Friendly"), permitindo:
- Sugestão de paradas durante a rota
- Exibição de pontos de apoio próximos
- Inserção automática de waypoint na navegação

### Exemplos
- Oficinas
- Cafés
- Locais com água
- Pontos de descanso

---

# Arquitetura

O projeto utiliza arquitetura MVVM (Model-View-ViewModel) com Riverpod para gerenciamento de estado.

### Tecnologias principais
- Flutter
- Dart
- Riverpod
- OSRM
- Nearby Connections
- Ed25519

---

# Como Compilar e Executar

## Pré-requisitos

Instale:
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio ou Xcode

Verifique a instalação:

```bash
flutter doctor
```

---

## Instalação das Dependências

Na raiz do projeto:

```bash
flutter pub get
```

---

## Executar em Desenvolvimento

```bash
flutter run
```

---

## Gerar APK Android

```bash
flutter build apk
```

APK gerado em:

```text
build/app/outputs/flutter-apk/
```

---

## Gerar App Bundle (.aab)

```bash
flutter build appbundle
```

---

## Executar Análise Estática

```bash
flutter analyze
```

---

## Executar Testes

```bash
flutter test
```

---

# Estrutura Geral do Projeto

```text
lib/
 ├── models/
 ├── services/
 ├── providers/
 ├── screens/
 ├── widgets/
 └── main.dart
```
