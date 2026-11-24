import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../sync/data/local_bridge_server.dart';
import '../../sync/data/sync_service.dart';
import '../data/vault_repository.dart';
import '../domain/client_model.dart';

class VaultState {
  final List<ClientRecord> clients;
  final bool isLoading;
  final bool isSyncing;
  final bool bridgeActive;
  final String? syncMessage;
  final String? syncError;
  final DateTime? lastSyncAt;
  final String syncBaseUrl;

  const VaultState({
    this.clients = const [],
    this.isLoading = true,
    this.isSyncing = false,
    this.bridgeActive = false,
    this.syncMessage,
    this.syncError,
    this.lastSyncAt,
    this.syncBaseUrl = 'https://securevault-dgteams.vercel.app',
  });

  VaultState copyWith({
    List<ClientRecord>? clients,
    bool? isLoading,
    bool? isSyncing,
    bool? bridgeActive,
    String? syncMessage,
    String? syncError,
    DateTime? lastSyncAt,
    String? syncBaseUrl,
    bool clearSyncFeedback = false,
  }) {
    return VaultState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      bridgeActive: bridgeActive ?? this.bridgeActive,
      syncMessage: clearSyncFeedback ? null : (syncMessage ?? this.syncMessage),
      syncError: clearSyncFeedback ? null : (syncError ?? this.syncError),
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncBaseUrl: syncBaseUrl ?? this.syncBaseUrl,
    );
  }

  ClientRecord? findClient(String id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class VaultController extends Notifier<VaultState> {
  final _repo = VaultRepository();
  final _random = Random.secure();
  LocalBridgeServer? _bridge;

  @override
  VaultState build() {
    ref.onDispose(() {
      _bridge?.stop();
    });
    Future.microtask(_loadInitial);
    return const VaultState();
  }

  String _newId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = _random.nextInt(999999);
    return '$ts-$rand';
  }

  Future<void> _loadInitial() async {
    try {
      final clients = await _repo.loadClients();
      final syncUrl = await _repo.loadSyncUrl();
      _bridge ??= LocalBridgeServer(
        port: 8080,
        onGetVaultJson: () => _repo.encodeClientsPayload(state.clients),
        onSaveFromExtension: _handleExtensionSave,
      );
      final started = await _bridge!.start();
      state = state.copyWith(
        clients: clients,
        isLoading: false,
        syncBaseUrl: syncUrl,
        bridgeActive: started,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Map<String, dynamic>> _handleExtensionSave(
    Map<String, dynamic> payload,
  ) async {
    final cc = (payload['cc'] ?? '').toString().trim();
    final nombre = (payload['nombre'] ?? '').toString().trim();
    final url = (payload['url'] ?? '').toString().trim();
    final username = (payload['username'] ?? '').toString().trim();
    final password = (payload['password'] ?? '').toString();
    final siteName = (payload['siteName'] ?? '').toString().trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      throw ArgumentError('URL, usuario y password son obligatorios');
    }

    final now = DateTime.now();
    final list = [...state.clients];
    int idx = -1;

    if (cc.isNotEmpty) {
      idx = list.indexWhere((c) => c.cc.toLowerCase() == cc.toLowerCase());
    }
    if (idx == -1 && nombre.isNotEmpty) {
      idx = list.indexWhere(
        (c) => c.nombre.toLowerCase() == nombre.toLowerCase(),
      );
    }

    final newPage = PageCredential(
      id: _newId(),
      siteName: siteName,
      url: url,
      username: username,
      password: password,
      updatedAt: now,
    );

    late ClientRecord savedClient;
    if (idx == -1) {
      savedClient = ClientRecord(
        id: _newId(),
        cc: cc.isEmpty ? 'S/N' : cc,
        nombre: nombre.isEmpty ? 'Cliente sin nombre' : nombre,
        pages: [newPage],
        createdAt: now,
        updatedAt: now,
      );
      list.insert(0, savedClient);
    } else {
      final existing = list[idx];
      final updatedPages = [...existing.pages];
      final pageIdx = updatedPages.indexWhere(
        (p) =>
            p.url.toLowerCase() == url.toLowerCase() &&
            p.username.toLowerCase() == username.toLowerCase(),
      );
      if (pageIdx >= 0) {
        updatedPages[pageIdx] = updatedPages[pageIdx].copyWith(
          siteName: siteName.isNotEmpty ? siteName : updatedPages[pageIdx].siteName,
          password: password,
          updatedAt: now,
        );
      } else {
        updatedPages.insert(0, newPage);
      }
      savedClient = existing.copyWith(
        cc: cc.isNotEmpty ? cc : existing.cc,
        nombre: nombre.isNotEmpty ? nombre : existing.nombre,
        pages: updatedPages,
        updatedAt: now,
      );
      list[idx] = savedClient;
    }

    state = state.copyWith(
      clients: list,
      lastSyncAt: now,
      syncMessage: 'Guardado desde la extensión',
    );
    await _repo.saveClients(list);

    return {
      'ok': true,
      'client': savedClient.toJson(),
      'clients': list.map((c) => c.toJson()).toList(),
    };
  }

  Future<void> _persistAndTrySync(List<ClientRecord> updated) async {
    state = state.copyWith(clients: updated, clearSyncFeedback: true);
    await _repo.saveClients(updated);
    await syncNow(silent: true);
  }

  Future<ClientRecord> addClient({
    required String cc,
    required String nombre,
  }) async {
    final now = DateTime.now();
    final client = ClientRecord(
      id: _newId(),
      cc: cc.trim(),
      nombre: nombre.trim(),
      pages: const [],
      createdAt: now,
      updatedAt: now,
    );
    await _persistAndTrySync([client, ...state.clients]);
    return client;
  }

  Future<void> updateClient({
    required String clientId,
    required String cc,
    required String nombre,
  }) async {
    final now = DateTime.now();
    final updated = state.clients.map((c) {
      if (c.id != clientId) return c;
      return c.copyWith(cc: cc.trim(), nombre: nombre.trim(), updatedAt: now);
    }).toList();
    await _persistAndTrySync(updated);
  }

  Future<void> deleteClient(String clientId) async {
    final updated = state.clients.where((c) => c.id != clientId).toList();
    await _persistAndTrySync(updated);
  }

  Future<void> addPage({
    required String clientId,
    required String siteName,
    required String url,
    required String username,
    required String password,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final page = PageCredential(
      id: _newId(),
      siteName: siteName.trim(),
      url: url.trim(),
      username: username.trim(),
      password: password,
      notes: notes.trim(),
      updatedAt: now,
    );
    final updated = state.clients.map((c) {
      if (c.id != clientId) return c;
      return c.copyWith(pages: [page, ...c.pages], updatedAt: now);
    }).toList();
    await _persistAndTrySync(updated);
  }

  Future<void> updatePage({
    required String clientId,
    required PageCredential page,
  }) async {
    final now = DateTime.now();
    final updated = state.clients.map((c) {
      if (c.id != clientId) return c;
      final pages = c.pages
          .map((p) => p.id == page.id ? page.copyWith(updatedAt: now) : p)
          .toList();
      return c.copyWith(pages: pages, updatedAt: now);
    }).toList();
    await _persistAndTrySync(updated);
  }

  Future<void> deletePage({
    required String clientId,
    required String pageId,
  }) async {
    final now = DateTime.now();
    final updated = state.clients.map((c) {
      if (c.id != clientId) return c;
      final pages = c.pages.where((p) => p.id != pageId).toList();
      return c.copyWith(pages: pages, updatedAt: now);
    }).toList();
    await _persistAndTrySync(updated);
  }

  Future<void> setSyncBaseUrl(String url) async {
    final normalized = url.trim().isEmpty
        ? 'https://securevault-dgteams.vercel.app'
        : url.trim().replaceAll(RegExp(r'/+$'), '');
    await _repo.saveSyncUrl(normalized);
    state = state.copyWith(syncBaseUrl: normalized);
  }

  Future<void> syncNow({bool silent = false}) async {
    if (state.bridgeActive && state.syncBaseUrl.contains('localhost:8080')) {
      if (!silent) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncAt: DateTime.now(),
          syncMessage: 'Listo y sincronizado con la extensión en localhost:8080',
        );
      }
      return;
    }
    final userId = ref.read(authControllerProvider).email ?? 'default';
    if (!silent) {
      state = state.copyWith(isSyncing: true, clearSyncFeedback: true);
    }
    try {
      final sync = SyncService(baseUrl: state.syncBaseUrl);
      final payload = _repo.encodeClientsPayload(state.clients);
      await sync.push(userId, payload);
      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
        syncMessage: 'Sincronizado con el servidor y la extensión',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: silent ? null : 'No se pudo conectar con ${state.syncBaseUrl}',
      );
    }
  }

  Future<void> pullFromServer() async {
    final userId = ref.read(authControllerProvider).email ?? 'default';
    state = state.copyWith(isSyncing: true, clearSyncFeedback: true);
    try {
      final sync = SyncService(baseUrl: state.syncBaseUrl);
      final remote = await sync.pull(userId);
      if (remote != null && remote.isNotEmpty) {
        final remoteClients = _repo.decodeClientsPayload(remote);
        await _repo.saveClients(remoteClients);
        state = state.copyWith(
          clients: remoteClients,
          isSyncing: false,
          lastSyncAt: DateTime.now(),
          syncMessage: 'Datos descargados desde el servidor',
        );
      } else {
        state = state.copyWith(
          isSyncing: false,
          syncMessage: 'No hay datos remotos nuevos',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Error al descargar desde ${state.syncBaseUrl}',
      );
    }
  }

  static String generatePassword({
    int length = 16,
    bool upper = true,
    bool lower = true,
    bool numbers = true,
    bool symbols = true,
  }) {
    const u = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const l = 'abcdefghijklmnopqrstuvwxyz';
    const n = '0123456789';
    const s = '!@#\$%^&*()-_=+[]{}';
    var pool = '';
    if (upper) pool += u;
    if (lower) pool += l;
    if (numbers) pool += n;
    if (symbols) pool += s;
    if (pool.isEmpty) pool = l + n;
    final rng = Random.secure();
    return List.generate(length, (_) => pool[rng.nextInt(pool.length)]).join();
  }
}

final vaultControllerProvider =
    NotifierProvider<VaultController, VaultState>(VaultController.new);
