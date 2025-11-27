import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'Cesta.dart';
import 'models/producto.dart';

// Widget para cargar imágenes de manera insegura (acepta certificados self-signed)
class InsecureImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const InsecureImage({super.key, required this.url, this.fit = BoxFit.cover});

  Future<Uint8List?> _loadImage() async {
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    IOClient client = IOClient(httpClient);

    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("IMAGEN ERROR STATUS: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("IMAGEN ERROR: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Icon(Icons.error, color: Colors.red, size: 80);
        }
        try {
          return Image.memory(snapshot.data!, fit: fit, width: double.infinity);
        } catch (e) {
          print("ERROR DECODIFICANDO IMG: $e");
          return const Icon(Icons.broken_image, color: Colors.grey, size: 80);
        }
      },
    );

  }
}

// Pantalla de detalle del producto
class ProductoDetalle extends StatelessWidget {
  final Producto producto;

  const ProductoDetalle({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    // Construimos la URL dinámica usando el id del producto
    final String imageUrl = "https://185.189.221.84/images/${producto.id}.jpg";

    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            alignment: Alignment.center,
            child: InsecureImage(
              url: imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${producto.precio.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    producto.descripcion.isNotEmpty
                        ? producto.descripcion
                        : "Sin descripción disponible",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  CarritoPage.carrito.add({
                    "nombre": producto.nombre,
                    "precio": producto.precio,
                    "cantidad": 1,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Producto añadido al carrito correctamente")),
                  );
                },
                child: const Text("Añadir al Carrito"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}