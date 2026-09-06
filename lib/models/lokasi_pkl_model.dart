/// Merepresentasikan dokumen config/lokasi_pkl (single document).
/// Ini titik referensi geofencing — hanya ada satu karena cuma 1 lokasi PKL.
class LokasiPklModel {
  final String namaInstansi;
  final double latitude;
  final double longitude;
  final double radiusMeter;
  final String alamat;

  LokasiPklModel({
    required this.namaInstansi,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
    required this.alamat,
  });

  factory LokasiPklModel.fromMap(Map<String, dynamic> map) {
    return LokasiPklModel(
      namaInstansi: map['nama_instansi'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeter: (map['radius_meter'] as num).toDouble(),
      alamat: map['alamat'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_instansi': namaInstansi,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radiusMeter,
      'alamat': alamat,
      'updated_at': DateTime.now(),
    };
  }
}
