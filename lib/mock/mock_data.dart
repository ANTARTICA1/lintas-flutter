import '../features/devices/domain/device_model.dart';
import '../features/activity/domain/activity_model.dart';
import '../features/file_transfer/domain/file_transfer_model.dart';

class MockData {
  static List<DeviceModel> get initialDevices => [
    DeviceModel(
      id: 'dev-krisna-pc-01',
      name: 'KRISNA-PC',
      os: 'Windows 11 Pro',
      isTrusted: true,
      isOnline: true,
      ipAddress: '192.168.1.102',
      bleRssi: -52,
      lastConnected: DateTime.now(),
      connectionType: DeviceConnectionType.both,
    ),
    DeviceModel(
      id: 'dev-laptop-krisna-02',
      name: 'LAPTOP-KRISNA',
      os: 'Windows 11 Home',
      isTrusted: true,
      isOnline: false,
      ipAddress: '192.168.1.105',
      bleRssi: null,
      lastConnected: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      connectionType: DeviceConnectionType.lan,
    ),
    DeviceModel(
      id: 'dev-desktop-a12-03',
      name: 'DESKTOP-A12',
      os: 'Windows 10 Pro',
      isTrusted: false,
      isOnline: true,
      ipAddress: '192.168.1.108',
      bleRssi: -76,
      lastConnected: null,
      connectionType: DeviceConnectionType.both,
    ),
  ];

  static List<ActivityModel> get initialActivities => [
    ActivityModel(
      id: 'act-001',
      title: 'Terhubung ke KRISNA-PC',
      description: 'Sesi aman terbentuk melalui LAN (Latensi 3 ms)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      type: ActivityType.connection,
      deviceName: 'KRISNA-PC',
    ),
    ActivityModel(
      id: 'act-002',
      title: 'Laporan_Keuangan_Q3.pdf terkirim',
      description: 'Ukuran berkas 12.4 MB dengan verifikasi integritas SHA-256',
      timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
      type: ActivityType.fileSent,
      deviceName: 'KRISNA-PC',
    ),
    ActivityModel(
      id: 'act-003',
      title: 'Teks Papan Klip diterima',
      description: 'Tautan web diterima dan disimpan ke Kotak Masuk Klip',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: ActivityType.clipboardReceived,
      deviceName: 'KRISNA-PC',
    ),
    ActivityModel(
      id: 'act-004',
      title: 'Touchpad aktif',
      description: 'Sesi kontrol pointer dan gestur selesai',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      type: ActivityType.touchpadUsed,
      deviceName: 'KRISNA-PC',
    ),
    ActivityModel(
      id: 'act-005',
      title: 'NearLock mengunci PC',
      description:
          'PC terkunci otomatis karena sinyal Bluetooth melemah di luar jangkauan',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      type: ActivityType.nearlockTriggered,
      deviceName: 'KRISNA-PC',
    ),
    ActivityModel(
      id: 'act-006',
      title: 'Pemasangan perangkat berhasil',
      description: 'Kunci otorisasi KRISNA-PC tersimpan aman di perangkat',
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      type: ActivityType.pairingSuccess,
      deviceName: 'KRISNA-PC',
    ),
  ];

  static List<FileTransferItem> get initialTransfers => [
    const FileTransferItem(
      id: 'ft-001',
      fileName: 'Dokumen_Spesifikasi_Lintas.pdf',
      totalBytes: 8540000,
      transferredBytes: 5551000,
      speedBytesPerSec: 1850000,
      etaSeconds: 2,
      status: TransferStatus.transferring,
      isOutgoing: true,
    ),
    const FileTransferItem(
      id: 'ft-002',
      fileName: 'Foto_Proyek_2026.zip',
      totalBytes: 47450000,
      transferredBytes: 47450000,
      speedBytesPerSec: 0,
      etaSeconds: 0,
      status: TransferStatus.completed,
      isOutgoing: true,
      sha256Hash:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    ),
  ];
}
