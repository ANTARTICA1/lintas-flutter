import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../core/network/protocol_message.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _timerRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _timerRunning = !_timerRunning;
      if (_timerRunning) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _secondsElapsed++;
          });
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _timerRunning = false;
      _secondsElapsed = 0;
    });
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _sendCommand(CommandType type) {
    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    transport.sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode Presentasi')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waktu Presentasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.outlined(
                          icon: Icon(
                            _timerRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          onPressed: _toggleTimer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.outlined(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: _resetTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox.expand(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg,
                                    ),
                                  ),
                                ),
                                onPressed: () => _sendCommand(
                                  CommandType.presentationPrevious,
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back_rounded, size: 48),
                                    SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'SLIDE SEBELUMNYA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: SizedBox.expand(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg,
                                    ),
                                  ),
                                ),
                                onPressed: () =>
                                    _sendCommand(CommandType.presentationNext),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_forward_rounded, size: 48),
                                    SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'SLIDE BERIKUTNYA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.slideshow_rounded),
                            label: const Text('Mulai (F5)'),
                            onPressed: () =>
                                _sendCommand(CommandType.presentationStart),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.stop_screen_share_rounded),
                            label: const Text('Layar Gelap'),
                            onPressed: () =>
                                _sendCommand(CommandType.presentationBlank),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Keluar'),
                            onPressed: () =>
                                _sendCommand(CommandType.presentationExit),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
