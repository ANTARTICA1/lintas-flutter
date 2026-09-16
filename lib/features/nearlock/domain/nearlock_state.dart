enum NearLockStatus {
  present,
  signalWeak,
  possiblyAway,
  deviceMissing,
  gracePeriod,
  recheck,
  away,
  lockPc,
}

enum NearLockSensitivity { close, normal, far }

class NearLockConfig {
  final bool enabled;
  final NearLockSensitivity sensitivity;
  final int gracePeriodSeconds;
  final bool returnDetectionEnabled;
  final NearLockStatus currentStatus;
  final int countdownRemaining;

  const NearLockConfig({
    this.enabled = true,
    this.sensitivity = NearLockSensitivity.normal,
    this.gracePeriodSeconds = 15,
    this.returnDetectionEnabled = true,
    this.currentStatus = NearLockStatus.present,
    this.countdownRemaining = 0,
  });

  String get sensitivityLabelIndonesian {
    switch (sensitivity) {
      case NearLockSensitivity.close:
        return 'Dekat Sekali (-65 dBm)';
      case NearLockSensitivity.normal:
        return 'Normal (-75 dBm)';
      case NearLockSensitivity.far:
        return 'Jauh (-85 dBm)';
    }
  }

  String get statusLabelIndonesian {
    switch (currentStatus) {
      case NearLockStatus.present:
        return 'Ponsel Terdeteksi Dekat';
      case NearLockStatus.signalWeak:
        return 'Sinyal Bluetooth Melemah';
      case NearLockStatus.possiblyAway:
        return 'Ponsel Mulai Menjauh';
      case NearLockStatus.deviceMissing:
        return 'Ponsel Tidak Ditemukan';
      case NearLockStatus.gracePeriod:
        return 'Masa Tenggang Penguncian ($countdownRemaining dtk)';
      case NearLockStatus.recheck:
        return 'Memeriksa Ulang Sinyal';
      case NearLockStatus.away:
        return 'Ponsel di Luar Jangkauan';
      case NearLockStatus.lockPc:
        return 'PC Terkunci';
    }
  }

  NearLockConfig copyWith({
    bool? enabled,
    NearLockSensitivity? sensitivity,
    int? gracePeriodSeconds,
    bool? returnDetectionEnabled,
    NearLockStatus? currentStatus,
    int? countdownRemaining,
  }) {
    return NearLockConfig(
      enabled: enabled ?? this.enabled,
      sensitivity: sensitivity ?? this.sensitivity,
      gracePeriodSeconds: gracePeriodSeconds ?? this.gracePeriodSeconds,
      returnDetectionEnabled:
          returnDetectionEnabled ?? this.returnDetectionEnabled,
      currentStatus: currentStatus ?? this.currentStatus,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
    );
  }
}
