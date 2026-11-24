import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CredentialDetailScreen extends StatelessWidget {
  final String id;
  const CredentialDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined))]),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sitio: ejemplo.com', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Usuario: usuario@ejemplo.com'),
            const SizedBox(height: 8),
            const Text('Contraseña: ••••••••'),
            const Spacer(),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.copy), label: const Text('Copiar contraseña'))),
          ],
        ),
      ),
    );
  }
}