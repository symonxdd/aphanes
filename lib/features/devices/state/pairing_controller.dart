import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/devmode_pairing_service.dart';

sealed class PairingState {
  const PairingState();
}

class PairingIdle extends PairingState {
  const PairingIdle();
}

class PairingConnecting extends PairingState {
  const PairingConnecting();
}

class PairingSucceeded extends PairingState {
  const PairingSucceeded(this.host, this.credentials);

  final String host;
  final PairedDevmodeCredentials credentials;
}

class PairingFailed extends PairingState {
  const PairingFailed(this.message);

  final String message;
}

final Provider<DevmodePairingService> devmodePairingServiceProvider =
    Provider<DevmodePairingService>((Ref ref) => DevmodePairingService());

class PairingController extends Notifier<PairingState> {
  @override
  PairingState build() => const PairingIdle();

  Future<void> pair({
    required String host,
    required String passphrase,
    String? cachedEncryptedPem,
  }) async {
    state = const PairingConnecting();
    try {
      final PairedDevmodeCredentials credentials = await ref
          .read(devmodePairingServiceProvider)
          .pair(
            host: host,
            passphrase: passphrase,
            cachedEncryptedPem: cachedEncryptedPem,
          );
      state = PairingSucceeded(host, credentials);
    } on DevmodePairingException catch (e) {
      state = PairingFailed(e.message);
    } catch (_) {
      state = const PairingFailed(
        'Something went wrong while pairing. Please try again.',
      );
    }
  }

  void reset() => state = const PairingIdle();
}

final NotifierProvider<PairingController, PairingState> pairingProvider =
    NotifierProvider<PairingController, PairingState>(PairingController.new);
