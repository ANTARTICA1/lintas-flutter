import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/file_transfer/domain/file_transfer_model.dart';

class FileTransferService {
  static final FileTransferService instance = FileTransferService._internal();
  FileTransferService._internal();

  Future<Directory> getLocalDownloadDirectory() async {
    Directory? dir;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        dir = Directory('$userProfile\\Downloads\\Lintas');
      }
    } else if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/Lintas');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    }
    dir ??= await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();

    final targetDir = dir.path.endsWith('Lintas')
        ? dir
        : Directory('${dir.path}${Platform.pathSeparator}Lintas');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  Future<String> calculateSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<FileTransferItem?> pickAndSendFile({
    required String host,
    required int port,
    required void Function(FileTransferItem) onProgress,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result.isEmpty) return null;
    final picked = result.first;
    final path = picked.path;
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    final fileName = picked.name;
    final totalBytes = await file.length();
    final transferId = 'ft-${DateTime.now().millisecondsSinceEpoch}';

    final sha = await calculateSha256(file);

    var item = FileTransferItem(
      id: transferId,
      fileName: fileName,
      totalBytes: totalBytes,
      transferredBytes: 0,
      speedBytesPerSec: 0,
      etaSeconds: 0,
      status: TransferStatus.transferring,
      isOutgoing: true,
      sha256Hash: sha,
      localPath: path,
    );
    onProgress(item);

    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.parse(
        'http://$host:$port/api/upload?filename=${Uri.encodeComponent(fileName)}&size=$totalBytes&sha256=$sha',
      );

      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.binary;
      request.headers.contentLength = totalBytes;

      final startTime = DateTime.now().millisecondsSinceEpoch;
      int transferred = 0;
      int lastReportTime = startTime;
      int lastReportBytes = 0;

      final fileStream = file.openRead();
      await for (final chunk in fileStream) {
        request.add(chunk);
        transferred += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSinceLastReport = (now - lastReportTime) / 1000.0;

        if (elapsedSinceLastReport >= 0.2 || transferred == totalBytes) {
          final bytesDelta = transferred - lastReportBytes;
          final speed = elapsedSinceLastReport > 0
              ? (bytesDelta / elapsedSinceLastReport).round()
              : 0;
          final remainingBytes = totalBytes - transferred;
          final eta = speed > 0 ? (remainingBytes / speed).round() : 0;

          item = item.copyWith(
            transferredBytes: transferred,
            speedBytesPerSec: speed,
            etaSeconds: eta,
          );
          onProgress(item);

          lastReportTime = now;
          lastReportBytes = transferred;
        }
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == HttpStatus.ok) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final success = json['success'] as bool? ?? false;

        item = item.copyWith(
          transferredBytes: totalBytes,
          status: success ? TransferStatus.completed : TransferStatus.failed,
          errorMessage: success ? null : 'Integritas berkas tidak valid',
          etaSeconds: 0,
        );
      } else {
        item = item.copyWith(
          status: TransferStatus.failed,
          errorMessage: 'Server HTTP error: ${response.statusCode}',
        );
      }
    } catch (e) {
      item = item.copyWith(
        status: TransferStatus.failed,
        errorMessage: 'Gagal mengirim berkas: $e',
      );
    } finally {
      httpClient.close();
      onProgress(item);
    }

    return item;
  }

  Future<FileTransferItem> downloadFile({
    required String host,
    required int port,
    required String remotePath,
    required String fileName,
    required int totalBytes,
    String? expectedSha,
    required void Function(FileTransferItem) onProgress,
  }) async {
    final transferId = 'ft-${DateTime.now().millisecondsSinceEpoch}';
    final downloadDir = await getLocalDownloadDirectory();
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

    var item = FileTransferItem(
      id: transferId,
      fileName: file.uri.pathSegments.last,
      totalBytes: totalBytes,
      transferredBytes: 0,
      status: TransferStatus.transferring,
      isOutgoing: false,
      sha256Hash: expectedSha,
      localPath: destinationPath,
    );
    onProgress(item);

    final httpClient = HttpClient();
    try {
      final uri = Uri.parse(
        'http://$host:$port/api/download?path=${Uri.encodeComponent(remotePath)}',
      );
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception('HTTP status ${response.statusCode}');
      }

      final sink = file.openWrite();

      int received = 0;
      final startTime = DateTime.now().millisecondsSinceEpoch;
      int lastReportTime = startTime;
      int lastReportBytes = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = (now - lastReportTime) / 1000.0;

        if (elapsed >= 0.2 || received == totalBytes) {
          final delta = received - lastReportBytes;
          final speed = elapsed > 0 ? (delta / elapsed).round() : 0;
          final remaining = totalBytes - received;
          final eta = speed > 0 ? (remaining / speed).round() : 0;

          item = item.copyWith(
            transferredBytes: received,
            speedBytesPerSec: speed,
            etaSeconds: eta,
          );
          onProgress(item);

          lastReportTime = now;
          lastReportBytes = received;
        }
      }

      await sink.flush();
      await sink.close();

      final actualSha = await calculateSha256(file);
      final valid = expectedSha == null ||
          expectedSha.isEmpty ||
          expectedSha.toLowerCase() == actualSha.toLowerCase();

      item = item.copyWith(
        transferredBytes: received,
        status: valid ? TransferStatus.completed : TransferStatus.failed,
        sha256Hash: actualSha,
        errorMessage: valid ? null : 'Ketidakcocokan Checksum SHA-256',
        etaSeconds: 0,
      );
    } catch (e) {
      item = item.copyWith(
        status: TransferStatus.failed,
        errorMessage: 'Gagal mengunduh berkas: $e',
      );
    } finally {
      httpClient.close();
      onProgress(item);
    }

    return item;
  }

  Future<OpenResult> openFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'Berkas tidak ditemukan pada direktori lokal',
      );
    }
    return OpenFilex.open(path);
  }
}
