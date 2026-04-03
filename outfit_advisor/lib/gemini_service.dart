import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiUrl =
      'https://outfit-advisor-xi.vercel.app/api/gemini';

  static Future<String> ask(String prompt) async {
    final res = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );
    if (res.statusCode != 200) {
      String err;
      try {
        err = (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String? ?? 'HTTP ${res.statusCode}';
      } catch (_) {
        err = 'HTTP ${res.statusCode}';
      }
      throw Exception(err);
    }
    String text;
    try {
      text = (jsonDecode(res.body) as Map<String, dynamic>)['text'] as String? ?? '';
    } catch (_) {
      throw Exception('回傳格式錯誤');
    }
    if (text.isEmpty) throw Exception('AI 沒有回傳內容');
    return text;
  }
}
