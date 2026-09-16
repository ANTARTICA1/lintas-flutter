class ClipboardItemModel {
  final String id;
  final String content;
  final String sourceDevice;
  final DateTime timestamp;
  final bool isUrl;
  final bool isSensitive;
  final bool isPrivate;

  const ClipboardItemModel({
    required this.id,
    required this.content,
    required this.sourceDevice,
    required this.timestamp,
    this.isUrl = false,
    this.isSensitive = false,
    this.isPrivate = false,
  });

  String get relativeTimeIndonesian {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return '${diff.inDays} hari yang lalu';
    }
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ClipboardItemModel copyWith({
    String? id,
    String? content,
    String? sourceDevice,
    DateTime? timestamp,
    bool? isUrl,
    bool? isSensitive,
    bool? isPrivate,
  }) {
    return ClipboardItemModel(
      id: id ?? this.id,
      content: content ?? this.content,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      timestamp: timestamp ?? this.timestamp,
      isUrl: isUrl ?? this.isUrl,
      isSensitive: isSensitive ?? this.isSensitive,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
