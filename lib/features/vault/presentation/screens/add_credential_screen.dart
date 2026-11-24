import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddCredentialScreen extends StatefulWidget {
  const AddCredentialScreen({super.key});

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _site = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva credencial')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(controller: _site, decoration: const InputDecoration(labelText: 'Sitio / URL', prefixIcon: Icon(Icons.link))),
              const SizedBox(height: 16),
              TextField(controller: _user, decoration: const InputDecoration(labelText: 'Usuario / Correo', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.key_outlined))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => context.pop(), child: const Text('Guardar'))),
            ],
          ),
        ),
      ),
    );
  }
}