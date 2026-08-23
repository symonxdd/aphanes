import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../models/device.dart';
import '../models/device_info.dart';

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
    await _storage.delete(_infoKey(deviceId));
    final List<String> ids = await _readIndex();
    ids.remove(deviceId);
    await _writeIndex(ids);
  }

  /// The last hardware/firmware facts fetched from each paired TV, keyed
  /// by device id. Read in one pass at startup so the device detail page
  /// has them synchronously and can render immediately instead of
  /// spinning while a fresh copy is fetched behind it.
  ///
  /// In the same secure store as the device records themselves rather
  /// than plain prefs. None of these fields is a credential on its own,
  /// but they are keyed by device id, and the project's rule puts device
  /// ids in secure storage - so this sits there too rather than
  /// splitting one device's data across two stores by field.
  Future<Map<String, DeviceInfo>> loadAllInfo() async {
    final List<String> ids = await _readIndex();
    final Map<String, DeviceInfo> infos = {};
    for (final String id in ids) {
      final String? raw = await _storage.read(_infoKey(id));
      if (raw != null) {
        infos[id] = DeviceInfo.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    }
    return infos;
  }

  Future<void> saveInfo(String deviceId, DeviceInfo info) {
    return _storage.write(_infoKey(deviceId), jsonEncode(info.toJson()));
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

  String _infoKey(String id) => 'device_info_$id';
}
