import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class LocalBridgeServer {
  HttpServer? _serverV4;
  HttpServer? _serverV6;
  final int port;
  final String Function() onGetVaultJson;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)
      onSaveFromExtension;

  LocalBridgeServer({
    this.port = 8080,
    required this.onGetVaultJson,
    required this.onSaveFromExtension,
  });

  bool get isRunning => _serverV4 != null || _serverV6 != null;

  Future<bool> start() async {
    if (kIsWeb) return false;
    if (isRunning) return true;
    try {
      _serverV4 = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _serverV4!.listen(_handleRequest);
    } catch (_) {}
    try {
      _serverV6 = await HttpServer.bind(InternetAddress.loopbackIPv6, port);
      _serverV6!.listen(_handleRequest);
    } catch (_) {}
    return isRunning;
  }

  Future<void> stop() async {
    await _serverV4?.close(force: true);
    await _serverV6?.close(force: true);
    _serverV4 = null;
    _serverV6 = null;
  }

  void _addCors(HttpResponse res) {
    res.headers.set('Access-Control-Allow-Origin', '*');
    res.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.headers.contentType = ContentType.json;
  }

  Future<void> _handleRequest(HttpRequest req) async {
    final res = req.response;
    _addCors(res);

    if (req.method == 'OPTIONS') {
      res.statusCode = HttpStatus.ok;
      await res.close();
      return;
    }

    try {
      final path = req.uri.path;
      if (req.method == 'GET' && path == '/api/health') {
        res.statusCode = HttpStatus.ok;
        res.write(jsonEncode({'ok': true, 'app': 'SecureVault'}));
      } else if (req.method == 'GET' &&
          (path == '/api/vault' || path.startsWith('/api/vault/'))) {
        res.statusCode = HttpStatus.ok;
        res.write(onGetVaultJson());
      } else if (req.method == 'POST' && path == '/api/extension/save') {
        final body = await utf8.decoder.bind(req).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final result = await onSaveFromExtension(payload);
        res.statusCode = HttpStatus.ok;
        res.write(jsonEncode(result));
      } else {
        res.statusCode = HttpStatus.notFound;
        res.write(jsonEncode({'error': 'Not found'}));
      }
    } catch (e) {
      res.statusCode = HttpStatus.badRequest;
      res.write(jsonEncode({'error': e.toString()}));
    } finally {
      await res.close();
    }
  }
}
