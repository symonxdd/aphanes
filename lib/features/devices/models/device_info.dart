/// Static hardware/firmware facts about a paired TV, read directly from it
/// over the luna-bus. None of this changes without a firmware update, so
/// it is cached between visits to the device detail page (see
/// `DeviceStorageService.saveInfo`) and shown immediately on reopening
/// while a fresh copy is fetched behind it.
///
/// Deliberately does not include the Developer Mode session alongside it:
/// that is a live countdown and a stored credential, and neither belongs
/// in a cache meant to be displayed before it has been re-verified.
class DeviceInfo {
  const DeviceInfo({
    this.modelName,
    this.firmwareVersion,
    this.webosVersion,
    this.otaId,
    this.socName,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      modelName: json['modelName'] as String?,
      firmwareVersion: json['firmwareVersion'] as String?,
      webosVersion: json['webosVersion'] as String?,
      otaId: json['otaId'] as String?,
      socName: json['socName'] as String?,
    );
  }

  final String? modelName;
  final String? firmwareVersion;
  final String? webosVersion;
  final String? otaId;
  final String? socName;

  /// True when the TV reported nothing usable at all, in which case there
  /// is no point persisting it or rendering a section of blank rows.
  bool get isEmpty =>
      modelName == null &&
      firmwareVersion == null &&
      webosVersion == null &&
      otaId == null &&
      socName == null;

  Map<String, dynamic> toJson() => {
    'modelName': modelName,
    'firmwareVersion': firmwareVersion,
    'webosVersion': webosVersion,
    'otaId': otaId,
    'socName': socName,
  };

  // Value equality so a re-fetch that returns exactly what is already
  // cached (the normal case, since none of this changes without a
  // firmware update) skips both the secure-storage write and the
  // rebuild it would otherwise trigger.
  @override
  bool operator ==(Object other) =>
      other is DeviceInfo &&
      other.modelName == modelName &&
      other.firmwareVersion == firmwareVersion &&
      other.webosVersion == webosVersion &&
      other.otaId == otaId &&
      other.socName == socName;

  @override
  int get hashCode =>
      Object.hash(modelName, firmwareVersion, webosVersion, otaId, socName);
}
