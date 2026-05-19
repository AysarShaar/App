import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/question_model.dart';
import '../services/local_storage_service.dart';

class SearchView extends StatefulWidget {
  final LocalStorageService storage;
  final List<QuizCategory> categories;

  const SearchView({
    Key? key,
    required this.storage,
    required this.categories,
  }) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();
  List<Question> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final List<Question> tempResults = [];

    for (var cat in widget.categories) {
      for (var q in cat.questions) {
        // Search text
        final questionMatch = q.text.toLowerCase().contains(lowerCaseQuery);
        // Search year string
        final yearMatch = q.year != null && q.year!.toLowerCase().contains(lowerCaseQuery);
        // Search options strings
        bool optionsMatch = false;
        for (var opt in q.options) {
          if (opt.toLowerCase().contains(lowerCaseQuery)) {
            optionsMatch = true;
            break;
          }
        }

        if (questionMatch || yearMatch || optionsMatch) {
          tempResults.add(q);
        }
      }
    }

    setState(() {
      _searchResults = tempResults;
      _isSearching = true;
    });
  }

  void _toggleFavorite(Question q) {
    final List<String> favs = List<String>.from(widget.storage.getFavorites());
    if (favs.contains(q.id)) {
      favs.remove(q.id);
    } else {
      favs.add(q.id);
    }
    widget.storage.saveFavorites(favs);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();
    final primaryColor = const Color(0xFF626F47);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Search Input Container
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'البحث الذكي عن السنوات أو نصوص الأسئلة الأكاديمية...',
                hintStyle: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                prefixIcon: Icon(LucideIcons.search, color: primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: !_isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.binary, size: 48, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text(
                            'اكتب كلمة أو سنة الدورة للبدء بالبحث الفوري السريع',
                            style: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'عذراً لم نجد أي تطابق لعملية البحث المدخلة',
                            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final q = _searchResults[index];
                            final isFav = widget.storage.getFavorites().contains(q.id);

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
                                              color: Colors.amber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'دورة ${q.year}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                            color: isFav ? Colors.red : Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: () => _toggleFavorite(q),
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
                                    const Divider(height: 24),
                                    ...List.generate(q.options.length, (optIdx) {
                                      final isCorrect = q.correctAnswer == optIdx;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                              color: isCorrect ? Colors.green : Colors.grey,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                q.options[optIdx],
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 12.5,
                                                  fontWeight: isCorrect ? FontWeight.black : FontWeight.normal,
                                                  color: isCorrect ? Colors.green.shade700 : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
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
