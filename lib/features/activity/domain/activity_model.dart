enum ActivityType {
  connection,
  disconnection,
  fileSent,
  fileReceived,
  clipboardSent,
  clipboardReceived,
  touchpadUsed,
  nearlockTriggered,
  pairingSuccess,
}

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;
  final String deviceName;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.deviceName,
  });

  String get groupCategoryIndonesian {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final difference = today.difference(itemDate).inDays;
    if (difference == 0) {
      return 'Hari Ini';
    } else if (difference == 1) {
      return 'Kemarin';
    } else {
      return 'Sebelumnya';
    }
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
