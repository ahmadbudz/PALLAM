import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiToken = '';
  // option A — the new standard path
static const String _apiUrl =
  'https://zayxnm9altzenl35.us-east4.gcp.endpoints.huggingface.cloud'
  '/generate';


  Future<String> getResponse(String userMessage) async {
    print('Posting to → $_apiUrl');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
    };

    final payload = {
      'inputs': userMessage,
      'parameters': {
        'max_length': 512,
        'temperature': 0.2,
        'top_p': 0.99,
        'repetition_penalty': 1.2,
        'do_sample': true,
        'num_return_sequences': 1,
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
