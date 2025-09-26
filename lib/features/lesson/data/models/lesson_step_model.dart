// lib/features/lesson/data/models/lesson_step_model.dart

enum LessonStepType {
  explanation,
  multipleChoice,
  dragAndDrop,
  earTraining,
}

abstract class LessonStep {
  final int id;
  final int lessonId;
  final int stepIndex;
  final LessonStepType type;

  LessonStep({
    required this.id,
    required this.lessonId,
    required this.stepIndex,
    required this.type,
  });

  factory LessonStep.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    final type = LessonStepType.values.firstWhere(
      (e) => e.toString() == 'LessonStepType.$typeString',
      orElse: () => throw 'Tipo de passo desconhecido: $typeString',
    );

    switch (type) {
      case LessonStepType.explanation:
        return ExplanationStep.fromMap(map);
      case LessonStepType.multipleChoice:
        return MultipleChoiceQuestionStep.fromMap(map);
      case LessonStepType.dragAndDrop:
        return DragAndDropStep.fromMap(map);
      case LessonStepType.earTraining:
        return EarTrainingStep.fromMap(map);
    }
  }
}

class ExplanationStep extends LessonStep {
  final String text;
  final String? imageUrl;

  ExplanationStep({
    required super.id,
    required super.lessonId,
    required super.stepIndex,
    required this.text,
    this.imageUrl,
  }) : super(type: LessonStepType.explanation);

  factory ExplanationStep.fromMap(Map<String, dynamic> map) {
    return ExplanationStep(
      id: map['id'],
      lessonId: map['lesson_id'],
      stepIndex: map['step_index'],
      text: map['text'] ?? '',
      imageUrl: map['image_url'],
    );
  }
}

class MultipleChoiceQuestionStep extends LessonStep {
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  MultipleChoiceQuestionStep({
    required super.id,
    required super.lessonId,
    required super.stepIndex,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  }) : super(type: LessonStepType.multipleChoice);

  factory MultipleChoiceQuestionStep.fromMap(Map<String, dynamic> map) {
    return MultipleChoiceQuestionStep(
      id: map['id'],
      lessonId: map['lesson_id'],
      stepIndex: map['step_index'],
      questionText: map['question_text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correct_answer'] ?? '',
    );
  }
}

class DragAndDropStep extends LessonStep {
  final String questionText;
  final List<String> draggableItems;
  final List<String> correctOrder;

  DragAndDropStep({
    required super.id,
    required super.lessonId,
    required super.stepIndex,
    required this.questionText,
    required this.draggableItems,
    required this.correctOrder,
  }) : super(type: LessonStepType.dragAndDrop);

  factory DragAndDropStep.fromMap(Map<String, dynamic> map) {
    return DragAndDropStep(
      id: map['id'],
      lessonId: map['lesson_id'],
      stepIndex: map['step_index'],
      questionText: map['question_text'] ?? '',
      draggableItems: List<String>.from(map['draggable_items'] ?? []),
      correctOrder: List<String>.from(map['correct_order'] ?? []),
    );
  }
}

class EarTrainingStep extends LessonStep {
  final String text;
  final String audioUrl;
  final List<String> options;
  final String correctAnswer;

  EarTrainingStep({
    required super.id,
    required super.lessonId,
    required super.stepIndex,
    required this.text,
    required this.audioUrl,
    required this.options,
    required this.correctAnswer,
  }) : super(type: LessonStepType.earTraining);

  factory EarTrainingStep.fromMap(Map<String, dynamic> map) {
    return EarTrainingStep(
      id: map['id'],
      lessonId: map['lesson_id'],
      stepIndex: map['step_index'],
      text: map['text'] ?? '',
      audioUrl: map['audio_url'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correct_answer'] ?? '',
    );
  }
}
