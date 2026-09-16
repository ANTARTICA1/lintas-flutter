import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../../core/network/protocol_message.dart';
import '../domain/clipboard_item_model.dart';
import '../../activity/domain/activity_model.dart';
import '../../../mock/mock_providers.dart';

class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  final TextEditingController _sendController = TextEditingController();
  bool _autoSync = false;
  bool _privateMode = false;
  int _maxHistoryItems = 25;
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _msgSub = ref.read(transportServiceProvider).messageStream.listen((msg) {
        if (msg.type == CommandType.clipboardContent) {
          final text = msg.payload['text'] as String? ?? '';
          if (text.isNotEmpty) {
            Clipboard.setData(ClipboardData(text: text));
            final isUrl =
                text.startsWith('http://') || text.startsWith('https://');
            setState(() {
              _timelineItems.insert(
                0,
                ClipboardItemModel(
                  id: 'clip-${DateTime.now().millisecondsSinceEpoch}',
                  content: text,
                  sourceDevice: 'KRISNA-PC',
                  timestamp: DateTime.now(),
                  isUrl: isUrl,
                ),
              );
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Papan klip dari PC diterima dan disalin ke ponsel!',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _sendController.dispose();
    super.dispose();
  }

  void _fetchClipboardFromPc() {
    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CommandType.clipboardFetch,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    transport.sendMessage(message);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meminta isi papan klip terbaru dari PC...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  final List<ClipboardItemModel> _timelineItems = [
    ClipboardItemModel(
      id: 'clip-1',
      sourceDevice: 'KRISNA-PC',
      content: 'https://flutter.dev/multi-platform/desktop',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      isUrl: true,
    ),
    ClipboardItemModel(
      id: 'clip-2',
      sourceDevice: 'Ponsel',
      content: '192.168.1.102:8945',
      timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
      isUrl: false,
    ),
    ClipboardItemModel(
      id: 'clip-3',
      sourceDevice: 'KRISNA-PC',
      content: 'Catatan Rapat Sinkronisasi Lintas Ecosystem Q4',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      isUrl: false,
    ),
  ];

  void _sendClipboardToPc() {
    final text = _sendController.text.trim();
    if (text.isEmpty) return;

    final transport = ref.read(transportServiceProvider);
    final message = ProtocolMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CommandType.clipboardSend,
      deviceId: 'mobile-client',
      sessionId: 'sess-active',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: DateTime.now().microsecondsSinceEpoch.toString(),
      payload: {'text': text, 'isPrivate': _privateMode},
    );
    transport.sendMessage(message);

    if (!_privateMode) {
      final isUrl = text.startsWith('http://') || text.startsWith('https://');
      setState(() {
        _timelineItems.insert(
          0,
          ClipboardItemModel(
            id: 'clip-${DateTime.now().millisecondsSinceEpoch}',
            content: text,
            sourceDevice: 'Ponsel',
            timestamp: DateTime.now(),
            isUrl: isUrl,
            isPrivate: false,
          ),
        );
        if (_timelineItems.length > _maxHistoryItems) {
          _timelineItems.removeLast();
        }
      });
    }

    ref
        .read(activityListProvider.notifier)
        .addActivity(
          ActivityModel(
            id: 'act-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Teks Papan Klip Terkirim',
            description: _privateMode
                ? 'Terkirim via Mode Privat (tanpa riwayat)'
                : 'Terkirim ke KRISNA-PC',
            timestamp: DateTime.now(),
            type: ActivityType.clipboardSent,
            deviceName: 'KRISNA-PC',
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _privateMode
              ? 'Teks dikirim ke PC (Mode Privat: tidak disimpan)'
              : 'Teks papan klip berhasil dikirim ke PC',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _sendController.clear();
  }

  void _copyToDevice(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks disalin ke papan klip ponsel'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteItem(String id) {
    setState(() {
      _timelineItems.removeWhere((item) => item.id == id);
    });
  }

  void _clearHistory() {
    setState(() {
      _timelineItems.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Riwayat linimasa papan klip dibersihkan'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linimasa Papan Klip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Bersihkan Riwayat',
            onPressed: _timelineItems.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kirim ke PC',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Mode Privat',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Switch(
                              value: _privateMode,
                              onChanged: (val) =>
                                  setState(() => _privateMode = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _sendController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Tempelkan teks atau URL yang ingin dikirim...',
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
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.content_paste_rounded),
                              label: const Text('Tempel HP'),
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                if (data?.text != null) {
                                  _sendController.text = data!.text!;
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Tarik dari PC'),
                              onPressed: _fetchClipboardFromPc,
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Kirim ke PC'),
                          onPressed: _sendClipboardToPc,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Sinkronisasi Otomatis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Bawaan nonaktif untuk mencegah kebocoran sandi.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _autoSync,
                    onChanged: (val) => setState(() => _autoSync = val),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      'Batas Riwayat Linimasa',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text('$_maxHistoryItems item disimpan lokal'),
                    trailing: DropdownButton<int>(
                      value: _maxHistoryItems,
                      underline: const SizedBox(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _maxHistoryItems = val);
                        }
                      },
                      items: const [10, 25, 50].map((count) {
                        return DropdownMenuItem(
                          value: count,
                          child: Text('$count Item'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LINIMASA PAPAN KLIP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                Text(
                  '${_timelineItems.length} Tersimpan',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_timelineItems.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.content_paste_off_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Belum ada riwayat linimasa',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Teks atau URL yang dibagikan antar perangkat akan muncul di sini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._timelineItems.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                Icon(
                                  item.isUrl
                                      ? Icons.link_rounded
                                      : Icons.notes_rounded,
                                  size: 16,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Dari ${item.sourceDevice}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              item.relativeTimeIndonesian,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SelectableText(
                          item.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              tooltip: 'Hapus',
                              onPressed: () => _deleteItem(item.id),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text('Salin ke Ponsel'),
                              onPressed: () => _copyToDevice(item.content),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
