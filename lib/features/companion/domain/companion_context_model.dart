enum CompanionContextType {
  defaultMode,
  media,
  presentation,
  fileTransfer,
  focus,
}

class CompanionContextModel {
  final CompanionContextType type;
  final String title;
  final String description;
  final String actionLabel;
  final String routePath;
  final Map<String, dynamic> metadata;

  const CompanionContextModel({
    required this.type,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.routePath,
    this.metadata = const {},
  });

  static const CompanionContextModel defaultContext = CompanionContextModel(
    type: CompanionContextType.defaultMode,
    title: 'Siap Digunakan',
    description: 'Pilih kontrol cepat untuk berinteraksi dengan PC.',
    actionLabel: 'Buka',
    routePath: '/',
  );

  static const CompanionContextModel presentationActive = CompanionContextModel(
    type: CompanionContextType.presentation,
    title: 'Presentasi Aktif Terdeteksi',
    description:
        'Gunakan ponsel sebagai remote pengendali slide presentasi PC.',
    actionLabel: 'Buka Remote Presentasi',
    routePath: '/presentation',
  );

  static const CompanionContextModel mediaActive = CompanionContextModel(
    type: CompanionContextType.media,
    title: 'Pemutar Media Berjalan',
    description: 'Putar, jeda, atau atur volume audio PC langsung dari ponsel.',
    actionLabel: 'Kendali Media',
    routePath: '/',
  );

  static const CompanionContextModel fileTransferActive = CompanionContextModel(
    type: CompanionContextType.fileTransfer,
    title: 'Transfer Berkas Sedang Berjalan',
    description: 'Pantau kecepatan dan status verifikasi kiriman berkas.',
    actionLabel: 'Lihat Transfer',
    routePath: '/files',
  );
}
