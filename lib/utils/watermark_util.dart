import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

/// Nambahin watermark timestamp + koordinat ke foto absen sebelum diupload.
/// Tujuannya biar foto enggak bisa dipakai ulang buat hari lain, dan jadi
/// bukti visual tambahan kalau ada dispute.
class WatermarkUtil {
  static Future<File> tambahWatermark({
    required File fotoAsli,
    required double lat,
    required double lng,
    required DateTime waktu,
  }) async {
    final bytes = await fotoAsli.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Gagal decode gambar untuk watermark.');
    }

    final formatWaktu = DateFormat('dd/MM/yyyy HH:mm:ss').format(waktu);
    final teks = '$formatWaktu\n'
        'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';

    // Background semi-transparan di bawah gambar biar teks tetap kebaca
    // di foto apapun warnanya.
    img.fillRect(
      image,
      x1: 0,
      y1: image.height - 70,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgba8(0, 0, 0, 140),
    );

    img.drawString(
      image,
      teks,
      font: img.arial24,
      x: 12,
      y: image.height - 60,
      color: img.ColorRgb8(255, 255, 255),
    );

    final path = '${fotoAsli.path}_watermarked.jpg';
    final fileHasil = File(path)..writeAsBytesSync(img.encodeJpg(image, quality: 90));
    return fileHasil;
  }
}
