/// A homebrew or system app currently installed on a paired TV, as reported
/// by `luna://com.webos.applicationManager/dev/listApps`. Only apps with
/// `visible: true` ever become one of these - `AppsService` filters the rest
/// out before this model exists at all, matching the reference CLI.
class InstalledApp {
  const InstalledApp({
    required this.id,
    required this.title,
    required this.version,
    this.vendor,
  });

  factory InstalledApp.fromJson(Map<String, dynamic> json) {
    return InstalledApp(
      id: json['id'] as String,
      title: json['title'] as String,
      version: json['version'] as String,
      vendor: json['vendor'] as String?,
    );
  }

  final String id;
  final String title;
  final String version;
  final String? vendor;
}
