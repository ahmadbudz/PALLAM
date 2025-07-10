import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiToken = '';
static const String _apiUrl =
  'https://zayxnm9altzenl35.us-east4.gcp.endpoints.huggingface.cloud'
  '/generate';

static const String _systemPrompt = '''
أنت باحث وخبير في التاريخ والجغرافيا الفلسطينية.
مهمتك أن تقدِّم شروحًا دقيقة وموثوقة حول جغرافية فلسطين الطبيعية (التضاريس، الأقاليم المناخية، الموارد) وتاريخها المتعدِّد الطبقات (العصور القديمة، الوسطى، الحديثة، والمعاصرة).
ابدأ كل إجابة بتأكيد فهمك لِـمراد السائل، واسأل أسئلة توضيحية موجزة فقط عند الضرورة.
فكِّر بخطوات متسلسلة عند معالجة الموضوعات المعقَّدة، مبرزًا التواريخ والأماكن والمنعطفات الرئيسة.
استشهد بالمصادر الأولية أو بالدراسات الأكاديمية الموثوقة عند الحاجة.
عند وجود خلاف تاريخي أو جغرافي، اعرض الآراء الرئيسة بحياد مع الإشارة إلى مصادرها.
توقَّع الأسئلة اللاحقة المفيدة (مثل الجداول الزمنية، الخرائط، التحولات الديموغرافية) واقترحها استباقيًا.
احرص على الدقة والعمق والوضوح، وعدِّل مستوى التفصيل ونبرة الخطاب بما يناسب خلفية المستخدم.
قدِّم الحقائق بسياقها، وتجنَّب الاستطرادات غير الضرورية.
''';

  Future<String> getResponse(String userMessage) async {
    final instPrompt = '<s>[INST] <<SYS>>\n$_systemPrompt\n<</SYS>>\n'
                     '$userMessage [/INST]';
    print('Posting to → $_apiUrl');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
    };

    final payload = {
      'inputs': instPrompt,
      'parameters': {
        'max_new_tokens': 1024,
        'temperature': 0.1,
        'top_p': 0.99,
        'do_sample': false,
        'num_return_sequences': 1,
        'stop': ['</s>'] 
      },
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    String text;
    if (decoded is List && decoded.isNotEmpty && decoded[0]['generated_text'] != null) {
      text = decoded[0]['generated_text'];
    } else if (decoded is Map && decoded['generated_text'] != null) {
      text = decoded['generated_text'];
    } else {
      text = decoded.toString();
    }

    return text.trim();
  }
}
