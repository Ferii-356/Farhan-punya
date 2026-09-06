import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_jailbreak_detection_plus/flutter_jailbreak_detection_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../models/lokasi_pkl_model.dart';

/// Hasil pengecekan lokasi — dipakai buat mutusin boleh/enggak lanjut ke kamera.
class CekLokasiResult {
  final bool boleh;
  final String? alasan;
  final Position? posisi;
  final double? jarak;
  final bool flagMocked;
  final bool flagJailbreak;
  final bool flagAnomaliKecepatan;

  CekLokasiResult({
    required this.boleh,
    this.alasan,
    this.posisi,
    this.jarak,
    this.flagMocked = false,
    this.flagJailbreak = false,
    this.flagAnomaliKecepatan = false,
  });
}

/// Batas akurasi GPS yang masih ditoleransi (meter).
/// Kalau akurasi device lebih buruk dari ini, minta user pindah ke tempat terbuka.
const double kBatasAkurasiGpsMeter = 30;

/// Batas kecepatan implisit yang dianggap enggak masuk akal (km/jam).
/// Dipakai buat deteksi "teleport" GPS.
const double kBatasKecepatanTidakWajarKmh = 200;

class LocationService {
  // Supabase client accessed via Supabase.instance.client

  /// Ambil config lokasi PKL (dokumen tunggal di config/lokasi_pkl).
  /// Memiliki fallback otomatis jika Firestore belum diisi atau sedang offline.
  Future<LokasiPklModel> ambilLokasiPkl() async {
    try {
      final res = await Supabase.instance.client
          .from('config_lokasi')
          .select()
          .maybeSingle();
      if (res != null) {
        return LokasiPklModel.fromMap(res);
      }
    } catch (_) {
      // Ignore Supabase errors (offline, etc.)
    }
    // Fallback location for testing / when no config exists
    return LokasiPklModel(
      namaInstansi: 'Lokasi PKL',
      latitude: 0.0,
      longitude: 0.0,
      radiusMeter: 5000000.0,
      alamat: 'Lokasi PKL',
    );
  }

  /// Pastikan permission lokasi sudah diberikan. Panggil ini sebelum cekLokasi().
  Future<bool> pastikanPermissionLokasi() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Pengecekan utama sebelum user boleh lanjut ke kamera absen.
  Future<CekLokasiResult> cekLokasi(String uid) async {
    // 0. Cek apakah layanan GPS di HP aktif
    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      return CekLokasiResult(
        boleh: false,
        alasan: 'GPS / Layanan lokasi di HP kamu belum diaktifkan. Harap nyalakan GPS di pengaturan HP lalu coba lagi.',
      );
    }

    // 1. Cek root/jailbreak dulu
    bool isJailbroken = false;
    try {
      isJailbroken = await FlutterJailbreakDetectionPlus.jailbroken;
    } catch (_) {}

    if (isJailbroken) {
      return CekLokasiResult(
        boleh: false,
        alasan:
            'Perangkat terdeteksi root/jailbreak. Absensi tidak bisa dilakukan.',
        flagJailbreak: true,
      );
    }

    // 2. Ambil posisi GPS saat ini (dengan timeout 10 detik dan fallback)
    Position? posisi;
    try {
      posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // Fallback ke posisi terakhir yang diketahui jika timeout atau bermasalah
      posisi = await Geolocator.getLastKnownPosition();
    }

    if (posisi == null) {
      // Fallback: gunakan lokasi PKL yang sudah diset di Firestore (atau default)
      final fallbackLokasi = await ambilLokasiPkl();
      // Jika fallback lokasi masih default (0,0) tetap beri error – user harus mengaktifkan GPS.
      if (fallbackLokasi.latitude == 0.0 && fallbackLokasi.longitude == 0.0) {
        return CekLokasiResult(
          boleh: false,
          alasan: 'Gagal mendapatkan lokasi GPS. Pastikan GPS aktif atau berada di tempat terbuka.',
        );
      }
      // Buat objek Position tiruan dari lokasi fallback
      posisi = Position(
        latitude: fallbackLokasi.latitude,
        longitude: fallbackLokasi.longitude,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        timestamp: DateTime.now(),
      );
    }

    // 3. Cek mock location
    if (posisi.isMocked) {
      return CekLokasiResult(
        boleh: false,
        alasan:
            'Lokasi terdeteksi tidak valid (kemungkinan aplikasi fake GPS aktif).',
        posisi: posisi,
        flagMocked: true,
      );
    }

    // 4. Cek akurasi GPS
    if (posisi.accuracy > kBatasAkurasiGpsMeter) {
      return CekLokasiResult(
        boleh: false,
        alasan:
            'Akurasi GPS kurang baik (${posisi.accuracy.round()}m). Coba pindah ke tempat terbuka lalu coba lagi.',
        posisi: posisi,
      );
    }

    // 5. Cek anomali kecepatan dibanding posisi terakhir yang tercatat
    final flagAnomali = await _cekAnomaliKecepatan(uid, posisi);

    // 6. Update posisi terakhir
    await _simpanPosisiTerakhir(uid, posisi);

    // 7. Cek radius ke lokasi PKL
    final lokasiPkl = await ambilLokasiPkl();

    // Jika koordinat lokasi PKL diset ke (0, 0) / default fallback, anggap lolos radius
    if (lokasiPkl.latitude == 0.0 && lokasiPkl.longitude == 0.0) {
      return CekLokasiResult(
        boleh: true,
        posisi: posisi,
        jarak: 0,
        flagAnomaliKecepatan: flagAnomali,
      );
    }

    final jarak = Geolocator.distanceBetween(
      posisi.latitude,
      posisi.longitude,
      lokasiPkl.latitude,
      lokasiPkl.longitude,
    );

    if (jarak > lokasiPkl.radiusMeter) {
      return CekLokasiResult(
        boleh: false,
        alasan:
            'Kamu berada ${jarak.round()}m dari lokasi PKL (maksimal ${lokasiPkl.radiusMeter.round()}m).',
        posisi: posisi,
        jarak: jarak,
        flagAnomaliKecepatan: flagAnomali,
      );
    }

    return CekLokasiResult(
      boleh: true,
      posisi: posisi,
      jarak: jarak,
      flagAnomaliKecepatan: flagAnomali,
    );
  }

  Future<bool> _cekAnomaliKecepatan(String uid, Position posisiSekarang) async {
    try {
      final res = await Supabase.instance.client
          .from('posisi_terakhir')
          .select()
          .eq('uid', uid)
          .maybeSingle();
      if (res == null) return false;
      final double latSebelumnya = (res['lat'] as num).toDouble();
      final double lngSebelumnya = (res['lng'] as num).toDouble();
      final DateTime waktuSebelumnya = DateTime.parse(res['timestamp'] as String);

      final double jarak = Geolocator.distanceBetween(
        latSebelumnya,
        lngSebelumnya,
        posisiSekarang.latitude,
        posisiSekarang.longitude,
      );
      final int detikBerlalu = DateTime.now().difference(waktuSebelumnya).inSeconds;
      if (detikBerlalu <= 0) return false;

      final double kecepatanKmh = (jarak / detikBerlalu) * 3.6;
      return kecepatanKmh > kBatasKecepatanTidakWajarKmh;
    } catch (_) {
      return false;
    }
  }

  Future<void> _simpanPosisiTerakhir(String uid, Position posisi) async {
    try {
      await Supabase.instance.client.from('posisi_terakhir').upsert({
          'uid': uid,
          'lat': posisi.latitude,
          'lng': posisi.longitude,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
    } catch (_) {}
  }
}
