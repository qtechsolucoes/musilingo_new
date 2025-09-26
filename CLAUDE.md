# MusiLingo Project - Claude Instructions

## Project Overview
MusiLingo é uma aplicação Flutter completa para ensino musical com tecnologia avançada. O app combina gamificação, inteligência artificial, análise de áudio em tempo real, e funcionalidades sociais para criar uma experiência de aprendizado musical interativa e personalizada.

## Development Commands

### Flutter Commands
- **Run app**: `flutter run`
- **Build**: `flutter build apk` (Android) ou `flutter build web` (Web)
- **Test**: `flutter test`
- **Clean**: `flutter clean`
- **Get dependencies**: `flutter pub get`
- **Analyze code**: `flutter analyze`

### Code Quality
- **Lint**: `flutter analyze` (usa flutter_lints)
- **Format**: `dart format .`

## Arquitetura do Projeto

### Estrutura de Diretórios
```
lib/
├── app/                           # Core da aplicação
│   ├── controllers/              # Controllers globais (AgentController)
│   ├── core/theme/              # Tema e cores da aplicação
│   ├── data/models/             # Modelos de dados principais
│   ├── models/                  # Modelos adicionais (chat, progress, etc.)
│   ├── presentation/           # Telas e widgets globais
│   ├── services/               # Serviços principais da aplicação
│   └── utils/                  # Utilitários e helpers
├── features/                    # Features organizadas por domínio
│   ├── auth/                   # Autenticação
│   ├── challenges/             # Sistema de desafios
│   ├── connections/            # Sistema professor-aluno
│   ├── duel/                   # Sistema de duelos musicais
│   ├── friends/                # Sistema de amizades
│   ├── home/                   # Tela inicial e trilha de aprendizado
│   ├── leagues/                # Sistema de ligas/rankings
│   ├── lesson/                 # Sistema de lições
│   ├── onboarding/             # Onboarding inicial
│   ├── practice/               # Exercícios de prática
│   ├── practice_solfege/       # Exercícios de solfejo
│   └── profile/                # Perfil do usuário
├── presentation/               # Widgets e páginas compartilhadas
├── services/                   # Serviços auxiliares
├── shared/                     # Componentes compartilhados
├── widgets/                    # Widgets reutilizáveis
└── main.dart                   # Entry point da aplicação
```

## Modelos de Dados Principais

### UserProfile (lib/app/data/models/user_profile_model.dart)
```dart
class UserProfile {
  final String id;              // UUID do usuário
  final String fullName;        // Nome completo
  final String? avatarUrl;      // URL do avatar
  final int points;             // Pontos acumulados
  final int lives;              // Vidas restantes (sistema de gamificação)
  final int correctAnswers;     // Respostas corretas
  final int wrongAnswers;       // Respostas erradas
  final int currentStreak;      // Sequência atual de acertos
  final String? lastPracticeDate; // Data da última prática
  final String league;          // Liga atual (Bronze, Silver, Gold, etc.)
  final int roleId;             // 1=Aluno, 2=Professor
  final String? description;    // Descrição do perfil
  final String? specialty;      // Especialidade (para professores)
}
```

### Lesson & Module (lib/app/data/models/lesson_model.dart, module_model.dart)
```dart
class Lesson {
  final int id;
  final String title;
  final IconData icon;
  final int order;              // Ordem na sequência de aprendizado
}

class Module {
  final int id;
  final String title;
  final List<Lesson> lessons;   // Lista de lições do módulo
}
```

### Exercícios de Prática
```dart
// Exercícios Melódicos
class MelodicExercise {
  final String clef;            // Clave (treble, bass)
  final String keySignature;   // Armadura de clave
  final String timeSignature;  // Fórmula de compasso
  final String referenceNote;  // Nota de referência
  final String musicXml;       // Partitura em MusicXML
  final List<String> correctSequence; // Sequência correta de notas
  final int tempo;              // Andamento
  final List<String> notePalette;     // Paleta de notas disponíveis
  final List<String> figurePalette;   // Figuras rítmicas disponíveis
}

// Exercícios Harmônicos
class HarmonicExercise {
  final List<String> chordNotes;      // Notas do acorde
  final List<String> options;         // Opções de resposta
  final String correctAnswer;         // Resposta correta
  final String inversion;             // Inversão do acorde
  final String playbackStyle;         // Estilo de reprodução (bloco/arpejo)
}

// Progressões Harmônicas
class HarmonicProgression {
  final String key;                   // Tonalidade
  final List<String> progression;     // Sequência de acordes
  final List<String> options;         // Opções de resposta
  final String correctAnswer;         // Resposta correta
}
```

