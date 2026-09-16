import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../mock/mock_providers.dart';
import '../domain/device_model.dart';
import '../../connection/presentation/connection_controller.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  void _showPairingDialog(
    BuildContext context,
    WidgetRef ref,
    DeviceModel device,
  ) {
    final verificationCode = '749 201';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permintaan Pemasangan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Menghubungkan ke ${device.name}...'),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Pastikan kode verifikasi berikut cocok dengan yang tampil di layar PC Windows Anda:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    verificationCode,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Kunci sesi aman akan dibuat secara lokal setelah konfirmasi kedua belah pihak.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tolak'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(devicesListProvider.notifier).pairDevice(device.id);
                ref
                    .read(connectionControllerProvider.notifier)
                    .connect(device.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Perangkat ${device.name} berhasil dipasangkan dan terpercaya',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Cocok & Pasangkan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceOptionsDialog(
    BuildContext context,
    WidgetRef ref,
    DeviceModel device,
  ) {
    final nameController = TextEditingController(text: device.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(device.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sistem Operasi: ${device.os}'),
              if (device.ipAddress != null)
                Text('Alamat IP: ${device.ipAddress}'),
              Text('Metode: ${device.connectionTypeLabelIndonesian}'),
              Text('Kekuatan BLE: ${device.proximityLabelIndonesian}'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ubah Nama Perangkat',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () {
                ref.read(devicesListProvider.notifier).forgetDevice(device.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${device.name} telah dihapus dari perangkat terpercaya',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Lupakan Perangkat'),
            ),
            FilledButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  ref
                      .read(devicesListProvider.notifier)
                      .renameDevice(device.id, newName);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesListProvider);
    final connectionState = ref.watch(connectionControllerProvider);

    final trustedDevices = devices.where((d) => d.isTrusted).toList();
    final nearbyDevices = devices.where((d) => !d.isTrusted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perangkat Komputer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Pindai Ulang',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memindai jaringan lokal dan Bluetooth...'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PERANGKAT SAYA (TERPERCAYA)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                Text(
                  '${trustedDevices.length} Terdaftar',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (trustedDevices.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('Belum ada perangkat PC terpercaya.'),
                ),
              )
            else
              ...trustedDevices.map((device) {
                final isCurrent =
                    connectionState.connectedDeviceId == device.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primaryDark.withAlpha(40)
                            : Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Icon(
                        Icons.computer_rounded,
                        color: isCurrent
                            ? AppColors.primaryDark
                            : AppColors.textSecondaryDark,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${device.os} • ${device.statusLabelIndonesian}'),
                        Text(
                          '${device.connectionTypeLabelIndonesian} • ${device.proximityLabelIndonesian}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(connectionControllerProvider.notifier)
                                  .disconnect();
                            },
                            child: const Text('Putuskan'),
                          )
                        else if (device.isOnline)
                          FilledButton.tonal(
                            onPressed: () {
                              ref
                                  .read(connectionControllerProvider.notifier)
                                  .connect(device.id);
                            },
                            child: const Text('Sambungkan'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: () =>
                              _showDeviceOptionsDialog(context, ref, device),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'PERANGKAT SEKITAR (BELUM TERPASANG)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (nearbyDevices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Tidak ada komputer baru terdeteksi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Pastikan Lintas Companion telah berjalan di PC Windows dan berada dalam jaringan yang sama.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...nearbyDevices.map((device) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.devices_other_rounded,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    title: Text(
                      device.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${device.os} • ${device.proximityLabelIndonesian}\n${device.connectionTypeLabelIndonesian}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () => _showPairingDialog(context, ref, device),
                      child: const Text('Pasangkan'),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
