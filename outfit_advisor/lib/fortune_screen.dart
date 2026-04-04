import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sound_service.dart';

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
  const FortuneScreen({super.key, required this.language});
  final String language;
  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  String _selected = 'gemini';
  bool _loading = false;
  bool _sharing = false;
  Map<String, String>? _fortune;
  String _error = '';
  final _screenshotController = ScreenshotController();

  (String, String, String) get _selectedZodiac =>
      _zodiacs.firstWhere((z) => z.$1 == _selected, orElse: () => _zodiacs[2]);

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
      _fortune = null;
    });
    try {
      final sign = _selectedZodiac.$1;
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final langCode = widget.language.startsWith('zh') ? 'zh' : 'en';

      final row = await Supabase.instance.client
          .from('daily_horoscopes')
          .select('content_json')
          .eq('zodiac_sign', sign)
          .eq('date', today)
          .eq('lang', langCode)
          .single();

      // ignore: avoid_print
      print('🔥 語言: $langCode, 資料: $row');

      final content = row['content_json'];
      if (content is! Map) throw Exception('資料格式錯誤');

      final map = Map<String, String>.fromEntries(
        content.entries.map(
          (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
        ),
      );
      setState(() => _fortune = map);
    } on PostgrestException catch (e) {
      setState(() => _error = e.code == 'PGRST116'
          ? '今日運勢尚未準備好，請稍後再試'
          : '查詢失敗：${e.message}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _shareCard() async {
    setState(() => _sharing = true);
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: _buildShareCardWidget(),
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 200),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              imageBytes,
              mimeType: 'image/png',
              name: 'fortune_card.png',
            ),
          ],
          text: '我的今日星座運勢 🔮 by 星座今日運勢',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失敗：$e'),
            backgroundColor: const Color(0xFF3B1F2B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _buildShareCardWidget() {
    final fortune = _fortune!;
    final zodiac = _selectedZodiac;
    return Container(
      width: 420,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D1B4E), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
                  ),
                ),
                child: const Text(
                  '✦ 今日運勢',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A00)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${zodiac.$3} ${zodiac.$2}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700)),
              ),
              const Spacer(),
              const Text(
                '🔮 星座運勢',
                style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xAAFFD700), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x55FFD700)),
            ),
            child: MarkdownBody(
              data: fortune['overall'] ?? '',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                    fontSize: 14,
                    color: Color(0xE6FFFFFF),
                    height: 1.7),
                strong: const TextStyle(
                    color: Color(0xFFFFE87C),
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ShareInfoTile(label: '🎨 幸運色', value: fortune['luckyColor'] ?? '')),
            const SizedBox(width: 10),
            Expanded(child: _ShareInfoTile(label: '🔢 幸運數字', value: fortune['luckyNumber'] ?? '')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ShareDetailTile(label: '💕 愛情運', text: fortune['love'] ?? '')),
            const SizedBox(width: 8),
            Expanded(child: _ShareDetailTile(label: '💼 事業運', text: fortune['career'] ?? '')),
            const SizedBox(width: 8),
            Expanded(child: _ShareDetailTile(label: '🌿 健康運', text: fortune['health'] ?? '')),
          ]),
        ],
      ),
    );
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
            const SizedBox(height: 12),
            _GradientButton(
              text: _sharing ? '⏳ 準備分享中...' : '📤 分享運勢卡片',
              disabled: _sharing,
              colors: const [
                Color(0xFFB8860B),
                Color(0xFFD4A017),
                Color(0xFFFFD700),
              ],
              onTap: _shareCard,
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

class _ShareInfoTile extends StatelessWidget {
  const _ShareInfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x44FFD700)),
        ),
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xAAFFFFFF))),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFE87C)),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

class _ShareDetailTile extends StatelessWidget {
  const _ShareDetailTile({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x22FFD700)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0x88FFFFFF))),
            const SizedBox(height: 5),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xCCFFFFFF), height: 1.5),
            ),
          ],
        ),
      );
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
        onTap: disabled
            ? null
            : () {
                SoundService.playMagic();
                onTap();
              },
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
