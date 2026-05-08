import 'package:flutter/material.dart';
import 'package:gmaps/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? alamatDipilih;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pilih Alamat'),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapPage(),
                          ), // MaterialPageRoute
                        );
                        if (result != null) {
                          setState(() {
                            alamatDipilih = result;
                          });
                        }
                      },
                    ), // IconButton
                  ],
                ), // Row
                alamatDipilih == null
                    ? const Text('Tidak ada alamat yang dipilih')
                    : Text(alamatDipilih!),