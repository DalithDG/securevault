import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/theme_provider.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../vault/application/vault_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _selectTheme(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccionar apariencia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _themeTile(context, ref, 'Claro', ThemeMode.light, Icons.light_mode_outlined, current),
              _themeTile(context, ref, 'Oscuro', ThemeMode.dark, Icons.dark_mode_outlined, current),
              _themeTile(context, ref, 'Sistema', ThemeMode.system, Icons.settings_suggest_outlined, current),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeTile(
    BuildContext context,
    WidgetRef ref,
    String label,
    ThemeMode mode,
    IconData icon,
    ThemeMode current,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: current == mode ? const Icon(Icons.check_circle) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).set(mode);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _editSyncUrl(BuildContext context, WidgetRef ref, String currentUrl) async {
    final ctrl = TextEditingController(text: currentUrl);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL del servidor de sincronización'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'URL base',
            hintText: 'http://localhost:8080',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (updated != null) {
      await ref.read(vaultControllerProvider.notifier).setSyncBaseUrl(updated);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final vault = ref.watch(vaultControllerProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            children: [
              if (auth.email != null)
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('Cuenta activa'),
                  subtitle: Text(auth.email!),
                ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Apariencia'),
                subtitle: Text(mode.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTheme(context, ref, mode),
              ),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Servidor / Extensión de sincronización'),
                subtitle: Text(vault.syncBaseUrl),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editSyncUrl(context, ref, vault.syncBaseUrl),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Subir datos al servidor ahora'),
                onTap: () async {
                  await ref.read(vaultControllerProvider.notifier).syncNow();
                  if (!context.mounted) return;
                  final v = ref.read(vaultControllerProvider);
                  final msg = v.syncMessage ?? v.syncError ?? 'Sincronización finalizada';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Descargar datos del servidor'),
                onTap: () async {
                  await ref.read(vaultControllerProvider.notifier).pullFromServer();
                  if (!context.mounted) return;
                  final v = ref.read(vaultControllerProvider);
                  final msg = v.syncMessage ?? v.syncError ?? 'Descarga finalizada';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Bloquear bóveda'),
                onTap: () => context.go('/unlock'),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar sesión'),
                textColor: Colors.red,
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (!context.mounted) return;
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
