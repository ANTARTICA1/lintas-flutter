import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/lan_server_service.dart';
import '../../../core/network/protocol_message.dart';
import '../../../mock/mock_providers.dart';
import '../../file_transfer/domain/file_transfer_model.dart';

class WindowsDropZoneWidget extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const WindowsDropZoneWidget({super.key, required this.onClose});

  @override
  ConsumerState<WindowsDropZoneWidget> createState() =>
      _WindowsDropZoneWidgetState();
}

class _WindowsDropZoneWidgetState extends ConsumerState<WindowsDropZoneWidget> {
  bool _isHovering = false;
  bool _isTransferring = false;
  double _progress = 0.0;
  String _fileName = '';

  Future<void> _pickFileAndBroadcast() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result.isEmpty) return;
    final picked = result.first;
    final path = picked.path;
    if (path == null) return;

    final file = File(path);
    if (!await file.exists()) return;

    final name = picked.name;
    final sizeBytes = await file.length();

    setState(() {
      _isTransferring = true;
      _fileName = name;
      _progress = 0.5;
    });

    final localIp = LanServerService.instance.localIp;
    final port = LanServerService.instance.port;
    final downloadUrl =
        'http://$localIp:$port/api/download?path=${Uri.encodeComponent(path)}';

    final newItem = FileTransferItem(
      id: 'ft-${DateTime.now().millisecondsSinceEpoch}',
      fileName: name,
      totalBytes: sizeBytes,
      transferredBytes: sizeBytes,
      speedBytesPerSec: 10500000,
      etaSeconds: 0,
      status: TransferStatus.completed,
      isOutgoing: true,
      localPath: path,
    );
    ref.read(fileTransferListProvider.notifier).addTransfer(newItem);

    LanServerService.instance.broadcastMessage(
      ProtocolMessage(
        messageId: 'ft-msg-${DateTime.now().millisecondsSinceEpoch}',
        type: CommandType.fileTransferRequest,
        deviceId: 'KRISNA-PC',
        sessionId: 'sess-active',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        nonce: DateTime.now().microsecondsSinceEpoch.toString(),
        payload: {
          'fileName': name,
          'size': sizeBytes,
          'remotePath': path,
          'downloadUrl': downloadUrl,
          'host': localIp,
          'port': port,
        },
      ),
    );

    if (mounted) {
      setState(() {
        _progress = 1.0;
        _isTransferring = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berkas $name siap diunduh oleh ponsel yang terhubung!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _isHovering
                ? AppColors.primaryDark
                : Theme.of(context).colorScheme.outline,
            width: _isHovering ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Lintas Drop Zone',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onHover: (val) => setState(() => _isHovering = val),
              onTap: _pickFileAndBroadcast,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isTransferring
                          ? Icons.sync_rounded
                          : Icons.upload_file_rounded,
                      size: 36,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isTransferring
                          ? 'Mengirim $_fileName'
                          : 'TARIK BERKAS KE SINI',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _isTransferring
                          ? '${(_progress * 100).toInt()}% • 6.5 MB/s'
                          : 'Kirim langsung ke Ponsel Krisna',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    if (_isTransferring) ...[
                      const SizedBox(height: AppSpacing.md),
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 4,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
