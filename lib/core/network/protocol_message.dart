enum CommandType {
  mouseMove,
  mouseClick,
  mouseScroll,
  keyboardText,
  keyboardKey,
  mediaPlayPause,
  mediaNext,
  mediaPrevious,
  volumeUp,
  volumeDown,
  volumeMute,
  pcLock,
  showDesktop,
  taskView,
  screenshot,
  sleepPc,
  restartPc,
  shutdownPc,
  presentationNext,
  presentationPrevious,
  presentationStart,
  presentationExit,
  presentationBlank,
  clipboardSend,
  clipboardFetch,
  clipboardContent,
  fileTransferRequest,
  fileTransferReady,
  fileTransferProgress,
  ping,
  pong,
  pairingRequest,
  pairingResponse,
  pairingConfirm,
  disconnect,
}

class ProtocolMessage {
  final int protocolVersion;
  final String messageId;
  final CommandType type;
  final String deviceId;
  final String sessionId;
  final int timestamp;
  final String nonce;
  final Map<String, dynamic> payload;
  final String? authenticationData;

  const ProtocolMessage({
    this.protocolVersion = 1,
    required this.messageId,
    required this.type,
    required this.deviceId,
    required this.sessionId,
    required this.timestamp,
    required this.nonce,
    this.payload = const {},
    this.authenticationData,
  });

  Map<String, dynamic> toJson() {
    return {
      'protocolVersion': protocolVersion,
      'messageId': messageId,
      'type': type.name,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'timestamp': timestamp,
      'nonce': nonce,
      'payload': payload,
      'authenticationData': authenticationData,
    };
  }

  factory ProtocolMessage.fromJson(Map<String, dynamic> json) {
    return ProtocolMessage(
      protocolVersion: json['protocolVersion'] as int? ?? 1,
      messageId: json['messageId'] as String? ?? '',
      type: CommandType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CommandType.ping,
      ),
      deviceId: json['deviceId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      nonce: json['nonce'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      authenticationData: json['authenticationData'] as String?,
    );
  }
}
