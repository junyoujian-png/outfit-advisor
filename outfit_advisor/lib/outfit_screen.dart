import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'gemini_service.dart';
import 'sound_service.dart';

// (id, zhName, enName, emoji)
const _occasions = [
  ('casual', '日常休閒', 'Casual',     '👕'),
  ('formal', '正式會議', 'Formal',     '💼'),
  ('date',   '約會晚宴', 'Date Night', '🌹'),
];

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key, required this.language});
  final String language;
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

  bool get _isEn => widget.language == 'en';

  // (id, zhName, enName, emoji)
  (String, String, String, String) get _currentOccasion =>
      _occasions.firstWhere((o) => o.$1 == _occasion,
          orElse: () => _occasions.first);

  Future<void> _fetch() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = _isEn
          ? 'Please fill in your personal details!'
          : '請填寫您的個人資料！');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
      _result = '';
    });
    try {
      final occasionLabel =
          _isEn ? _currentOccasion.$3 : _currentOccasion.$2;
      final String prompt;
      if (_isEn) {
        prompt =
            'You are a professional fashion stylist. Please provide outfit suggestions for a "$occasionLabel" occasion.\n'
            'User profile: $input\n'
            'Please clearly list in English: 1. Overall style overview 2. Top suggestions 3. Bottom suggestions '
            '4. Footwear suggestions 5. Accessory pairing 6. Styling tips. '
            'Please explain the reasons for each suggestion in detail to create a layered look.';
      } else {
        prompt =
            '你是一位專業時尚穿搭顧問。請針對「$occasionLabel」場合提供建議。\n'
            '使用者資料：$input\n'
            '請以繁體中文清楚列出：1.整體風格概述 2.上衣建議 3.下身建議 '
            '4.鞋款建議 5.配件搭配 6.造型小技巧。請詳細說明搭配原因，讓造型具備層次感。';
      }
      final text = await GeminiService.ask(prompt);
      setState(() {
        _result = text;
        _resultOccasion = occasionLabel;
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
          text: _isEn
              ? 'My Outfit Suggestions ✨ by Horoscope Advisor'
              : '我的穿搭建議 ✨ by 星座穿搭顧問',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEn ? 'Share failed: $e' : '分享失敗：$e'),
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
                child: Text(
                  _isEn ? '✦ Outfit Advice' : '✦ 穿搭建議',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_isEn ? "Occasion" : "場合"}：$_resultOccasion',
                style: const TextStyle(
                    fontSize: 13, color: Color(0x99FFFFFF)),
              ),
              const Spacer(),
              Text(
                _isEn ? '✨ Horoscope Advisor' : '✨ 星座穿搭顧問',
                style: const TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
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
          Text(
            _isEn ? '✨ Outfit Advisor' : '✨ 星座穿搭顧問',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _isEn
                ? 'Tell me your height, weight, gender, zodiac sign, lucky color, and style preferences!'
                : '告訴我你的身高、體重、性別、星座、幸運色、喜好顏色，讓我幫你搭配！',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),

          _sectionLabel(_isEn ? 'Occasion' : '選擇場合'),
          Row(
            children: _occasions.map((o) {
              final active = o.$1 == _occasion;
              final isLast = o.$1 == _occasions.last.$1;
              final displayName = _isEn ? o.$3 : o.$2;
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
                          Text(o.$4,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
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

          _sectionLabel(_isEn ? 'Your Profile' : '個人資料'),
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
                hintText: _isEn
                    ? 'e.g. Height: 174.5cm, Weight: 70kg, Gender: Male, Zodiac: Pisces, Lucky color: Sky blue, Prefer dark tones, Slim build...'
                    : '例如：身高:174.5cm，體重:70kg，性別:男，星座:雙魚座，幸運色:天藍色，喜歡深色系，體型偏瘦...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _GradientButton(
            text: _loading
                ? (_isEn ? '⏳ Styling you...' : '⏳ 正在為你穿搭中...')
                : (_isEn ? '💫 Style Me' : '💫 幫我穿搭'),
            disabled: _loading,
            colors: const [
              Color(0xFF7C3AED),
              Color(0xFF9333EA),
              Color(0xFFC026D3),
            ],
            onTap: _fetch,
          ),
          const SizedBox(height: 12),
          const Center(child: _BannerAdWidget()),

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
                child: Text(
                  _isEn ? '✦ Outfit Advice' : '✦ 穿搭建議',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_isEn ? "Occasion" : "場合"}：$_resultOccasion',
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
              text: _sharing
                  ? (_isEn ? '⏳ Preparing...' : '⏳ 準備分享中...')
                  : (_isEn ? '📤 Share Outfit Card' : '📤 分享穿搭卡片'),
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

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();
  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
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
