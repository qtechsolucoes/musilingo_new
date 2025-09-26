# Mudanças Específicas para Migração Verovio

## 🔄 Substituições no SolfegeExerciseProvider

### 1. Imports (Linha ~7)
```dart
// REMOVER:
// import 'package:musilingo/features/practice_solfege/presentation/widgets/optimized_score_view.dart';

// ADICIONAR:
import 'package:musilingo/services/verovio_service.dart';
```

### 2. Callback WebView (Linha 139, 171)
```dart
// REMOVER:
Function(String jsCommand)? _webViewCallback;

void setWebViewCallback(Function(String jsCommand)? callback) {
  _webViewCallback = callback;
}

// SUBSTITUIR POR:
// Não é mais necessário - comunicação direta com VerovioService
```

### 3. Coloração de Notas (Linhas 465-476)
```dart
// ANTES:
String jsCommand = '';
if (correct == null) {
  jsCommand = "window.colorNote($noteIndex, '#FFD700')";
} else if (correct) {
  jsCommand = "window.colorNote($noteIndex, '#00CC00')";
} else {
  jsCommand = "window.colorNote($noteIndex, '#CC0000')";
}

if (_webViewCallback != null) {
  _webViewCallback!(jsCommand);
}

// DEPOIS:
Future<void> _highlightNote(int noteIndex, {bool? correct}) async {
  String color;
  if (correct == null) {
    color = '#FFD700';  // Amarelo para destaque
  } else if (correct) {
    color = '#00CC00';  // Verde para correto
  } else {
    color = '#CC0000';  // Vermelho para incorreto
  }

  try {
    await VerovioService.instance.colorNote('note-$noteIndex', color);
    debugPrint('✅ FASE 3.3: Nota $noteIndex destacada com cor $color');
  } catch (e) {
    debugPrint('❌ FASE 3.3: Erro ao destacar nota: $e');
  }
}
```

### 4. Feedback de Resultados (Linhas 563-564)
```dart
// ANTES:
if (_webViewCallback != null) {
  _webViewCallback!("window.applyResultsFeedback(${_generateResultsJson(results)})");
}

// DEPOIS:
Future<void> _applyResultsFeedback(List<SolfegeAnalysisResult> results) async {
  try {
    final noteColors = <String, String>{};

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final color = result.pitchCorrect ? '#00CC00' : '#CC0000';
      noteColors['note-$i'] = color;
    }

    await VerovioService.instance.colorMultipleNotes(noteColors);
    debugPrint('✅ FASE 3.3: Feedback visual aplicado para ${results.length} notas');
  } catch (e) {
    debugPrint('❌ FASE 3.3: Erro ao aplicar feedback: $e');
  }
}
```

### 5. Controle de Zoom (Linhas 810-811)
```dart
// ANTES:
if (_webViewCallback != null) {
  _webViewCallback!("window.setZoomLevel($zoom)");
}

// DEPOIS:
Future<void> setZoomLevel(double zoom) async {
  try {
    await VerovioService.instance.setZoomLevel(zoom);

    state = state.copyWith(zoomLevel: zoom);

    debugPrint('✅ FASE 3.3: Zoom definido para ${(zoom * 100).round()}%');
  } catch (e) {
    debugPrint('❌ FASE 3.3: Erro ao definir zoom: $e');
  }
}
```

### 6. Modo de Display (Linhas 828-830)
```dart
// ANTES:
if (_webViewCallback != null) {
  final modeString = mode == ScoreDisplayMode.horizontal ? 'horizontal' : 'lineBreak';
  _webViewCallback!("window.setDisplayMode('$modeString')");
}

// DEPOIS:
Future<void> toggleDisplayMode() async {
  try {
    final newMode = state.displayMode == ScoreDisplayMode.horizontal
        ? ScoreDisplayMode.lineBreak
        : ScoreDisplayMode.horizontal;

    final newWidth = newMode == ScoreDisplayMode.horizontal ? 800 : 350;
    await VerovioService.instance.setPageWidth(newWidth);

    state = state.copyWith(displayMode: newMode);

    debugPrint('✅ FASE 3.3: Modo de display alterado para $newMode');
  } catch (e) {
    debugPrint('❌ FASE 3.3: Erro ao alterar modo de display: $e');
  }
}
```

