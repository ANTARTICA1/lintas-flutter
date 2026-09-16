import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'connection_state.dart';
import 'protocol_message.dart';
import 'transport_service.dart';

class LanClientTransport implements TransportService {
  WebSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final List<int> _backoffSeconds = [1, 2, 4, 8, 15];

  String _targetHost = '127.0.0.1';
  int _targetPort = 8945;
  String? _connectedDeviceId;

  final StreamController<ConnectionStateModel> _stateController =
      StreamController<ConnectionStateModel>.broadcast();
  final StreamController<ProtocolMessage> _messageController =
      StreamController<ProtocolMessage>.broadcast();

  ConnectionStateModel _state = const ConnectionStateModel(
    status: ConnectionStatus.disconnected,
    transport: TransportType.none,
  );

  LanClientTransport() {
    _stateController.add(_state);
  }

  @override
  Stream<ConnectionStateModel> get stateStream => _stateController.stream;

  @override
  ConnectionStateModel get currentState => _state;

  @override
  Stream<ProtocolMessage> get messageStream => _messageController.stream;

  @override
  Future<void> startDiscovery() async {
    _updateState(_state.copyWith(status: ConnectionStatus.discovering));
    await Future.delayed(const Duration(milliseconds: 500));
    _updateState(_state.copyWith(status: ConnectionStatus.deviceFound));
  }

  @override
  Future<void> stopDiscovery() async {
    if (_state.status == ConnectionStatus.discovering) {
      _updateState(_state.copyWith(status: ConnectionStatus.disconnected));
    }
  }

  @override
  Future<bool> connect(String deviceId, {String? host, int? port}) async {
    _connectedDeviceId = deviceId;
    if (host != null && host.isNotEmpty) _targetHost = host;
    if (port != null) _targetPort = port;

    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    _updateState(
      _state.copyWith(
        status: ConnectionStatus.pairing,
        connectedDeviceId: deviceId,
      ),
    );

    try {
      final wsUrl = 'ws://$_targetHost:$_targetPort';
      _socket = await WebSocket.connect(
        wsUrl,
      ).timeout(const Duration(seconds: 5));

      _updateState(
        _state.copyWith(
          status: ConnectionStatus.authenticating,
          transport: TransportType.lan,
        ),
      );

      _socket!.listen(
        _onMessageReceived,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );

      _updateState(
        ConnectionStateModel(
          status: ConnectionStatus.connected,
          transport: TransportType.lan,
          quality: ConnectionQuality.excellent,
          latencyMs: 3,
          connectedDeviceId: deviceId,
          connectedDeviceName: 'KRISNA-PC',
          connectedDeviceOs: 'Windows 11 Pro',
          connectedHost: _targetHost,
          connectedPort: _targetPort,
        ),
      );

      _startHeartbeat();
      return true;
    } catch (_) {
      _updateState(
        _state.copyWith(
          status: ConnectionStatus.disconnected,
          errorMessage: 'Gagal terhubung ke $_targetHost:$_targetPort',
        ),
      );
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_state.isConnected && _socket != null) {
        final ping = ProtocolMessage(
          messageId: 'ping-${DateTime.now().millisecondsSinceEpoch}',
          type: CommandType.ping,
          deviceId: 'mobile-client',
          sessionId: 'sess-active',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          nonce: DateTime.now().microsecondsSinceEpoch.toString(),
        );
        sendMessage(ping);
      }
    });
  }

  void _onMessageReceived(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = ProtocolMessage.fromJson(json);

      if (message.type == CommandType.pong) {
        final clientTime = message.payload['clientTime'] as int?;
        if (clientTime != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final rtt = (now - clientTime).clamp(1, 999);
          _updateState(_state.copyWith(latencyMs: rtt));
        }
      } else {
        _messageController.add(message);
      }
    } catch (_) {}
  }

  void _onDisconnected() {
    _heartbeatTimer?.cancel();
    _socket = null;

    if (_connectedDeviceId != null) {
      _triggerReconnect();
    } else {
      _updateState(
        const ConnectionStateModel(
          status: ConnectionStatus.disconnected,
          transport: TransportType.none,
        ),
      );
    }
  }

  void _triggerReconnect() {
    final delay =
        _backoffSeconds[_reconnectAttempts.clamp(
          0,
          _backoffSeconds.length - 1,
        )];
    _reconnectAttempts++;

    _updateState(
      _state.copyWith(
        status: ConnectionStatus.reconnecting,
        transport: TransportType.none,
      ),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_connectedDeviceId != null) {
        connect(_connectedDeviceId!, host: _targetHost, port: _targetPort);
      }
    });
  }

  @override
  Future<bool> sendMessage(ProtocolMessage message) async {
    if (_socket == null || !_state.isConnected) return false;
    try {
      _socket!.add(jsonEncode(message.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectedDeviceId = null;
    await _socket?.close();
    _socket = null;

    _updateState(
      const ConnectionStateModel(
        status: ConnectionStatus.disconnected,
        transport: TransportType.none,
      ),
    );
  }

  void _updateState(ConnectionStateModel newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
