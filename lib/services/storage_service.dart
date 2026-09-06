import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import '../utils/watermark_util.dart';

class StorageService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Compress foto sebelum diupload. Foto absen tidak butuh resolusi tinggi,
  /// jadi ini nurunin ukuran drastis (biasanya dari beberapa MB jadi ~150-250KB)
  /// tanpa bikin fotonya jadi tidak kelihatan. Ini langkah paling ngaruh buat
  /// hemat kuota Storage.
  Future<File> _compress(File foto) async {
    final hasil = await FlutterImageCompress.compressAndGetFile(
      foto.path,
      '${foto.path}_compressed.jpg',
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
    );
    return File(hasil!.path);
  }

  /// Alur lengkap: compress -> watermark -> upload ke Supabase Storage.
  /// Return-nya URL publik foto yang disimpan ke Cloud Firestore.
  Future<String> prosesDanUploadFoto({
    required File fotoAsli,
    required String uid,
    required double lat,
    required double lng,
  }) async {
    final waktu = DateTime.now();

    final fotoCompressed = await _compress(fotoAsli);
    final fotoWatermarked = await WatermarkUtil.tambahWatermark(
      fotoAsli: fotoCompressed,
      lat: lat,
      lng: lng,
      waktu: waktu,
    );

    // Jika kStorageAktif false atau URL/Key Supabase belum diisi dengan benar, simpan ke lokal
    final bool supabaseValid = kStorageAktif &&
        kSupabaseUrl.startsWith('https://') &&
        !kSupabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');

    if (!supabaseValid) {
      final dirDokumen = await getApplicationDocumentsDirectory();
      final namaFileLokal = '${uid}_${waktu.millisecondsSinceEpoch}.jpg';
      final tujuanLokal = '${dirDokumen.path}/$namaFileLokal';
      final fotoTersimpan = await fotoWatermarked.copy(tujuanLokal);

      try {
        await fotoCompressed.delete();
        await fotoWatermarked.delete();
      } catch (_) {}

      return fotoTersimpan.path;
    }

    final pathFile = '$uid/${waktu.millisecondsSinceEpoch}.jpg';

    // Upload file ke Supabase Storage Bucket
    await _supabase.storage.from(kSupabaseBucketFoto).upload(
          pathFile,
          fotoWatermarked,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    // Ambil Public URL gambar dari Supabase
    final url = _supabase.storage.from(kSupabaseBucketFoto).getPublicUrl(pathFile);

    // Bersihkan file temp lokal setelah upload sukses
    try {
      await fotoCompressed.delete();
      await fotoWatermarked.delete();
    } catch (_) {}

    return url;
  }
}

