import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusAbsensi { hadir, ditolakLokasi, perluReview }
enum JenisAbsensi { masuk, pulang }

class AbsensiModel {
  final String? id;
  final String uid;
  final String namaSiswa;
  final DateTime timestamp;
  final String tanggal; // format "yyyy-MM-dd" — lihat catatan desain di lib/utils
  final JenisAbsensi jenis;
  final String fotoUrl;
  final double lat;
  final double lng;
  final double jarakDariLokasi;
  final double akurasiGps;
  final StatusAbsensi status;
  final bool flagMocked;
  final bool flagJailbreak;
  final bool flagAnomaliKecepatan;
  final String? catatanAdmin;

  AbsensiModel({
    this.id,
    required this.uid,
    required this.namaSiswa,
    required this.timestamp,
    required this.tanggal,
    required this.jenis,
    required this.fotoUrl,
    required this.lat,
    required this.lng,
    required this.jarakDariLokasi,
    required this.akurasiGps,
    required this.status,
    this.flagMocked = false,
    this.flagJailbreak = false,
    this.flagAnomaliKecepatan = false,
    this.catatanAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama_siswa': namaSiswa,
      'timestamp': Timestamp.fromDate(timestamp),
      'tanggal': tanggal,
      'jenis': jenis.name,
      'foto_url': fotoUrl,
      'lat': lat,
      'lng': lng,
      'jarak_dari_lokasi': jarakDariLokasi,
      'akurasi_gps': akurasiGps,
      'status': status.name,
      'flag_mocked': flagMocked,
      'flag_jailbreak': flagJailbreak,
      'flag_anomali_kecepatan': flagAnomaliKecepatan,
      'catatan_admin': catatanAdmin,
    };
  }

  factory AbsensiModel.fromMap(String id, Map<String, dynamic> map) {
    return AbsensiModel(
      id: id,
      uid: map['uid'],
      namaSiswa: map['nama_siswa'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      tanggal: map['tanggal'],
      jenis: JenisAbsensi.values.firstWhere((e) => e.name == map['jenis']),
      fotoUrl: map['foto_url'],
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      jarakDariLokasi: (map['jarak_dari_lokasi'] as num).toDouble(),
      akurasiGps: (map['akurasi_gps'] as num).toDouble(),
      status: StatusAbsensi.values.firstWhere((e) => e.name == map['status']),
      flagMocked: map['flag_mocked'] ?? false,
      flagJailbreak: map['flag_jailbreak'] ?? false,
      flagAnomaliKecepatan: map['flag_anomali_kecepatan'] ?? false,
      catatanAdmin: map['catatan_admin'],
    );
  }
}
