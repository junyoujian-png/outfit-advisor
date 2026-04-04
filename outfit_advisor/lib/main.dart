import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fortune_screen.dart';
import 'outfit_screen.dart';
import 'language_select_screen.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Supabase.initialize(
        url: 'https://xgqspvqpmvousjkyznal.supabase.co',
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      runApp(OutfitAdvisorApp(initialLanguage: savedLang));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

class OutfitAdvisorApp extends StatelessWidget {
  const OutfitAdvisorApp({super.key, required this.initialLanguage});
  final String? initialLanguage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        final lang = Localizations.localeOf(context).languageCode;
        return lang == 'en' ? 'Horoscope Advisor' : '星座穿搭顧問';
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      initialRoute: initialLanguage == null ? '/language' : '/home',
      onGenerateRoute: (settings) {
        if (settings.name == '/language') {
          return MaterialPageRoute(
            builder: (_) => const LanguageSelectScreen(),
          );
        }
        if (settings.name == '/home') {
          final lang = settings.arguments as String? ?? initialLanguage ?? 'zh';
          return MaterialPageRoute(
            builder: (_) => _HomeShell(language: lang),
          );
        }
        return null;
      },
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.language});
  final String language;
  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tab = 0;
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = widget.language;
  }

  void _openLanguageSelect() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LanguageSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = _language == 'en';

    final pages = <Widget>[
      FortuneScreen(language: _language),
      OutfitScreen(language: _language),
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              pages[_tab],
              Positioned(
                top: 8,
                right: 16,
                child: GestureDetector(
                  onTap: _openLanguageSelect,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEn ? '🇺🇸' : '🇹🇼',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEn ? 'EN' : '中文',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: const Color(0xFF12122A),
          selectedItemColor: const Color(0xFFA78BFA),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Text('🔮', style: TextStyle(fontSize: 22)),
              label: isEn ? 'Horoscope' : '星座運勢',
            ),
            BottomNavigationBarItem(
              icon: const Text('✨', style: TextStyle(fontSize: 22)),
              label: isEn ? 'Outfit' : '穿搭建議',
            ),
          ],
        ),
      ),
    );
  }
}
