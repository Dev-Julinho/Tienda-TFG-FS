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

    // 🔍 filtro búsqueda
    if (_searchText.isNotEmpty) {
      result = result
          .where((p) =>
          p.nombre.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }

    // 🔧 ordenamiento
    switch (selectedPriceFilter) {
      case 'Precio: Menor a Mayor':
        result.sort((a, b) => a.precio.compareTo(b.precio));
        break;

      case 'Precio: Mayor a Menor':
        result.sort((a, b) => b.precio.compareTo(a.precio));
        break;

      case 'Más Populares':
        result.sort((a, b) => b.id.compareTo(a.id)); // ajustar si tienes campo popularidad
        break;

      case 'Nuevos':
        result.sort((a, b) => b.id.compareTo(a.id)); // mismo criterio
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
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar producto...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _searchText = value;
            _aplicarFiltros();
          },
        )
            : Text(widget.categoria.nombre,
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
              icon: Icon(Icons.person),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => MiCuentaPage()))),
          IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => CarritoPage()))),
        ],
      ),

      body: Column(
        children: [
          // 🔽 Dropdown filtros
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

          // 📦 Lista de productos
          Expanded(
            child: productosFiltrados.isEmpty
                ? Center(child: Text("No hay productos"))
                : ListView.builder(
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final p = productosFiltrados[index];

                return ListTile(
                  leading: Image.network(
                    "https://185.189.221.84/images/${p.id}.jpg",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.broken_image),
                  ),
                  title: Text(p.nombre),
                  subtitle: Text("${p.precio.toStringAsFixed(2)} €"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductoDetalle(producto: p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
