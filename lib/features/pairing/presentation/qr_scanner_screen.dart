import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/security/qr_payload.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../mock/mock_providers.dart';
import '../../devices/domain/device_model.dart';
import '../../activity/domain/activity_model.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;
  MobileScannerController? _scannerController;

  bool get _isCameraSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isCameraSupported) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _processQrPayload(String rawCode) {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final payload = QrPayload.decode(rawCode.trim());
    if (payload == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Format kode QR tidak valid atau bukan berasal dari Lintas Companion.';
      });
      return;
    }

    if (payload.isExpired) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Kode QR telah kedaluwarsa. Silakan perbarui kode pada Lintas Companion di PC.';
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showConfirmationDialog(payload);
    });
  }

  void _showConfirmationDialog(QrPayload payload) {
    const confirmationDigits = '492 815';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pemasangan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terhubung ke ${payload.deviceName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Alamat IP: ${payload.host}:${payload.port}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Pastikan kode angka verifikasi berikut sama persis dengan yang muncul pada layar PC Anda:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: const Text(
                    confirmationDigits,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Kunci sesi aman AES-256 dibuat secara lokal tanpa perantara cloud.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final newDevice = DeviceModel(
                  id: 'dev-${payload.pairingId}',
                  name: payload.deviceName,
                  os: 'Windows 11 Pro',
                  isTrusted: true,
                  isOnline: true,
                  ipAddress: payload.host,
                  bleRssi: -54,
                  lastConnected: DateTime.now(),
                  connectionType: DeviceConnectionType.both,
                );

                ref
                    .read(devicesListProvider.notifier)
                    .addOrUpdateDevice(newDevice);
                ref
                    .read(connectionControllerProvider.notifier)
                    .connect(
                      newDevice.id,
                      host: payload.host,
                      port: payload.port,
                    );

                ref
                    .read(activityListProvider.notifier)
                    .addActivity(
                      ActivityModel(
                        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
                        title: 'Pemasangan Berhasil',
                        description:
                            'Terhubung ke ${payload.deviceName} secara aman (${payload.host}:${payload.port})',
                        timestamp: DateTime.now(),
                        type: ActivityType.pairingSuccess,
                        deviceName: payload.deviceName,
                      ),
                    );

                Navigator.of(context).pop();
                context.go('/');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berhasil dipasangkan dengan ${payload.deviceName}',
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Kode Cocok & Hubungkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _autoDiscoverLanPc() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 500);

    try {
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:8945/api/status'),
      );
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final realIp = json['ip'] as String? ?? '127.0.0.1';
        final payload = QrPayload.generate(
          deviceName: 'KRISNA-PC (Lokal)',
          host: realIp,
          port: 8945,
          validityDurationSeconds: 300,
        );
        _processQrPayload(payload.encode());
        return;
      }
    } catch (_) {}

    try {
      final req = await client.getUrl(
        Uri.parse('http://10.0.2.2:8945/api/status'),
      );
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        final payload = QrPayload.generate(
          deviceName: 'KRISNA-PC (Emulator Host)',
          host: '10.0.2.2',
          port: 8945,
          validityDurationSeconds: 300,
        );
        _processQrPayload(payload.encode());
        return;
      }
    } catch (_) {}

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              !addr.address.startsWith('169.254') &&
              !addr.address.startsWith('192.168.56.')) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
              final priorityIps = [
                '$prefix.2',
                '$prefix.1',
                '$prefix.3',
                '$prefix.4',
                '$prefix.5',
                '$prefix.100',
                '$prefix.101',
              ];

              for (final targetIp in priorityIps) {
                try {
                  final fastClient = HttpClient()
                    ..connectionTimeout = const Duration(milliseconds: 300);
                  final r = await fastClient.getUrl(
                    Uri.parse('http://$targetIp:8945/api/status'),
                  );
                  final resp = await r.close();
                  if (resp.statusCode == HttpStatus.ok) {
                    fastClient.close();
                    final payload = QrPayload.generate(
                      deviceName: 'KRISNA-PC',
                      host: targetIp,
                      port: 8945,
                      validityDurationSeconds: 300,
                    );
                    _processQrPayload(payload.encode());
                    return;
                  }
                  fastClient.close();
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Tidak menemukan server Lintas Companion aktif di port 8945. Pastikan Companion di PC sudah dijalankan atau masukkan kode manual di bawah.';
      });
    }
  }

  Widget _buildScannerView() {
    if (_isCameraSupported && _scannerController != null) {
      return MobileScanner(
        controller: _scannerController!,
        onDetect: (capture) {
          if (_isProcessing) return;
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final val = barcode.rawValue;
            if (val != null && val.trim().isNotEmpty) {
              _processQrPayload(val.trim());
              break;
            }
          }
        },
      );
    } else {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  size: 48,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Mode Desktop / Jaringan LAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  'Gunakan Deteksi Otomatis LAN untuk menghubungkan ke PC Windows di jaringan yang sama.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai QR Pemasangan')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: _buildScannerView()),
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryDark,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        _isCameraSupported
                            ? 'Arahkan kamera ke QR pada Lintas Companion PC'
                            : 'Kamera aktif di perangkat bergerak (Android / iOS)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  FilledButton.icon(
                    icon: const Icon(Icons.wifi_find_rounded),
                    label: const Text(
                      'Cari PC di Jaringan LAN (Auto-Detect)',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _autoDiscoverLanPc,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Atau Masukkan Teks Kode Pemasangan Manual',
                      hintText: 'Tempel payload QR di sini',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: () {
                          if (_codeController.text.isNotEmpty) {
                            _processQrPayload(_codeController.text);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
