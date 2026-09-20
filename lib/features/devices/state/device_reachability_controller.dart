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
      // Only the address is watched, not the whole list: a rename or
      // another TV's change is no reason to ask this one again, and it
      // used to send every dot to "Checking..." for a purely local edit.
      final (String, int)? address = await ref.watch(
        deviceListProvider.selectAsync((List<Device> devices) {
          for (final Device d in devices) {
            if (d.id == deviceId) {
              return (d.host, d.port);
            }
          }
          return null;
        }),
      );
      if (address == null) {
        return false;
      }
      final (String host, int port) = address;
      try {
        final Socket socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 3),
        );
        unawaited(socket.close());
        return true;
      } catch (_) {
        return false;
      }
    });
