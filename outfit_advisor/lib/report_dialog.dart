import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showReportDialog(
  BuildContext context, {
  required bool isEn,
  required String source,
}) async {
  int? selected;

  const reasonsZh = ['內容不當', '內容錯誤', '其他'];
  const reasonsEn = ['Inappropriate content', 'Incorrect information', 'Other'];

  final confirmed = await showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEn ? '🚩 Report Content' : '🚩 舉報內容',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final label = isEn ? reasonsEn[i] : reasonsZh[i];
            return RadioListTile<int>(
              value: i,
              groupValue: selected,
              onChanged: (v) => setS(() => selected = v),
              title: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              activeColor: const Color(0xFFA78BFA),
              contentPadding: EdgeInsets.zero,
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isEn ? 'Cancel' : '取消',
              style: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          TextButton(
            onPressed: selected == null ? null : () => Navigator.pop(ctx, selected),
            child: Text(
              isEn ? 'Submit' : '確認',
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (confirmed == null || !context.mounted) return;

  final reason = isEn ? reasonsEn[confirmed] : reasonsZh[confirmed];

  try {
    await Supabase.instance.client.from('reports').insert({
      'source': source,
      'reason': reason,
      'lang': isEn ? 'en' : 'zh',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Thank you for your report!' : '感謝您的回報！'),
          backgroundColor: const Color(0xFF2D1B4E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Report failed, please try again' : '舉報失敗，請稍後再試'),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
