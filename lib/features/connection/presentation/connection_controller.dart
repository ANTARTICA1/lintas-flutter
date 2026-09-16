import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/network/transport_service.dart';
import '../../../core/network/smart_bridge_service.dart';
import '../../../core/network/lan_client_transport.dart';
import '../../../mock/mock_providers.dart';

final smartBridgeServiceProvider = Provider<SmartBridgeService>((ref) {
  final service = SmartBridgeService();
  ref.onDispose(service.dispose);
  return service;
});

final lanClientTransportProvider = Provider<LanClientTransport>((ref) {
  final client = LanClientTransport();
  ref.onDispose(client.dispose);
  return client;
});

final transportServiceProvider = Provider<TransportService>((ref) {
  final mockMode = ref.watch(mockModeProvider);
  if (mockMode) {
    return ref.watch(smartBridgeServiceProvider);
  } else {
    return ref.watch(lanClientTransportProvider);
  }
});

class ConnectionController extends Notifier<ConnectionStateModel> {
  @override
  ConnectionStateModel build() {
    final transport = ref.watch(transportServiceProvider);
    transport.stateStream.listen((newState) {
      state = newState;
    });
    return transport.currentState;
  }

  Future<void> connect(String deviceId, {String? host, int? port}) async {
    final transport = ref.read(transportServiceProvider);
    await transport.connect(deviceId, host: host, port: port);
  }

  Future<void> disconnect() async {
    final transport = ref.read(transportServiceProvider);
    await transport.disconnect();
  }

  Future<void> startDiscovery() async {
    final transport = ref.read(transportServiceProvider);
    await transport.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    final transport = ref.read(transportServiceProvider);
    await transport.stopDiscovery();
  }
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionStateModel>(
      ConnectionController.new,
    );
