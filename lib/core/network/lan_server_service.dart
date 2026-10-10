import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'protocol_message.dart';
import '../native/windows_input_service.dart';
import '../../features/file_transfer/domain/file_transfer_model.dart';

class LanServerService {
  static final LanServerService instance = LanServerService._internal();

  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();
  final StreamController<int> _clientCountController =
      StreamController<int>.broadcast();
  final StreamController<ProtocolMessage> _incomingMessagesController =
      StreamController<ProtocolMessage>.broadcast();
  final StreamController<FileTransferItem> _fileTransferController =
      StreamController<FileTransferItem>.broadcast();

  String _localIp = '127.0.0.1';
  int _port = 8945;
  bool _isRunning = false;
  bool isPaused = false;

  LanServerService._internal();

  bool get isRunning => _isRunning;
  String get localIp => _localIp;
  int get port => _port;
  int get clientCount => _clients.length;

  Stream<bool> get statusStream => _statusController.stream;
  Stream<int> get clientCountStream => _clientCountController.stream;
  Stream<ProtocolMessage> get incomingMessagesStream =>
      _incomingMessagesController.stream;
  Stream<FileTransferItem> get fileTransferStream =>
      _fileTransferController.stream;

  List<String> _availableIps = [];
  List<String> get availableIps => _availableIps;

  void setLocalIp(String ip) {
    _localIp = ip;
  }

  Future<String> discoverLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      final List<String> detected = [];
      String? bestIp;
      int bestScore = -100;

      for (final iface in interfaces) {
        final nameLower = iface.name.toLowerCase();
        final isVirtual = nameLower.contains('virtual') ||
            nameLower.contains('vbox') ||
            nameLower.contains('vmware') ||
            nameLower.contains('hyper-v') ||
            nameLower.contains('vethernet') ||
            nameLower.contains('wsl') ||
            nameLower.contains('docker') ||
            nameLower.contains('bluetooth') ||
            nameLower.contains('tap');

        for (final addr in iface.addresses) {
          if (addr.isLoopback || addr.address.startsWith('169.254')) continue;
          detected.add(addr.address);

          int score = 10;
          if (isVirtual) score -= 30;
          if (addr.address.startsWith('192.168.56.')) score -= 30;

          if (nameLower.contains('wi-fi') ||
              nameLower.contains('wifi') ||
              nameLower.contains('wlan')) {
            score += 50;
          } else if (nameLower.contains('ethernet') ||
              nameLower.contains('eth')) {
            score += 20;
          }

          if (score > bestScore) {
            bestScore = score;
            bestIp = addr.address;
          }
        }
      }

