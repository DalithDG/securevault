import 'package:flutter/material.dart';

import '../../domain/client_model.dart';

Future<({String cc, String nombre})?> showClientFormDialog(
  BuildContext context, {
  ClientRecord? existing,
}) {
  return showDialog<({String cc, String nombre})>(
    context: context,
    builder: (context) => _ClientFormDialog(existing: existing),
  );
}

class _ClientFormDialog extends StatefulWidget {
  final ClientRecord? existing;

  const _ClientFormDialog({this.existing});

  @override
  State<_ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<_ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ccCtrl;
  late final TextEditingController _nombreCtrl;

  @override
  void initState() {
    super.initState();
    _ccCtrl = TextEditingController(text: widget.existing?.cc ?? '');
    _nombreCtrl = TextEditingController(text: widget.existing?.nombre ?? '');
  }

  @override
  void dispose() {
    _ccCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      cc: _ccCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar cliente' : 'Agregar cliente'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _ccCtrl,
                decoration: const InputDecoration(
                  labelText: 'CC / Cédula',
                  hintText: 'Ej. 1020304050',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el CC del cliente' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  hintText: 'Ej. Juan Pérez',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del cliente' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
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
          label: Text(isEdit ? 'Guardar cambios' : 'Agregar cliente'),
        ),
      ],
    );
  }
}
