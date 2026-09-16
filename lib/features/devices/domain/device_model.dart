enum DeviceConnectionType { lan, bluetooth, both }

class DeviceModel {
  final String id;
  final String name;
  final String os;
  final bool isTrusted;
  final bool isOnline;
  final String? ipAddress;
  final int? bleRssi;
  final DateTime? lastConnected;
  final DeviceConnectionType connectionType;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.os,
    this.isTrusted = false,
    this.isOnline = false,
    this.ipAddress,
    this.bleRssi,
    this.lastConnected,
    this.connectionType = DeviceConnectionType.lan,
  });

  String get proximityLabelIndonesian {
    if (bleRssi == null) {
      return 'Jarak Tidak Diketahui';
    }
    if (bleRssi! > -60) {
      return 'Sangat Dekat';
    } else if (bleRssi! > -75) {
      return 'Dekat';
    } else if (bleRssi! > -90) {
      return 'Sedang';
    } else {
      return 'Jauh';
    }
  }

  String get connectionTypeLabelIndonesian {
    switch (connectionType) {
      case DeviceConnectionType.lan:
        return 'LAN (Mode Cepat)';
      case DeviceConnectionType.bluetooth:
        return 'Bluetooth (Mode Sekitar)';
      case DeviceConnectionType.both:
        return 'LAN & Bluetooth';
    }
  }

  String get statusLabelIndonesian {
    if (!isOnline) {
      return 'Offline';
    }
    if (isTrusted) {
      return 'Siap Tersambung';
    }
    return 'Siap Dipasangkan';
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? os,
    bool? isTrusted,
    bool? isOnline,
    String? ipAddress,
    int? bleRssi,
    DateTime? lastConnected,
    DeviceConnectionType? connectionType,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      os: os ?? this.os,
      isTrusted: isTrusted ?? this.isTrusted,
      isOnline: isOnline ?? this.isOnline,
      ipAddress: ipAddress ?? this.ipAddress,
      bleRssi: bleRssi ?? this.bleRssi,
      lastConnected: lastConnected ?? this.lastConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}