### Sistema de Solfejo (lib/features/practice_solfege/models/solfege_exercise.dart)
```dart
class SolfegeExercise {
  final String difficultyLevel;       // Nível de dificuldade
  final int difficultyValue;          // Valor numérico da dificuldade
  final String keySignature;          // Armadura de clave
  final String timeSignature;         // Fórmula de compasso
  final int tempo;                     // Andamento
  final List<NoteInfo> noteSequence;  // Sequência de notas para cantar
  final String clef;                   // Clave
}

class NoteInfo {
  final String note;                   // Nome da nota (C4, D4, etc.)
  final String lyric;                  // Nome em solfejo (dó, ré, etc.)
  final String duration;              // Duração da nota
  final double frequency;              // Frequência em Hz
}
```

### Sistema de Duelos (lib/features/duel/data/models/duel_models.dart)
```dart
enum DuelStatus { searching, ongoing, finished }

class Duel {
  final String id;
  final DuelStatus status;
  final String? winnerId;
  final DateTime createdAt;
}

class DuelParticipant {
  final String duelId;
  final String userId;
  final int score;                     // Pontuação no duelo
  final String? username;              // Nome do participante
  final String? avatarUrl;             // Avatar do participante
}

class DuelQuestion {
  final String questionText;           // Pergunta do duelo
  final List<String> options;          // Opções de resposta
  final String correctAnswer;          // Resposta correta
  final String? answeredByUserId;      // Quem respondeu
  final DateTime? answeredAt;          // Quando foi respondida
}
```

## Serviços Principais

### DatabaseService (lib/app/services/database_service.dart)
- **Função**: Interface principal com Supabase
- **Métodos importantes**:
  - `getModulesAndLessons()`: Busca módulos e lições (com cache de 10 min)
  - `getProfile(String userId)`: Busca perfil do usuário
  - `updateStats()`: Atualiza estatísticas do usuário
  - `getMelodicExercises()`, `getHarmonicExercises()`: Busca exercícios
  - `markLessonAsCompleted()`: Marca lição como concluída
  - `upsertWeeklyXp()`: Atualiza XP semanal via stored procedure

### GamificationService (lib/app/services/gamification_service.dart)
- **Padrão**: Singleton
- **Função**: Gerencia sistema de pontuação e progressão
- **Métodos**: `addPoints(int points, String reason)`

### AIService (lib/app/services/ai_service.dart)
- **Base URL**: "https://a12c863957f9.ngrok-free.app" (configurável)
- **Métodos**:
  - `startChat(List<ChatMessage> messages)`: Chat com IA
  - `transcribeAudio(File audioFile)`: Transcrição de áudio para MusicXML

### MidiPlaybackService (lib/app/services/midi_playback_service.dart)
- **Função**: Reprodução de MIDI usando flutter_midi_pro
- **Soundfont**: `assets/sf2/GeneralUserGS.sf2`
- **Métodos**: `playNoteSequence()` com callbacks de progresso

### TeacherService (lib/app/services/teacher_service.dart)
- **Função**: Gerencia relacionamento professor-aluno
- **Métodos**:
  - `getOrGenerateTeacherCode()`: Gera código único para professor
  - `connectToTeacherByCode()`: Conecta aluno ao professor
  - `getStudents()`: Lista alunos do professor
  - `disconnectFromTeacher()`: Remove conexão professor-aluno

### FriendsService (lib/features/friends/data/services/friends_service.dart)
- **Função**: Sistema de amizades
- **Métodos**:
  - `searchUsers()`: Busca usuários por nome
  - `sendFriendRequest()`: Envia pedido de amizade
  - `acceptFriendRequest()`: Aceita pedido
  - `getFriends()`, `getPendingRequests()`: Lista amigos e pedidos

### DuelService (lib/features/duel/services/duel_service.dart)
- **Função**: Sistema de duelos em tempo real
- **Realtime**: Usa Supabase Realtime com PostgresChangeEvent
- **Métodos**:
  - `findOrCreateDuel()`: Encontra/cria duelo
  - `submitAnswer()`: Submete resposta via stored procedure
  - `listenToDuelUpdates()`: Escuta mudanças em tempo real

## Sistema de Estados

### UserSession (lib/app/services/user_session.dart)
- **Padrão**: ChangeNotifier (Provider)
- **Função**: Gerencia estado global do usuário autenticado
- **Propriedades**: `currentUser`, `currentTeacher`

### SolfegeController (lib/features/practice_solfege/controllers/solfege_controller.dart)
- **Framework**: GetX
- **Estados**: idle, countdown, listening, analyzing, finished
- **Função**: Controla exercícios de solfejo com análise de áudio em tempo real

