import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'gemini_service.dart';

const _occasions = [
  ('casual', '日常休閒', '👕'),
  ('formal', '正式會議', '💼'),
  ('date',   '約會晚宴', '🌹'),
];

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});
  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  String _occasion = 'casual';
  final _controller = TextEditingController();
  final _screenshotController = ScreenshotController();
  bool _loading = false;
  bool _sharing = false;
  String _result = '';
  String _resultOccasion = '';
  String _error = '';

  (String, String, String) get _currentOccasion =>
      _occasions.firstWhere((o) => o.$1 == _occasion,
          orElse: () => _occasions.first);

  Future<void> _fetch() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = '請填寫您的個人資料！');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
      _result = '';
    });
    try {
      final label = _currentOccasion.$2;
      final prompt =
          '你是一位專業時尚穿搭顧問。請針對「$label」場合提供建議。\n'
          '使用者資料：$input\n'
          '請以繁體中文清楚列出：1.整體風格概述 2.上衣建議 3.下身建議 '
          '4.鞋款建議 5.配件搭配 6.造型小技巧。請詳細說明搭配原因，讓造型具備層次感。';
      final text = await GeminiService.ask(prompt);
      setState(() {
        _result = text;
        _resultOccasion = label;
      });
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
              name: 'outfit_card.png',
            ),
          ],
          text: '我的穿搭建議 ✨ by 星座穿搭顧問',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失敗：$e'),
            backgroundColor: const Color(0xFF3B1F6B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _buildShareCardWidget() {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                  ),
                ),
                child: const Text(
                  '✦ 穿搭建議',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '場合：$_resultOccasion',
                style: const TextStyle(
                    fontSize: 13, color: Color(0x99FFFFFF)),
              ),
              const Spacer(),
              const Text(
                '✨ 星座穿搭顧問',
                style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x667C3AED), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x4DA78BFA)),
            ),
            child: MarkdownBody(
              data: _result,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                    fontSize: 13,
                    color: Color(0xE6FFFFFF),
                    height: 1.7),
                strong: const TextStyle(
                    color: Color(0xFFE2D9FF),
                    fontWeight: FontWeight.w700),
                h1: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                h2: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                h3: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                listBullet: const TextStyle(
                    fontSize: 13, color: Color(0xE6FFFFFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            '✨ 星座穿搭顧問',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '告訴我你的身高、體重、性別、星座、幸運色、喜好顏色，讓 我 幫你搭配！',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),

          _sectionLabel('選擇場合'),
          Row(
            children: _occasions.map((o) {
              final active = o.$1 == _occasion;
              final isLast = o.$1 == _occasions.last.$1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _occasion = o.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? const Color(0xFFA78BFA)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                        gradient: active
                            ? const LinearGradient(
                                colors: [
                                  Color(0x668B5CF6),
                                  Color(0x55EC4899)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: active
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        children: [
                          Text(o.$3,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            o.$2,
                            style: TextStyle(
                              fontSize: 13,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _sectionLabel('個人資料'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText:
                    '例如：身高:174.5cm，體重:70kg，性別:男，星座:雙魚座，幸運色:天藍色，喜歡深色系，體型偏瘦...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _GradientButton(
            text: _loading ? '⏳ 正在為你穿搭中...' : '💫 幫我穿搭',
            disabled: _loading,
            colors: const [
              Color(0xFF7C3AED),
              Color(0xFF9333EA),
              Color(0xFFC026D3),
            ],
            onTap: _fetch,
          ),

          if (_loading) ...[
            const SizedBox(height: 28),
            const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFA78BFA)),
            ),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: _error),
          ],
          if (_result.isNotEmpty && !_loading) ...[
            const SizedBox(height: 24),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFC026D3)]),
                ),
                child: const Text(
                  '✦ 穿搭建議',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '場合：$_resultOccasion',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5)),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x4DA78BFA)),
              ),
              child: MarkdownBody(
                data: _result,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.8),
                  strong: const TextStyle(
                      color: Color(0xFFE2D9FF),
                      fontWeight: FontWeight.w700),
                  h1: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  h2: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  h3: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  listBullet: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _GradientButton(
              text: _sharing ? '⏳ 準備分享中...' : '📤 分享穿搭卡片',
              disabled: _sharing,
              colors: const [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
                Color(0xFFA855F7),
              ],
              onTap: _shareCard,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
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
