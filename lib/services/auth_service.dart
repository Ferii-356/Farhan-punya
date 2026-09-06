import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Firebase Auth butuh format email di baliknya, jadi "Nama" dibungkus
  /// jadi email palsu di belakang layar -- siswa/guru enggak pernah lihat
  /// atau ngetik email ini secara langsung.
  ///
  /// PENTING: karena ini pakai NAMA (bukan NISN yang dijamin unik), kalau
  /// ada dua siswa daftar dengan nama yang PERSIS SAMA (termasuk spasi dan
  /// huruf besar/kecil), Firebase otomatis MENOLAK pendaftaran yang kedua
  /// (error "email-already-in-use"). Siswa itu perlu daftar pakai variasi
  /// nama sedikit berbeda (misal tambah nama tengah). Ini bukan bug --
  /// ini proteksi supaya dua siswa enggak ke-mix jadi satu akun.
  String _emailDariNama(String nama) {
    final dinormalisasi =
        nama.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return '$dinormalisasi@pklapp.local';
  }

  Future<UserModel> login(String nama, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: _emailDariNama(nama),
      password: password,
    );
    return await ambilDataUser(cred.user!.uid);
  }

  /// Registrasi siswa baru.
  Future<UserModel> register({
    required String nama,
    required String sekolahAsal,
    required String kelas,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _emailDariNama(nama),
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      nama: nama,
      sekolahAsal: sekolahAsal,
      kelas: kelas,
      role: 'siswa',
    );

    await _db.collection('users').doc(cred.user!.uid).set(user.toMap());
    return user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel> ambilDataUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Data user tidak ditemukan di database.');
    }
    return UserModel.fromMap(uid, doc.data()!);
  }
}
