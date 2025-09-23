import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  final String baseUrl;

  BackendService({required this.baseUrl});

  Future<Map<String, dynamic>> getMetrics() async {
    final response = await http.get(Uri.parse('$baseUrl/metrics'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch metrics');
    }
  }
}
