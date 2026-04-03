import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiUrl = 'https://outfit-advisor-xi.vercel.app/api/gemini';

  static Future<String> ask(String prompt) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw Exception('網路連線失敗：$e');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('伺服器回傳格式錯誤（HTTP ${res.statusCode}）');
    }

    if (res.statusCode != 200) {
      final err = body['error']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(err);
    }

    final text = body['text']?.toString() ?? '';
    if (text.isEmpty) throw Exception('AI 沒有回傳內容');
    return text;
  }
}
