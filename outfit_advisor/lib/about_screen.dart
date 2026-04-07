import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.language});
  final String language;

  bool get _isEn => language == 'en';

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(
        'https://outfit-advisor-xi.vercel.app/privacy-policy.html');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEn
                ? 'Could not open the link'
                : '無法開啟連結'),
            backgroundColor: const Color(0xFF2D1B4E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // App icon & name
          const Text('🔮', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            _isEn ? 'Zodiac Advisor' : '星座顧問',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _isEn ? 'Zodiac Advisor' : 'Zodiac Advisor',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Text(
              'v1.0.0',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 32),

          // Disclaimer
          _SectionCard(
            icon: '⚠️',
            title: _isEn ? 'Disclaimer' : '免責聲明',
            child: Text(
              _isEn
                  ? 'The content in this App is AI-generated and for entertainment purposes only. It does not represent any professional advice.'
                  : '本 App 內容由 AI 生成，僅供娛樂參考，不代表任何專業建議。',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.65),
            ),
          ),

          const SizedBox(height: 14),

          // Privacy policy
          _SectionCard(
            icon: '🔒',
            title: _isEn ? 'Privacy Policy' : '隱私權政策',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEn
                      ? 'We respect your privacy. Tap below to view our full privacy policy.'
                      : '我們尊重您的隱私。點擊下方查看完整隱私權政策。',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.65),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openPrivacyPolicy(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔗',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          _isEn
                              ? 'View Privacy Policy'
                              : '查看隱私權政策',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Third-party services
          _SectionCard(
            icon: '🛠️',
            title: _isEn ? 'Powered By' : '技術支援',
            child: Column(
              children: [
                _ServiceRow(name: 'Groq AI', desc: _isEn ? 'Outfit generation' : '穿搭建議生成'),
                _ServiceRow(name: 'Supabase', desc: _isEn ? 'Horoscope data' : '星座運勢資料'),
                _ServiceRow(name: 'Google AdMob', desc: _isEn ? 'Advertising' : '廣告服務'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Copyright
          Text(
            '© 2026 星座顧問. All rights reserved.',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.35)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon,
      required this.title,
      required this.child});
  final String icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.name, required this.desc});
  final String name;
  final String desc;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(
            name,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC4B5FD)),
          ),
          const SizedBox(width: 8),
          Text(
            '·  $desc',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5)),
          ),
        ]),
      );
}
