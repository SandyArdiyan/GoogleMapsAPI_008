import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _ctrl = Completer();
  Marker? _pickedMarker;
  String? _pickedAddress;
  String? _currentAddress;
  CameraPosition? _initialCamera;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    try {
      // Memanggil getPosition() untuk mendapatkan lokasi saat ini
      final pos = await getPosition(); 
      _currentPosition = pos;
      _initialCamera = CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 16,
      );

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final p = placemarks.first;
      _currentAddress = '${p.name}, ${p.locality}, ${p.country}';

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _initialCamera = const CameraPosition(target: LatLng(0,0), zoom: 2);
      if (mounted) {
        setState(() {});
        debugPrint(e.toString()); // Menggunakan debugPrint untuk menghindari avoid_print warning
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<Position> getPosition() async {
    // Cek apakah layanan lokasi aktif
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location services belum aktif';
    }

    // Cek izin lokasi
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw 'Izin lokasi ditolak';
      }
    }

    if (perm == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen, silakan aktifkan di pengaturan';
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _onTap(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );

    final p = placemarks.first;
    setState(() {
      _pickedMarker = Marker(
        markerId: const MarkerId('picked'),
        position: latlng,
        infoWindow: InfoWindow(
          title: (p.name == null || p.name!.isEmpty) ? 'Lokasi Dipilih' : p.name,
          snippet: '${p.street}, ${p.locality}',
        ),
      );
    });

    final ctrl = await _ctrl.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(latlng, 18));

    setState(() {
      _pickedAddress = '${p.name}, ${p.street}, ${p.locality}, ${p.country}, ${p.postalCode}';
    });
  }

  void _confirmSelection() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Alamat'),
        content: Text(_pickedAddress ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Menutup dialog
              Navigator.pop(context, _pickedAddress); // Kembali ke HomePage dengan data
            },
            child: const Text('Pilih'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Alamat'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCamera!,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomControlsEnabled: true,
              rotateGesturesEnabled: true,
              trafficEnabled: true,
              buildingsEnabled: true,
              indoorViewEnabled: true,
              onMapCreated: (GoogleMapController ctrl) {
                _ctrl.complete(ctrl);
              },
              markers: _pickedMarker != null ? {_pickedMarker!} : {},
              onTap: _onTap,
            ),
            // Penempatan alamat saat ini (Current Address)
            Positioned(
              top: 16,
              left: 16,
              right: 60, // Batas kanan agar tidak tertutup tombol MyLocation
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _currentAddress ?? 'Mencari lokasi...',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Penempatan alamat yang dipilih (Picked Address)
            if (_pickedAddress != null)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16, // Menghindari overflow teks panjang
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _pickedAddress!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end, // Rata kanan agar rapi
        children: [
          if (_pickedAddress != null)
            FloatingActionButton.extended(
              onPressed: _confirmSelection,
              heroTag: 'confirm',
              icon: const Icon(Icons.check),
              label: const Text('Pilih Alamat'),
            ),
          const SizedBox(height: 8),
          if (_pickedAddress != null)
            FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _pickedAddress = null;
                  _pickedMarker = null;
                });
              },
              heroTag: 'clear', 
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Alamat'), 
            ),
        ],
      ),
    );
  }
}