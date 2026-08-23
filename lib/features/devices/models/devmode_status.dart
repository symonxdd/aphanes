/// Whether this TV currently has a live webOS Developer Mode session, and
/// how long is left on it. webOS's own Developer Mode sessions expire
/// periodically by design; this is what "Renew" on the device detail page
/// acts on.
class DevModeStatus {
  const DevModeStatus({this.token, this.remaining});

  final String? token;
  final String? remaining;

  bool get hasToken => token != null;
}
