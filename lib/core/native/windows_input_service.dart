import 'dart:ffi';
import 'dart:io';

typedef MouseEventNative =
    Void Function(
      Uint32 dwFlags,
      Uint32 dx,
      Uint32 dy,
      Uint32 dwData,
      IntPtr dwExtraInfo,
    );
typedef MouseEventDart =
    void Function(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

typedef KeybdEventNative =
    Void Function(Uint8 bVk, Uint8 bScan, Uint32 dwFlags, IntPtr dwExtraInfo);
typedef KeybdEventDart =
    void Function(int bVk, int bScan, int dwFlags, int dwExtraInfo);

typedef LockWorkStationNative = Int32 Function();
typedef LockWorkStationDart = int Function();

class WindowsInputService {
  static final WindowsInputService instance = WindowsInputService._internal();

  MouseEventDart? _mouseEvent;
  KeybdEventDart? _keybdEvent;
  LockWorkStationDart? _lockWorkStation;
  bool _initialized = false;

  static const int mouseEventMove = 0x0001;
  static const int mouseEventLeftDown = 0x0002;
  static const int mouseEventLeftUp = 0x0004;
  static const int mouseEventRightDown = 0x0008;
  static const int mouseEventRightUp = 0x0010;
  static const int mouseEventWheel = 0x0800;

  static const int keyEventKeyUp = 0x0002;

  static const int vkBack = 0x08;
  static const int vkTab = 0x09;
  static const int vkReturn = 0x0D;
  static const int vkShift = 0x10;
  static const int vkControl = 0x11;
  static const int vkMenu = 0x12;
  static const int vkEscape = 0x1B;
  static const int vkSpace = 0x20;
  static const int vkLeft = 0x25;
  static const int vkUp = 0x26;
  static const int vkRight = 0x27;
  static const int vkDown = 0x28;
  static const int vkLWin = 0x5B;

  static const int vkVolumeMute = 0xAD;
  static const int vkVolumeDown = 0xAE;
  static const int vkVolumeUp = 0xAF;
  static const int vkMediaNextTrack = 0xB0;
  static const int vkMediaPrevTrack = 0xB1;
  static const int vkMediaPlayPause = 0xB3;

  WindowsInputService._internal() {
    _initFfi();
  }

  void _initFfi() {
    if (!Platform.isWindows) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');

      _mouseEvent = user32.lookupFunction<MouseEventNative, MouseEventDart>(
        'mouse_event',
      );
      _keybdEvent = user32.lookupFunction<KeybdEventNative, KeybdEventDart>(
        'keybd_event',
      );
      _lockWorkStation = user32
          .lookupFunction<LockWorkStationNative, LockWorkStationDart>(
            'LockWorkStation',
          );
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  bool get isSupported => Platform.isWindows && _initialized;

  void moveMouse(double dx, double dy) {
    if (!isSupported || _mouseEvent == null) return;
    _mouseEvent!(mouseEventMove, dx.round(), dy.round(), 0, 0);
  }

  void clickLeft() {
    if (!isSupported || _mouseEvent == null) return;
    _mouseEvent!(mouseEventLeftDown, 0, 0, 0, 0);
    _mouseEvent!(mouseEventLeftUp, 0, 0, 0, 0);
  }

  void doubleClickLeft() {
    clickLeft();
    clickLeft();
  }

  void clickRight() {
    if (!isSupported || _mouseEvent == null) return;
    _mouseEvent!(mouseEventRightDown, 0, 0, 0, 0);
    _mouseEvent!(mouseEventRightUp, 0, 0, 0, 0);
  }

  void scroll(double dy) {
    if (!isSupported || _mouseEvent == null) return;
    final delta = (dy * 120).round();
    _mouseEvent!(mouseEventWheel, 0, 0, delta, 0);
  }

  void pressKey(int virtualKey) {
    if (!isSupported || _keybdEvent == null) return;
    _keybdEvent!(virtualKey, 0, 0, 0);
    _keybdEvent!(virtualKey, 0, keyEventKeyUp, 0);
  }

  void pressKeyWithModifiers(
    int virtualKey, {
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool win = false,
  }) {
    if (!isSupported || _keybdEvent == null) return;

    if (ctrl) _keybdEvent!(vkControl, 0, 0, 0);
    if (alt) _keybdEvent!(vkMenu, 0, 0, 0);
    if (shift) _keybdEvent!(vkShift, 0, 0, 0);
    if (win) _keybdEvent!(vkLWin, 0, 0, 0);

    _keybdEvent!(virtualKey, 0, 0, 0);
    _keybdEvent!(virtualKey, 0, keyEventKeyUp, 0);

    if (win) _keybdEvent!(vkLWin, 0, keyEventKeyUp, 0);
    if (shift) _keybdEvent!(vkShift, 0, keyEventKeyUp, 0);
    if (alt) _keybdEvent!(vkMenu, 0, keyEventKeyUp, 0);
    if (ctrl) _keybdEvent!(vkControl, 0, keyEventKeyUp, 0);
  }

  void sendText(String text) {
    if (!isSupported) return;
    for (final char in text.runes) {
      if (char >= 65 && char <= 90) {
        pressKeyWithModifiers(char, shift: true);
      } else if (char >= 97 && char <= 122) {
        pressKey(char - 32);
      } else if (char >= 48 && char <= 57) {
        pressKey(char);
      } else if (char == 32) {
        pressKey(vkSpace);
      }
    }
  }

  void lockPc() {
    if (!isSupported || _lockWorkStation == null) return;
    _lockWorkStation!();
  }

  void showDesktop() {
    pressKeyWithModifiers(0x44, win: true);
  }

  void taskView() {
    pressKeyWithModifiers(vkTab, win: true);
  }

  void mediaPlayPause() {
    pressKey(vkMediaPlayPause);
  }

  void mediaNext() {
    pressKey(vkMediaNextTrack);
  }

  void mediaPrevious() {
    pressKey(vkMediaPrevTrack);
  }

  void volumeUp() {
    pressKey(vkVolumeUp);
  }

  void volumeDown() {
    pressKey(vkVolumeDown);
  }

  void volumeMute() {
    pressKey(vkVolumeMute);
  }

  void presentationNext() {
    pressKey(vkRight);
  }

  void presentationPrevious() {
    pressKey(vkLeft);
  }

  void presentationStart() {
    pressKey(0x74);
  }

  void presentationExit() {
    pressKey(vkEscape);
  }

  void presentationBlank() {
    pressKey(0x42);
  }
}
