import 'package:flutter/material.dart';

import '../../application/vault_controller.dart';
import '../../domain/client_model.dart';

typedef PageFormResult = ({
  String siteName,
  String url,
  String username,
  String password,
  String notes,
});

Future<PageFormResult?> showPageFormDialog(
  BuildContext context, {
  required ClientRecord client,
  PageCredential? existing,
}) {
  return showDialog<PageFormResult>(
    context: context,
    builder: (context) => _PageFormDialog(client: client, existing: existing),
  );
}

class _PageFormDialog extends StatefulWidget {
  final ClientRecord client;
  final PageCredential? existing;

  const _PageFormDialog({
    required this.client,
    this.existing,
  });

  @override
  State<_PageFormDialog> createState() => _PageFormDialogState();
}

class _PageFormDialogState extends State<_PageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _siteCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _notesCtrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _siteCtrl = TextEditingController(text: widget.existing?.siteName ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.url ?? '');
    _userCtrl = TextEditingController(text: widget.existing?.username ?? '');
    _passCtrl = TextEditingController(text: widget.existing?.password ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _siteCtrl.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _passCtrl.text = VaultController.generatePassword(length: 16);
      _obscure = false;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      siteName: _siteCtrl.text.trim(),
      url: _urlCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      notes: _notesCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(isEdit ? 'Editar página' : 'Agregar página'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.client.nombre}  •  CC: ${widget.client.cc}',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _siteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la página (opcional)',
                    hintText: 'Ej. Portal Bancario, DIAN, Gmail',
                    prefixIcon: Icon(Icons.web_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://ejemplo.com/login',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa la URL de la página' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario / Correo',
                    hintText: 'usuario@ejemplo.com',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el usuario' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password / Contraseña',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Generar contraseña segura',
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          onPressed: _generatePassword,
                        ),
                        IconButton(
                          tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ],
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa la contraseña' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(isEdit ? 'Guardar página' : 'Agregar página'),
        ),
      ],
    );
  }
}
