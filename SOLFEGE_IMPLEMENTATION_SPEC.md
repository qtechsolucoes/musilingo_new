# Especificação Técnica Completa - Sistema de Solfejo MusiLingo

## Visão Geral do Sistema

O sistema de solfejo é uma funcionalidade completa de treino auditivo que permite aos usuários praticar canto de partituras com feedback em tempo real, análise de precisão e progressão gamificada.

## Fluxo do Usuário

### 1. Navegação Inicial
- Usuário clica em "Prática" na barra de navegação
- Clica no container de "Solfejo"
- Escolhe nível (apenas "Iniciante" implementado no BD)
- **Arquivo**: `lib/features/practice/presentation/view/practice_screen.dart`

### 2. Seleção de Exercício
- Tela mostra exercícios disponíveis baseados no progresso
- Usuário escolhe **Agudo** (altura real) ou **Grave** (uma oitava abaixo)
- Sistema carrega exercício do Supabase
- **Tabela BD**: `practice_solfege` + `solfege_progress`

### 3. Configurações da Partitura
- **Visualização**: Horizontal contínua vs. Quebra de linha
- **Zoom**: Aumentar/diminuir para melhor visualização
- **Nomes**: Mostrar/ocultar nomes de solfejo abaixo das notas

### 4. Execução do Exercício
- **Preview**: Ouvir com/sem metrônomo, com/sem contagem
- **Solfejo**: Contagem visual+sonora sincronizada
- **Feedback**: Notas amarelas (cantando) → verdes (correto) / vermelhas (erro)
- **Auto-scroll**: Partitura acompanha execução

### 5. Resultado Final
- Modal com análise detalhada de erros
- Indicação se cantou mais agudo/grave nos erros
- Pontuação baseada em dificuldade
- Sistema de desbloqueio: >90% (próximo exercício + pontos), 50-90% (sem penalidade), <50% (perde vida)

## Estrutura do Banco de Dados

### Tabela `practice_solfege`
```sql
CREATE TABLE public.practice_solfege (
  id bigint PRIMARY KEY,
  title text NOT NULL,
  difficulty_level text NOT NULL,
  difficulty_value smallint NOT NULL,
  key_signature text NOT NULL DEFAULT 'C',
  time_signature text NOT NULL DEFAULT '4/4',
  tempo smallint NOT NULL DEFAULT 100,
  note_sequence jsonb NOT NULL, -- [{"note":"C4","lyric":"Dó","duration":"quarter"}]
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  clef text NOT NULL DEFAULT 'treble'
);
```

### Tabela `solfege_progress`
```sql
CREATE TABLE public.solfege_progress (
  id bigint PRIMARY KEY,
  user_id uuid NOT NULL,
  exercise_id bigint NOT NULL,
  best_score integer NOT NULL DEFAULT 0 CHECK (best_score >= 0 AND best_score <= 100),
  attempts integer NOT NULL DEFAULT 0,
  is_unlocked boolean NOT NULL DEFAULT false,
  first_completed_at timestamp with time zone,
  last_attempt_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
```

## Arquitetura de Código Existente

### Models
- `lib/features/practice_solfege/models/solfege_exercise.dart`
  - `SolfegeExercise` - dados do exercício
  - `NoteInfo` - informações de cada nota
  - `NoteResult` - resultado da análise
  - `AudioAnalysisData` - dados do áudio em tempo real

### Services
- `lib/features/practice_solfege/services/audio_analysis_service.dart` ✅ Implementado
- `lib/features/practice_solfege/services/midi_service.dart` ✅ Implementado
- **CRIAR**: `lib/features/practice_solfege/services/solfege_database_service.dart`

### Providers/Controllers
- `lib/features/practice_solfege/providers/solfege_exercise_provider.dart` ✅ Base implementada
- **Melhorias necessárias**: Integração com BD, sistema de pontuação

### UI
- `lib/features/practice_solfege/presentation/view/solfege_exercise_screen.dart` ✅ Base implementada
- `lib/features/practice_solfege/presentation/widgets/optimized_score_view.dart` ✅ Implementado
- **CRIAR**: Lista de exercícios, configurações avançadas