## Banco de Dados (Supabase)

### Tabelas Principais
- **profiles**: Perfis dos usuários com gamificação
- **modules/lessons**: Sistema de aprendizado estruturado
- **lesson_steps**: Passos individuais das lições
- **completed_lessons**: Registro de lições completadas
- **practice_melodies**: Exercícios melódicos
- **practice_harmonies**: Exercícios harmônicos
- **practice_progressions**: Progressões harmônicas
- **practice_solfege**: Exercícios de solfejo
- **teacher_student_relationships**: Conexões professor-aluno
- **friends**: Sistema de amizades
- **duels/duel_participants/duel_questions**: Sistema de duelos
- **weekly_xp**: XP semanal para rankings

### Stored Procedures
- **get_user_friends_and_requests**: Retorna amigos e pedidos
- **get_user_role**: Retorna role do usuário
- **handle_correct_answer**: Adiciona pontos por resposta correta
- **handle_wrong_answer**: Remove vida por resposta errada
- **submit_duel_answer**: Processa resposta de duelo
- **upsert_weekly_xp**: Atualiza XP semanal

### Triggers
- **handle_new_user**: Cria perfil automaticamente para novos usuários

## Navegação Principal

### MainNavigationScreen (lib/app/presentation/view/main_navigation_screen.dart)
1. **Aprender** (HomeScreen): Trilha de aprendizado com módulos
2. **CecilIA** (AiHubScreen): Chat com IA musical
3. **Praticar** (PracticeScreen): Exercícios de prática
4. **Ligas** (DuelLobbyScreen): Sistema de duelos
5. **Conexões** (ConnectionsHubScreen): Professor-aluno e amigos
6. **Mais** (MoreScreen): Perfil e configurações

## Funcionalidades Específicas

### Sistema de Solfejo
- **Localização**: `lib/features/practice_solfege/`
- **Funcionalidade**: Exercícios de canto com análise de pitch e reconhecimento de voz
- **Tecnologia**: Análise de áudio em tempo real, detecção de frequência
- **Fluxo**: Countdown → Listening → Analyzing → Results

### Sistema de Duelos
- **Tempo real**: Usando Supabase Realtime
- **Matchmaking**: Automático (busca duelo existente ou cria novo)
- **Pontuação**: +10 pontos por acerto, -5 pontos para oponente

### Sistema Professor-Aluno
- **Códigos únicos**: Geração automática de códigos de 6 caracteres
- **Roles**: 1=Aluno, 2=Professor
- **Dashboard**: Professores veem progresso dos alunos

### Gamificação
- **Pontos**: Ganhos por acertos em exercícios
- **Vidas**: Sistema de vidas (perdidas por erros)
- **Streaks**: Sequências de acertos consecutivos
- **Ligas**: Bronze, Silver, Gold (baseado em XP semanal)

## Testing
- **Unit tests**: `flutter test`
- **Mocking**: Usa mockito
- **Localização**: `test/` directory

## Build Process
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build [platform]`

## Environment Variables (.env)
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Assets Importantes
- **Soundfont**: `assets/sf2/GeneralUserGS.sf2` (para reprodução MIDI)
- **OSMD**: `assets/osmd_viewer/` (renderização de partituras)
- **Audio**: `assets/audio/` (efeitos sonoros)

## Padrões de Código

### State Management
- **Global**: Provider (UserSession)
- **Local**: GetX (SolfegeController)
- **BLoC**: flutter_bloc (para features específicas)

### Arquitetura
- **Feature-based**: Organização por domínio
- **Clean Architecture**: Separação de data/presentation/domain
- **Singleton**: Para serviços globais (GamificationService, SfxService)

### Naming Conventions
- **Arquivos**: snake_case
- **Classes**: PascalCase
- **Variáveis**: camelCase
- **Constantes**: UPPER_SNAKE_CASE

## Debugging e Logs
- Usa `debugPrint()` extensivamente
- Logs específicos para cache hits/misses no DatabaseService
- Error handling com try-catch em todos os serviços

## Common Issues & Solutions
- **Build failure**: `flutter clean && flutter pub get`
- **Audio não funciona**: Verificar permissões no Android/iOS
- **Supabase timeout**: Verificar conectividade e URL
- **MIDI não toca**: Verificar se soundfont foi carregado
- **Realtime não atualiza**: Verificar configuração do canal Supabase

## Próximas Funcionalidades (baseado no código atual)
- Integração com servidor AI (Python) via ngrok
- Expansão do sistema de achievements
- Mais tipos de exercícios (intervalos, escalas)
- Sistema de notificações push
- Modo offline para algumas funcionalidades