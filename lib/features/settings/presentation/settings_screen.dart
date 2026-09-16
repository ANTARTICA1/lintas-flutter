import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../mock/mock_providers.dart';
import '../../nearlock/domain/nearlock_state.dart';
import '../../connection/presentation/connection_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoReconnect = true;
  bool _autoClipboard = false;
  bool _verifyChecksum = true;

  void _showDisconnectAllDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Putuskan Semua Sesi'),
          content: const Text(
            'Tindakan darurat ini akan segera memutuskan seluruh sesi koneksi aktif antara ponsel dan semua PC Windows terdaftar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                ref.read(connectionControllerProvider.notifier).disconnect();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Semua sesi koneksi telah diputuskan secara darurat',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Putuskan Sekarang'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockMode = ref.watch(mockModeProvider);
    final nearlockConfig = ref.watch(nearlockConfigProvider);
    final connectionState = ref.watch(connectionControllerProvider);
    final devices = ref.watch(devicesListProvider);

    final trustedCount = devices.where((d) => d.isTrusted).length;
    final activeCount = connectionState.isConnected ? 1 : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Privasi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildSectionHeader('DASHBOARD PRIVASI & KEAMANAN'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatBox(
                          title: 'Perangkat Terpercaya',
                          value: '$trustedCount',
                          icon: Icons.verified_user_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildStatBox(
                          title: 'Koneksi Aktif',
                          value: '$activeCount',
                          icon: Icons.link_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _buildStatBox(
                          title: 'NearLock',
                          value: nearlockConfig.enabled ? 'Aktif' : 'Nonaktif',
                          icon: Icons.lock_clock_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildStatBox(
                          title: 'Sinkronisasi Klip',
                          value: _autoClipboard ? 'Otomatis' : 'Manual',
                          icon: Icons.assignment_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.power_off_rounded, size: 18),
                        label: const Text('PUTUSKAN SEMUA KONEKSI SEKARANG'),
                        onPressed: _showDisconnectAllDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader('SIMULASI & MODE COMPANION'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.developer_mode_rounded),
                    title: const Text('Mode Simulasi (Mock Mode)'),
                    subtitle: const Text(
                      'Menjalankan emulasi perangkat virtual tanpa membutuhkan PC fisik.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: mockMode,
                    onChanged: (val) {
                      ref.read(mockModeProvider.notifier).setMode(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.desktop_windows_rounded),
                    title: const Text('Buka Layar Windows Companion'),
                    subtitle: const Text(
                      'Simulasikan tampilan jendela PC Windows, QR pairing, dan Drop Zone.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/windows-companion'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader('NEARLOCK 2.0 (KEHADIRAN & KEAMANAN PC)'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_clock_rounded),
                    title: const Text('Aktifkan NearLock'),
                    subtitle: const Text(
                      'Mengunci PC secara otomatis jika ponsel menjauh di luar jangkauan.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: nearlockConfig.enabled,
                    onChanged: (val) {
                      ref.read(nearlockConfigProvider.notifier).toggleEnabled();
                    },
                  ),
                  if (nearlockConfig.enabled) ...[
                    const Divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.restart_alt_rounded),
                      title: const Text(
                        'Deteksi Kepulangan (Return Detection)',
                      ),
                      subtitle: const Text(
                        'Menyiapkan sesi saat ponsel kembali tanpa melewati sandi Windows.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: nearlockConfig.returnDetectionEnabled,
                      onChanged: (val) {
                        ref
                            .read(nearlockConfigProvider.notifier)
                            .updateConfig(
                              nearlockConfig.copyWith(
                                returnDetectionEnabled: val,
                              ),
                            );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: const Text('Sensitivitas Sinyal'),
                      subtitle: Text(nearlockConfig.sensitivityLabelIndonesian),
                      trailing: DropdownButton<NearLockSensitivity>(
                        value: nearlockConfig.sensitivity,
                        underline: const SizedBox(),
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(nearlockConfigProvider.notifier)
                                .updateConfig(
                                  nearlockConfig.copyWith(sensitivity: val),
                                );
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: NearLockSensitivity.close,
                            child: Text('Dekat Sekali'),
                          ),
                          DropdownMenuItem(
                            value: NearLockSensitivity.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: NearLockSensitivity.far,
                            child: Text('Jauh'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.timer_rounded),
                      title: const Text('Masa Tenggang Penguncian'),
                      subtitle: Text(
                        '${nearlockConfig.gracePeriodSeconds} Detik',
                      ),
                      trailing: DropdownButton<int>(
                        value: nearlockConfig.gracePeriodSeconds,
                        underline: const SizedBox(),
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(nearlockConfigProvider.notifier)
                                .updateConfig(
                                  nearlockConfig.copyWith(
                                    gracePeriodSeconds: val,
                                  ),
                                );
                          }
                        },
                        items: const [5, 10, 15, 30, 60]
                            .map(
                              (sec) => DropdownMenuItem(
                                value: sec,
                                child: Text('$sec Detik'),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionHeader('TRANSFER & PRIVASI DATA'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.autorenew_rounded),
                    title: const Text('Sambung Ulang Otomatis'),
                    subtitle: const Text(
                      'Menghubungkan kembali menggunakan jeda eksponensial (1s, 2s, 4s, 8s, 15s).',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _autoReconnect,
                    onChanged: (val) => setState(() => _autoReconnect = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.verified_outlined),
                    title: const Text('Verifikasi Integritas SHA-256'),
                    subtitle: const Text(
                      'Memeriksa checksum berkas setelah transfer selesai guna mencegah kerusakan berkas.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _verifyChecksum,
                    onChanged: (val) => setState(() => _verifyChecksum = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.assignment_outlined),
                    title: const Text('Sinkronisasi Papan Klip Otomatis'),
                    subtitle: const Text(
                      'Bawaan nonaktif. Gunakan Linimasa untuk perlindungan sandi.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _autoClipboard,
                    onChanged: (val) => setState(() => _autoClipboard = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.textSecondaryDark,
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
