import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/theme_provider.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _unlockVault() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce tu contraseña maestra.')),
      );
      return;
    }
    context.go('/vault');
  }

  void _selectTheme() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleccionar apariencia', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _themeOption('Claro', ThemeMode.light, Icons.light_mode_outlined),
                _themeOption('Oscuro', ThemeMode.dark, Icons.dark_mode_outlined),
                _themeOption('Sistema', ThemeMode.system, Icons.settings_suggest_outlined),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeOption(String title, ThemeMode mode, IconData icon) {
    final current = ref.read(themeModeProvider);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: current == mode ? const Icon(Icons.check_circle, color: Color(0xFF9B72E8)) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).set(mode);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final purple = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(tooltip: 'Cambiar apariencia', onPressed: _selectTheme, icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: purple.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(26)),
                    child: Icon(Icons.shield_outlined, size: 52, color: purple),
                  ),
                  const SizedBox(height: 20),
                  Text('SecureVault', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -1, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Tu seguridad comienza aquí.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: secondaryColor)),
                  const SizedBox(height: 42),
                  Card(
                    elevation: isDark ? 0 : 1,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15))),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 32, color: Color(0xFF9B72E8)),
                          const SizedBox(height: 16),
                          Text('Desbloquea tu bóveda', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 8),
                          Text('Introduce tu contraseña maestra para acceder a tus credenciales.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: secondaryColor)),
                          const SizedBox(height: 28),
                          Text('Contraseña maestra', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onSubmitted: (_) => _unlockVault(),
                            decoration: InputDecoration(
                              hintText: 'Introduce tu contraseña',
                              prefixIcon: const Icon(Icons.key_outlined),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _unlockVault,
                              icon: const Icon(Icons.lock_open_rounded),
                              label: const Text('Desbloquear bóveda', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}