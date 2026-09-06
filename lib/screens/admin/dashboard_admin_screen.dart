import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/absensi_model.dart';
import '../../services/firestore_service.dart';

/// Dashboard sederhana buat admin/pembimbing pantau absen hari ini secara
/// realtime. Absen yang flag_anomali_kecepatan true otomatis kelihatan
/// sebagai "Perlu Review" dan perlu dicek manual — bukan auto-block.
class DashboardAdminScreen extends StatelessWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('Absensi Hari Ini'),
        backgroundColor: const Color(0xFF00B074),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AbsensiModel>>(
        stream: firestoreService.absenHariIniSemuaSiswa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00B074)));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada absen hari ini.',
                style: TextStyle(color: Color(0xFF047857), fontSize: 16),
              ),
            );
          }

          final perluReview =
              data.where((a) => a.status == StatusAbsensi.perluReview).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (perluReview.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(
                        '${perluReview.length} absen perlu direview manual',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ...data.map((absen) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF00B074),
                        backgroundImage: absen.fotoUrl.startsWith('http')
                            ? NetworkImage(absen.fotoUrl) as ImageProvider
                            : FileImage(File(absen.fotoUrl)),
                      ),
                      title: Text(
                        absen.namaSiswa,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                      ),
                      subtitle: Text(
                        'Absen Masuk — ${DateFormat('HH:mm').format(absen.timestamp)} — ${absen.jarakDariLokasi.round()}m',
                        style: const TextStyle(color: Color(0xFF047857)),
                      ),
                      trailing: absen.status == StatusAbsensi.perluReview
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : const Icon(Icons.check_circle, color: Color(0xFF00B074)),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
