enum TransferStatus {
  waiting,
  transferring,
  paused,
  completed,
  failed,
  cancelled,
}

class FileTransferItem {
  final String id;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final int speedBytesPerSec;
  final int etaSeconds;
  final TransferStatus status;
  final bool isOutgoing;
  final String? sha256Hash;
  final String? errorMessage;
  final String? localPath;

  const FileTransferItem({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.speedBytesPerSec = 0,
    this.etaSeconds = 0,
    this.status = TransferStatus.waiting,
    this.isOutgoing = true,
    this.sha256Hash,
    this.errorMessage,
    this.localPath,
  });

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get formattedSize {
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String get formattedSpeed {
    if (speedBytesPerSec < 1024) {
      return '$speedBytesPerSec B/s';
    } else if (speedBytesPerSec < 1024 * 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  String get statusLabelIndonesian {
    switch (status) {
      case TransferStatus.waiting:
        return 'Menunggu';
      case TransferStatus.transferring:
        return 'Mengirim ($formattedSpeed)';
      case TransferStatus.paused:
        return 'Dijeda';
      case TransferStatus.completed:
        return 'Selesai';
      case TransferStatus.failed:
        return 'Gagal';
      case TransferStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  FileTransferItem copyWith({
    String? id,
    String? fileName,
    int? totalBytes,
    int? transferredBytes,
    int? speedBytesPerSec,
    int? etaSeconds,
    TransferStatus? status,
    bool? isOutgoing,
    String? sha256Hash,
    String? errorMessage,
    String? localPath,
  }) {
    return FileTransferItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      status: status ?? this.status,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      errorMessage: errorMessage ?? this.errorMessage,
      localPath: localPath ?? this.localPath,
    );
  }
}
