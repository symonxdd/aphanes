/// Matches a dotted-quad IPv4 address (each octet 0-255).
final RegExp ipv4Pattern = RegExp(
  r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
  r'(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$',
);