      _availableIps = detected;
      if (bestIp != null) {
        _localIp = bestIp;
      }
    } catch (_) {}
    return _localIp;
  }

  Future<bool> startServer({int port = 8945}) async {
    if (_isRunning) return true;
    _port = port;
    await discoverLocalIp();

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;
      _statusController.add(true);

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _handleNewClient(socket);
        } else {
          await _handleHttpRequest(request);
        }
      });
      return true;
    } catch (_) {
      _isRunning = false;
      _statusController.add(false);
      return false;
    }
  }

  void _handleNewClient(WebSocket socket) {
    _clients.add(socket);
    _clientCountController.add(_clients.length);

    socket.listen(
      (data) {
        _handleClientMessage(socket, data);
      },
      onDone: () {
        _clients.remove(socket);
        _clientCountController.add(_clients.length);
      },
      onError: (_) {
        _clients.remove(socket);
        _clientCountController.add(_clients.length);
      },
    );
  }

  void _handleClientMessage(WebSocket socket, dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = ProtocolMessage.fromJson(json);

      _incomingMessagesController.add(message);
      _executeCommand(socket, message);
    } catch (_) {}
  }

  void _executeCommand(WebSocket socket, ProtocolMessage message) {
    if (isPaused && message.type != CommandType.ping) return;
    final input = WindowsInputService.instance;

    switch (message.type) {
      case CommandType.mouseMove:
        final dx = (message.payload['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (message.payload['dy'] as num?)?.toDouble() ?? 0.0;
        input.moveMouse(dx, dy);
        break;

      case CommandType.mouseClick:
        final button = message.payload['button'] as String? ?? 'left';
        if (button == 'left') {
          input.clickLeft();
        } else if (button == 'right') {
          input.clickRight();
        } else if (button == 'double_left') {
          input.doubleClickLeft();
        }
        break;

      case CommandType.mouseScroll:
        final dy = (message.payload['dy'] as num?)?.toDouble() ?? 0.0;
        input.scroll(dy);
        break;

      case CommandType.keyboardText:
        final text = message.payload['text'] as String? ?? '';
        if (text.isNotEmpty) {
          input.sendText(text);
        }
        break;

      case CommandType.keyboardKey:
        final key = message.payload['key'] as String? ?? '';
        final ctrl = message.payload['ctrl'] as bool? ?? false;
        final alt = message.payload['alt'] as bool? ?? false;
        final shift = message.payload['shift'] as bool? ?? false;
        final win = message.payload['win'] as bool? ?? false;

        if (key == 'Escape') {
          input.pressKeyWithModifiers(
            WindowsInputService.vkEscape,
            ctrl: ctrl,
            alt: alt,
            shift: shift,
            win: win,
          );
        } else if (key == 'Tab') {
          input.pressKeyWithModifiers(
            WindowsInputService.vkTab,
            ctrl: ctrl,
            alt: alt,
            shift: shift,
            win: win,
          );
        } else if (key == 'Backspace') {
          input.pressKey(WindowsInputService.vkBack);
        } else if (key == 'Enter') {
          input.pressKey(WindowsInputService.vkReturn);
        } else if (key == 'ArrowUp') {
          input.pressKey(WindowsInputService.vkUp);
        } else if (key == 'ArrowDown') {
          input.pressKey(WindowsInputService.vkDown);
        } else if (key == 'ArrowLeft') {
          input.pressKey(WindowsInputService.vkLeft);
        } else if (key == 'ArrowRight') {
          input.pressKey(WindowsInputService.vkRight);
        } else if (key == 'ctrl_c') {
          input.pressKeyWithModifiers(0x43, ctrl: true);
        } else if (key == 'ctrl_v') {
          input.pressKeyWithModifiers(0x56, ctrl: true);
        } else if (key == 'ctrl_z') {
          input.pressKeyWithModifiers(0x5A, ctrl: true);
        } else if (key == 'alt_tab') {
          input.pressKeyWithModifiers(WindowsInputService.vkTab, alt: true);
        } else if (key == 'win_d') {
          input.showDesktop();
        }
        break;

      case CommandType.mediaPlayPause:
        input.mediaPlayPause();
        break;

      case CommandType.mediaNext:
        input.mediaNext();
        break;

      case CommandType.mediaPrevious:
        input.mediaPrevious();
        break;

      case CommandType.volumeUp:
        input.volumeUp();
        break;

      case CommandType.volumeDown:
        input.volumeDown();
        break;

      case CommandType.volumeMute:
        input.volumeMute();
        break;

      case CommandType.pcLock:
        input.lockPc();
        break;

      case CommandType.showDesktop:
        input.showDesktop();
        break;

      case CommandType.taskView:
        input.taskView();
        break;

      case CommandType.screenshot:
        input.screenshot();
        break;

      case CommandType.restartPc:
        input.restartPc();
        break;

      case CommandType.shutdownPc:
        input.shutdownPc();
        break;

      case CommandType.sleepPc:
        input.sleepPc();
        break;

      case CommandType.presentationNext:
        input.presentationNext();
        break;

      case CommandType.presentationPrevious:
        input.presentationPrevious();
        break;

      case CommandType.presentationStart:
        input.presentationStart();
        break;

      case CommandType.presentationExit:
        input.presentationExit();
        break;

      case CommandType.presentationBlank:
        input.presentationBlank();
        break;

      case CommandType.ping:
        final pongMessage = ProtocolMessage(
          messageId: 'pong-${DateTime.now().millisecondsSinceEpoch}',
          type: CommandType.pong,
          deviceId: 'KRISNA-PC',
          sessionId: message.sessionId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          nonce: message.nonce,
          payload: {'clientTime': message.timestamp},
        );
        socket.add(jsonEncode(pongMessage.toJson()));
        break;

      case CommandType.clipboardSend:
        final text = message.payload['text'] as String? ?? '';
        if (text.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: text));
        }
        break;

      case CommandType.clipboardFetch:
        Clipboard.getData(Clipboard.kTextPlain).then((data) {
          final currentText = data?.text ?? '';
          final response = ProtocolMessage(
            messageId: 'clip-resp-${DateTime.now().millisecondsSinceEpoch}',
            type: CommandType.clipboardContent,
            deviceId: 'KRISNA-PC',
            sessionId: message.sessionId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            nonce: message.nonce,
            payload: {'text': currentText},
          );
          socket.add(jsonEncode(response.toJson()));
        });
        break;

      default:
        break;
    }
  }

  Future<Directory> getOrCreateDownloadDirectory() async {
    Directory? dir;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        dir = Directory('$userProfile\\Downloads\\Lintas');
      }
    }
    dir ??= await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();

    final targetDir = Directory('${dir.path}${Platform.pathSeparator}Lintas');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    if (path == '/api/ping' || path == '/api/status') {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'status': 'ok',
          'server': 'Lintas Companion',
          'ip': _localIp,
          'port': _port,
          'clients': _clients.length,
        }),
      );
      await request.response.close();
      return;
    }

    if (path == '/api/upload' && request.method == 'POST') {
      await _handleFileUpload(request);
      return;
    }

    if (path == '/api/download' && request.method == 'GET') {
      await _handleFileDownload(request);
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'error': 'Endpoint not found'}));
    await request.response.close();
  }

  Future<void> _handleFileUpload(HttpRequest request) async {
    try {
      final rawFilename =
          request.uri.queryParameters['filename'] ?? 'berkas_diterima.bin';
      final fileName = Uri.decodeComponent(rawFilename);
      final expectedSha = request.uri.queryParameters['sha256'];
      final expectedSize =
          int.tryParse(request.uri.queryParameters['size'] ?? '0') ?? 0;

      final downloadDir = await getOrCreateDownloadDirectory();
      var destinationPath =
          '${downloadDir.path}${Platform.pathSeparator}$fileName';

      var file = File(destinationPath);
      var counter = 1;
      while (await file.exists()) {
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1) {
          final base = fileName.substring(0, dotIndex);
          final ext = fileName.substring(dotIndex);
          destinationPath =
              '${downloadDir.path}${Platform.pathSeparator}${base}_($counter)$ext';
        } else {
          destinationPath =
              '${downloadDir.path}${Platform.pathSeparator}${fileName}_($counter)';
        }
        file = File(destinationPath);
        counter++;
      }

      final sink = file.openWrite();
      int totalBytesWritten = 0;
      await for (final chunk in request) {
        sink.add(chunk);
        totalBytesWritten += chunk.length;
      }

      await sink.flush();
      await sink.close();

      final actualSha = (await sha256.bind(file.openRead()).first).toString();
      final shaValid = expectedSha == null ||
          expectedSha.isEmpty ||
          expectedSha.toLowerCase() == actualSha.toLowerCase();

      final item = FileTransferItem(
        id: 'ft-${DateTime.now().millisecondsSinceEpoch}',
        fileName: file.uri.pathSegments.last,
        totalBytes: totalBytesWritten > 0 ? totalBytesWritten : expectedSize,
        transferredBytes: totalBytesWritten,
        speedBytesPerSec: 12500000,
        etaSeconds: 0,
        status: shaValid ? TransferStatus.completed : TransferStatus.failed,
        isOutgoing: false,
        sha256Hash: actualSha,
        localPath: destinationPath,
        errorMessage: shaValid ? null : 'Ketidakcocokan Checksum SHA-256',
      );

      _fileTransferController.add(item);

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'success': shaValid,
          'fileName': item.fileName,
          'savedPath': destinationPath,
          'sha256': actualSha,
          'size': totalBytesWritten,
        }),
      );
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleFileDownload(HttpRequest request) async {
    final filePath = request.uri.queryParameters['path'];
    if (filePath == null || filePath.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Parameter path dibutuhkan');
      await request.response.close();
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Berkas tidak ditemukan');
      await request.response.close();
      return;
    }

    final filename = file.uri.pathSegments.last;
    final length = await file.length();

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.binary;
    request.response.headers.contentLength = length;
    request.response.headers.add(
      'Content-Disposition',
      'attachment; filename="${Uri.encodeComponent(filename)}"',
    );

    await file.openRead().pipe(request.response);
  }

  void broadcastMessage(ProtocolMessage message) {
    final payloadString = jsonEncode(message.toJson());
    for (final client in _clients) {
      try {
        client.add(payloadString);
      } catch (_) {}
    }
  }

  Future<void> stopServer() async {
    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _statusController.add(false);
    _clientCountController.add(0);
  }
}
