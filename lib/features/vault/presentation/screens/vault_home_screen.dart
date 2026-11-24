import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/vault_controller.dart';
import '../../domain/client_model.dart';
import '../widgets/client_form_dialog.dart';

class VaultHomeScreen extends ConsumerStatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  ConsumerState<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends ConsumerState<VaultHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addClient() async {
    final res = await showClientFormDialog(context);
    if (res == null) return;
    final created = await ref
        .read(vaultControllerProvider.notifier)
        .addClient(cc: res.cc, nombre: res.nombre);
    if (!mounted) return;
    context.go('/vault/client/${created.id}');
  }

  Future<void> _editClient(ClientRecord client) async {
    final res = await showClientFormDialog(context, existing: client);
    if (res == null) return;
    await ref.read(vaultControllerProvider.notifier).updateClient(
          clientId: client.id,
          cc: res.cc,
          nombre: res.nombre,
        );
  }

  Future<void> _deleteClient(ClientRecord client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Seguro que deseas eliminar a "${client.nombre}" (CC: ${client.cc}) y sus ${client.pages.length} páginas registradas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vaultControllerProvider.notifier).deleteClient(client.id);
    }
  }

  Future<void> _syncNow() async {
    await ref.read(vaultControllerProvider.notifier).syncNow();
    if (!mounted) return;
    final vault = ref.read(vaultControllerProvider);
    final msg = vault.syncMessage ?? vault.syncError;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultControllerProvider);
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? vault.clients
        : vault.clients
            .where((c) =>
                c.nombre.toLowerCase().contains(q) ||
                c.cc.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar con extensión / servidor',
            onPressed: vault.isSyncing ? null : _syncNow,
            icon: vault.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _addClient,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Agregar cliente'),
            ),
          ),
        ],
      ),
      body: vault.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente por nombre o CC...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyClientsState(
                          hasQuery: q.isNotEmpty,
                          onAdd: _addClient,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 1100
                                ? 3
                                : width >= 680
                                    ? 2
                                    : 1;
                            if (crossAxisCount == 1) {
                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, i) => _ClientCard(
                                  client: filtered[i],
                                  onTap: () => context.go('/vault/client/${filtered[i].id}'),
                                  onEdit: () => _editClient(filtered[i]),
                                  onDelete: () => _deleteClient(filtered[i]),
                                ),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 148,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _ClientCard(
                                client: filtered[i],
                                onTap: () => context.go('/vault/client/${filtered[i].id}'),
                                onEdit: () => _editClient(filtered[i]),
                                onDelete: () => _deleteClient(filtered[i]),
                              ),
                            );
                          },
                        ),
                ),
                if (vault.lastSyncAt != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    child: Text(
                      'Última sincronización: ${vault.lastSyncAt!.hour.toString().padLeft(2, '0')}:${vault.lastSyncAt!.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar cliente'),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientRecord client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageCount = client.pages.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      client.initials,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CC: ${client.cc}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar cliente')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language, size: 15, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '$pageCount ${pageCount == 1 ? 'página' : 'páginas'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Ver páginas',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyClientsState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onAdd;

  const _EmptyClientsState({required this.hasQuery, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery
                  ? 'No se encontraron clientes con esa búsqueda'
                  : 'Aún no tienes clientes registrados',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Prueba buscando con otro nombre o número de CC.'
                  : 'Agrega tu primer cliente para guardar sus páginas, usuarios y contraseñas.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Agregar primer cliente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
