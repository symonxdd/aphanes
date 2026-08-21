import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import 'device_list_controller.dart';

/// Whether a paired device currently answers on its SSH port - not a full
/// SSH handshake, just a raw TCP connect with a short timeout. Enough to
/// tell "TV off / wrong network / unreachable" apart from "TV is there but
/// something else is wrong", without the cost of a real connection.
///
/// `autoDispose`, not cached for the app's lifetime: leaving and
/// returning to a screen that watches this (or a pull-to-refresh) is what
/// re-checks it, rather than a background timer polling a device nobody's
/// currently looking at.
final deviceReachabilityProvider = FutureProvider.autoDispose
    .family<bool, String>((Ref ref, String deviceId) async {
      final List<Device> devices = await ref.watch(deviceListProvider.future);
      Device? device;
      for (final Device d in devices) {
        if (d.id == deviceId) {
          device = d;
          break;
        }
      }
      if (device == null) {
        return false;
      }
      try {
        final Socket socket = await Socket.connect(
          device.host,
          device.port,
          timeout: const Duration(seconds: 3),
        );
        unawaited(socket.close());
        return true;
      } catch (_) {
        return false;
      }
    });
