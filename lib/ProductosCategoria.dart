import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';

import 'models/producto.dart';
import 'models/categoria.dart';
import 'productoDetalle.dart';
import 'miCuenta.dart';
import 'Cesta.dart';

class ProductosCategoria extends StatefulWidget {
  final Categoria categoria;

  const ProductosCategoria({super.key, required this.categoria});

  @override
  _ProductosCategoriaState createState() => _ProductosCategoriaState();
}

class _ProductosCategoriaState extends State<ProductosCategoria> {
  late IOClient ioClient;

  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];

  bool _isSearching = false;
  String _searchText = '';

  String selectedPriceFilter = 'Precio: Menor a Mayor';

  List<String> priceFilters = [
    'Precio: Menor a Mayor',
    'Precio: Mayor a Menor',
    'Más Populares',
    'Nuevos',
  ];

  @override
  void initState() {
    super.initState();

    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    ioClient = IOClient(httpClient);

    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final res = await ioClient.get(Uri.parse(
        "http://185.189.221.84/api.php/records/Producto?filter=id_categoria,eq,${widget.categoria.id}"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      productos = (data["records"] as List)
          .map((e) => Producto.fromJson(e))
          .toList();

      _aplicarFiltros();
    }
  }

  void _aplicarFiltros() {
    List<Producto> result = List.from(productos);

    if (_searchText.isNotEmpty) {
      result = result
          .where((p) =>
          p.nombre.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }

    switch (selectedPriceFilter) {
      case 'Precio: Menor a Mayor':
        result.sort((a, b) => a.precio.compareTo(b.precio));
        break;

      case 'Precio: Mayor a Menor':
        result.sort((a, b) => b.precio.compareTo(a.precio));
        break;

      case 'Más Populares':
        result.sort((a, b) => b.id.compareTo(a.id));
        break;

      case 'Nuevos':
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    productosFiltrados = result;
    setState(() {});
  }

  @override
  void dispose() {
    ioClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3ECF8),
      appBar: AppBar(
        backgroundColor: Color(0xFF00122B),
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar producto...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _searchText = value;
            _aplicarFiltros();
          },
        )
            : Text(
          widget.categoria.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchText = '';
                  _aplicarFiltros();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => MiCuentaPage()))),
          IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => CarritoPage()))),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedPriceFilter,
              items: priceFilters
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) {
                selectedPriceFilter = value!;
                _aplicarFiltros();
              },
            ),
          ),

          Expanded(
            child: productosFiltrados.isEmpty
                ? const Center(child: Text("No hay productos"))
                : ListView.builder(
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final p = productosFiltrados[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductoDetalle(producto: p),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 📸 Imagen grande
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            "https://185.189.221.84/images/${p.id}.jpg",
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 60),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // 📝 Nombre + precio
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "${p.precio.toStringAsFixed(2)} €",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
