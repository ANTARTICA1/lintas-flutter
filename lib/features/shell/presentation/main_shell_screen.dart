import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/protocol_message.dart';
import '../../../core/network/file_transfer_service.dart';
import '../../../mock/mock_providers.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../activity/domain/activity_model.dart';
import '../../file_transfer/domain/file_transfer_model.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _msgSub = ref
          .read(transportServiceProvider)
          .messageStream
          .listen((msg) {
        if (msg.type == CommandType.fileTransferRequest) {
          if (!mounted) return;
          final location = GoRouterState.of(context).matchedLocation;
          if (location != '/files') {
            _showIncomingFileDialog(msg);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  void _showIncomingFileDialog(ProtocolMessage msg) {
    final fileName = msg.payload['fileName'] as String? ?? 'berkas_unduhan';
    final size = msg.payload['size'] as int? ?? 0;
    final remotePath = msg.payload['remotePath'] as String? ?? '';
    final connectionState = ref.read(connectionControllerProvider);
    final host = (msg.payload['host'] as String?) ??
        connectionState.connectedHost ??
        '127.0.0.1';
    final port = (msg.payload['port'] as int?) ??
        connectionState.connectedPort ??
        8945;

    final formattedSize = FileTransferItem(
      id: '',
      fileName: fileName,
      totalBytes: size,
      transferredBytes: 0,
      status: TransferStatus.transferring,
      isOutgoing: false,
    ).formattedSize;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Berkas Masuk'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${msg.deviceId} ingin mengirimkan berkas:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            formattedSize,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tolak'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('Terima & Unduh'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _downloadFile(
                  host: host,
                  port: port,
                  remotePath: remotePath,
                  fileName: fileName,
                  totalBytes: size,
                  deviceName: msg.deviceId,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadFile({
    required String host,
    required int port,
    required String remotePath,
    required String fileName,
    required int totalBytes,
    required String deviceName,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mengunduh $fileName dari $deviceName...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final item = await FileTransferService.instance.downloadFile(
      host: host,
      port: port,
      remotePath: remotePath,
      fileName: fileName,
      totalBytes: totalBytes,
      onProgress: (updated) {
        ref.read(fileTransferListProvider.notifier).updateTransfer(updated);
      },
    );

    if (item.status == TransferStatus.completed) {
      ref.read(activityListProvider.notifier).addActivity(
        ActivityModel(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          title: '${item.fileName} berhasil diunduh',
          description:
              'Tersimpan di direktori Lintas (${item.formattedSize})',
          timestamp: DateTime.now(),
          type: ActivityType.fileReceived,
          deviceName: deviceName,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.fileName} berhasil diunduh!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () {
                if (item.localPath != null) {
                  FileTransferService.instance.openFile(item.localPath!);
                }
              },
            ),
          ),
        );
      }
    } else if (item.status == TransferStatus.failed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengunduh berkas: ${item.errorMessage ?? "Kesalahan jaringan"}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices_rounded),
            label: 'Perangkat',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Aktivitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
