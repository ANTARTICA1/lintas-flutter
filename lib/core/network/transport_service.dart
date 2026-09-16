import 'connection_state.dart';
import 'protocol_message.dart';

abstract class TransportService {
  Stream<ConnectionStateModel> get stateStream;
  ConnectionStateModel get currentState;

  Future<void> startDiscovery();
  Future<void> stopDiscovery();

  Future<bool> connect(String deviceId, {String? host, int? port});
  Future<void> disconnect();

  Future<bool> sendMessage(ProtocolMessage message);
  Stream<ProtocolMessage> get messageStream;
}
