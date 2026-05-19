import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswer;
  final String? explanation;
  final String? year;
  final String? categoryId;
  final String? chapterId;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.year,
    this.categoryId,
    this.chapterId,
  });

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    return Question(
      id: id,
      text: map['text'] as String? ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] as int? ?? 0,
      explanation: map['explanation'] as String?,
      year: map['year']?.toString(),
      categoryId: map['categoryId'] as String?,
      chapterId: map['chapterId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'year': year,
      'categoryId': categoryId,
      'chapterId': chapterId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        text,
        options,
        correctAnswer,
        explanation,
        year,
        categoryId,
        chapterId,
      ];
}

class Chapter extends Equatable {
  final String id;
  final String name;
  final List<Question> questions;
  final List<String> summaryImages;

  const Chapter({
    required this.id,
    required this.name,
    required this.questions,
    this.summaryImages = const [],
  });

  factory Chapter.fromMap(Map<String, dynamic> map, String id) {
    var rawQuestions = map['questions'] as List? ?? [];
    List<Question> parsedQuestions = rawQuestions.map((q) {
      if (q is Map<String, dynamic>) {
        return Question.fromMap(q, q['id']?.toString() ?? '');
      }
      return Question.fromMap(Map<String, dynamic>.from(q), '');
    }).toList();

    return Chapter(
      id: id,
      name: map['name'] as String? ?? '',
      questions: parsedQuestions,
      summaryImages: List<String>.from(map['summaryImages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'questions': questions.map((q) => q.toMap()).toList(),
      'summaryImages': summaryImages,
    };
  }

  @override
  List<Object?> get props => [id, name, questions, summaryImages];
}

class QuizCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final List<Question> questions;
  final List<Chapter>? chapters;
  final bool isAI;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.questions,
    this.chapters,
    this.isAI = false,
  });

  factory QuizCategory.fromMap(Map<String, dynamic> map, String id) {
    var rawQuestions = map['questions'] as List? ?? [];
    List<Question> parsedQuestions = rawQuestions.map((q) {
      return Question.fromMap(Map<String, dynamic>.from(q), q['id']?.toString() ?? '');
    }).toList();

    var rawChapters = map['chapters'] as List?;
    List<Chapter>? parsedChapters = rawChapters?.map((c) {
      return Chapter.fromMap(Map<String, dynamic>.from(c), c['id']?.toString() ?? '');
    }).toList();

    return QuizCategory(
      id: id,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? 'help',
      questions: parsedQuestions,
      chapters: parsedChapters,
      isAI: map['isAI'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'questions': questions.map((q) => q.toMap()).toList(),
      'chapters': chapters?.map((c) => c.toMap()).toList(),
      'isAI': isAI,
    };
  }

  @override
  List<Object?> get props => [id, name, icon, questions, chapters, isAI];
}
