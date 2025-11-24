import 'package:latlong2/latlong.dart';

class CatatanModel {
  final LatLng position;
  final String note;
  final String address;
  String jenis;

  CatatanModel({required this.position, required this.note, required this.address, required this.jenis});

  Map<String, dynamic> toMap() => {'lat': position.latitude, 'lng': position.longitude, 'note': note, 'address': address, 'jenis': jenis};

  factory CatatanModel.fromMap(Map<String, dynamic> map) => CatatanModel(position: LatLng(map['lat'], map['lng']), note: map['note'], address: map['address'], jenis: map['jenis']);
}
