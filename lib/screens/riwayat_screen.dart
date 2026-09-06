import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/absensi_model.dart';
import '../services/firestore_service.dart';

class RiwayatScreen extends StatelessWidget {
  final String uid;
  const RiwayatScreen({required this.uid, super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: const Color(0xFF00B074),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AbsensiModel>>(
        stream: firestoreService.riwayatAbsenSiswa(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00B074)));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat absensi.',
                style: TextStyle(color: Color(0xFF047857), fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final absen = data[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _warnaStatus(absen.status),
                    child: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Absen Masuk — ${_labelStatus(absen.status)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(absen.timestamp),
                    style: const TextStyle(color: Color(0xFF047857)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${absen.jarakDariLokasi.round()}m',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B074),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _warnaStatus(StatusAbsensi status) {
    switch (status) {
      case StatusAbsensi.hadir:
        return Colors.green;
      case StatusAbsensi.perluReview:
        return Colors.orange;
      case StatusAbsensi.ditolakLokasi:
        return Colors.red;
    }
  }

  String _labelStatus(StatusAbsensi status) {
    switch (status) {
      case StatusAbsensi.hadir:
        return 'Hadir';
      case StatusAbsensi.perluReview:
        return 'Perlu Review';
      case StatusAbsensi.ditolakLokasi:
        return 'Ditolak';
    }
  }
}