### 7. Limpar Cores (Linhas 848-849)
```dart
// ANTES:
if (_webViewCallback != null) {
  _webViewCallback!("window.clearAllNoteColors()");
}

// DEPOIS:
Future<void> clearAllNoteColors() async {
  try {
    await VerovioService.instance.clearAllColors();
    debugPrint('✅ FASE 3.3: Todas as cores de notas removidas');
  } catch (e) {
    debugPrint('❌ FASE 3.3: Erro ao limpar cores: $e');
  }
}
```

### 8. Geração e Renderização de Partitura
```dart
// ADICIONAR NOVO MÉTODO:
Future<void> _generateAndRenderScore() async {
  try {
    // Gerar MusicXML (método existente mantido)
    final musicXML = _musicXmlBuilder.generateMusicXML(
      exercise: state.exercise,
      isOctaveDown: false, // ou state.isOctaveDown se existir
    );

    // NOVA IMPLEMENTAÇÃO: Usar Verovio em vez de OSMD
    await VerovioService.instance.initialize();

    // Cache key baseado no ID do exercício
    final cacheKey = 'exercise_${state.exercise.id}';

    final svg = await VerovioService.instance.renderMusicXML(
      musicXML,
      cacheKey: cacheKey
    );

    if (svg != null) {
      state = state.copyWith(
        musicXml: musicXML,
        isInitialized: true,
      );

      debugPrint('✅ FASE 3.3: Partitura renderizada com Verovio');
    } else {
      throw Exception('Falha ao renderizar SVG');
    }
  } catch (e) {
    debugPrint('❌ FASE 3.3: Erro ao renderizar com Verovio: $e');
    // TODO: Set error state
  }
}
```

## 🎵 SolfegeExerciseScreen - Mudanças na UI

### Substituir OptimizedScoreView:
```dart
// ANTES:
OptimizedScoreView(
  musicXML: state.musicXML,
  onScoreLoaded: () => debugPrint('Score loaded'),
  height: 300,
  backgroundColor: Colors.transparent,
)

// DEPOIS:
VerovioScoreWidget(
  musicXML: state.musicXML,
  cacheKey: 'exercise_${state.exercise?.id}',
  zoom: state.zoomLevel,
  onScoreLoaded: () => debugPrint('✅ FASE 3.4: Score loaded with Verovio'),
  enableInteraction: true,
  onNotePressed: (noteId) => debugPrint('🎵 Nota pressionada: $noteId'),
  padding: const EdgeInsets.all(16),
)
```

## 🔧 Métodos a Serem Atualizados

1. `_highlightNote()` → Usar `VerovioService.instance.colorNote()`
2. `_applyResultsFeedback()` → Usar `VerovioService.instance.colorMultipleNotes()`
3. `setZoomLevel()` → Usar `VerovioService.instance.setZoomLevel()`
4. `toggleDisplayMode()` → Usar `VerovioService.instance.setPageWidth()`
5. `clearAllNoteColors()` → Usar `VerovioService.instance.clearAllColors()`
6. `_generateAndRenderScore()` → Usar `VerovioService.instance.renderMusicXML()`

## 🗑️ Código a Ser Removido

1. `Function(String jsCommand)? _webViewCallback`
2. `void setWebViewCallback(Function(String jsCommand)? callback)`
3. `_generateResultsJson()` method (se existir)
4. Todos os `_webViewCallback!()` calls
5. Todas as strings JavaScript (`window.colorNote`, `window.setZoomLevel`, etc.)

## ✅ Benefícios Imediatos

- **Performance**: Eliminação da camada WebView JavaScript
- **Reliability**: Sem mais problemas de comunicação WebView
- **Maintainability**: Código Dart puro, sem JavaScript
- **Features**: Acesso a API completa do Verovio
- **Debugging**: Logs nativos, stack traces claras

---
*Guia específico para implementar a migração do sistema de solfejo para Verovio*