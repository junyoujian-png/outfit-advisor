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
      final err = jsonDecode(res.body)['error'] ?? 'HTTP ${res.statusCode}';
      throw Exception(err);
    }
    final text = jsonDecode(res.body)['text'] as String?;
    if (text == null || text.isEmpty) throw Exception('AI 沒有回傳內容');
    return text;
  }
}