### WebView/JavaScript
- `assets/osmd_viewer/js/main.js` ✅ Implementado
- **Melhorias**: Controles de zoom, layout, auto-scroll

## Implementações Necessárias

### 1. SolfegeDatabaseService
```dart
class SolfegeDatabaseService {
  // Carregar exercícios por nível
  Future<List<SolfegeExercise>> getExercisesByLevel(String level);

  // Carregar progresso do usuário
  Future<SolfegeProgress> getUserProgress(String userId, int exerciseId);

  // Salvar resultado do exercício
  Future<void> saveExerciseResult(String userId, int exerciseId, int score);

  // Verificar desbloqueios
  Future<List<int>> getUnlockedExercises(String userId);
}
```

### 2. Melhorias no SolfegeExerciseProvider
```dart
class SolfegeExerciseNotifier extends StateNotifier<SolfegeExerciseState> {
  // Estados adicionais
  bool isOctaveDown = false; // Agudo/Grave
  ScoreDisplayMode displayMode = ScoreDisplayMode.horizontal;
  double zoomLevel = 1.0;
  bool showMetronome = true;
  bool showCountdown = true;

  // Métodos adicionais
  void setOctaveMode(bool isDown);
  void setDisplayMode(ScoreDisplayMode mode);
  void setZoomLevel(double zoom);
  void configurePlayback(bool metronome, bool countdown);

  // Análise detalhada
  NoteAnalysis analyzeNoteError(double expected, double detected);
  int calculateScore(List<NoteResult> results, int difficulty);
}
```

### 3. Novos Enums e Classes
```dart
enum ScoreDisplayMode { horizontal, lineBreak }
enum NoteErrorType { tooHigh, tooLow, correct, notSung }

class NoteAnalysis {
  final bool isCorrect;
  final NoteErrorType errorType;
  final double centsDifference; // Diferença em cents
  final bool rhythmCorrect;
}

class SolfegeProgress {
  final String userId;
  final int exerciseId;
  final int bestScore;
  final int attempts;
  final bool isUnlocked;
}
```

### 4. Melhorias JavaScript (OSMD)
```javascript
// Controles de zoom
window.setZoomLevel = function(level) {
  // Implementar zoom da partitura
};

// Controles de layout
window.setDisplayMode = function(mode) {
  // 'horizontal' ou 'lineBreak'
};

// Auto-scroll inteligente
window.autoScrollToCurrentNote = function(noteIndex) {
  // Scroll que mantém nota atual visível
};
```

### 5. UI de Configurações
```dart
class SolfegeConfigurationWidget extends StatelessWidget {
  // Seletor Agudo/Grave
  // Controles de zoom
  // Toggle visualização
  // Configurações de playback
}
```

### 6. Sistema de Pontuação
```dart
class SolfegeScoring {
  static int calculateScore(List<NoteResult> results, int difficulty) {
    // Fórmula baseada em:
    // - Precisão de altura (peso 60%)
    // - Precisão rítmica (peso 30%)
    // - Dificuldade do exercício (multiplicador)
    // - Penalidade por tentativas
  }

  static bool shouldUnlockNext(int score) => score >= 90;
  static bool shouldLoseLife(int score) => score < 50;
  static int getPointsReward(int score, int difficulty) {
    // Pontos baseados em score e dificuldade
  }
}
```

## Plano de Implementação

### Fase 1: Base de Dados e Progressão ⏰ PRIORIDADE
1. Criar `SolfegeDatabaseService`
2. Implementar carregamento de exercícios
3. Sistema de progresso e desbloqueio
4. Integração com `UserSession` para pontos/vidas

### Fase 2: Melhorias na Interface
1. Opção Agudo/Grave
2. Controles de zoom e visualização
3. Configurações de playback

### Fase 3: Análise Avançada
1. Análise detalhada de erros (mais agudo/grave)
2. Sistema de pontuação refinado
3. Feedback visual aprimorado

### Fase 4: Otimizações
1. Auto-scroll inteligente
2. Performance e responsividade
3. Testes e polimento

## Pontos Críticos de Implementação

### 1. Fonte Única de Verdade
- **Tempo**: Sempre usar `tempo` da tabela `practice_solfege`
- **Sequência**: `note_sequence` do BD é autoritativa
- **Progresso**: Tabela `solfege_progress` controla desbloqueios

