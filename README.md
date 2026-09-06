# Absensi PKL — Struktur Project

Skeleton Flutter + Firebase buat aplikasi absensi PKL dengan verifikasi lokasi
dan foto wajib. Semua desain di sini sesuai yang udah didiskusikan: satu lokasi
PKL, geofencing, deteksi mock GPS + jailbreak + anomali kecepatan, kamera-only
(no galeri), watermark foto, dan compress sebelum upload.

## Struktur folder

```
lib/
├── main.dart                          # entry point + auth gate
├── models/
│   ├── user_model.dart                # data user (siswa/pembimbing/admin)
│   ├── lokasi_pkl_model.dart          # config lokasi PKL (dokumen tunggal)
│   └── absensi_model.dart             # satu record log absensi
├── services/
│   ├── auth_service.dart              # login/logout
│   ├── location_service.dart          # INTI: geofencing + semua deteksi keamanan
│   ├── storage_service.dart           # compress + upload foto
│   └── firestore_service.dart         # baca/tulis absensi_log
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── absen_camera_screen.dart       # INTI: flow cek lokasi -> kamera -> simpan
│   ├── riwayat_screen.dart            # riwayat absen siswa (realtime)
│   └── admin/
│       └── dashboard_admin_screen.dart # monitoring realtime buat pembimbing/admin
├── widgets/
│   └── loading_widget.dart
└── utils/
    └── watermark_util.dart            # burn timestamp+koordinat ke foto

firestore.rules   # security rules Firestore
storage.rules     # security rules Storage
```

File paling penting buat dipahami dulu: **`location_service.dart`** (urutan
pengecekan keamanan) dan **`absen_camera_screen.dart`** (gimana semua service
itu dirangkai jadi satu flow).

## Langkah setup

1. **Buat project Firebase** di [console.firebase.google.com](https://console.firebase.google.com)
2. **Upgrade ke plan Blaze** (wajib buat Storage — lihat catatan di bawah)
3. **Aktifkan servis**: Authentication (Email/Password), Firestore, Storage
4. Install FlutterFire CLI, lalu jalankan di root project:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Ini bakal generate `lib/firebase_options.dart` otomatis. Setelah itu, di
   `main.dart`, uncomment baris `options: DefaultFirebaseOptions.currentPlatform`.
5. `flutter pub get`
6. Deploy security rules:
   ```
   firebase deploy --only firestore:rules,storage:rules
   ```
7. Buat dokumen `config/lokasi_pkl` manual dulu di Firestore console (nanti
   bisa dipindah ke screen admin):
   ```
   nama_instansi: "..."
   latitude: -0.xxxxx
   longitude: 117.xxxxx
   radius_meter: 100
   alamat: "..."
   ```
8. Buat akun user pertama (admin) lewat Firebase Auth console, lalu bikin
   dokumen matching-nya di `users/{uid}` dengan `role: "admin"`.

## Yang BELUM ada di skeleton ini (next steps)

Sengaja belum dibikin biar kita kerjain bertahap, bukan sekaligus:

- [ ] Screen admin buat CRUD data siswa + edit config lokasi PKL dari dalam app
- [ ] Setup Android (`AndroidManifest.xml` — permission kamera & lokasi) dan
      iOS (`Info.plist` — `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`)
- [ ] Cloud Function terjadwal buat auto-delete foto lama (retention policy
      yang kita bahas: simpan sampai selesai PKL + buffer 1-2 bulan)
- [ ] Export laporan absensi (misal ke Excel/PDF) buat keperluan penilaian sekolah
- [ ] Halaman lupa password
- [ ] Validasi/testing di device fisik Android DAN iOS (khususnya cek
      `isMocked` yang emang cuma efektif di Android)

## Catatan penting

- **Firebase Storage wajib plan Blaze** sejak Feb 2026 (lihat diskusi
  sebelumnya). Set budget alert di Google Cloud Console begitu upgrade,
  biar aman dari tagihan enggak terduga.
- Jangan lupa `flutter analyze` tiap habis nambah fitur baru sebelum lanjut
  ke bagian berikutnya — sesuai alur kerja bertahap yang udah kita sepakati.
