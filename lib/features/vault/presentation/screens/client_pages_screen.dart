import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/vault_controller.dart';
import '../../domain/client_model.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/page_form_dialog.dart';

class ClientPagesScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientPagesScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientPagesScreen> createState() => _ClientPagesScreenState();
}

class _ClientPagesScreenState extends ConsumerState<ClientPagesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _visiblePasswords = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addPage(ClientRecord client) async {
    final res = await showPageFormDialog(context, client: client);
    if (res == null) return;
    await ref.read(vaultControllerProvider.notifier).addPage(
          clientId: client.id,
          siteName: res.siteName,
          url: res.url,
          username: res.username,
          password: res.password,
          notes: res.notes,
        );
  }

  Future<void> _editPage(ClientRecord client, PageCredential page) async {
    final res = await showPageFormDialog(context, client: client, existing: page);
    if (res == null) return;
    await ref.read(vaultControllerProvider.notifier).updatePage(
          clientId: client.id,
          page: page.copyWith(
            siteName: res.siteName,
            url: res.url,
            username: res.username,
            password: res.password,
            notes: res.notes,
          ),
        );
  }

  Future<void> _deletePage(ClientRecord client, PageCredential page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar página'),
        content: Text('¿Eliminar "${page.displayTitle}" (${page.url})?'),
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
      await ref
          .read(vaultControllerProvider.notifier)
          .deletePage(clientId: client.id, pageId: page.id);
    }
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

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultControllerProvider);
    final client = vault.findClient(widget.clientId);
    final theme = Theme.of(context);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/vault'),
          ),
          title: const Text('Cliente no encontrado'),
        ),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/vault'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a clientes'),
          ),
        ),
      );
    }

    final q = _query.trim().toLowerCase();
    final pages = q.isEmpty
        ? client.pages
        : client.pages
            .where((p) =>
                p.displayTitle.toLowerCase().contains(q) ||
                p.url.toLowerCase().contains(q) ||
                p.username.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver a clientes',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/vault'),
        ),
        title: Text(client.nombre),
        actions: [
          IconButton(
            tooltip: 'Editar cliente',
            onPressed: () => _editClient(client),
            icon: const Icon(Icons.edit_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _addPage(client),
              icon: const Icon(Icons.add_link),
              label: const Text('Agregar página'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            client.initials,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () => _copy('CC', client.cc),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CC: ${client.cc}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.copy, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Chip(
                      avatar: const Icon(Icons.language, size: 16),
                      label: Text(
                        '${client.pages.length} ${client.pages.length == 1 ? 'página registrada' : 'páginas registradas'}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (client.pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar página, URL o usuario...',
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
            child: pages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.web_asset_off_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            q.isNotEmpty
                                ? 'No hay páginas que coincidan'
                                : 'Este cliente aún no tiene páginas registradas',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega las páginas con su URL, usuario y contraseña para autocompletar con la extensión.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _addPage(client),
                            icon: const Icon(Icons.add_link),
                            label: const Text('Agregar página'),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 1100
                          ? 2
                          : 1;
                      if (crossAxisCount == 1) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: pages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final page = pages[i];
                            final visible = _visiblePasswords.contains(page.id);
                            return _PageCard(
                              client: client,
                              page: page,
                              passwordVisible: visible,
                              onTogglePassword: () {
                                setState(() {
                                  if (visible) {
                                    _visiblePasswords.remove(page.id);
                                  } else {
                                    _visiblePasswords.add(page.id);
                                  }
                                });
                              },
                              onCopy: _copy,
                              onEdit: () => _editPage(client, page),
                              onDelete: () => _deletePage(client, page),
                            );
                          },
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 265,
                        ),
                        itemCount: pages.length,
                        itemBuilder: (context, i) {
                          final page = pages[i];
                          final visible = _visiblePasswords.contains(page.id);
                          return _PageCard(
                            client: client,
                            page: page,
                            passwordVisible: visible,
                            onTogglePassword: () {
                              setState(() {
                                if (visible) {
                                  _visiblePasswords.remove(page.id);
                                } else {
                                  _visiblePasswords.add(page.id);
                                }
                              });
                            },
                            onCopy: _copy,
                            onEdit: () => _editPage(client, page),
                            onDelete: () => _deletePage(client, page),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPage(client),
        icon: const Icon(Icons.add),
        label: const Text('Agregar página'),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  final ClientRecord client;
  final PageCredential page;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final void Function(String label, String value) onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PageCard({
    required this.client,
    required this.page,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.language, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    page.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar página',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Eliminar página',
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const Divider(height: 16),
            _FieldRow(
              icon: Icons.link,
              label: 'URL',
              value: page.url,
              onCopy: () => onCopy('URL', page.url),
            ),
            const SizedBox(height: 8),
            _FieldRow(
              icon: Icons.person_outline,
              label: 'Usuario',
              value: page.username,
              onCopy: () => onCopy('Usuario', page.username),
            ),
            const SizedBox(height: 8),
            _FieldRow(
              icon: Icons.key_outlined,
              label: 'Password',
              value: passwordVisible ? page.password : '••••••••••••',
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: passwordVisible ? 'Ocultar' : 'Mostrar',
                icon: Icon(
                  passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: onTogglePassword,
              ),
              onCopy: () => onCopy('Contraseña', page.password),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${client.nombre} • CC: ${client.cc}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback onCopy;

  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (trailing != null) trailing!,
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Copiar $label',
          icon: const Icon(Icons.copy_outlined, size: 18),
          onPressed: onCopy,
        ),
      ],
    );
  }
}
