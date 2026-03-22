import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_word.dart';

class ApiService {
  static const _base = 'https://api.wisdomedu.uz/api';

  // In-memory cache
  final Map<String, List<ApiSearchResult>> _searchCache = {};
  final Map<int, ApiWordDetail> _detailCache = {};

  // Shared HTTP client for connection reuse
  final http.Client _client = http.Client();

  Future<List<ApiSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final cacheKey = q.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) return _searchCache[cacheKey]!;

    try {
      final url = Uri.parse(
          '$_base/catalogue/search?page=1&per_page=50&search=${Uri.encodeComponent(q)}&order=asc&short=1&type=en');
      final res = await _client.get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        List<dynamic> data = [];
        if (json is List) {
          data = json;
        } else if (json is Map && json['data'] is List) {
          data = json['data'];
        }
        final results = data.map((e) => ApiSearchResult.fromJson(e)).toList();
        _searchCache[cacheKey] = results;
        return results;
      }
    } catch (_) {}
    return [];
  }

  Future<ApiWordDetail?> getDetail(int id) async {
    if (_detailCache.containsKey(id)) return _detailCache[id];

    try {
      final url = Uri.parse('$_base/word/$id');
      final res = await _client.get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final detail = ApiWordDetail.fromJson(jsonDecode(res.body));
        _detailCache[id] = detail;
        return detail;
      }
    } catch (_) {}
    return null;
  }

  void dispose() => _client.close();
}
