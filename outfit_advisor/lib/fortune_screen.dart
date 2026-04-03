import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'gemini_service.dart';

const _zodiacs = [
  ('aries',       '牡羊座', '♈'),
  ('taurus',      '金牛座', '♉'),
  ('gemini',      '雙子座', '♊'),
  ('cancer',      '巨蟹座', '♋'),
  ('leo',         '獅子座', '♌'),
  ('virgo',       '處女座', '♍'),
  ('libra',       '天秤座', '♎'),
  ('scorpio',     '天蠍座', '♏'),
  ('sagittarius', '射手座', '♐'),
  ('capricorn',   '摩羯座', '♑'),
  ('aquarius',    '水瓶座', '♒'),
  ('pisces',      '雙魚座', '♓'),
];

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});
  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  String _selected = 'gemini';
  bool _loading = false;
  Map<String, String>? _fortune;
  String _error = '';

  (String, String, String) get _selectedZodiac =>
      _zodiacs.firstWhere((z) => z.$1 == _selected, orElse: () => _zodiacs[2]);

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
      _fortune = null;
    });
    try {
      final label = _selectedZodiac.$2;
      final prompt =
          '你是一位專業星座運勢占卜師。請為「$label」提供今日運勢，'
          '並嚴格以下方 JSON 格式回傳，不要加任何多餘文字或 markdown：\n'
          '{"overall":"今日運勢總評（2-3句）","luckyColor":"幸運色",'
          '"luckyNumber":"幸運數字","love":"愛情運（1-2句）",'
          '"career":"事業運（1-2句）","health":"健康運（1-2句）"}';

      final raw = await GeminiService.ask(prompt);
      final clean = raw
          .replaceAll(RegExp(r'```json'), '')
          .replaceAll(RegExp(r'```'), '')
          .trim();

      final decoded = jsonDecode(clean);
      if (decoded is! Map) throw Exception('AI 回傳格式錯誤');

      final map = Map<String, String>.fromEntries(
        decoded.entries.map(
          (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
        ),
      );
      setState(() => _fortune = map);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            '🔮 星座今日運勢',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '選擇你的星座，讓我解讀今日運勢',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: _zodiacs.map((z) {
              final active = z.$1 == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = z.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF818CF8)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                    gradient: active
                        ? const LinearGradient(
                            colors: [Color(0x664F46E5), Color(0x55A855F7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: active
                        ? null
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(z.$3, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        z.$2,
                        style: TextStyle(
                          fontSize: 11,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _GradientButton(
            text: _loading ? '⏳ 正在解讀星象中...' : '🌟 查看今日運勢',
            disabled: _loading,
            colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFA855F7)],
            onTap: _fetch,
          ),

          if (_loading) ...[
            const SizedBox(height: 28),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFA78BFA)),
            ),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: _error),
          ],
          if (_fortune != null && !_loading) ...[
            const SizedBox(height: 24),
            _FortuneResult(
              fortune: _fortune!,
              label: _selectedZodiac.$2,
              emoji: _selectedZodiac.$3,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FortuneResult extends StatelessWidget {
  const _FortuneResult({
    required this.fortune,
    required this.label,
    required this.emoji,
  });
  final Map<String, String> fortune;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFFA855F7)]),
            ),
            child: const Text(
              '✦ 今日運勢',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$emoji $label',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
          ),
        ]),
        const SizedBox(height: 12),

        _GlassCard(
          color: const Color(0x1A6366F1),
          borderColor: const Color(0x408181F8),
          child: MarkdownBody(
            data: fortune['overall'] ?? '',
            styleSheet: _mdStyle(),
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(
              child: _InfoCard(
                  label: '🎨 幸運色', value: fortune['luckyColor'] ?? '')),
          const SizedBox(width: 10),
          Expanded(
              child: _InfoCard(
                  label: '🔢 幸運數字', value: fortune['luckyNumber'] ?? '')),
        ]),
        const SizedBox(height: 10),

        Row(children: [
          Expanded(
              child: _DetailCard(
                  label: '💕 愛情運', text: fortune['love'] ?? '')),
          const SizedBox(width: 8),
          Expanded(
              child: _DetailCard(
                  label: '💼 事業運', text: fortune['career'] ?? '')),
          const SizedBox(width: 8),
          Expanded(
              child: _DetailCard(
                  label: '🌿 健康運', text: fortune['health'] ?? '')),
        ]),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => _GlassCard(
        color: Colors.white.withValues(alpha: 0.04),
        borderColor: Colors.white.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            MarkdownBody(data: text, styleSheet: _mdStyle(fontSize: 12)),
          ],
        ),
      );
}

MarkdownStyleSheet _mdStyle({double fontSize = 14}) => MarkdownStyleSheet(
      p: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withValues(alpha: 0.88),
          height: 1.6),
      strong: const TextStyle(
          color: Color(0xFFE2D9FF), fontWeight: FontWeight.w700),
      h3: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
    );

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.color, this.borderColor});
  final Widget child;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.1)),
        ),
        child: child,
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Text(
          '⚠️ $message',
          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 14),
        ),
      );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.onTap,
    required this.colors,
    this.disabled = false,
  });
  final String text;
  final VoidCallback onTap;
  final List<Color> colors;
  final bool disabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                    color: colors.first.withValues(alpha: 0.35),
                    blurRadius: 20),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      );
}
