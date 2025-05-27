import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiToken = ''; //i can't push the access token to github please contact me -Ahmad
  static const String _apiUrl =
      'https://router.huggingface.co/hf-inference/models/meta-llama/Llama-3.1-8B-Instruct/v1/chat/completions';

  Future<String> getResponse(String userMessage) async {
    final headers = {
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "model": "meta-llama/Llama-3.1-8B-Instruct",
      "messages": [
        {
          "role": "user",
          "content": userMessage,
        }
      ]
    });

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);

      final message = decoded["choices"][0]["message"]["content"];
      return message.trim();
    } else {
      throw Exception(
          'Failed to fetch response (${response.statusCode}): ${response.body}');
    }
  }
}
