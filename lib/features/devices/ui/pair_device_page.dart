import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../../core/validation/ipv4.dart';
import '../models/device.dart';
import '../services/devmode_pairing_service.dart';
import '../state/device_list_controller.dart';
import '../state/pairing_controller.dart';
import 'widgets/devmode_explainers.dart';
import 'widgets/devmode_setup_checklist.dart';

enum _HostProbeStatus { idle, checking, found, notFound }

enum _PassphraseStatus { idle, checking, valid, invalid }

class PairDevicePage extends ConsumerStatefulWidget {
  const PairDevicePage({super.key});

  @override
  ConsumerState<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends ConsumerState<PairDevicePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _nameControllerInitialized = false;

  Timer? _probeDebounce;
  _HostProbeStatus _probeStatus = _HostProbeStatus.idle;
  int _probeToken = 0;

  // Cached once the host is found, so different passphrase attempts can be
  // validated locally afterward without fetching the key again each time.
  String? _cachedEncryptedPem;
  Timer? _passphraseDebounce;
  _PassphraseStatus _passphraseStatus = _PassphraseStatus.idle;
  int _passphraseToken = 0;

  @override
  void initState() {
    super.initState();
    // A stale success/error from a previous visit to this page shouldn't
    // carry over. Deferred to after this frame: Riverpod disallows
    // modifying a provider while the widget tree is still building, which
    // initState counts as for a page that was just pushed.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        ref.read(pairingProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _probeDebounce?.cancel();
    _passphraseDebounce?.cancel();
    _hostController.dispose();
    _passphraseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Only ever advisory - never blocks the Pair button, since a false
  // negative (e.g. a slow network) shouldn't stop someone from trying the
  // real pairing attempt anyway.
  void _onHostChanged(String value) {
    _probeDebounce?.cancel();
    final String host = value.trim();
    _cachedEncryptedPem = null;
    _passphraseStatus = _PassphraseStatus.idle;
    if (!ipv4Pattern.hasMatch(host)) {
      setState(() => _probeStatus = _HostProbeStatus.idle);
      return;
    }
    setState(() => _probeStatus = _HostProbeStatus.checking);
    final int token = ++_probeToken;
    _probeDebounce = Timer(const Duration(milliseconds: 100), () async {
      final bool found = await ref
          .read(devmodePairingServiceProvider)
          .probe(host);
      if (mounted && token == _probeToken) {
        setState(() {
          _probeStatus = found
              ? _HostProbeStatus.found
              : _HostProbeStatus.notFound;
        });
        if (found) {
          unawaited(_primeKeyCache(host, token));
        }
      }
    });
  }

  // The passphrase is never sent over the network at all (it's only ever
  // used locally, to decrypt the key already fetched here) - so once the
  // encrypted key is cached, checking a passphrase against it is a pure
  // local computation, no further network round trips needed.
  Future<void> _primeKeyCache(String host, int probeToken) async {
    try {
      final String pem = await ref
          .read(devmodePairingServiceProvider)
          .fetchEncryptedKey(host);
      if (mounted && probeToken == _probeToken) {
        _cachedEncryptedPem = pem;
        _onPassphraseChanged(_passphraseController.text);
      }
    } catch (_) {
      // Silent: this only primes the validation cache. If this host can't
      // really be reached, the real Pair attempt will surface that
      // properly.
    }
  }

  void _onPassphraseChanged(String value) {
    _passphraseDebounce?.cancel();
    final String passphrase = value.trim();
    final String? pem = _cachedEncryptedPem;
    if (passphrase.isEmpty || pem == null) {
      setState(() => _passphraseStatus = _PassphraseStatus.idle);
      return;
    }
    setState(() => _passphraseStatus = _PassphraseStatus.checking);
    final int token = ++_passphraseToken;
    _passphraseDebounce = Timer(const Duration(milliseconds: 150), () async {
      final bool valid = await ref
          .read(devmodePairingServiceProvider)
          .validatePassphrase(pem, passphrase);
      if (mounted && token == _passphraseToken) {
        setState(() {
          _passphraseStatus = valid
              ? _PassphraseStatus.valid
              : _PassphraseStatus.invalid;
        });
      }
    });
  }

  Future<void> _onPairPressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String host = _hostController.text.trim();
    final String passphrase = _passphraseController.text.trim();
    await ref
        .read(pairingProvider.notifier)
        .pair(
          host: host,
          passphrase: passphrase,
          cachedEncryptedPem: _cachedEncryptedPem,
        );
  }

