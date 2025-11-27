import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';

import 'Cesta.dart';
import 'ProductosCategoria.dart';
import 'miCuenta.dart';
import 'models/categoria.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearching = false;
  String _searchText = '';

  late IOClient ioClient;

  List<Categoria> categorias = [];

  @override
  void initState() {
    super.initState();
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    ioClient = IOClient(httpClient);

    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    categorias = await traerCategorias(ioClient: ioClient);
    setState(() {});
  }

  Future<List<Categoria>> traerCategorias({required IOClient ioClient}) async {
    final res = await ioClient.get(
      Uri.parse("http://185.189.221.84/api.php/records/Categoria"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["records"] as List)
          .map((e) => Categoria.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  void dispose() {
    ioClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar categoría...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _searchText = value;
            setState(() {});
          },
        )
            : Text('Mi App', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchText = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => MiCuentaPage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => CarritoPage()));
            },
          ),
        ],
        leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
      ),

      body: categorias.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];

          if (_searchText.isNotEmpty &&
              !categoria.nombre
                  .toLowerCase()
                  .contains(_searchText.toLowerCase())) {
            return SizedBox.shrink();
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProductosCategoria(categoria: categoria),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      categoria.nombre,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Imagen de categoría
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    child: Image.network(
                      "https://185.189.221.84/images/categorias/c${categoria.id}.jpg",
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: Colors.black26,
                        child: Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
