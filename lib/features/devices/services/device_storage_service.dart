import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../models/device.dart';

const String _indexKey = 'device_ids';

/// Persists paired devices, private keys included, entirely through
/// platform secure storage (Keystore/Keychain-backed) - never plaintext
/// prefs, per the project's device-credential handling rule.
class DeviceStorageService {
  DeviceStorageService(this._storage);

  final SecureKeyValueStore _storage;

  Future<List<Device>> loadAll() async {
    final List<String> ids = await _readIndex();
    final List<Device> devices = [];
    for (final String id in ids) {
      final String? raw = await _storage.read(_deviceKey(id));
      if (raw != null) {
        devices.add(Device.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      }
    }
    return devices;
  }

  Future<void> save(Device device) async {
    await _storage.write(_deviceKey(device.id), jsonEncode(device.toJson()));
    final List<String> ids = await _readIndex();
    if (!ids.contains(device.id)) {
      ids.add(device.id);
      await _writeIndex(ids);
    }
  }

  Future<void> delete(String deviceId) async {
    await _storage.delete(_deviceKey(deviceId));
    final List<String> ids = await _readIndex();
    ids.remove(deviceId);
    await _writeIndex(ids);
  }

  Future<List<String>> _readIndex() async {
    final String? raw = await _storage.read(_indexKey);
    if (raw == null) {
      return [];
    }
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  Future<void> _writeIndex(List<String> ids) {
    return _storage.write(_indexKey, jsonEncode(ids));
  }

  String _deviceKey(String id) => 'device_$id';
}
