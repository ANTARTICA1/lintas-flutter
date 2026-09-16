import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrPayload {
  final int protocolVersion;
  final String pairingId;
  final String deviceName;
  final String deviceFingerprint;
  final String host;
  final int port;
  final int expiresAt;
  final String nonce;

  const QrPayload({
    this.protocolVersion = 1,
    required this.pairingId,
    required this.deviceName,
    required this.deviceFingerprint,
    required this.host,
    required this.port,
    required this.expiresAt,
    required this.nonce,
  });

  bool get isExpired {
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  int get remainingSeconds {
    final diff = expiresAt - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return 0;
    return diff ~/ 1000;
  }

  String encode() {
    final map = {
      'v': protocolVersion,
      'id': pairingId,
      'name': deviceName,
      'fp': deviceFingerprint,
      'host': host,
      'port': port,
      'exp': expiresAt,
      'n': nonce,
    };
    final rawJson = jsonEncode(map);
    return base64Url.encode(utf8.encode(rawJson));
  }

  static QrPayload? decode(String raw) {
    try {
      final decodedJson = utf8.decode(base64Url.decode(raw));
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;
      return QrPayload(
        protocolVersion: map['v'] as int? ?? 1,
        pairingId: map['id'] as String? ?? '',
        deviceName: map['name'] as String? ?? '',
        deviceFingerprint: map['fp'] as String? ?? '',
        host: map['host'] as String? ?? '',
        port: map['port'] as int? ?? 8945,
        expiresAt: map['exp'] as int? ?? 0,
        nonce: map['n'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static QrPayload generate({
    required String deviceName,
    required String host,
    int port = 8945,
    int validityDurationSeconds = 120,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + (validityDurationSeconds * 1000);
    final nonce = sha256
        .convert(utf8.encode('$now-$deviceName'))
        .toString()
        .substring(0, 16);
    final pairingId = sha256
        .convert(utf8.encode('$nonce-$expiresAt'))
        .toString()
        .substring(0, 12);
    final fingerprint = sha256
        .convert(utf8.encode('$deviceName-$host'))
        .toString()
        .substring(0, 24);

    return QrPayload(
      protocolVersion: 1,
      pairingId: pairingId,
      deviceName: deviceName,
      deviceFingerprint: fingerprint,
      host: host,
      port: port,
      expiresAt: expiresAt,
      nonce: nonce,
    );
  }
}
