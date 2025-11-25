import 'dart:convert';
import 'dart:io';
import 'package:TFGPruebas/productoDetalle.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'Cesta.dart';
import 'miCuenta.dart';
import 'models/producto.dart';
import 'models/categoria.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearching = false;
  String _searchText = '';

  String selectedPriceFilter = 'Precio: Menor a Mayor';
  String? selectedCategoriaFilter;

  List<String> priceFilters = [
    'Precio: Menor a Mayor',
    'Precio: Mayor a Menor',
    'Más Populares',
    'Nuevos',
  ];

  late IOClient ioClient;

  List<Producto> allProductos = [];
  List<Producto> displayedProductos = [];
  int page = 0;
  final int pageSize = 10;

  List<Categoria> categorias = [];

  @override
  void initState() {
    super.initState();
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    ioClient = IOClient(httpClient);

    _cargarCategoriasYProductos();
  }

  Future<void> _cargarCategoriasYProductos() async {
    categorias = await traerCategorias(ioClient: ioClient);
    allProductos = await traerProductos(ioClient: ioClient); // todos los productos
    _aplicarFiltrosYPaginacion();
  }

  void _aplicarFiltrosYPaginacion() {
    List<Producto> filtered = List.from(allProductos);

    // Filtro por búsqueda
    if (_searchText.isNotEmpty) {
      filtered = filtered
          .where((p) =>
          p.nombre.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }

    // Filtro por categoría
    if (selectedCategoriaFilter != null && selectedCategoriaFilter!.isNotEmpty) {
      filtered = filtered
          .where((p) =>
      categorias
          .firstWhere((c) => c.nombre == selectedCategoriaFilter)
          .id ==
          p.idCategoria)
          .toList();
    }

    // Orden por precio u otros filtros
    switch (selectedPriceFilter) {
      case 'Precio: Menor a Mayor':
        filtered.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case 'Precio: Mayor a Menor':
        filtered.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case 'Más Populares':
        filtered.sort((a, b) => b.id.compareTo(a.id)); //Quitar o revisar
        break;
      case 'Nuevos':
        filtered.sort((a, b) => b.id.compareTo(a.id)); //Quitar o revisar
        break;
    }

    // Paginación
    int start = page * pageSize;
    int end = start + pageSize;
    if (start > filtered.length) start = filtered.length;
    if (end > filtered.length) end = filtered.length;
    displayedProductos = filtered.sublist(0, end);

    setState(() {});
  }

  Future<List<Categoria>> traerCategorias({required IOClient ioClient}) async {
    final res =
    await ioClient.get(Uri.parse("http://185.189.221.84/api.php/records/Categoria"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["records"] as List)
          .map((e) => Categoria.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<Producto>> traerProductos({required IOClient ioClient}) async {
    final res =
    await ioClient.get(Uri.parse("http://185.189.221.84/api.php/records/Producto"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["records"] as List)
          .map((e) => Producto.fromJson(e))
          .toList();
    }
    return [];
  }

  void _mostrarMas() {
    page++;
    _aplicarFiltrosYPaginacion();
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
            page = 0;
            _aplicarFiltrosYPaginacion();
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
                  page = 0;
                  _aplicarFiltrosYPaginacion();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(icon: Icon(Icons.person), onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => MiCuentaPage()),);}),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CarritoPage()),
              );
            },
          ),
        ],
        leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
      ),
      body: Column(
        children: [
          // Filtros de precio y categoría
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedPriceFilter,
                    isExpanded: true,
                    items: priceFilters
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      selectedPriceFilter = value!;
                      page = 0;
                      _aplicarFiltrosYPaginacion();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCategoriaFilter,
                    hint: Text("Seleccionar categoría"),
                    isExpanded: true,
                    items: categorias
                        .map((c) =>
                        DropdownMenuItem(value: c.nombre, child: Text(c.nombre)))
                        .toList(),
                    onChanged: (value) {
                      selectedCategoriaFilter = value;
                      page = 0;
                      _aplicarFiltrosYPaginacion();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: displayedProductos.isEmpty
                ? Center(child: Text("No hay productos disponibles"))
                : ListView.builder(
              itemCount: displayedProductos.length + 1,
              itemBuilder: (context, index) {
                if (index == displayedProductos.length) {
                  // Botón mostrar más
                  if (displayedProductos.length < allProductos.length) {
                    return TextButton(
                      onPressed: _mostrarMas,
                      child: Text("Mostrar más"),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }

                final producto = displayedProductos[index];
                return ListTile(
                  title: Text(producto.nombre),
                  subtitle: Text("${producto.precio.toStringAsFixed(2)} €"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductoDetalle(producto: producto),
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
