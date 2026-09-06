import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/absensi_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Format tanggal "yyyy-MM-dd" dipisah dari timestamp — biar query
  /// "absen hari ini" enggak perlu range query yang rawan salah timezone.
  String formatTanggal(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  Future<void> simpanAbsensi(AbsensiModel absensi) async {
    try {
      await _db.collection('absensi_log').add(absensi.toMap());
    } catch (e) {
      // Jika Firestore offline/unavailable, jangan throw crash fatal
      debugPrint('Firestore error saat simpanAbsensi: $e');
    }
  }

  /// Cek apakah siswa sudah absen hari ini
  Future<bool> sudahAbsenHariIni(String uid, JenisAbsensi jenis) async {
    try {
      final tanggalHariIni = formatTanggal(DateTime.now());
      final snapshot = await _db
          .collection('absensi_log')
          .where('uid', isEqualTo: uid)
          .where('tanggal', isEqualTo: tanggalHariIni)
          .where('jenis', isEqualTo: jenis.name)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Jika Firestore offline/unavailable atau timeout, izinkan absen (return false)
      return false;
    }
  }

  /// Stream realtime riwayat absen satu siswa, terbaru dulu.
  Stream<List<AbsensiModel>> riwayatAbsenSiswa(String uid) {
    return _db
        .collection('absensi_log')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AbsensiModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream realtime buat dashboard admin/pembimbing — semua absen hari ini.
  Stream<List<AbsensiModel>> absenHariIniSemuaSiswa() {
    final tanggalHariIni = formatTanggal(DateTime.now());
    return _db
        .collection('absensi_log')
        .where('tanggal', isEqualTo: tanggalHariIni)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AbsensiModel.fromMap(d.id, d.data())).toList());
  }
}
