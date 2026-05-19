import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/question_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class HomeView extends StatefulWidget {
  final LocalStorageService storage;
  final Function(QuizCategory, Chapter?, String?, bool) onStartQuiz;

  const HomeView({
    Key? key,
    required this.storage,
    required this.onStartQuiz,
  }) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QuizCategory> _categories = [];
  bool _isLoading = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  void _loadLocalData() {
    final String? localJSON = widget.storage.getLicenseKey() != null
        ? null // Load fresh or check storage
        : null;
    
    // Attempt parsing from cached storage
    try {
      final cachedStr = widget.storage.getFavorites(); // Or custom cached quiz config
      // Usually loaded dynamically from cloud or pre-seeded assets
    } catch (_) {}
    
    _syncCategories(silent: true);
  }

  Future<void> _syncCategories({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _syncMessage = null;
      });
    }

    try {
      final QuerySnapshot querySnap = await _firestore.collection('manifests').get();
      final List<QuizCategory> loaded = [];

      for (var doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['data'] != null) {
          try {
            final Map<String, dynamic> parsedJSON = json.decode(data['data']);
            loaded.add(QuizCategory.fromMap(parsedJSON, doc.id));
          } catch (e) {
            print("Error decoding manifest content: $e");
          }
        }
      }

      if (loaded.isNotEmpty) {
        setState(() {
          _categories = loaded;
          if (!silent) _syncMessage = "تم تحديث البيانات بنجاح 💫";
        });
      } else {
        if (!silent) _syncMessage = "لم يتم العثور على أي ملفات تعريف";
      }
    } catch (e) {
      if (!silent) _syncMessage = "عذراً فشل الاتصال بالخادم لمزامنة الأسئلة";
      print("Sync error: $e");
    } finally {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _syncMessage = null;
            });
          }
        });
      }
    }
  }

  void _showCategoryOptions(QuizCategory category) {
    final isDark = widget.storage.isDarkMode();
    final primaryColor = const Color(0xFF626F47);

    // Extract all unique years from category questions
    final Set<String> yearsSet = {};
    for (var q in category.questions) {
      if (q.year != null && q.year!.isNotEmpty) {
        yearsSet.add(q.year!);
      }
    }
    final List<String> sortedYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.black,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر نمط البدء: فصول مخصصة، دورات سنوية كاملة أو اختبار عشوائي سريع',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Quiz Action Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(LucideIcons.zap, size: 20),
                      label: const Text(
                        'اختبار سريع عشوائي (10 أسئلة) ⚡',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.black, fontSize: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onStartQuiz(category, null, null, true);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Chapters Section
                    if (category.chapters != null && category.chapters!.isNotEmpty) ...[
                      Text(
                        '📁 الفصول والأقسام (${category.chapters!.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.black,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: category.chapters!.length,
                        itemBuilder: (context, index) {
                          final ch = category.chapters![index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.pop(context);
                                widget.onStartQuiz(category, ch, null, false);
                              },
                              title: Text(
                                ch.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                              ),
                              subtitle: Text(
                                '${ch.questions.length} سؤال متاح للتدريب',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Years Section
                    if (sortedYears.isNotEmpty) ...[
                      Text(
                        '🗓️ أسئلة الدورات كاملة حسب السنوات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.black,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: sortedYears.length,
                        itemBuilder: (context, index) {
                          final yr = sortedYears[index];
                          final count = category.questions.where((q) => q.year == yr).length;

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onStartQuiz(category, null, yr, false);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    yr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.black,
                                      fontSize: 14,
                                      color: isDark ? Colors.orange.shade300 : primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '$count س',
                                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();
    final primaryColor = const Color(0xFF626F47);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _syncCategories(silent: true),
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Cloud Sync Banner & Streak info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أرشيف الأسئلة والأقسام',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.black,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: Icon(Icons.sync_rounded, color: primaryColor),
                          onPressed: () => _syncCategories(),
                        ),
                ],
              ),
              if (_syncMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    _syncMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.green.shade300 : primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Categories Grid
              Expanded(
                child: _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.packageOpen, size: 48, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد تصنيفات حالية. اسحب الشاشة للأسفل أو اضغط مزامنة للتحديث 💫',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Card(
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                            child: InkWell(
                              onTap: () => _showCategoryOptions(cat),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        cat.isAI ? LucideIcons.gemini : LucideIcons.bookOpen,
                                        color: primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.black,
                                        fontFamily: 'Cairo',
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${cat.questions.length} سؤال',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 80), // Padding to spare space for bottom bar
            ],
          ),
        ),
      ),
    );
  }
}
