import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/security/qr_payload.dart';
import '../../../core/network/lan_server_service.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../mock/mock_providers.dart';
import 'windows_drop_zone_widget.dart';

class WindowsCompanionScreen extends ConsumerStatefulWidget {
  const WindowsCompanionScreen({super.key});

  @override
  ConsumerState<WindowsCompanionScreen> createState() =>
      _WindowsCompanionScreenState();
}

class _WindowsCompanionScreenState
    extends ConsumerState<WindowsCompanionScreen> {
  late QrPayload _currentPayload;
  Timer? _countdownTimer;
  int _remainingSeconds = 120;
  bool _startWithWindows = false;
  bool _showDropZone = false;
  bool _pauseConnections = false;
  StreamSubscription? _serverSub;
  StreamSubscription? _clientSub;

  @override
  void initState() {
    super.initState();
    _currentPayload = QrPayload.generate(
      deviceName: 'KRISNA-PC',
      host: LanServerService.instance.localIp,
      port: LanServerService.instance.port,
      validityDurationSeconds: 120,
    );
    _initServer();
  }

  Future<void> _initServer() async {
    await LanServerService.instance.startServer(port: 8945);
    _generateNewPayload();

    _serverSub = LanServerService.instance.statusStream.listen((_) {
      if (mounted) setState(() {});
    });
    _clientSub = LanServerService.instance.clientCountStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _serverSub?.cancel();
    _clientSub?.cancel();
    super.dispose();
  }

  void _generateNewPayload() {
    _countdownTimer?.cancel();
    final realIp = LanServerService.instance.localIp;
    final port = LanServerService.instance.port;

    _currentPayload = QrPayload.generate(
      deviceName: 'KRISNA-PC',
      host: realIp,
      port: port,
      validityDurationSeconds: 120,
    );
    _remainingSeconds = 120;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
    setState(() {});
  }

  String get _formattedRemainingTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionControllerProvider);
    final nearlockConfig = ref.watch(nearlockConfigProvider);
    final isServerActive = LanServerService.instance.isRunning;
    final serverIp = LanServerService.instance.localIp;
    final serverPort = LanServerService.instance.port;
    final clientCount = LanServerService.instance.clientCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.devices_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Lintas Companion',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_android_rounded),
            tooltip: 'Buka Tampilan Mode Remote Mobile',
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isServerActive
                  ? AppColors.success.withAlpha(30)
                  : AppColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isServerActive
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isServerActive
                      ? 'Server Aktif (Port $serverPort)'
                      : 'Server Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isServerActive
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Text(
                        'KRISNA-PC',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Windows 11 Pro • ws://$serverIp:$serverPort',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                      if (LanServerService.instance.availableIps.length > 1) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Pilih IP:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            for (final ip in LanServerService.instance.availableIps)
                              ChoiceChip(
                                label: Text(
                                  ip == '192.168.1.2' ? '$ip (Wi-Fi)' : ip,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selected: serverIp == ip,
                                onSelected: (selected) {
                                  if (selected) {
                                    LanServerService.instance.setLocalIp(ip);
                                    _generateNewPayload();
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PERANGKAT TERHUBUNG',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (clientCount > 0 ||
                                              connectionState.isConnected)
                                          ? AppColors.primaryDark.withAlpha(40)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      color:
                                          (clientCount > 0 ||
                                              connectionState.isConnected)
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondaryDark,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (clientCount > 0 ||
                                                  connectionState.isConnected)
                                              ? 'Ponsel Terhubung ($clientCount klien aktif)'
                                              : 'Menunggu koneksi ponsel...',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          (clientCount > 0 ||
                                                  connectionState.isConnected)
                                              ? 'Mode Cepat • LAN WebSocket • Siap Terima Perintah'
                                              : 'Buka Lintas pada ponsel dan pindai QR di samping',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(150),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Divider(),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Text(
                                    'NearLock: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    nearlockConfig.enabled
                                        ? 'Aktif'
                                        : 'Nonaktif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: nearlockConfig.enabled
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.bluetooth_rounded,
                                    size: 16,
                                    color: AppColors.secondaryDark,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Text(
                                    'Kehadiran: Ponsel Dekat',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'PENGATURAN CEPAT WINDOWS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: const Icon(
                                Icons.power_settings_new_rounded,
                              ),
                              title: const Text('Mulai Bersama Windows'),
                              subtitle: const Text(
                                'Lintas berjalan di latar belakang saat PC dinyalakan.',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _startWithWindows,
                              onChanged: (val) =>
                                  setState(() => _startWithWindows = val),
                            ),
                            const Divider(),
                            SwitchListTile(
                              secondary: const Icon(
                                Icons.pause_circle_outline_rounded,
                              ),
                              title: const Text('Jeda Koneksi'),
                              subtitle: const Text(
                                'Tolak perintah jarak jauh sementara waktu tanpa menutup aplikasi.',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _pauseConnections,
                              onChanged: (val) {
                                LanServerService.instance.isPaused = val;
                                setState(() => _pauseConnections = val);
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.drag_indicator_rounded),
                              title: const Text(
                                'Zona Tarik Berkas (Drop Zone)',
                              ),
                              subtitle: const Text(
                                'Buka jendela mengambang untuk menarik berkas ke ponsel.',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: FilledButton.tonal(
                                onPressed: () {
                                  setState(
                                    () => _showDropZone = !_showDropZone,
                                  );
                                },
                                child: Text(
                                  _showDropZone ? 'Sembunyikan' : 'Tampilkan',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Pemasangan Cepat QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Pindai QR ini dari aplikasi ponsel Lintas untuk terhubung langsung ke PC.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 2,
                            ),
                          ),
                          child: QrImageView(
                            data: _currentPayload.encode(),
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _remainingSeconds > 0
                                  ? Icons.timer_outlined
                                  : Icons.error_outline_rounded,
                              size: 16,
                              color: _remainingSeconds > 0
                                  ? AppColors.textSecondaryDark
                                  : AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _remainingSeconds > 0
                                  ? 'Kedaluwarsa dalam $_formattedRemainingTime'
                                  : 'Kode telah kedaluwarsa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _remainingSeconds > 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Buat Kode Baru'),
                          onPressed: _generateNewPayload,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showDropZone)
              Positioned(
                top: 40,
                right: 40,
                child: WindowsDropZoneWidget(
                  onClose: () => setState(() => _showDropZone = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
