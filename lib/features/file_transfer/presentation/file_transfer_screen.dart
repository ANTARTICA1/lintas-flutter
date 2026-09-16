import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/file_transfer_service.dart';
import '../../../core/network/lan_server_service.dart';
import '../../../mock/mock_providers.dart';
import '../domain/file_transfer_model.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../activity/domain/activity_model.dart';
import '../../../core/network/protocol_message.dart';

class FileTransferScreen extends ConsumerStatefulWidget {
  const FileTransferScreen({super.key});

  @override
  ConsumerState<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends ConsumerState<FileTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _transferSub;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _transferSub = LanServerService.instance.fileTransferStream.listen((item) {
      ref.read(fileTransferListProvider.notifier).updateTransfer(item);
      ref.read(activityListProvider.notifier).addActivity(
        ActivityModel(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          title: '${item.fileName} diterima',
          description:
              'Berkas tersimpan di folder Downloads/Lintas (${item.formattedSize})',
          timestamp: DateTime.now(),
          type: ActivityType.fileReceived,
          deviceName: 'Perangkat Pengirim',
        ),
      );
    });

    Future.microtask(() {
      _messageSub = ref
          .read(transportServiceProvider)
          .messageStream
          .listen((msg) {
        if (msg.type == CommandType.fileTransferRequest) {
          _handleIncomingFileRequest(msg);
        }
      });
    });
  }

  @override
  void dispose() {
    _transferSub?.cancel();
    _messageSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _handleIncomingFileRequest(ProtocolMessage msg) {
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
                _startDownloadingIncomingFile(
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

  Future<void> _startDownloadingIncomingFile({
    required String host,
    required int port,
    required String remotePath,
    required String fileName,
    required int totalBytes,
    required String deviceName,
  }) async {
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
            content: Text('${item.fileName} siap dibuka!'),
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

  Future<void> _pickAndSendFile() async {
    final connectionState = ref.read(connectionControllerProvider);
    final targetDevice = connectionState.connectedDeviceName ?? 'KRISNA-PC';

    var targetHost = connectionState.connectedHost ?? '127.0.0.1';
    final connectedId = connectionState.connectedDeviceId;
    if (targetHost == '127.0.0.1' && connectedId != null) {
      final matchedDevice = ref
          .read(devicesListProvider)
          .where((d) => d.id == connectedId)
          .firstOrNull;
      if (matchedDevice != null &&
          matchedDevice.ipAddress != null &&
          matchedDevice.ipAddress!.isNotEmpty) {
        targetHost = matchedDevice.ipAddress!;
      }
    }
    final targetPort = connectionState.connectedPort ?? 8945;

    final item = await FileTransferService.instance.pickAndSendFile(
      host: targetHost,
      port: targetPort,
      onProgress: (updatedItem) {
        ref.read(fileTransferListProvider.notifier).updateTransfer(updatedItem);
      },
    );

    if (item != null) {
      if (item.status == TransferStatus.completed) {
        ref.read(activityListProvider.notifier).addActivity(
          ActivityModel(
            id: 'act-${DateTime.now().millisecondsSinceEpoch}',
            title: '${item.fileName} terkirim',
            description:
                'Terkirim ke $targetDevice via LAN Mode Cepat (${item.formattedSize})',
            timestamp: DateTime.now(),
            type: ActivityType.fileSent,
            deviceName: targetDevice,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berkas ${item.fileName} berhasil ditransfer ke $targetDevice',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (item.status == TransferStatus.failed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengirim ${item.fileName}: ${item.errorMessage ?? "Kesalahan koneksi"}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transfers = ref.watch(fileTransferListProvider);
    final connectionState = ref.watch(connectionControllerProvider);

    final activeTransfers = transfers
        .where(
          (t) =>
              t.status == TransferStatus.transferring ||
              t.status == TransferStatus.waiting ||
              t.status == TransferStatus.paused,
        )
        .toList();

    final completedTransfers = transfers
        .where(
          (t) =>
              t.status == TransferStatus.completed ||
              t.status == TransferStatus.failed ||
              t.status == TransferStatus.cancelled,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Transfer Berkas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryDark,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: [
            Tab(text: 'AKTIF (${activeTransfers.length})'),
            Tab(text: 'RIWAYAT (${completedTransfers.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instant Drop',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Kirim berkas kilat ke ${connectionState.connectedDeviceName ?? "PC"} via LAN',
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
                  FilledButton.tonal(
                    onPressed: _pickAndSendFile,
                    child: const Text('Kirim Kilat'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  activeTransfers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_empty_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Text(
                                'Tidak ada transfer aktif saat ini',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Text(
                                'Tarik atau pilih berkas untuk memulai transfer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: activeTransfers.length,
                          itemBuilder: (context, index) {
                            final item = activeTransfers[index];
                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          item.isOutgoing
                                              ? Icons.upload_file_rounded
                                              : Icons.download_rounded,
                                          color: AppColors.primaryDark,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.fileName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${item.formattedSize} • Kecepatan: ${item.formattedSpeed}',
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
                                    const SizedBox(height: AppSpacing.md),
                                    LinearProgressIndicator(
                                      value: item.progress,
                                      color: AppColors.primaryDark,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainer,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${(item.progress * 100).toInt()}% • Estimasi: ~${item.etaSeconds} dtk lagi',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      fileTransferListProvider
                                                          .notifier,
                                                    )
                                                    .pauseTransfer(item.id);
                                              },
                                              child: const Text('Jeda'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      fileTransferListProvider
                                                          .notifier,
                                                    )
                                                    .cancelTransfer(item.id);
                                              },
                                              child: const Text('Batal'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  completedTransfers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Text(
                                'Belum ada riwayat transfer selesai',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: completedTransfers.length,
                          itemBuilder: (context, index) {
                            final item = completedTransfers[index];
                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color:
                                        item.status == TransferStatus.completed
                                        ? AppColors.success.withAlpha(30)
                                        : AppColors.error.withAlpha(30),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                  ),
                                  child: Icon(
                                    item.status == TransferStatus.completed
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.error_outline_rounded,
                                    color:
                                        item.status == TransferStatus.completed
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                title: Text(
                                  item.fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.formattedSize} • ${item.statusLabelIndonesian}',
                                    ),
                                    if (item.sha256Hash != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 13,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          const Text(
                                            'Integritas SHA-256 Valid',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing:
                                    item.status == TransferStatus.completed
                                    ? OutlinedButton(
                                        onPressed: () async {
                                          if (item.localPath != null) {
                                            final res =
                                                await FileTransferService
                                                    .instance
                                                    .openFile(item.localPath!);
                                            if (res.type != ResultType.done &&
                                                context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Tidak dapat membuka berkas: ${res.message}',
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Berkas ${item.fileName} ada di folder Lintas',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Buka'),
                                      )
                                    : FilledButton.tonal(
                                        onPressed: () {
                                          ref
                                              .read(
                                                fileTransferListProvider
                                                    .notifier,
                                              )
                                              .resumeTransfer(item.id);
                                        },
                                        child: const Text('Coba Lagi'),
                                      ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: FilledButton.icon(
          icon: const Icon(Icons.add_to_photos_rounded),
          label: const Text('PILIH BERKAS UNTUK DITRANSFER'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          onPressed: _pickAndSendFile,
        ),
      ),
    );
  }
}
