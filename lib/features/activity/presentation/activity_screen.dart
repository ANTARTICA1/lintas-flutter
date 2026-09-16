import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../mock/mock_providers.dart';
import '../domain/activity_model.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.connection:
        return Icons.link_rounded;
      case ActivityType.disconnection:
        return Icons.link_off_rounded;
      case ActivityType.fileSent:
        return Icons.upload_file_rounded;
      case ActivityType.fileReceived:
        return Icons.download_rounded;
      case ActivityType.clipboardSent:
        return Icons.content_copy_rounded;
      case ActivityType.clipboardReceived:
        return Icons.assignment_returned_rounded;
      case ActivityType.touchpadUsed:
        return Icons.touch_app_rounded;
      case ActivityType.nearlockTriggered:
        return Icons.lock_person_rounded;
      case ActivityType.pairingSuccess:
        return Icons.security_rounded;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.connection:
      case ActivityType.pairingSuccess:
        return AppColors.success;
      case ActivityType.disconnection:
        return AppColors.warning;
      case ActivityType.fileSent:
      case ActivityType.fileReceived:
        return AppColors.primaryDark;
      case ActivityType.nearlockTriggered:
        return AppColors.secondaryDark;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityListProvider);

    final grouped = <String, List<ActivityModel>>{};
    for (final item in activities) {
      final group = item.groupCategoryIndonesian;
      grouped.putIfAbsent(group, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Hapus Riwayat',
            onPressed: () {
              ref.read(activityListProvider.notifier).clearActivities();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat aktivitas telah dibersihkan'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: activities.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Tidak ada aktivitas tercatat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Aktivitas seperti koneksi, transfer berkas, dan NearLock akan dicatat di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entry.value.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final act = entry.value[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: _getActivityColor(
                                    act.type,
                                  ).withAlpha(30),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Icon(
                                  _getActivityIcon(act.type),
                                  color: _getActivityColor(act.type),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                act.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                act.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                              trailing: Text(
                                act.formattedTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }
}
