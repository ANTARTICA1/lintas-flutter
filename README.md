# Lintas

Lintas adalah aplikasi ekosistem lintas perangkat (cross-device) yang menghubungkan smartphone Android dengan komputer berbasis Windows melalui jaringan lokal (LAN) secara langsung, aman, dan berkecepatan tinggi.

Aplikasi ini dirancang untuk memudahkan produktivitas pengguna tanpa memerlukan koneksi internet eksternal atau server pihak ketiga. Semua komunikasi data berjalan langsung antara perangkat Android dan PC Windows di dalam jaringan Wi-Fi yang sama.

---

## Gambaran Cara Kerja

Aplikasi Lintas menggunakan arsitektur peer-to-peer berbasis Client-Server lokal:

1. Mode Windows (Host Companion Server):
   Saat dijalankan pada komputer Windows, aplikasi secara otomatis memulai server HTTP dan WebSocket lokal pada port 8945. Server ini menampilkan kode QR yang memuat informasi koneksi (IP lokal, port, dan token sesi yang memiliki masa kedaluwarsa).

2. Mode Android (Mobile Controller):
   Saat dijalankan pada smartphone Android, aplikasi dapat langsung memindai kode QR dari layar PC atau menggunakan fitur pemindaian otomatis (Auto-Discovery) untuk menemukan PC di jaringan Wi-Fi lokal.

3. Komunikasi Dua Arah:
   Setelah terhubung melalui WebSocket dan HTTP, kedua perangkat dapat saling bertukar perintah pengendali, sinkronisasi papan klip, maupun pengiriman berkas berukuran besar secara instan.

---

## Fitur Lengkap

### 1. Pairing Cepat dan Aman
- Pemindaian Kode QR: Terhubung dalam hitungan detik dengan memindai kode QR berwaktu kedaluwarsa pada layar PC.
- LAN Auto-Discovery: Deteksi otomatis PC yang sedang aktif pada subnet jaringan Wi-Fi yang sama tanpa perlu mengetikkan alamat IP secara manual.

### 2. Remote Touchpad
- Kontrol Kursor: Gerakkan kursor PC secara mulus melalui layar sentuh smartphone.
- Dukungan Gestur: Mendukung ketukan untuk klik kiri, ketukan dua jari untuk klik kanan, gulir halaman (scrolling), dan penahanan untuk drag-and-drop.

### 3. Keyboard Virtual
- Input Teks Langsung: Ketik kalimat atau teks panjang dari ponsel dan kirimkan langsung ke PC.
- Tombol Aksi Khusus: Mendukung tombol fungsional seperti Enter, Backspace, Spasi, Tab, dan pintasan navigasi.

### 4. Instant Drop (Transfer Berkas Berkecepatan Tinggi)
- Pengiriman Berkas Dua Arah: Kirim berkas dari HP ke PC atau dari PC ke HP melalui jaringan lokal.
- Kecepatan Penuh Jaringan LAN: Kecepatan transfer memanfaatkan kapasitas maksimal router Wi-Fi lokal tanpa pembatasan kuota internet.
- Verifikasi Integritas SHA-256: Setiap transfer berkas diverifikasi menggunakan algoritma hash SHA-256 untuk memastikan data tidak rusak atau korup.

### 5. Universal Clipboard (Sinkronisasi Papan Klip)
- Pemantauan Papan Klip Otomatis: Teks atau tautan URL yang disalin di satu perangkat dapat segera dilihat dan digunakan di perangkat lainnya.
- Deteksi Tautan Otomatis: Tautan web yang disalin ditandai secara otomatis sehingga dapat langsung dibuka melalui browser.

### 6. NearLock (Kunci Jarak Dekat)
- Pemantauan Status Kehadiran: Memantau keterhubungan perangkat secara berkala.
- Otomasi Kunci Layar: Memungkinkan pengiriman perintah penguncian PC saat ponsel berada di luar jangkauan atau saat pengguna meninggalkan meja kerja.

### 7. Mode Presentasi
- Pengendali Slide: Navigasi slide maju (Next) dan mundur (Previous) untuk aplikasi presentasi seperti PowerPoint atau PDF.
- Fungsi Tambahan: Fitur layar hitam (Black Screen) dan penghitung waktu presentasi untuk memantau durasi presentasi Anda.

---

## Arsitektur dan Teknologi

- Framework: Flutter (Mendukung target platform Android dan Windows Desktop)
- Bahasa Pemrograman: Dart, C++ (untuk runner Windows)
- Manajemen State: Flutter Riverpod
- Manajemen Rute: GoRouter (dengan pemilihan rute otomatis berdasarkan platform)
- Protokol Jaringan:
  - HttpServer dan HttpClient bawaan Dart
  - WebSocket untuk komunikasi perintah real-time berlatensi rendah
- Kriptografi dan Hash: Paket crypto (perhitungan checksum berkas SHA-256)
- Pembacaan QR: Paket mobile_scanner (Android) dan qr_flutter (Windows)

---

## Persyaratan Sistem

### Perangkat Komputer (Windows)
- Sistem Operasi: Windows 10 versi 1809 atau Windows 11 (64-bit)
- Jaringan: Terhubung ke jaringan lokal (Wi-Fi atau kabel LAN)
- Port: Port 8945 harus diizinkan pada Windows Firewall untuk koneksi masuk lokal

### Perangkat Smartphone (Android)
- Sistem Operasi: Android 7.0 (Nougat) atau versi lebih baru
- Fitur Perangkat: Kamera (untuk pemindaian kode QR) dan Wi-Fi aktif

---

## Panduan Menjalankan Aplikasi

### 1. Menyiapkan Lingkungan Pengembangan
Pastikan perangkat Anda telah terpasang:
- Flutter SDK (versi 3.11.5 atau lebih baru)
- Visual Studio dengan modul "Desktop development with C++" (untuk build Windows)
- Android Studio / Android SDK (untuk build Android)

Periksa kesiapan environment dengan perintah:
```bash
flutter doctor
```

### 2. Mengunduh Dependensi
Jalankan perintah berikut di direktori proyek:
```bash
flutter pub get
```

### 3. Menjalankan di Komputer Windows (Mode Server Host)
Buka terminal dan jalankan:
```bash
flutter run -d windows
```
Aplikasi akan terbuka dalam jendela Windows Companion dan langsung mengaktifkan server lokal beserta tampilan kode QR.

### 4. Menjalankan di Smartphone Android (Mode Controller)
Hubungkan ponsel Android Anda menggunakan kabel USB (dengan USB Debugging aktif) atau emulator Android, lalu jalankan:
```bash
flutter run -d <nama-perangkat-anda>
```

### 5. Menghubungkan Kedua Perangkat
1. Pastikan komputer Windows dan ponsel Android terhubung pada jaringan Wi-Fi yang sama.
2. Pada aplikasi Android, tekan tombol "Hubungkan PC Sekarang" atau pilih ikon pemindai QR.
3. Arahkan kamera ponsel ke kode QR yang ada di layar komputer Anda, atau gunakan opsi "Deteksi Otomatis PC di Wi-Fi".
4. Setelah terhubung, indikator status akan berubah menjadi terhubung dan semua fitur pengendali siap digunakan.

---

## Pengujian dan Kualitas Kode

Aplikasi ini dilengkapi pengujian otomatis dan mengikuti standar analisis kode Flutter:

Menjalankan pengujian unit dan widget:
```bash
flutter test
```

Menjalankan analisis statis kode:
```bash
flutter analyze
```