  Future<void> _onSavePressed(PairingSucceeded succeeded) async {
    final Device device = Device(
      id: const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? 'webOS TV'
          : _nameController.text.trim(),
      model: succeeded.credentials.model,
      host: succeeded.host,
      port: DevmodePairingService.devModePort,
      username: DevmodePairingService.devModeUsername,
      privateKeyPem: succeeded.credentials.privateKeyPem,
      pairedAt: DateTime.now(),
    );
    await ref.read(deviceListProvider.notifier).add(device);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PairingState state = ref.watch(pairingProvider);

    if (state is PairingSucceeded && !_nameControllerInitialized) {
      _nameController.text = state.credentials.model ?? 'webOS TV';
      _nameControllerInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pair a device')),
      body: Stack(
        children: [
          const AmbientBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: switch (state) {
                PairingSucceeded() => _NameDeviceForm(
                  nameController: _nameController,
                  onSave: () => _onSavePressed(state),
                ),
                _ => _ConnectForm(
                  formKey: _formKey,
                  hostController: _hostController,
                  passphraseController: _passphraseController,
                  onHostChanged: _onHostChanged,
                  onPassphraseChanged: _onPassphraseChanged,
                  probeStatus: _probeStatus,
                  passphraseStatus: _passphraseStatus,
                  state: state,
                  onPair: _onPairPressed,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectForm extends ConsumerWidget {
  const _ConnectForm({
    required this.formKey,
    required this.hostController,
    required this.passphraseController,
    required this.onHostChanged,
    required this.onPassphraseChanged,
    required this.probeStatus,
    required this.passphraseStatus,
    required this.state,
    required this.onPair,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController hostController;
  final TextEditingController passphraseController;
  final ValueChanged<String> onHostChanged;
  final ValueChanged<String> onPassphraseChanged;
  final _HostProbeStatus probeStatus;
  final _PassphraseStatus passphraseStatus;
  final PairingState state;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool connecting = state is PairingConnecting;
    final ThemeData theme = Theme.of(context);
    final List<Device> pairedDevices =
        ref.watch(deviceListProvider).value ?? const [];
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Connect to a TV',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'How it works',
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  showConnectionInfoSheet(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Both the IP address and passphrase are shown in the '
            'Developer Mode app on the TV',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: hostController,
            enabled: !connecting,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "TV's IP address",
              hintText: 'e.g. 192.168.1.42',
            ),
            onChanged: onHostChanged,
            validator: (String? value) {
              final String host = value?.trim() ?? '';
              if (host.isEmpty) {
                return 'IP address is required';
              }
              if (!ipv4Pattern.hasMatch(host)) {
                return 'Enter a valid IP address';
              }
              if (pairedDevices.any((Device d) => d.host == host)) {
                return 'This TV is already paired';
              }
              return null;
            },
          ),
          // Tight above (belongs to the IP field), generous below (clearly
          // separate from the passphrase field that follows) - so which
          // field this status is about reads from spacing alone.
          const SizedBox(height: 8),
          _HostProbeIndicator(status: probeStatus),
          const SizedBox(height: 24),
          TextFormField(
            controller: passphraseController,
            enabled: !connecting,
            decoration: const InputDecoration(labelText: 'Passphrase'),
            onChanged: onPassphraseChanged,
            validator: (String? value) =>
                (value == null || value.trim().isEmpty)
                ? 'Passphrase is required'
                : null,
          ),
          const SizedBox(height: 8),
          _PassphraseStatusIndicator(status: passphraseStatus),
          if (state is PairingFailed) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (state as PairingFailed).message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: connecting ? null : onPair,
            child: connecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Pair'),
          ),
          const SizedBox(height: 40),
          Center(
            child: DevmodeSetupLink(highlighted: state is PairingFailed),
          ),
        ],
      ),
    );
  }
}

/// Shared visual shape for the two live status lines (host probe,
/// passphrase validation): a small icon, a label, both in one color.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _HostProbeIndicator extends StatelessWidget {
  const _HostProbeIndicator({required this.status});

  final _HostProbeStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == _HostProbeStatus.idle) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final (Widget icon, String label, Color color) = switch (status) {
      _HostProbeStatus.checking => (
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        'Checking...',
        theme.colorScheme.onSurfaceVariant,
      ),
      _HostProbeStatus.found => (
        Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
        'Developer Mode and Key Server are on',
        theme.colorScheme.primary,
      ),
      _HostProbeStatus.notFound => (
        Icon(
          Icons.info_outline,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        'No response. Check Developer Mode and Key Server are on.',
        theme.colorScheme.onSurfaceVariant,
      ),
      _HostProbeStatus.idle => (
        const SizedBox.shrink(),
        '',
        Colors.transparent,
      ),
    };

    return _StatusLine(icon: icon, label: label, color: color);
  }
}

class _PassphraseStatusIndicator extends StatelessWidget {
  const _PassphraseStatusIndicator({required this.status});

  final _PassphraseStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == _PassphraseStatus.idle) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final (Widget icon, String label, Color color) = switch (status) {
      _PassphraseStatus.checking => (
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        'Checking...',
        theme.colorScheme.onSurfaceVariant,
      ),
      _PassphraseStatus.valid => (
        Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
        'Passphrase looks correct',
        theme.colorScheme.primary,
      ),
      // Deliberately the same muted, non-alarming treatment as the host
      // probe's "not found" - a real error color is reserved for the
      // actual failed Pair attempt below, not this live-typing hint.
      _PassphraseStatus.invalid => (
        Icon(
          Icons.info_outline,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        'Incorrect passphrase',
        theme.colorScheme.onSurfaceVariant,
      ),
      _PassphraseStatus.idle => (
        const SizedBox.shrink(),
        '',
        Colors.transparent,
      ),
    };

    return _StatusLine(icon: icon, label: label, color: color);
  }
}

class _NameDeviceForm extends StatelessWidget {
  const _NameDeviceForm({required this.nameController, required this.onSave});

  final TextEditingController nameController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: theme.colorScheme.primary,
          size: 48,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Paired successfully',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name this device'),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}