### 2. Sincronização Audio/Visual
- Timer único baseado no tempo do BD
- WebView e áudio usam mesma fonte de tempo
- Estados sincronizados via Provider

### 3. Sistema de Feedback
- Amarelo: Detectando áudio (amplitude > threshold)
- Verde: Nota correta (pitch + timing)
- Vermelho: Nota incorreta
- Análise em cents para feedback "mais agudo/grave"

### 4. Performance
- Cache de exercícios carregados
- Lazy loading de áudio/MIDI
- Otimização do WebView

## Estrutura de Arquivos Final
```
lib/features/practice_solfege/
├── data/
│   ├── models/
│   │   ├── solfege_exercise.dart ✅
│   │   ├── solfege_progress.dart [CRIAR]
│   │   └── solfege_scoring.dart [CRIAR]
│   └── services/
│       ├── solfege_database_service.dart [CRIAR]
│       └── solfege_scoring_service.dart [CRIAR]
├── presentation/
│   ├── view/
│   │   ├── solfege_exercise_screen.dart ✅
│   │   ├── solfege_exercises_list_screen.dart [CRIAR]
│   │   └── solfege_configuration_screen.dart [CRIAR]
│   └── widgets/
│       ├── optimized_score_view.dart ✅
│       ├── solfege_controls_widget.dart ✅
│       ├── solfege_progress_widget.dart [CRIAR]
│       └── solfege_results_modal.dart [MELHORAR]
├── providers/
│   ├── solfege_exercise_provider.dart ✅
│   ├── solfege_exercises_list_provider.dart [CRIAR]
│   └── solfege_progress_provider.dart [CRIAR]
└── services/
    ├── audio_analysis_service.dart ✅
    └── midi_service.dart ✅
```

## Status Atual da Implementação

### ✅ IMPLEMENTADO (Fase 1 Completa)
- **Base do sistema de exercícios** ✅
- **Análise de áudio em tempo real** ✅
- **Comunicação WebView com coloração de notas** ✅
- **Feedback visual básico (amarelo/verde/vermelho)** ✅
- **MIDI playbook e preview** ✅
- **Interface básica** ✅
- **SolfegeDatabaseService - Integração completa com Supabase** ✅
- **Sistema de progressão e desbloqueio** ✅
- **Modelos SolfegeProgress** ✅
- **Sistema de pontuação baseado em dificuldade** ✅
- **Gamificação (pontos/vidas baseado no desempenho)** ✅
- **Opção Agudo/Grave (isOctaveDown)** ✅

### 🚧 Próximas Fases
- **Integração com UserSession** (para userId real)
- **Lista de exercícios com desbloqueios visuais**
- **Controles avançados da partitura (zoom, layout)**
- **Análise detalhada de erros (mais agudo/grave)**
- **Auto-scroll inteligente**
- **Configurações de preview (metrônomo on/off)**

### 📋 Sistema Completo Implementado

#### 1. Fluxo de Dados Completo
```
Supabase → SolfegeDatabaseService → SolfegeExerciseProvider → UI → WebView
```

#### 2. Sistema de Pontuação
- **Fórmula**: Pitch (70%) + Duração (30%)
- **>= 90%**: Desbloqueio + Pontos (50 + bonus)
- **50-89%**: Sem penalidade
- **< 50%**: Perde vida

#### 3. Funcionalidades Principais
- ✅ Carregamento de exercícios do BD
- ✅ Progresso salvo automaticamente
- ✅ Desbloqueio automático de próximo exercício
- ✅ Feedback visual em tempo real
- ✅ Modo agudo/grave
- ✅ Análise de áudio precisa
- ✅ Sistema de cache (10min)

#### 4. Novos Métodos Disponíveis
```dart
// No Provider
await loadExerciseById(exerciseId, userId)
toggleOctaveMode() // Alterna agudo/grave
// Automático: salvamento e gamificação

// No Service
getExercisesByLevel(level)
saveExerciseResult(userId, exerciseId, score)
getUnlockedExercises(userId, level)
```

---

**NOTA IMPORTANTE**: Este documento serve como guia completo para retomar o desenvolvimento a qualquer momento. Priorizar Fase 1 para funcionalidade básica completa.