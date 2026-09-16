enum ConnectionStatus {
  disconnected,
  discovering,
  deviceFound,
  pairing,
  authenticating,
  connected,
  reconnecting,
}

enum TransportType { none, lan, bluetooth }

enum ConnectionQuality { excellent, good, weak, unstable }

class ConnectionStateModel {
  final ConnectionStatus status;
  final TransportType transport;
  final ConnectionQuality quality;
  final int latencyMs;
  final String? connectedDeviceId;
  final String? connectedDeviceName;
  final String? connectedDeviceOs;
  final String? connectedHost;
  final int? connectedPort;
  final String? errorMessage;

  const ConnectionStateModel({
    this.status = ConnectionStatus.disconnected,
    this.transport = TransportType.none,
    this.quality = ConnectionQuality.good,
    this.latencyMs = 0,
    this.connectedDeviceId,
    this.connectedDeviceName,
    this.connectedDeviceOs,
    this.connectedHost,
    this.connectedPort,
    this.errorMessage,
  });

  bool get isConnected => status == ConnectionStatus.connected;

  String get statusLabelIndonesian {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Terputus';
      case ConnectionStatus.discovering:
        return 'Memindai Perangkat';
      case ConnectionStatus.deviceFound:
        return 'Perangkat Ditemukan';
      case ConnectionStatus.pairing:
        return 'Memasangkan';
      case ConnectionStatus.authenticating:
        return 'Mengautentikasi';
      case ConnectionStatus.connected:
        return 'Terhubung';
      case ConnectionStatus.reconnecting:
        return 'Menyambung Ulang';
    }
  }

  String get transportLabelIndonesian {
    switch (transport) {
      case TransportType.lan:
        return 'LAN (Mode Cepat)';
      case TransportType.bluetooth:
        return 'Bluetooth (Mode Sekitar)';
      case TransportType.none:
        return 'Tidak Ada';
    }
  }

  String get qualityLabelIndonesian {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Sangat Baik';
      case ConnectionQuality.good:
        return 'Baik';
      case ConnectionQuality.weak:
        return 'Lemah';
      case ConnectionQuality.unstable:
        return 'Tidak Stabil';
    }
  }

  ConnectionStateModel copyWith({
    ConnectionStatus? status,
    TransportType? transport,
    ConnectionQuality? quality,
    int? latencyMs,
    String? connectedDeviceId,
    String? connectedDeviceName,
    String? connectedDeviceOs,
    String? connectedHost,
    int? connectedPort,
    String? errorMessage,
  }) {
    return ConnectionStateModel(
      status: status ?? this.status,
      transport: transport ?? this.transport,
      quality: quality ?? this.quality,
      latencyMs: latencyMs ?? this.latencyMs,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      connectedDeviceOs: connectedDeviceOs ?? this.connectedDeviceOs,
      connectedHost: connectedHost ?? this.connectedHost,
      connectedPort: connectedPort ?? this.connectedPort,
      errorMessage: errorMessage,
    );
  }
}
