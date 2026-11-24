import 'package:http/http.dart' as http;

class SyncService {
  final String baseUrl;
  SyncService({this.baseUrl = 'http://localhost:8080'});

  Future<String?> pull(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/vault/$userId'));
    if (res.statusCode == 200) return res.body;
    return null;
  }

  Future<void> push(String userId, String blob) async {
    await http.post(Uri.parse('$baseUrl/api/vault/$userId'), body: blob);
  }
}