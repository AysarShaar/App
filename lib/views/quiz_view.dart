import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../models/question_model.dart';
import '../services/local_storage_service.dart';

class QuizView extends StatefulWidget {
  final QuizCategory category;
  final Chapter? chapter;
  final String? selectedYear;
  final bool isQuickQuiz;
  final LocalStorageService storage;
  final VoidCallback onFinish;

  const QuizView({
    Key? key,
    required this.category,
    this.chapter,
    this.selectedYear,
    required this.isQuickQuiz,
    required this.storage,
    required this.onFinish,
  }) : super(key: key);

  @override
  _QuizViewState createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _finished = false;
  
  // Track selected answer per question. -1 means unanswered, else 0-3
  Map<int, int> _selectedAnswers = {};
  
  // Timer setup
  Timer? _quizTimer;
  int _secondsElapsed = 0;

  // Question local note
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prepareQuestions();
    _startTimer();
  }

  void _prepareQuestions() {
    List<Question> temp = [];
    if (widget.isQuickQuiz) {
      temp = List<Question>.from(widget.category.questions)..shuffle();
      if (temp.length > 10) {
        temp = temp.sublist(0, 10);
      }
    } else if (widget.chapter != null) {
      temp = widget.chapter!.questions;
    } else if (widget.selectedYear != null) {
      temp = widget.category.questions.where((q) => q.year == widget.selectedYear).toList();
    } else {
      temp = widget.category.questions;
    }
    _questions = temp;
    _loadNoteForCurrentQuestion();
  }

  void _startTimer() {
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _loadNoteForCurrentQuestion() {
    if (_questions.isEmpty) return;
    final currentQ = _questions[_currentIndex];
    final notes = widget.storage.getNotes();
    _noteController.text = notes[currentQ.id] ?? '';
  }

  void _saveCurrentNote() {
    if (_questions.isEmpty) return;
    final currentQ = _questions[_currentIndex];
    final notes = widget.storage.getNotes();
    if (_noteController.text.trim().isEmpty) {
      notes.remove(currentQ.id);
    } else {
      notes[currentQ.id] = _noteController.text.trim();
    }
    widget.storage.saveNotes(notes);
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(int optIndex) {
    if (_selectedAnswers.containsKey(_currentIndex)) return; // Already answered this question

    _saveCurrentNote();

    setState(() {
      _selectedAnswers[_currentIndex] = optIndex;
      if (optIndex == _questions[_currentIndex].correctAnswer) {
        _score++;
      }
    });

    // Award streak days if they finished an answer successfully today
    _increaseStreakOnFirstDailyQuiz();
  }

  void _increaseStreakOnFirstDailyQuiz() {
    final now = DateTime.now();
    final dateString = "${now.year}-${now.month}-${now.day}";
    final lastActiveStr = widget.storage.getLastActiveDate();

    if (lastActiveStr != dateString) {
      int currentStreak = widget.storage.getStreakCount();
      if (lastActiveStr == null || 
          now.subtract(const Duration(days: 1)).toIso8601String().startsWith(lastActiveStr)) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
      widget.storage.setStreakCount(currentStreak);
      widget.storage.setLastActiveDate(dateString);
    }
  }

  bool _isAnswered() => _selectedAnswers.containsKey(_currentIndex);

  void _toggleFavorite(Question q) {
    final List<String> favs = List<String>.from(widget.storage.getFavorites());
    if (favs.contains(q.id)) {
      favs.remove(q.id);
    } else {
      favs.add(q.id);
    }
    widget.storage.saveFavorites(favs);
    setState(() {}); // Re-render bookmarks
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  void _nextQuestion() {
    _saveCurrentNote();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadNoteForCurrentQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _saveCurrentNote();
    _quizTimer?.cancel();
    setState(() {
      _finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();
    final primaryColor = const Color(0xFF626F47);

    if (_questions.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('خطأ في البيانات')),
          body: const Center(
            child: Text('عذراً لا توجد أسئلة كافية في هذا القسم التدريبي', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ),
      );
    }

    if (_finished) {
      return _buildResultsView(isDark, primaryColor);
    }

    final currentQuestion = _questions[_currentIndex];
    final bool isFav = widget.storage.getFavorites().contains(currentQuestion.id);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            widget.isQuickQuiz ? 'اختبار سريع' : widget.category.name,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.black, fontSize: 16),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.5),
                child: Text(
                  _formatTime(_secondsElapsed),
                  style: TextStyle(
                    fontWeight: FontWeight.black,
                    fontSize: 15,
                    color: isDark ? Colors.amber : primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator bar (Matches sleek modern design)
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                color: primaryColor,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السؤال رقم ${_currentIndex + 1} من ${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigoAccent),
                  ),
                  
                  // Question actions: Favorite Toggle
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(currentQuestion),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Statement Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04),
                margin: EdgeInsets.zero,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: currentQuestion.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        height: 1.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Options Iterations
              ...List.generate(currentQuestion.options.length, (optIdx) {
                final isSelected = _selectedAnswers[_currentIndex] == optIdx;
                final bool isThisCorrectAns = currentQuestion.correctAnswer == optIdx;
                final bool wasThisSelectedIncorrectly = isSelected && !isThisCorrectAns;
                final bool showCorrectOptionMarker = _isAnswered() && isThisCorrectAns;
                
                Color optionBgColor = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
                Color borderClr = isDark ? Colors.white10 : Colors.grey.shade300;
                Color textClr = isDark ? Colors.white87 : Colors.black87;

                if (_isAnswered()) {
                  if (isSelected && isThisCorrectAns) {
                    optionBgColor = Colors.green.withOpacity(0.15);
                    borderClr = Colors.green;
                    textClr = Colors.green.shade700;
                  } else if (wasThisSelectedIncorrectly) {
                    optionBgColor = Colors.red.withOpacity(0.15);
                    borderClr = Colors.red;
                    textClr = Colors.red.shade700;
                  } else if (showCorrectOptionMarker) {
                    optionBgColor = Colors.green.withOpacity(0.1);
                    borderClr = Colors.green.shade200;
                  }
                } else if (isSelected) {
                  optionBgColor = primaryColor.withOpacity(0.1);
                  borderClr = primaryColor;
                }

                return GestureDetector(
                  onTap: () => _handleOptionSelected(optIdx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: optionBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderClr, width: 2),
                    ),
                    child: Row(
                      children: [
                        // Option Circle Index (أ ، ب ، ج ، د)
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: borderClr.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            ['أ', 'ب', 'ج', 'د'][optIdx],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textClr),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            currentQuestion.options[optIdx],
                            style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textClr, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_isAnswered() && isThisCorrectAns)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (_isAnswered() && wasThisSelectedIncorrectly)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                );
              }),

              // Question Explanation (Appears only after user answer selection)
              if (_isAnswered()) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isDark ? Colors.amber.withOpacity(0.04) : Colors.amber.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'التوضيح العلمي للمسألة:',
                              style: TextStyle(
                                fontWeight: FontWeight.black,
                                fontSize: 14,
                                color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MarkdownBody(
                          data: currentQuestion.explanation ?? 'لا توجد تفاصيل مرفقة حالياً لشرح الإجابة.',
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Save Sticky Note (Equivalent to React bottom interactive notes)
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.stickyNote, size: 16, color: Colors.grey),
                            SizedBox(width: 6),
                            Text('مذكرتي الشخصية عن هذا السؤال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'اكتب ملاحظة مهمة لمراجعتها لاحقاً...',
                            hintStyle: const TextStyle(fontSize: 11, fontFamily: 'Cairo'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(8),
                          ),
                          onChanged: (_) => _saveCurrentNote(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _nextQuestion,
                  child: Text(
                    _currentIndex == _questions.length - 1 ? 'إنهاء وحفظ النتائج 🎉' : 'السؤال التالي ➡️',
                    style: const TextStyle(fontWeight: FontWeight.black, fontFamily: 'Cairo', fontSize: 15),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView(bool isDark, Color primaryColor) {
    final double percent = (_score / _questions.length) * 100;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقرير نهاية الاختبار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.black)),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                percent >= 60 ? 'نجاح متميز! 🌟' : 'حاول مجدداً للتحسين والتفوق 📚',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.black,
                  fontFamily: 'Cairo',
                  color: percent >= 60 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),

              // Score Indicator Big Badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.black, color: primaryColor),
                    ),
                    Text(
                      '$_score إجابة صحيحة من أصل ${_questions.length}',
                      style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'الوقت الإجمالي المستغرق: ${_formatTime(_secondsElapsed)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: widget.onFinish,
                child: const Text('العودة للقائمة الرئيسية 🏠', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
