enum PresenceStatus { unknown, present, weak, away }

class PresenceState {
  final PresenceStatus status;
  final int smoothedRssi;
  final List<int> rawSamples;
  final DateTime lastObservation;
  final bool isReturnDetected;

  const PresenceState({
    this.status = PresenceStatus.unknown,
    this.smoothedRssi = -100,
    this.rawSamples = const [],
    required this.lastObservation,
    this.isReturnDetected = false,
  });

  String get statusLabelIndonesian {
    switch (status) {
      case PresenceStatus.unknown:
        return 'Tidak Diketahui';
      case PresenceStatus.present:
        return 'Ponsel Terdeteksi Dekat';
      case PresenceStatus.weak:
        return 'Sinyal Ponsel Melemah';
      case PresenceStatus.away:
        return 'Ponsel Berada di Luar Jangkauan';
    }
  }

  PresenceState addSample(int rssi, {int maxSamples = 5}) {
    final updated = [...rawSamples, rssi];
    if (updated.length > maxSamples) {
      updated.removeAt(0);
    }
    final sum = updated.reduce((a, b) => a + b);
    final avg = (sum / updated.length).round();

    PresenceStatus newStatus;
    if (avg > -68) {
      newStatus = PresenceStatus.present;
    } else if (avg > -82) {
      newStatus = PresenceStatus.weak;
    } else {
      newStatus = PresenceStatus.away;
    }

    final returnDetected =
        status == PresenceStatus.away && newStatus == PresenceStatus.present;

    return PresenceState(
      status: newStatus,
      smoothedRssi: avg,
      rawSamples: updated,
      lastObservation: DateTime.now(),
      isReturnDetected: returnDetected,
    );
  }
}
