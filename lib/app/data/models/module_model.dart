import 'package:musilingo/app/data/models/lesson_model.dart';

class Module {
  final int id;
  final String title;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory Module.fromMap(Map<String, dynamic> map) {
    // Pega a lista de lições do mapa e a converte em objetos Lesson
    final lessonsData = map['lessons'] as List<dynamic>? ?? [];
    final lessons = lessonsData
        .map((lessonMap) => Lesson.fromMap(lessonMap as Map<String, dynamic>))
        .toList();

    return Module(
      id: map['id'],
      title: map['title'],
      lessons: lessons,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
    };
  }
}