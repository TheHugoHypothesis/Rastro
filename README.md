# RASTRO: Sistema de Roteamento Adaptativo e Segurança Colaborativa Offline-First para Ciclistas

O Rastro e um sistema de navegacao e seguranca colaborativa desenvolvido em Flutter, voltado especificamente para ciclistas urbanos. O projeto aborda desafios complexos de IHC (Interacao Humano-Computador), usabilidade movel, roteamento adaptativo multicriterio, seguranca colaborativa peer-to-peer (P2P) e integracao de modelos de monetizacao offline-first.

---

## 1. Introducao e Fundamentacao Teorica

O ciclismo urbano exige do ciclista atencao visual constante nas condicoes de trafego e da via, tornando interfaces moveis tradicionais (dependentes de visualizacao constante e interacoes complexas por toque) perigosas. 

O Rastro resolve essa problematica atraves de uma abordagem centrada no usuario:
* **Navegacao Acessivel e Silenciosa**: Utiliza sintese de voz local (TTS) e padroes especificos de vibracao (feedback tatil) para instruir manobras e alertar perigos, reduzindo a carga cognitiva e visual.
* **Resiliencia de Rede Offline-First**: O ecossistema opera sem dependencia de servidores centrais ou conectividade a internet, utilizando uma rede mesh local para sincronizacao de dados entre aparelhos proximos.
* **Modelo Criptografico Baseado em Confianca**: Emprega criptografia asimetrica Ed25519 local para autenticacao e protecao contra ataques Sybil e spam de dados.

---

## 2. Engenharia de IHC e Usabilidade

O sistema segue rigidamente as diretrizes de design universal e usabilidade do Nielsen Norman Group e do WCAG 2.1 (Web Content Accessibility Guidelines):

### 2.1. Acessibilidade Visual e Contraste
Toda a paleta de cores (neo-brutalista de alto contraste) foi ajustada para atender ao nivel de conformidade WCAG AA e AAA. O contraste minimo entre a cor de texto mutada e o fundo escuro e superior a **8.5:1** (superando o patamar de 4.5:1 exigido para acessibilidade), garantindo a legibilidade sob luz solar direta.

### 2.2. Feedback Tatil Avançado (RNF014)
Auxilia na navegacao silenciosa atraves de padroes de vibracao distintos gerenciados pelo `HapticService`:
* **Mudanca de direcao**: Duas vibracoes curtas e medias.
* **Alertas de seguranca**: Uma vibracao forte, pausa e outra vibracao forte.
* **Acao geral / confirmacao**: Vibracao sutil de clique.

### 2.3. Prevencao de Erro no Toque (RNF017)
Todos os elementos de interacao em tela (como os controles na interface de guia de rota) possuem dimensoes fisicas minimas de **48x48 dp** (densidade de pixels), prevenindo toques acidentais sob movimento ou vibracoes mecanicas na bicicleta.

### 2.4. Onboarding Promocional e Interativo
Integrado na primeira inicializacao do aplicativo para ensinar intuitivamente o usuario as caracteristicas operacionais do sistema. O onboarding apresenta informacoes textuais e interacoes dinamicas de forma limpa, podendo ser revisado a qualquer momento na aba de configuracoes de perfil do usuario.

---

## 3. Arquitetura de Software (MVVM)

O aplicativo segue estritamente o padrao arquitetural **Model-View-ViewModel (MVVM)**, fornecendo desacoplamento completo entre a interface e as regras de negocio:

```
┌────────────────────────────────────────────────────────┐
│                        VIEW                            │
│ (Home, Profile, Onboarding Screens & Widgets)          │
└───────────────────────────┬────────────────────────────┘
                            │ ref.watch / ref.read
                            ▼
┌────────────────────────────────────────────────────────┐
│                     VIEWMODEL                          │
│ (AppStateProvider, Providers Riverpod, Notifiers)      │
└───────────────────────────┬────────────────────────────┘
                            │ Acesso e Modificação
                            ▼
┌────────────────────────────────────────────────────────┐
│                        MODEL                           │
│ (Domain Models: Partner, SafetyEvaluation, BikeType)   │
│ (Data: PreferencesService, RoutingService, P2PMesh)     │
└────────────────────────────────────────────────────────┘
```

* **Model (Camada de Dados e Dominio)**: Contem entidades puras e servicos locais ou remotos de persistencia e consulta (`PreferencesService`, `RoutingService`, `PartnerSyncService`).
* **ViewModel (Camada de Gerenciamento de Estado)**: Implementada com a biblioteca Riverpod. Os Notifiers expoem estados imutaveis limpos para a UI e processam eventos assincronos, permitindo que a regra de negocio seja totalmente isolada do framework Flutter.
* **View (Camada de Interface)**: Desenhada atraves de widgets declarativos reativos que se registram nos provedores de estado (ViewModels) e reagem instantaneamente a mudancas de dados.

