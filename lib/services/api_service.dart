import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_word.dart';

class ApiService {
  static const _base = 'https://api.wisdomedu.uz/api';

  Future<List<ApiSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final url = Uri.parse(
        '$_base/catalogue/search?page=1&per_page=30&search=${Uri.encodeComponent(query)}&order=asc&short=1&type=en');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'] as List<dynamic>? ?? json as List<dynamic>? ?? [];
      return data.map((e) => ApiSearchResult.fromJson(e)).toList();
    }
    return [];
  }

  Future<ApiWordDetail?> getDetail(int id) async {
    final url = Uri.parse('$_base/word/$id');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ApiWordDetail.fromJson(jsonDecode(res.body));
    }
    return null;
  }
}
