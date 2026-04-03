import 'package:flutter/material.dart';
import 'fortune_screen.dart';
import 'outfit_screen.dart';

void main() => runApp(const OutfitAdvisorApp());

class OutfitAdvisorApp extends StatelessWidget {
  const OutfitAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '星座穿搭顧問',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
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

  static const _pages = [
    FortuneScreen(),
    OutfitScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: _pages[_tab]),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFFA78BFA),
            unselectedItemColor: Colors.white38,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Text('🔮', style: TextStyle(fontSize: 22)), label: '星座運勢'),
              BottomNavigationBarItem(
                  icon: Text('✨', style: TextStyle(fontSize: 22)), label: '穿搭建議'),
            ],
          ),
        ),
      ),
    );
  }
}
