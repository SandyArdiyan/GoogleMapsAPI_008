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
      final pos = await _determinePosition(); 
      _currentPosition = pos;
      _initialCamera = CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 16,
      ); // CameraPosition

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final p = placemarks.first;
      _currentAddress = '${p.name}, ${p.locality}, ${p.country}';

      setState(() {

      });
    } catch (e) {
      _initialCamera = const CameraPosition(target: LatLng(0,0), zoom: 2);
      setState(() {
      });
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<Position> getPosition() async {
    //Check for Services
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location services belum aktif';
    }

    //Check For Permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw 'Izin lokasi ditolak';
      }
    }

    //Kembalikan nilai awal lokasi
    return Geolocator.getCurrentPosition();
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
          title: p.name?.isEmpty == true ? 'Lokasi Dipilih' : p.name,
          snippet: '${p.street}, ${p.locality}',
        ), // InfoWindow
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
          ), // TextButton
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Menutup dialog
              Navigator.pop(context, _pickedAddress); // Kembali ke halaman sebelumnya dengan membawa data
            },
            child: const Text('Pilih'),
          ), // ElevatedButton
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
        ), // Center
      ); // Scaffold
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Alamat'),
      ), // AppBar
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
            ), // GoogleMap
            Positioned(
              top: 250,
              left: 56,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ), // BoxShadow
                  ],
                ), // BoxDecoration
                child: Text(_currentAddress ?? 'Kosong'),
              ), // Container
            ), // Positioned
            if (_pickedAddress != null)
              Positioned(
                bottom: 120,
                left: 10,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _pickedAddress!,
                      style: const TextStyle(fontSize: 12),
                    ), // Text
                  ), // Padding
                ), // Card
              ), // Positioned
          ],
        ), // Stack
      ), // SafeArea
      floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (_pickedAddress != null)
                  FloatingActionButton.extended(
                    onPressed: _confirmSelection,
                    heroTag: 'confirm',
                    label: const Text('Pilih Alamat'),
                  ), // FloatingActionButton.extended
                const SizedBox(height: 8),
                if (_pickedAddress != null)
                  FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        _pickedAddress = null;
                        _pickedMarker = null;
                      });
                    },
                    // Bagian bawah ini terpotong di layar, jadi aku lengkapi ya:
                    heroTag: 'clear', 
                    label: const Text('Hapus Alamat'), 
                  ), // FloatingActionButton.extended
              ],
            ), // Column
          ); // Scaffold
  } // Penutup method build
} // Penutup class _MapPageState