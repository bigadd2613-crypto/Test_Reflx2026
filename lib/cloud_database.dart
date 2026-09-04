import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudDatabase {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Map<String, String> get _headers => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
  };

  static Uri _table(String table, [Map<String, String>? query]) {
    final base = '$_url/rest/v1/$table';
    return Uri.parse(base).replace(queryParameters: query);
  }

  static Future<List<Map<String, dynamic>>> select(String table) async {
    final response = await http.get(
      _table(table, {'select': '*'}),
      headers: _headers,
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    return (decoded as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> upsert(
    String table,
    Map<String, dynamic> values, {
    required String onConflict,
  }) async {
    final response = await http.post(
      _table(table, {'on_conflict': onConflict}),
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode(values),
    );
    _ensureSuccess(response);
  }

  static Future<void> insert(String table, Map<String, dynamic> values) async {
    final response = await http.post(
      _table(table),
      headers: {..._headers, 'Prefer': 'return=minimal'},
      body: jsonEncode(values),
    );
    _ensureSuccess(response);
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cloud database error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
