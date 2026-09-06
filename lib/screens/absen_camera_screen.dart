import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/absensi_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/loading_widget.dart';

/// Screen ini punya 3 tahap yang jelas:
///  1. cekLokasi()      -> tombol kamera cuma nongol kalau lolos semua syarat
///  2. _ambilFoto()     -> kamera custom, TIDAK ada opsi pilih dari galeri
///  3. _prosesAbsen()   -> compress + watermark + upload + simpan ke Firestore
///
/// Penting: pengecekan lokasi dilakukan ULANG persis sebelum simpan absen,
/// bukan cuma sekali di awal. Ini mencegah celah "cek lokasi dulu di dalam
/// radius, jalan keluar radius, baru submit".
class AbsenCameraScreen extends StatefulWidget {
  final UserModel user;
  final JenisAbsensi jenis;

  const AbsenCameraScreen({required this.user, required this.jenis, super.key});

  @override
  State<AbsenCameraScreen> createState() => _AbsenCameraScreenState();
}

class _AbsenCameraScreenState extends State<AbsenCameraScreen> {
  final _locationService = LocationService();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();

  CameraController? _cameraController;
  bool _loading = true;
  bool _memproses = false;
  String? _pesanError;
  String _statusLoading = 'Memeriksa lokasi & kamera...';
  CekLokasiResult? _hasilCekLokasi;

  @override
  void initState() {
    super.initState();
    _mulaiCekLokasi();
  }

  Future<void> _mulaiCekLokasi() async {
    setState(() {
      _loading = true;
      _pesanError = null;
      _statusLoading = 'Memeriksa riwayat absensi...';
    });

    try {
      // 1. Cek apakah sudah absen hari ini
      final sudahAbsen =
          await _firestoreService.sudahAbsenHariIni(widget.user.uid, widget.jenis);
      if (sudahAbsen) {
        if (mounted) {
          setState(() {
            _loading = false;
            _pesanError = 'Kamu sudah melakukan absen masuk hari ini.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _statusLoading = 'Memeriksa izin lokasi & GPS...');
      }

      // 2. Pastikan permission lokasi ok
      final permissionOk = await _locationService.pastikanPermissionLokasi();
      if (!permissionOk) {
        if (mounted) {
          setState(() {
            _loading = false;
            _pesanError = 'Izin lokasi diperlukan untuk melakukan absensi. Harap aktifkan izin lokasi di pengaturan HP Anda.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _statusLoading = 'Mendapatkan lokasi GPS Anda...');
      }

      // 3. Cek lokasi (GPS active, accuracy, radius, mock location)
      final hasil = await _locationService.cekLokasi(widget.user.uid);
      if (!hasil.boleh) {
        if (mounted) {
          setState(() {
            _hasilCekLokasi = hasil;
            _loading = false;
            _pesanError = hasil.alasan ?? 'Gagal memverifikasi lokasi.';
          });
        }
        return;
      }

      _hasilCekLokasi = hasil;

      if (mounted) {
        setState(() => _statusLoading = 'Membuka kamera HP...');
      }

      // 4. Inisialisasi kamera jika lolos syarat lokasi
      await _siapkanKamera();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _pesanError = 'Gagal memproses absensi: $e';
        });
      }
    }
  }

  Future<void> _siapkanKamera() async {
    try {
      final kameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Kamera HP lambat merespons.'),
      );
      if (kameras.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _pesanError = 'Kamera tidak ditemukan pada perangkat ini.';
          });
        }
        return;
      }
      final kameraDepan = kameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => kameras.first,
      );

      _cameraController = CameraController(
        kameraDepan,
        ResolutionPreset.medium,
        enableAudio: false, // Menghindari permintaan izin mikrofon yang bisa membekukan kamera
      );

      await _cameraController!.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Inisialisasi kamera mengalami timeout.'),
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _pesanError = 'Gagal membuka kamera: $e. Pastikan izin kamera sudah diberikan di pengaturan HP.';
        });
      }
    }
  }

  Future<void> _ambilFotoDanProses() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() => _memproses = true);

    try {
      // Cek ulang lokasi TEPAT sebelum submit — mencegah celah timing.
      final hasilCekUlang = await _locationService.cekLokasi(widget.user.uid);
      if (!hasilCekUlang.boleh) {
        setState(() {
          _memproses = false;
          _pesanError = hasilCekUlang.alasan;
          _hasilCekLokasi = hasilCekUlang;
        });
        return;
      }

      final xFile = await _cameraController!.takePicture();
      final fotoUrl = await _storageService.prosesDanUploadFoto(
        fotoAsli: File(xFile.path),
        uid: widget.user.uid,
        lat: hasilCekUlang.posisi!.latitude,
        lng: hasilCekUlang.posisi!.longitude,
      );

      final adaFlagMencurigakan = hasilCekUlang.flagAnomaliKecepatan;

      final absensi = AbsensiModel(
        uid: widget.user.uid,
        namaSiswa: widget.user.nama,
        timestamp: DateTime.now(),
        tanggal: _firestoreService.formatTanggal(DateTime.now()),
        jenis: widget.jenis,
        fotoUrl: fotoUrl,
        lat: hasilCekUlang.posisi!.latitude,
        lng: hasilCekUlang.posisi!.longitude,
        jarakDariLokasi: hasilCekUlang.jarak ?? 0,
        akurasiGps: hasilCekUlang.posisi!.accuracy,
        status: adaFlagMencurigakan
            ? StatusAbsensi.perluReview
            : StatusAbsensi.hadir,
        flagAnomaliKecepatan: adaFlagMencurigakan,
      );

      await _firestoreService.simpanAbsensi(absensi);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adaFlagMencurigakan
              ? 'Absen tersimpan, menunggu review pembimbing.'
              : 'Absen masuk berhasil!'),
        ),
      );
    } catch (e) {
      setState(() {
        _memproses = false;
        _pesanError = 'Gagal memproses absen: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('Absen Masuk'),
        backgroundColor: const Color(0xFF00B074),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_loading)
            _tampilanLoading()
          else if (_pesanError != null && (_hasilCekLokasi?.boleh != true))
            _tampilanError()
          else if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            _tampilanKamera()
          else
            _tampilanLoading(),
          if (_memproses) const LoadingOverlay(pesan: 'Menyimpan absen...'),
        ],
      ),
    );
  }

  Widget _tampilanLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00B074)),
          const SizedBox(height: 16),
          Text(
            _statusLoading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF064E3B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tampilanError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 48, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                _pesanError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _mulaiCekLokasi,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00B074),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Coba Lagi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tampilanKamera() {
    return Column(
      children: [
        Expanded(child: CameraPreview(_cameraController!)),
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.black,
          child: SafeArea(
            top: false,
            child: Center(
              child: GestureDetector(
                onTap: _memproses ? null : _ambilFotoDanProses,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
