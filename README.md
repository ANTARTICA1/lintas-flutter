# Lintas Ecosystem

**Lintas** adalah ekosistem aplikasi lintas perangkat (*cross-device ecosystem*) yang menghubungkan smartphone Android dan PC Windows melalui jaringan lokal (LAN) secara instan, aman, dan tanpa latensi tinggi.

---

## ✨ Fitur Utama

- ⚡ **Smart Bridge & Auto-Discovery**: Deteksi otomatis host PC pada jaringan Wi-Fi/LAN lokal dengan protokol HTTP & WebSocket tanpa perlu konfigurasi IP manual.
- 📷 **Pairing Cepat via QR Code**: Sambungkan perangkat ponsel ke laptop/PC dengan memindai kode QR berenkripsi waktu (Time-based Token).
- 📁 **Instant Drop (File Transfer)**: Transfer berkas dua arah antara HP dan PC dengan kecepatan LAN maksimal, dilengkapi validasi integritas berkas menggunakan checksum SHA-256.
- 🖱️ **Remote Touchpad**: Kontrol kursor PC dari layar smartphone secara halus dengan gestur klik, klik kanan, scroll dua jari, dan drag-and-drop.
- ⌨️ **Virtual Keyboard**: Kirim ketikan teks dan tombol aksi (Enter, Backspace, Shortcuts) langsung dari ponsel ke PC.
- 📋 **Universal Clipboard**: Sinkronisasi papan klip (clipboard) otomatis secara real-time antara PC dan smartphone.
- 🔒 **NearLock**: Pemantauan kedekatan perangkat untuk penguncian PC otomatis dan deteksi kepulangan pengguna.
- 📊 **Presentation Mode**: Remote kendali slide presentasi (Next, Previous, Black Screen, Timer).

---

## 🛠️ Arsitektur & Teknologi

- **Framework**: [Flutter](https://flutter.dev) (Multi-platform: Android & Windows Desktop)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**:
  - `HttpServer` & WebSocket Server bawaan Dart (Sisi Windows Desktop)
  - `HttpClient` & WebSocket Client (Sisi Android Mobile)
- **Keamanan**: Payload QR bertanda waktu kedaluwarsa & validasi integritas SHA-256 untuk transfer file.

---

## 🚀 Cara Menjalankan

### 1. Prasyarat
- Flutter SDK (versi ^3.11.5 atau lebih baru)
- Android Studio / Android SDK (untuk menjalankan di Android)
- Visual Studio dengan C++ Desktop Development (untuk menjalankan di Windows)

### 2. Instalasi Dependensi
```bash
flutter pub get
```

### 3. Menjalankan di Windows (Host Companion Mode)
```bash
flutter run -d windows
```

### 4. Menjalankan di Android (Client Mode)
```bash
flutter run -d <device-id>
```

---

## 🧪 Menjalankan Pengujian

Jalankan pengujian unit dan widget:
```bash
flutter test
```

Analisis statis kode:
```bash
flutter analyze
```
