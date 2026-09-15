import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';

import '../config/app_config.dart';
import '../storage/storage_service.dart';
import 'api_exception.dart';
import 'mock_api_data.dart';

class ApiClient {
  final ChopperClient _client;
  final StorageService _storage;

  ApiClient({required StorageService storage})
      : _storage = storage,
        _client = ChopperClient(
          baseUrl: Uri.parse(AppConfig.baseUrl),
        );

  Map<String, String> _headers({bool auth = true, bool multipart = false}) {
    final headers = <String, String>{};
    if (!multipart) headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    if (auth) {
      final token = _storage.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? cleanQuery;
    if (query != null && query.isNotEmpty) {
      final mapped = <String, String>{};
      for (final entry in query.entries) {
        final value = entry.value;
        if (value != null) mapped[entry.key] = value.toString();
      }
      if (mapped.isNotEmpty) cleanQuery = mapped;
    }
    return Uri.parse('${AppConfig.baseUrl}$path').replace(queryParameters: cleanQuery);
  }

  Future<dynamic> _handle(Response response) {
    final code = response.statusCode;
    final bodyStr = _extractBodyString(response);

    if (code >= 200 && code < 300) {
      if (bodyStr.isEmpty) return Future.value(null);
      try {
        return Future.value(jsonDecode(bodyStr));
      } catch (_) {
        return Future.value(bodyStr);
      }
    }

    String message = 'Hitilafu ya mfumo (code $code)';
    try {
      final decoded = jsonDecode(bodyStr);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is List) {
          message = detail.map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString()).join(', ');
        } else {
          message = detail.toString();
        }
      }
    } catch (_) {}
    throw ApiException(message: message, statusCode: code);
  }

  String _extractBodyString(Response response) {
    try {
      final s = response.bodyString;
      if (s.isNotEmpty) return s;
    } catch (_) {}
    final body = response.body;
    if (body == null) return '';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return MockApiData.respond('GET', path);
    }
    final request = Request('GET', _uri(path, query), _client.baseUrl, headers: _headers(auth: auth));
    final response = await _client.send(request);
    return _handle(response);
  }

  Future<List<int>> getBytes(String path, {bool auth = true, Map<String, dynamic>? query}) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return MockApiData.mockBytes();
    }
    final request = Request('GET', _uri(path, query), _client.baseUrl, headers: _headers(auth: auth, multipart: true));
    final response = await _client.send(request);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(message: 'Imeshindikana kupakua faili (code ${response.statusCode})', statusCode: response.statusCode);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, bool auth = true}) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return MockApiData.respond('POST', path, body: body);
    }
    final request = Request(
      'POST',
      _uri(path, query),
      _client.baseUrl,
      body: body == null ? null : jsonEncode(body),
      headers: _headers(auth: auth),
    );
    final response = await _client.send(request);
    return _handle(response);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return MockApiData.respond('PUT', path, body: body);
    }
    final request = Request(
      'PUT',
      _uri(path),
      _client.baseUrl,
      body: body == null ? null : jsonEncode(body),
      headers: _headers(auth: auth),
    );
    final response = await _client.send(request);
    return _handle(response);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    if (AppConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return MockApiData.respond('DELETE', path);
    }
    final request = Request('DELETE', _uri(path), _client.baseUrl, headers: _headers(auth: auth));
    final response = await _client.send(request);
    return _handle(response);
  }
}
