import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../core/network/protocol_message.dart';
import '../../../mock/mock_providers.dart';
import '../../companion/domain/companion_context_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CompanionContextModel _activeContext =
      CompanionContextModel.presentationActive;

  void _sendCommand(CommandType type, [Map<String, dynamic>? payload]) {
    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
      payload: payload ?? {},
    );
    transport.sendMessage(message);
  }

  void _showConfirmationDialog(
    String title,
    String content,
    CommandType command,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.of(context).pop();
                _sendCommand(command);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Perintah $title telah dikirim ke PC'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionControllerProvider);
    final devices = ref.watch(devicesListProvider);
    final nearlockConfig = ref.watch(nearlockConfigProvider);

    final otherTrustedDevices = devices
        .where((d) => d.isTrusted && d.id != connectionState.connectedDeviceId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Krisna',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'Lintas Ecosystem',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Pindai QR PC',
            onPressed: () => context.push('/qr-scanner'),
          ),
          IconButton(
            icon: const Icon(Icons.desktop_windows_rounded),
            tooltip: 'Tampilan Windows Companion',
            onPressed: () => context.push('/windows-companion'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!connectionState.isConnected) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.computer_rounded,
                          size: 48,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Hubungkan Komputer Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Gunakan ponsel cerdas untuk mengontrol, memindahkan berkas, dan mengamankan PC secara instan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('HUBUNGKAN PC SEKARANG'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        onPressed: () => context.push('/qr-scanner'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'TIGA LANGKAH MUDAH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildStepItem('1', 'Buka Lintas Companion pada Windows'),
                      _buildStepItem('2', 'Pindai kode QR yang muncul di PC'),
                      _buildStepItem('3', 'Kedua perangkat terhubung otomatis'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark.withAlpha(30),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.computer_rounded,
                                  color: AppColors.primaryDark,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    connectionState.connectedDeviceName ??
                                        'KRISNA-PC',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    connectionState.connectedDeviceOs ??
                                        'Windows 11 Pro',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(150),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(30),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Terhubung',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.flash_on_rounded,
                            size: 15,
                            color: AppColors.secondaryDark,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Koneksi Cepat: ${connectionState.transportLabelIndonesian} • ${connectionState.latencyMs} ms',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 15,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Secure Presence: Ponsel Terdeteksi Dekat • NearLock ${nearlockConfig.enabled ? "Aktif" : "Nonaktif"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                      if (otherTrustedDevices.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Text(
                              'Pindah Perangkat: ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                            ...otherTrustedDevices.map((d) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                ),
                                child: ActionChip(
                                  label: Text(
                                    d.name,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(
                                          connectionControllerProvider.notifier,
                                        )
                                        .connect(d.id);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.primaryDark.withAlpha(60),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.co_present_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeContext.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _activeContext.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                      ),
                      onPressed: () => context.push(_activeContext.routePath),
                      child: const Text('BUKA'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Kontrol Cepat',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _buildQuickCard(
                    title: 'Touchpad',
                    icon: Icons.touch_app_rounded,
                    onTap: () => context.push('/touchpad'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildQuickCard(
                    title: 'Papan Ketik',
                    icon: Icons.keyboard_rounded,
                    onTap: () => context.push('/keyboard'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _buildQuickCard(
                    title: 'Instant Drop',
                    icon: Icons.flash_on_rounded,
                    onTap: () => context.push('/files'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildQuickCard(
                    title: 'Papan Klip',
                    icon: Icons.assignment_rounded,
                    onTap: () => context.push('/clipboard'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Pengontrol Media PC',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton.outlined(
                            iconSize: 26,
                            icon: const Icon(Icons.skip_previous_rounded),
                            onPressed: () =>
                                _sendCommand(CommandType.mediaPrevious),
                          ),
                          IconButton.filled(
                            iconSize: 34,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () =>
                                _sendCommand(CommandType.mediaPlayPause),
                          ),
                          IconButton.outlined(
                            iconSize: 26,
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed: () =>
                                _sendCommand(CommandType.mediaNext),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.volume_down_rounded,
                              size: 18,
                            ),
                            label: const Text('Kecilkan'),
                            onPressed: () =>
                                _sendCommand(CommandType.volumeDown),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.volume_up_rounded, size: 18),
                            label: const Text('Besarkan'),
                            onPressed: () => _sendCommand(CommandType.volumeUp),
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.volume_off_rounded,
                              size: 18,
                            ),
                            label: const Text('Bisu'),
                            onPressed: () =>
                                _sendCommand(CommandType.volumeMute),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Aksi Cepat PC',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.lock_outline_rounded, size: 16),
                    label: const Text('Kunci PC'),
                    onPressed: () {
                      _sendCommand(CommandType.pcLock);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perintah Kunci PC telah dikirim'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.co_present_rounded, size: 16),
                    label: const Text('Remote Presentasi'),
                    onPressed: () => context.push('/presentation'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.screenshot_rounded, size: 16),
                    label: const Text('Cuplikan Layar'),
                    onPressed: () {
                      _sendCommand(CommandType.screenshot);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cuplikan layar PC disimpan'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.desktop_windows_rounded, size: 16),
                    label: const Text('Desktop'),
                    onPressed: () => _sendCommand(CommandType.showDesktop),
                  ),
                  ActionChip(
                    avatar: const Icon(
                      Icons.restart_alt_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Mulai Ulang',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _showConfirmationDialog(
                      'Mulai Ulang PC',
                      'Apakah Anda yakin ingin memulai ulang PC?',
                      CommandType.restartPc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppColors.primaryDark),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
