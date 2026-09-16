import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/devices/domain/device_model.dart';
import '../features/activity/domain/activity_model.dart';
import '../features/file_transfer/domain/file_transfer_model.dart';
import '../features/nearlock/domain/nearlock_state.dart';
import 'mock_data.dart';

class MockModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void setMode(bool enabled) {
    state = enabled;
  }
}

final mockModeProvider = NotifierProvider<MockModeNotifier, bool>(
  MockModeNotifier.new,
);

class DevicesNotifier extends Notifier<List<DeviceModel>> {
  @override
  List<DeviceModel> build() => MockData.initialDevices;

  void renameDevice(String id, String newName) {
    state = state.map((d) {
      if (d.id == id) {
        return d.copyWith(name: newName);
      }
      return d;
    }).toList();
  }

  void addOrUpdateDevice(DeviceModel device) {
    var found = false;
    state = state.map((d) {
      if (d.id == device.id) {
        found = true;
        return device;
      }
      return d;
    }).toList();
    if (!found) {
      state = [device, ...state];
    }
  }

  void forgetDevice(String id) {
    state = state.where((d) => d.id != id).toList();
  }

  void pairDevice(String id) {
    state = state.map((d) {
      if (d.id == id) {
        return d.copyWith(isTrusted: true, lastConnected: DateTime.now());
      }
      return d;
    }).toList();
  }
}

final devicesListProvider =
    NotifierProvider<DevicesNotifier, List<DeviceModel>>(DevicesNotifier.new);

class ActivityNotifier extends Notifier<List<ActivityModel>> {
  @override
  List<ActivityModel> build() => MockData.initialActivities;

  void addActivity(ActivityModel activity) {
    state = [activity, ...state];
  }

  void clearActivities() {
    state = [];
  }
}

final activityListProvider =
    NotifierProvider<ActivityNotifier, List<ActivityModel>>(
      ActivityNotifier.new,
    );

class FileTransferNotifier extends Notifier<List<FileTransferItem>> {
  @override
  List<FileTransferItem> build() {
    final isMock = ref.watch(mockModeProvider);
    return isMock ? MockData.initialTransfers : [];
  }

  void cancelTransfer(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(status: TransferStatus.cancelled);
      }
      return item;
    }).toList();
  }

  void pauseTransfer(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(status: TransferStatus.paused);
      }
      return item;
    }).toList();
  }

  void resumeTransfer(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(status: TransferStatus.transferring);
      }
      return item;
    }).toList();
  }

  void addTransfer(FileTransferItem item) {
    state = [item, ...state];
  }

  void updateTransfer(FileTransferItem item) {
    var found = false;
    state = state.map((existing) {
      if (existing.id == item.id) {
        found = true;
        return item;
      }
      return existing;
    }).toList();
    if (!found) {
      state = [item, ...state];
    }
  }
}

final fileTransferListProvider =
    NotifierProvider<FileTransferNotifier, List<FileTransferItem>>(
      FileTransferNotifier.new,
    );

class NearLockNotifier extends Notifier<NearLockConfig> {
  @override
  NearLockConfig build() => const NearLockConfig();

  void updateConfig(NearLockConfig config) {
    state = config;
  }

  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }
}

final nearlockConfigProvider =
    NotifierProvider<NearLockNotifier, NearLockConfig>(NearLockNotifier.new);
