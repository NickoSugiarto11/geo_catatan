import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catatan_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MapScreen());
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<CatatanModel> _savedNotes = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1. LOAD SAVE DATA
  Future<void> _loadData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? raw = pref.getString('notes');

    if (raw != null) {
      List list = jsonDecode(raw);
      setState(() {
        _savedNotes.clear();
        _savedNotes.addAll(list.map((e) => CatatanModel.fromMap(e)));
      });
    }
  }

  // 2. SAVE DATA
  Future<void> _saveData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('notes', jsonEncode(_savedNotes.map((e) => e.toMap()).toList()));
  }

  // Fitur Lokasi
  Future<void> _findMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _mapController.move(latlong.LatLng(position.latitude, position.longitude), 15.0);
  }

  // LONG PRESS UNTUK MENAMBAH CATATAN
  void _handleLongPress(TapPosition _, latlong.LatLng point) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);

    String address = placemarks.first.street ?? "Alamat tidak dikenali";

    // Tampilkan dialog memilih jenis
    String? jenisDipilih = await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Pilih Jenis Catatan"),
          children: [
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Rumah"), child: const Text("Rumah")),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Toko"), child: const Text("Toko")),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, "Kantor"), child: const Text("Kantor")),
          ],
        );
      },
    );

    if (jenisDipilih == null) return;

    setState(() {
      _savedNotes.add(CatatanModel(position: point, note: "Catatan Baru", address: address, jenis: jenisDipilih));
    });

    _saveData();
  }

  // ICON MARKER BERDASARKAN JENIS
  Icon _getMarkerIcon(String jenis) {
    switch (jenis) {
      case "Rumah":
        return const Icon(Icons.home, color: Colors.blue, size: 40);
      case "Toko":
        return const Icon(Icons.store, color: Colors.green, size: 40);
      case "Kantor":
        return const Icon(Icons.apartment, color: Colors.orange, size: 40);
      default:
        return const Icon(Icons.location_on, color: Colors.red, size: 40);
    }
  }

  // HAPUS MARKER
  void _hapusMarker(int index) {
    setState(() {
      _savedNotes.removeAt(index);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geo-Catatan")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: const latlong.LatLng(-6.2, 106.8), initialZoom: 13.0, onLongPress: _handleLongPress),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

          // MARKER LAYER
          MarkerLayer(
            markers: List.generate(_savedNotes.length, (i) {
              final n = _savedNotes[i];
              return Marker(
                point: n.position,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => ListTile(
                        title: Text(n.address),
                        subtitle: Text("${n.jenis} • ${n.note}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _hapusMarker(i);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  child: _getMarkerIcon(n.jenis),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _findMyLocation, child: const Icon(Icons.my_location)),
    );
  }
}
