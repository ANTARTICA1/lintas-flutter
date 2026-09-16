import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../core/network/protocol_message.dart';

class TouchpadScreen extends ConsumerStatefulWidget {
  const TouchpadScreen({super.key});

  @override
  ConsumerState<TouchpadScreen> createState() => _TouchpadScreenState();
}

class _TouchpadScreenState extends ConsumerState<TouchpadScreen> {
  double _sensitivity = 1.0;
  Offset _lastPosition = Offset.zero;

  void _sendTouchpadEvent(CommandType type, Map<String, dynamic> payload) {
    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
      payload: payload,
    );
    transport.sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Touchpad Nirkabel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sensitivitas',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sensitivitas Kursor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Slider(
                              value: _sensitivity,
                              min: 0.5,
                              max: 2.5,
                              divisions: 8,
                              label: _sensitivity.toStringAsFixed(1),
                              onChanged: (val) {
                                setModalState(() => _sensitivity = val);
                                setState(() => _sensitivity = val);
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Lambat'),
                                Text(
                                  '${(_sensitivity * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Cepat'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.surfaceDark,
              child: Row(
                children: [
                  Icon(
                    connectionState.isConnected
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: connectionState.isConnected
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    connectionState.isConnected
                        ? 'Terhubung ke ${connectionState.connectedDeviceName ?? "PC"}'
                        : 'Menunggu koneksi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _lastPosition = details.localPosition;
                  },
                  onPanUpdate: (details) {
                    final delta =
                        (details.localPosition - _lastPosition) * _sensitivity;
                    _lastPosition = details.localPosition;
                    _sendTouchpadEvent(CommandType.mouseMove, {
                      'dx': delta.dx,
                      'dy': delta.dy,
                    });
                  },
                  onTap: () {
                    _sendTouchpadEvent(CommandType.mouseClick, {
                      'button': 'left',
                    });
                  },
                  onDoubleTap: () {
                    _sendTouchpadEvent(CommandType.mouseClick, {
                      'button': 'double_left',
                    });
                  },
                  onLongPress: () {
                    _sendTouchpadEvent(CommandType.mouseClick, {
                      'button': 'right',
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(80),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Area Sentuh Trackpad',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(120),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '1 jari: gerak kursor • Ketuk: klik kiri • Tahan: klik kanan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: () {
                        _sendTouchpadEvent(CommandType.mouseClick, {
                          'button': 'left',
                        });
                      },
                      child: const Text('KLIK KIRI'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: () {
                        _sendTouchpadEvent(CommandType.mouseScroll, {'dy': -1});
                      },
                      child: const Icon(Icons.unfold_more_rounded),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: () {
                        _sendTouchpadEvent(CommandType.mouseClick, {
                          'button': 'right',
                        });
                      },
                      child: const Text('KLIK KANAN'),
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
