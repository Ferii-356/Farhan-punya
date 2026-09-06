/// Merepresentasikan satu user (siswa, pembimbing, atau admin).
/// Field wajib disesuaikan dengan koleksi `users` di Firestore.
class UserModel {
  final String uid;
  final String nama;
  final String sekolahAsal;
  final String kelas;
  final String role; // "siswa" | "pembimbing" | "admin"
  final DateTime? tanggalMulaiPkl;
  final DateTime? tanggalSelesaiPkl;

  UserModel({
    required this.uid,
    required this.nama,
    required this.sekolahAsal,
    required this.kelas,
    required this.role,
    this.tanggalMulaiPkl,
    this.tanggalSelesaiPkl,
  });

  bool get isSiswa => role == 'siswa';
  bool get isPembimbing => role == 'pembimbing';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      nama: map['nama'] ?? '',
      sekolahAsal: map['sekolah_asal'] ?? '',
      kelas: map['kelas'] ?? '',
      role: map['role'] ?? 'siswa',
      tanggalMulaiPkl: map['tanggal_mulai_pkl']?.toDate(),
      tanggalSelesaiPkl: map['tanggal_selesai_pkl']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'sekolah_asal': sekolahAsal,
      'kelas': kelas,
      'role': role,
      'tanggal_mulai_pkl': tanggalMulaiPkl,
      'tanggal_selesai_pkl': tanggalSelesaiPkl,
    };
  }
}
