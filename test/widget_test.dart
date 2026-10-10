import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lintas/core/network/connection_state.dart';
import 'package:lintas/core/network/protocol_message.dart';
import 'package:lintas/core/security/qr_payload.dart';
import 'package:lintas/core/network/lan_server_service.dart';
import 'package:lintas/core/native/windows_input_service.dart';
import 'package:lintas/core/network/file_transfer_service.dart';
import 'package:lintas/mock/mock_providers.dart';
import 'package:lintas/features/presence/domain/presence_model.dart';
import 'package:lintas/features/clipboard/domain/clipboard_item_model.dart';
import 'package:lintas/features/home/presentation/home_screen.dart';

class _AlwaysMockNotifier extends MockModeNotifier {
  @override
  bool build() => true;
}

void main() {
  test('Pengujian status koneksi model default', () {
    const state = ConnectionStateModel();
    expect(state.status, ConnectionStatus.disconnected);
    expect(state.isConnected, false);
    expect(state.statusLabelIndonesian, 'Terputus');
  });

  test('Pengujian serialisasi dan deserialisasi ProtocolMessage', () {
    final message = ProtocolMessage(
      messageId: 'test-msg-01',
      type: CommandType.pcLock,
      deviceId: 'mobile-client',
      sessionId: 'sess-test',
      timestamp: 123456789,
      nonce: 'nonce-abc',
      payload: {'action': 'lock'},
    );

    final json = message.toJson();
    expect(json['messageId'], 'test-msg-01');
    expect(json['type'], 'pcLock');

    final parsed = ProtocolMessage.fromJson(json);
    expect(parsed.messageId, 'test-msg-01');
    expect(parsed.type, CommandType.pcLock);
    expect(parsed.payload['action'], 'lock');
  });

  test('Pengujian pembuatan dan decoding QrPayload dengan kedaluwarsa', () {
    final payload = QrPayload.generate(
      deviceName: 'KRISNA-PC',
      host: '192.168.1.102',
      port: 8945,
      validityDurationSeconds: 120,
    );

    expect(payload.deviceName, 'KRISNA-PC');
    expect(payload.isExpired, false);
    expect(payload.remainingSeconds, greaterThan(115));

    final encoded = payload.encode();
    final decoded = QrPayload.decode(encoded);

    expect(decoded, isNotNull);
    expect(decoded!.deviceName, 'KRISNA-PC');
    expect(decoded.host, '192.168.1.102');
    expect(decoded.port, 8945);
  });

  test('Pengujian pemulusan sinyal PresenceState dan Deteksi Kepulangan', () {
    var presence = PresenceState(
      status: PresenceStatus.away,
      lastObservation: DateTime.now(),
    );

    presence = presence.addSample(-50);
    expect(presence.status, PresenceStatus.present);
    expect(presence.isReturnDetected, true);
    expect(presence.statusLabelIndonesian, 'Ponsel Terdeteksi Dekat');

    presence = presence.addSample(-90);
    presence = presence.addSample(-95);
    presence = presence.addSample(-92);
    expect(presence.status, PresenceStatus.away);
  });

  test('Pengujian waktu relatif ClipboardItemModel', () {
    final item = ClipboardItemModel(
      id: 'c1',
      content: 'https://flutter.dev',
      sourceDevice: 'KRISNA-PC',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isUrl: true,
    );

    expect(item.relativeTimeIndonesian, '5 menit yang lalu');
  });

  test('Pengujian inisialisasi LanServerService dan WindowsInputService', () {
    final server = LanServerService.instance;
    expect(server.port, 8945);
    expect(server.clientCount, 0);

    final input = WindowsInputService.instance;
    expect(input, isNotNull);
  });

  test('Pengujian inisialisasi FileTransferService', () {
    final service = FileTransferService.instance;
    expect(service, isNotNull);
  });

  testWidgets('Pengujian pemuatan awal antarmuka Lintas saat belum terhubung', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo, Krisna'), findsOneWidget);
    expect(find.text('Lintas Ecosystem'), findsOneWidget);
    expect(find.text('Hubungkan Komputer Anda'), findsOneWidget);
    expect(find.text('HUBUNGKAN PC SEKARANG'), findsOneWidget);
  });

  testWidgets('Pengujian antarmuka Lintas saat terhubung (Mock / Connected Mode)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockModeProvider.overrideWith(_AlwaysMockNotifier.new),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo, Krisna'), findsOneWidget);
    expect(find.text('Touchpad'), findsOneWidget);
    expect(find.text('Papan Ketik'), findsOneWidget);
    expect(find.text('Instant Drop'), findsOneWidget);
  });

  test('Pengujian ClipboardTimelineNotifier operasi penambahan dan pembatasan item', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(clipboardTimelineProvider), isEmpty);

    final item1 = ClipboardItemModel(
      id: 'clip-101',
      content: 'Teks Pertama',
      sourceDevice: 'Ponsel',
      timestamp: DateTime.now(),
    );
    container.read(clipboardTimelineProvider.notifier).addItem(item1, maxItems: 2);

    expect(container.read(clipboardTimelineProvider).length, 1);
    expect(container.read(clipboardTimelineProvider).first.content, 'Teks Pertama');

    // Duplicate identical consecutive item should be ignored
    container.read(clipboardTimelineProvider.notifier).addItem(item1, maxItems: 2);
    expect(container.read(clipboardTimelineProvider).length, 1);

    final item2 = ClipboardItemModel(
      id: 'clip-102',
      content: 'Teks Kedua',
      sourceDevice: 'Ponsel',
      timestamp: DateTime.now(),
    );
    container.read(clipboardTimelineProvider.notifier).addItem(item2, maxItems: 2);
    expect(container.read(clipboardTimelineProvider).length, 2);

    // Limit cap
    final item3 = ClipboardItemModel(
      id: 'clip-103',
      content: 'Teks Ketiga',
      sourceDevice: 'Ponsel',
      timestamp: DateTime.now(),
    );
    container.read(clipboardTimelineProvider.notifier).addItem(item3, maxItems: 2);
    expect(container.read(clipboardTimelineProvider).length, 2);
    expect(container.read(clipboardTimelineProvider).first.content, 'Teks Ketiga');

    container.read(clipboardTimelineProvider.notifier).clearAll();
    expect(container.read(clipboardTimelineProvider), isEmpty);
  });

  test('Pengujian kontrol jeda koneksi LanServerService', () {
    final server = LanServerService.instance;
    expect(server.isPaused, false);
    server.isPaused = true;
    expect(server.isPaused, true);
    server.isPaused = false;
  });
}
