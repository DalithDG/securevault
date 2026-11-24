import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../vault/application/vault_controller.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  double _length = 16;
  bool _upper = true;
  bool _lower = true;
  bool _numbers = true;
  bool _symbols = true;
  late String _result;

  @override
  void initState() {
    super.initState();
    _result = VaultController.generatePassword(length: _length.toInt());
  }

  void _regenerate() {
    setState(() {
      _result = VaultController.generatePassword(
        length: _length.toInt(),
        upper: _upper,
        lower: _lower,
        numbers: _numbers,
        symbols: _symbols,
      );
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña copiada al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generador de contraseñas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _result,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar contraseña',
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: _copy,
                      ),
                      IconButton(
                        tooltip: 'Regenerar',
                        icon: const Icon(Icons.refresh),
                        onPressed: _regenerate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Longitud: ${_length.toInt()} caracteres'),
              Slider(
                value: _length,
                min: 8,
                max: 40,
                divisions: 32,
                onChanged: (v) {
                  _length = v;
                  _regenerate();
                },
              ),
              SwitchListTile(
                title: const Text('Mayúsculas (A-Z)'),
                value: _upper,
                onChanged: (v) {
                  _upper = v;
                  _regenerate();
                },
              ),
              SwitchListTile(
                title: const Text('Minúsculas (a-z)'),
                value: _lower,
                onChanged: (v) {
                  _lower = v;
                  _regenerate();
                },
              ),
              SwitchListTile(
                title: const Text('Números (0-9)'),
                value: _numbers,
                onChanged: (v) {
                  _numbers = v;
                  _regenerate();
                },
              ),
              SwitchListTile(
                title: const Text('Símbolos (!@#\$%)'),
                value: _symbols,
                onChanged: (v) {
                  _symbols = v;
                  _regenerate();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _regenerate,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Generar nueva'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                    ),
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