---

## 4. Motores Tecnicos Principais

### 4.1. Motor de Roteamento Adaptativo (RF003 / RF004)
Calcula trajetos customizados atraves de chamadas à API OSRM (Open Source Routing Machine). A geometria do percurso e a velocidade media sao recalculadas com base em:
* **Tipo de Veiculo (Bicicleta)**:
  * *Corrida (Speed/Racing)*: Direciona o fluxo por vias de asfalto liso e estruturado, definindo velocidade media de 25 km/h.
  * *Urbana Comum*: Velocidade de 18 km/h em ciclovias e vias de trafego calmo.
  * *Dobravel*: Velocidade reduzida para 14 km/h com filtro para evitar pavimentacoes irregulares ou acidentadas.
  * *E-Bike (Eletrica)*: Velocidade de 22 km/h, ignorando limitacoes fisicas por altimetria.
* **Estrategias de Esforco**:
  * *Menor Esforço*: Prioriza trajetos com menor densidade de curvas e manobras frequentes (evitando paradas repetidas).
  * *Menor Distancia*: Prioriza o menor percurso geometrico absoluto.

### 4.2. Rede Mesh P2P Descentralizada e Web of Trust (RF005)
A troca colaborativa de dados de seguranca urbana ocorre de forma local e asimetrica:
* **Mesh Local**: Utiliza a API `Nearby Connections` para buscar outros dispositivos em um raio aproximado de 10 metros via Bluetooth/Wi-Fi Direct.
* **Web of Trust (WoT)**: Relatos de segurança sao assinados individualmente no aparelho com criptografia Ed25519. Ao receber um dado P2P, a assinatura e validada e a confiabilidade do relato e avaliada com base nas relacoes locais de conexao, mitigando campanhas de spam de localizacoes (ataques Sybil).
* **Consolidacao e Correspondencia**: Avaliacoes associadas a vias geograficas sao estendidas semanticamente para a rua inteira, permitindo visualizacao de status completo da via antes de iniciar a jornada.

### 4.3. Ecossistema de Parcerias Patrocinadas (RF007 / RF009 / RF002)
O modelo de sustentacao financeira descentralizado offline do aplicativo baseia-se em:
* **Pontos de Apoio ("Bike-Friendly")**: Estabelecimentos oficiais validados pelo administrador central do Rastro que fornecem facilidades (agua, ferramentas, tomadas).
* **Assinatura Digital Administrativa**: A integridade da lista de parceiros e garantida por uma chave publica mestra instalada no app (`ADMIN_PUBLIC_KEY`). Somente registros assinados digitalmente pela chave privada do admin sao renderizados como parceiros legitimos.
* **Sugerir Paradas na Rota**: O sistema varre as proximidades (raio de 1.5 km) do destino do ciclista e sugere o desvio para um local patrocinado. Se aceito, insere a coordenada como waypoint intermediario recalculando a rota.

---

## 5. Instrucoes de Execucao e Desenvolvimento

### 5.1. Pre-requisitos
* Flutter SDK (versao >= 3.0.0)
* Dart SDK (versao >= 3.0.0)
* Android SDK / iOS Xcode para emuladores ou dispositivos reais

### 5.2. Instalacao das Dependencias
Na raiz do projeto executado em terminal:
```bash
flutter pub get
```

### 5.3. Execucao em Modo de Desenvolvimento
```bash
flutter run
```

### 5.4. Analise Estatica de Codigo (Linting)
Para garantir a integridade da tipagem e padroes esteticos do Rastro:
```bash
flutter analyze
```

### 5.5. Execucao da Suite de Testes
Os testes de unidade da logica de negocio e de widgets sao executados isoladamente de forma rapida:
```bash
flutter test
```

---

## 6. Cobertura da Suite de Testes (RNF010)

Os testes estao divididos de forma modular:
* **Testes de Unidade (`test/unit_test.dart`)**:
  * Valida a integridade estrutural e parser JSON do modelo `PartnerEstablishment`.
  * Testa os calculos geometricos e utilitarios matematicos locais.
  * Valida o `CryptoIdentityService` e a aprovacao de assinaturas administrativas legitimas.
* **Testes de Widgets e Bootstrap (`test/widget_test.dart`)**:
  * Realiza testes de smoke no bootstrap completo do aplicativo (`MyApp`).
  * Valida o fluxo da `SplashScreen`, a ativacao do `OnboardingScreen` e a integridade visual do PageView.
