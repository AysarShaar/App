import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/question_model.dart';
import '../services/local_storage_service.dart';

class FavoritesView extends StatefulWidget {
  final LocalStorageService storage;
  final List<QuizCategory> categories;

  const FavoritesView({
    Key? key,
    required this.storage,
    required this.categories,
  }) : super(key: key);

  @override
  _FavoritesViewState createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  List<Question> _favQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final List<String> savedFavIds = widget.storage.getFavorites();
    final List<Question> temp = [];

    for (var cat in widget.categories) {
      for (var q in cat.questions) {
        if (savedFavIds.contains(q.id)) {
          temp.add(q);
        }
      }
    }

    setState(() {
      _favQuestions = temp;
    });
  }

  void _removeFavorite(Question q) {
    final List<String> favs = List<String>.from(widget.storage.getFavorites());
    favs.remove(q.id);
    widget.storage.saveFavorites(favs);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();
    final primaryColor = const Color(0xFF626F47);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'الأسئلة المفضلة والملاحظات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.black,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _favQuestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.heart, size: 48, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text(
                            'لم تقم بإضافة أي أسئلة للمفضلة بعد',
                            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _favQuestions.length,
                      itemBuilder: (context, index) {
                        final q = _favQuestions[index];
                        final userNote = widget.storage.getNotes()[q.id];

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (q.year != null && q.year!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'دورة ${q.year}',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                                      onPressed: () => _removeFavorite(q),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                MarkdownBody(
                                  data: q.text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  ),
                                ),
                                const Divider(height: 20),
                                // Correct answer preview
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                  title: Text(
                                    'الإجابة الصحيحة: ${q.options[q.correctAnswer]}',
                                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                  ),
                                ),
                                if (userNote != null && userNote.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(LucideIcons.stickyNote, size: 14, color: Colors.amber),
                                            SizedBox(width: 4),
                                            Text(
                                              'ملاحظتي الشخصية:',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'Cairo'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userNote,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
