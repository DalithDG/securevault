import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

class VaultKeyNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;
  void set(Uint8List? key) => state = key;
}

final vaultKeyProvider = NotifierProvider<VaultKeyNotifier, Uint8List?>(VaultKeyNotifier.new);