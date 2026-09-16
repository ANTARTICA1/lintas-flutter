import 'dart:async';
import 'connection_state.dart';
import 'protocol_message.dart';
import 'transport_service.dart';

class SmartBridgeService implements TransportService {
  final StreamController<ConnectionStateModel> _stateController =
      StreamController<ConnectionStateModel>.broadcast();
  final StreamController<ProtocolMessage> _messageController =
      StreamController<ProtocolMessage>.broadcast();

  ConnectionStateModel _currentState = const ConnectionStateModel(
    status: ConnectionStatus.connected,
    transport: TransportType.lan,
    quality: ConnectionQuality.excellent,
    latencyMs: 3,
    connectedDeviceId: 'dev-krisna-pc-01',
    connectedDeviceName: 'KRISNA-PC',
    connectedDeviceOs: 'Windows 11 Pro',
  );

  int _reconnectAttempt = 0;
  final List<int> _backoffIntervals = [1, 2, 4, 8, 15];
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  SmartBridgeService() {
    _stateController.add(_currentState);
    _startHeartbeat();
  }

  @override
  Stream<ConnectionStateModel> get stateStream => _stateController.stream;

  @override
  ConnectionStateModel get currentState => _currentState;

  @override
  Stream<ProtocolMessage> get messageStream => _messageController.stream;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_currentState.isConnected) {
        final variance = (DateTime.now().millisecond % 3) + 2;
        _updateState(_currentState.copyWith(latencyMs: variance));
      }
    });
  }

  @override
  Future<void> startDiscovery() async {
    _updateState(_currentState.copyWith(status: ConnectionStatus.discovering));
    await Future.delayed(const Duration(milliseconds: 500));
    _updateState(_currentState.copyWith(status: ConnectionStatus.deviceFound));
  }

  @override
  Future<void> stopDiscovery() async {
    if (_currentState.status == ConnectionStatus.discovering) {
      _updateState(
        _currentState.copyWith(status: ConnectionStatus.disconnected),
      );
    }
  }

  @override
  Future<bool> connect(String deviceId, {String? host, int? port}) async {
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;

    _updateState(
      _currentState.copyWith(
        status: ConnectionStatus.pairing,
        connectedDeviceId: deviceId,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));

    _updateState(
      _currentState.copyWith(status: ConnectionStatus.authenticating),
    );
    await Future.delayed(const Duration(milliseconds: 300));

    _updateState(
      ConnectionStateModel(
        status: ConnectionStatus.connected,
        transport: TransportType.lan,
        quality: ConnectionQuality.excellent,
        latencyMs: 3,
        connectedDeviceId: deviceId,
        connectedDeviceName: 'KRISNA-PC',
        connectedDeviceOs: 'Windows 11 Pro',
      ),
    );
    return true;
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _updateState(
      const ConnectionStateModel(
        status: ConnectionStatus.disconnected,
        transport: TransportType.none,
        quality: ConnectionQuality.weak,
        latencyMs: 0,
      ),
    );
  }

  void switchTransport(TransportType newTransport) {
    if (!_currentState.isConnected) return;
    _updateState(
      _currentState.copyWith(
        transport: newTransport,
        quality: newTransport == TransportType.lan
            ? ConnectionQuality.excellent
            : ConnectionQuality.good,
        latencyMs: newTransport == TransportType.lan ? 3 : 24,
      ),
    );
  }

  void triggerAutoReconnect() {
    if (_currentState.status == ConnectionStatus.reconnecting) return;
    final delaySeconds =
        _backoffIntervals[_reconnectAttempt.clamp(
          0,
          _backoffIntervals.length - 1,
        )];
    _reconnectAttempt++;

    _updateState(
      _currentState.copyWith(
        status: ConnectionStatus.reconnecting,
        transport: TransportType.none,
      ),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect('dev-krisna-pc-01');
    });
  }

  @override
  Future<bool> sendMessage(ProtocolMessage message) async {
    if (!_currentState.isConnected) return false;
    _messageController.add(message);
    return true;
  }

  void _updateState(ConnectionStateModel newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _stateController.close();
    _messageController.close();
  }
}
