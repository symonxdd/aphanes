/** Mirrors the mobile app's core/validation/ipv4.dart: four dotted octets, 0 to 255 each. */
const ipv4 = /^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/;

export function isValidIpv4(value: string): boolean {
  return ipv4.test(value);
}
