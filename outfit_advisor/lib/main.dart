import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fortune_screen.dart';
import 'outfit_screen.dart';

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
      runApp(const OutfitAdvisorApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

class OutfitAdvisorApp extends StatelessWidget {
  const OutfitAdvisorApp({super.key});

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
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();
  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isEn = locale == 'en';

    final pages = <Widget>[
      FortuneScreen(language: locale),
      OutfitScreen(language: locale),
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
        child: SafeArea(child: pages[_tab]),
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
