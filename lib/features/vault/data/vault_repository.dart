import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/client_model.dart';

class VaultRepository {
  static const _boxName = 'vault_box';
  static const _clientsKey = 'clients_json';
  static const _syncUrlKey = 'sync_base_url';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  Future<void> init() async {
    await _openBox();
  }

  Future<void> saveBlob(String blob) async {
    final box = await _openBox();
    await box.put('vault', blob);
  }

  Future<String?> loadBlob() async {
    final box = await _openBox();
    return box.get('vault') as String?;
  }

  Future<List<ClientRecord>> loadClients() async {
    final box = await _openBox();
    final raw = box.get(_clientsKey) as String?;
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['clients'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((c) => ClientRecord.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  Future<void> saveClients(List<ClientRecord> clients) async {
    final box = await _openBox();
    final payload = encodeClientsPayload(clients);
    await box.put(_clientsKey, payload);
  }

  String encodeClientsPayload(List<ClientRecord> clients) {
    return jsonEncode({
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'clients': clients.map((c) => c.toJson()).toList(),
    });
  }

  List<ClientRecord> decodeClientsPayload(String payload) {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final list = decoded['clients'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((c) => ClientRecord.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  Future<String> loadSyncUrl() async {
    final box = await _openBox();
    final saved = (box.get(_syncUrlKey) as String?)?.trim();
    if (saved == null ||
        saved.isEmpty ||
        saved == 'http://localhost:8080' ||
        saved == 'https://securevault-276j.onrender.com') {
      return 'https://securevault-dgteams.vercel.app';
    }
    return saved;
  }

  Future<void> saveSyncUrl(String url) async {
    final box = await _openBox();
    await box.put(_syncUrlKey, url.trim());
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.delete('vault');
    await box.delete(_clientsKey);
  }
}
