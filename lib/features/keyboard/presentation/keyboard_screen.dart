import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../core/network/protocol_message.dart';

class KeyboardScreen extends ConsumerStatefulWidget {
  const KeyboardScreen({super.key});

  @override
  ConsumerState<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends ConsumerState<KeyboardScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _ctrlActive = false;
  bool _altActive = false;
  bool _shiftActive = false;
  bool _winActive = false;

  void _sendKey(String key) {
    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CommandType.keyboardKey,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
      payload: {
        'key': key,
        'ctrl': _ctrlActive,
        'alt': _altActive,
        'shift': _shiftActive,
        'win': _winActive,
      },
    );
    transport.sendMessage(message);

    if (_ctrlActive || _altActive || _shiftActive || _winActive) {
      setState(() {
        _ctrlActive = false;
        _altActive = false;
        _shiftActive = false;
        _winActive = false;
      });
    }
  }

  void _sendText(String text) {
    if (text.isEmpty) return;
    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CommandType.keyboardText,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
      payload: {'text': text},
    );
    transport.sendMessage(message);
    _textController.clear();
  }

  Widget _buildKeyButton(
    String label,
    VoidCallback onPressed, {
    bool isActive = false,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isActive
                ? AppColors.primaryDark.withAlpha(60)
                : null,
            side: BorderSide(
              color: isActive
                  ? AppColors.primaryDark
                  : Theme.of(context).colorScheme.outline,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primaryDark : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Papan Ketik Jarak Jauh')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ketik teks untuk dikirim ke PC...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                      ),
                      onSubmitted: (val) => _sendText(val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                    onPressed: () => _sendText(_textController.text),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKeyButton('ESC', () => _sendKey('Escape')),
                      _buildKeyButton('TAB', () => _sendKey('Tab')),
                      _buildKeyButton(
                        'WIN',
                        () => setState(() => _winActive = !_winActive),
                        isActive: _winActive,
                      ),
                      _buildKeyButton(
                        'BACKSPACE',
                        () => _sendKey('Backspace'),
                        flex: 2,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildKeyButton(
                        'CTRL',
                        () => setState(() => _ctrlActive = !_ctrlActive),
                        isActive: _ctrlActive,
                      ),
                      _buildKeyButton(
                        'ALT',
                        () => setState(() => _altActive = !_altActive),
                        isActive: _altActive,
                      ),
                      _buildKeyButton(
                        'SHIFT',
                        () => setState(() => _shiftActive = !_shiftActive),
                        isActive: _shiftActive,
                      ),
                      _buildKeyButton(
                        'ENTER',
                        () => _sendKey('Enter'),
                        flex: 2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pintasan Khusus',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ActionChip(
                    label: const Text('CTRL + C'),
                    onPressed: () => _sendKey('ctrl_c'),
                  ),
                  ActionChip(
                    label: const Text('CTRL + V'),
                    onPressed: () => _sendKey('ctrl_v'),
                  ),
                  ActionChip(
                    label: const Text('CTRL + Z'),
                    onPressed: () => _sendKey('ctrl_z'),
                  ),
                  ActionChip(
                    label: const Text('ALT + TAB'),
                    onPressed: () => _sendKey('alt_tab'),
                  ),
                  ActionChip(
                    label: const Text('WIN + D'),
                    onPressed: () => _sendKey('win_d'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.arrow_drop_up_rounded),
                        onPressed: () => _sendKey('ArrowUp'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.arrow_left_rounded),
                        onPressed: () => _sendKey('ArrowLeft'),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      IconButton.outlined(
                        icon: const Icon(Icons.arrow_right_rounded),
                        onPressed: () => _sendKey('ArrowRight'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onPressed: () => _sendKey('ArrowDown'),
                      ),
                    ],
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
