# Migração do Sistema de Solfejo para Verovio

## 🎯 Objetivo
Migrar o sistema de solfejo do OSMD (OpenSheetMusicDisplay) para **Verovio nativo** via FFI, eliminando dependências WebView e maximizando performance.

## 📋 Plano de Migração

### ✅ FASE 1: Infraestrutura Verovio
- [x] Plugin FFI criado (`verovio_flutter/`)
- [x] Bridge C++ implementado (versão teste)
- [x] Interface Dart configurada
- [x] VerovioService criado (`lib/services/verovio_service.dart`)
- [x] VerovioScoreWidget criado (`lib/widgets/verovio_score_widget.dart`)

### 🔄 FASE 2: Migração Gradual
- [ ] Atualizar SolfegeExerciseProvider
- [ ] Substituir OptimizedScoreView por VerovioScoreWidget
- [ ] Migrar controles avançados (zoom, layout)
- [ ] Implementar coloração de notas nativa
- [ ] Testar funcionalidades críticas

### 🎵 FASE 3: Otimizações
- [ ] Cache inteligente de partituras
- [ ] Performance profiling
- [ ] Integração com audio analysis
- [ ] Testes de stress

## 🔧 Mudanças Necessárias

### 1. SolfegeExerciseProvider
```dart
// ANTES (OSMD):
import 'package:musilingo/features/practice_solfege/presentation/widgets/optimized_score_view.dart';

// DEPOIS (Verovio):
import 'package:musilingo/services/verovio_service.dart';
import 'package:musilingo/widgets/verovio_score_widget.dart';
```

### 2. Renderização de Partituras
```dart
// ANTES:
Future<void> _generateAndRenderScore() async {
  // Logic with InAppWebViewController
  await _webController.evaluateJavascript(source: 'loadScore(musicXML)');
}

// DEPOIS:
Future<void> _generateAndRenderScore() async {
  final svg = await VerovioService.instance.renderMusicXML(
    musicXML,
    cacheKey: 'exercise_${exercise.id}',
  );
  // SVG renderizado nativamente
}
```

### 3. Coloração de Notas
```dart
// ANTES (JavaScript):
await _webController.evaluateJavascript(
  source: 'window.colorNote($noteIndex, "$color")'
);

// DEPOIS (Nativo):
await VerovioService.instance.colorNote('note-$noteIndex', color);
```

### 4. Controles Avançados
```dart
// ANTES:
window.setZoomLevel(zoomLevel)
window.setDisplayMode(mode)

// DEPOIS:
await VerovioService.instance.setZoomLevel(zoomLevel);
await VerovioService.instance.setPageWidth(width);
```

## 📁 Arquivos Afetados

### Para Atualizar:
- `lib/features/practice_solfege/providers/solfege_exercise_provider.dart`
- `lib/features/practice_solfege/presentation/view/solfege_exercise_screen.dart`
- `lib/features/practice_solfege/presentation/widgets/optimized_score_view.dart` → **REMOVER**

### Novos Arquivos:
- ✅ `lib/services/verovio_service.dart`
- ✅ `lib/widgets/verovio_score_widget.dart`
- ✅ `verovio_flutter/` (plugin completo)

## 🎵 Exemplo de Migração

### SolfegeExerciseScreen - Antes:
```dart
OptimizedScoreView(
  musicXML: state.musicXML,
  onScoreLoaded: _onScoreLoaded,
  height: 300,
  backgroundColor: Colors.transparent,
)
```

### SolfegeExerciseScreen - Depois:
```dart
VerovioScoreWidget(
  musicXML: state.musicXML,
  cacheKey: 'exercise_${state.exercise?.id}',
  onScoreLoaded: _onScoreLoaded,
  zoom: state.zoomLevel,
  enableInteraction: true,
  onNotePressed: _onNotePressed,
)
```

## ⚡ Vantagens da Migração

### Performance:
- ❌ **OSMD**: WebView pesado, JavaScript interpreter
- ✅ **Verovio**: Engine C++ nativo, máxima performance

### Funcionalidades:
- ❌ **OSMD**: Símbolos limitados, bugs de rendering
- ✅ **Verovio**: SMuFL completo, rendering perfeito

### Controle:
- ❌ **OSMD**: API JavaScript limitada
- ✅ **Verovio**: API C++ completa, controle total

### Escalabilidade:
- ❌ **OSMD**: Problemas com múltiplas partituras
- ✅ **Verovio**: Otimizado para múltiplas partituras simultâneas

## 🧪 Testes Necessários

### Funcionais:
- [ ] Renderização básica de MusicXML
- [ ] Coloração de notas individuais
- [ ] Coloração múltipla (feedback de resultados)
- [ ] Zoom e controles de layout
- [ ] Cache de partituras

### Performance:
- [ ] Tempo de renderização vs OSMD
- [ ] Uso de memória
- [ ] Scroll suave
- [ ] Múltiplas partituras simultâneas

### Integração:
- [ ] Compatibilidade com audio analysis
- [ ] Sincronização com MIDI playback
- [ ] Funcionalidade de destaque de notas

## 🚀 Plano de Implementação

### Semana 1: Setup Completo
1. Finalizar plugin FFI com Verovio real
2. Implementar VerovioService completamente funcional
3. Testes básicos de renderização

### Semana 2: Migração do Solfejo
1. Atualizar SolfegeExerciseProvider
2. Migrar SolfegeExerciseScreen
3. Implementar coloração de notas

### Semana 3: Polimento e Otimização
1. Cache inteligente
2. Performance tuning
3. Testes completos
4. Documentação final

## 🎯 Resultado Final

Sistema de solfejo com:
- **Performance nativa máxima**
- **Renderização perfeita de partituras**
- **Controle total da UI**
- **Escalabilidade para futuras features**
- **Zero dependências WebView**

---
*Documento criado para guiar a migração completa do sistema de solfejo para Verovio nativo.*