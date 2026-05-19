import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/local_storage_service.dart';
import '../models/question_model.dart';
import 'home_view.dart';
import 'search_view.dart';
import 'favorites_view.dart';
import 'quiz_view.dart';

class MainNavigationShell extends StatefulWidget {
  final LocalStorageService storage;
  const MainNavigationShell({Key? key, required this.storage}) : super(key: key);

  @override
  _MainNavigationShellState createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  int _streakCount = 0;

  // Active Quiz State controllers
  bool _isQuizActive = false;
  QuizCategory? _activeCategory;
  Chapter? _activeChapter;
  String? _activeYear;
  bool _activeIsQuickQuiz = false;

  // Shared loaded categories
  List<QuizCategory> _cachedCategoriesList = [];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.storage.isDarkMode();
    _streakCount = widget.storage.getStreakCount();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showStreakSnackbar() {
    setState(() {
      _streakCount = widget.storage.getStreakCount();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سلسلة دراسة متواصلة لـ $_streakCount أيام! ✨',
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startQuizSession(QuizCategory category, Chapter? chapter, String? year, bool isQuick) {
    setState(() {
      _activeCategory = category;
      _activeChapter = chapter;
      _activeYear = year;
      _activeIsQuickQuiz = isQuick;
      _isQuizActive = true;
    });
  }

  void _exitQuizSession() {
    setState(() {
      _isQuizActive = false;
      _activeCategory = null;
      _activeChapter = null;
      _activeYear = null;
      _currentIndex = 0; // Return to dashboard
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF626F47);
    final Color darkBackground = const Color(0xFF121212);
    final Color lightBackground = const Color(0xFFF9F6EE);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: _isDarkMode
            ? ThemeData.dark().copyWith(
                primaryColor: primaryColor,
                scaffoldBackgroundColor: darkBackground,
                colorScheme: ColorScheme.dark(
                  primary: primaryColor,
                  background: darkBackground,
                ),
              )
            : ThemeData.light().copyWith(
                primaryColor: primaryColor,
                scaffoldBackgroundColor: lightBackground,
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  background: lightBackground,
                ),
              ),
        child: _isQuizActive && _activeCategory != null
            ? QuizView(
                category: _activeCategory!,
                chapter: _activeChapter,
                selectedYear: _activeYear,
                isQuickQuiz: _activeIsQuickQuiz,
                storage: widget.storage,
                onFinish: _exitQuizSession,
              )
            : Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأرشيف الكامل',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white60 : Colors.grey,
                          letterSpacing: 1.1,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'دورات الوطني',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.black,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                        color: _isDarkMode ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                          widget.storage.setDarkMode(_isDarkMode);
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: IndexedStack(
                  index: _currentIndex,
                  children: [
                    HomeView(
                      storage: widget.storage,
                      onStartQuiz: (cat, ch, year, isQuick) {
                        // Gather list of categories to pass to secondary tabs (Search/Favorites)
                        setState(() {
                          _startQuizSession(cat, ch, year, isQuick);
                        });
                      },
                    ),
                    SearchView(
                      storage: widget.storage,
                      categories: _cachedCategoriesList,
                    ),
                    _buildStreakTab(),
                    FavoritesView(
                      storage: widget.storage,
                      categories: _cachedCategoriesList,
                    ),
                  ],
                ),
                
                bottomNavigationBar: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomNavItem(
                          index: 0,
                          icon: LucideIcons.layoutGrid,
                          label: 'الرئيسية',
                          isActive: _currentIndex == 0,
                        ),
                        _buildBottomNavItem(
                          index: 1,
                          icon: LucideIcons.search,
                          label: 'البحث',
                          isActive: _currentIndex == 1,
                        ),
                        _buildBottomNavItem(
                          index: 2,
                          icon: LucideIcons.flame,
                          label: 'السلسلة ($_streakCount)',
                          isActive: _currentIndex == 2,
                          isStreak: true,
                          onTap: () {
                            _showStreakSnackbar();
                            _onTabSelected(2);
                          },
                        ),
                        _buildBottomNavItem(
                          index: 3,
                          icon: LucideIcons.heart,
                          label: 'المفضلة',
                          isActive: _currentIndex == 3,
                          isFavorite: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStreakTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.flame, size: 80, color: const Color(0xFF626F47)),
            const SizedBox(height: 16),
            Text(
              'سلسلة المتفوقين',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.black, fontFamily: 'Cairo', color: _isDarkMode ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'لديك سلسلة تواصل دراسي بمقدار $_streakCount أيام متتالية! استمر بالتدرب يومياً لحفظ تميزك وضمان النجاح.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    bool isStreak = false,
    bool isFavorite = false,
    VoidCallback? onTap,
  }) {
    final Color activeColor = const Color(0xFF626F47);
    final Color inactiveColor = _isDarkMode ? Colors.white60 : Colors.grey;

    Color iconColor = isActive ? activeColor : inactiveColor;
    if (isStreak && _streakCount > 0) {
      iconColor = activeColor;
    }
    if (isFavorite && widget.storage.getFavorites().isNotEmpty) {
      iconColor = Colors.redAccent;
    }

    return GestureDetector(
      onTap: onTap ?? () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              if (isFavorite && widget.storage.getFavorites().isNotEmpty)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${widget.storage.getFavorites().length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.black : FontWeight.bold,
              color: iconColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
