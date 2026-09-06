import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _namaController = TextEditingController();
  final _sekolahController = TextEditingController();
  final _kelasController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();

  bool _loading = false;
  bool _passwordTerlihat = false;
  String? _error;

  Future<void> _daftar() async {
    if (_passwordController.text != _konfirmasiPasswordController.text) {
      setState(() => _error = 'Konfirmasi password tidak cocok.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    if (_namaController.text.trim().isEmpty) {
      setState(() => _error = 'Nama wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _authService.register(
        nama: _namaController.text.trim(),
        sekolahAsal: _sekolahController.text.trim(),
        kelas: _kelasController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } catch (e) {
      final pesan = e.toString().contains('email-already-in-use')
          ? 'Nama ini sudah terdaftar. Coba tambahkan nama tengah/inisial untuk membedakan, atau langsung login jika ini akunmu.'
          : 'Registrasi gagal: coba periksa kembali data yang diisi.';
      setState(() => _error = pesan);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: const Color(0xFF00B074),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Buat Akun Siswa PKL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF064E3B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Isi data diri Anda di bawah ini dengan benar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF047857)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                hintText: 'Nama Lengkap',
                helperText: 'Nama ini yang dipakai untuk login nanti',
                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF00B074)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _sekolahController,
              decoration: const InputDecoration(
                hintText: 'Asal Sekolah',
                prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF00B074)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _kelasController,
              decoration: const InputDecoration(
                hintText: 'Kelas',
                prefixIcon: Icon(Icons.class_outlined, color: Color(0xFF00B074)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordTerlihat,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00B074)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordTerlihat ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF00B074),
                  ),
                  onPressed: () => setState(() => _passwordTerlihat = !_passwordTerlihat),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _konfirmasiPasswordController,
              obscureText: !_passwordTerlihat,
              decoration: const InputDecoration(
                hintText: 'Konfirmasi Password',
                prefixIcon: Icon(Icons.lock_reset, color: Color(0xFF00B074)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _loading ? null : _daftar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00B074),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
