import 'package:flutter/material.dart';
import '../models/absensi_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'absen_camera_screen.dart';
import 'riwayat_screen.dart';
import 'admin/dashboard_admin_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  const HomeScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Column(
          children: [
            // Top Green Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF00B074),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF00B074),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nama,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                user.isSiswa
                                    ? '${user.kelas} • ${user.sekolahAsal}'
                                    : 'Pembimbing / Admin',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await AuthService().logout();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content Menu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF064E3B),
                        ),
                      ),
                    ),
                    if (user.isSiswa) ...[
                      _KartuMenu(
                        icon: Icons.login_rounded,
                        iconBgColor: const Color(0xFF00B074),
                        label: 'Absen Masuk',
                        sublabel: 'Ambil foto & verifikasi lokasi absensi',
                        onTap: () => _bukaAbsen(context, JenisAbsensi.masuk),
                      ),
                      const SizedBox(height: 16),
                      _KartuMenu(
                        icon: Icons.history_rounded,
                        iconBgColor: const Color(0xFF059669),
                        label: 'Riwayat Absensi',
                        sublabel: 'Lihat catatan kehadiran Anda',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RiwayatScreen(uid: user.uid)),
                        ),
                      ),
                    ],
                    if (user.isAdmin || user.isPembimbing) ...[
                      const SizedBox(height: 16),
                      _KartuMenu(
                        icon: Icons.dashboard_rounded,
                        iconBgColor: const Color(0xFF047857),
                        label: 'Dashboard Absensi',
                        sublabel: 'Monitoring kehadiran siswa real-time',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardAdminScreen()),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bukaAbsen(BuildContext context, JenisAbsensi jenis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenCameraScreen(user: user, jenis: jenis),
      ),
    );
  }
}

class _KartuMenu extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _KartuMenu({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFA7F3D0), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: iconBgColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF00B074)),
            ],
          ),
        ),
      ),
    );
  }
}

