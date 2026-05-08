import 'package:flutter/material.dart';
import 'map_page.dart'; // PERBAIKAN: Menggunakan relative import

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0), // Tambahan padding agar teks tidak menempel tepi layar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pilih Alamat:"),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapPage()
                          )
                        );
                        if (result != null) {
                          setState(() {
                            alamatDipilih = result;
                          });
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 16),
                // PERBAIKAN: Menghapus nested Row berlebihan dan menangani teks panjang
                alamatDipilih == null
                    ? const Text("Tidak ada alamat yang dipilih")
                    : Text(
                        alamatDipilih!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
              ],
            ),
          ),
        ),
      )
    );
  }
}