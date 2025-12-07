import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as ioClient;
import 'models/producto.dart';
import 'models/stock.dart';
import 'models/talla.dart';
import 'services/cestaService.dart';

class ProductoDetalle extends StatefulWidget {
  final Producto producto;

  const ProductoDetalle({super.key, required this.producto});

  @override
  State<ProductoDetalle> createState() => _ProductoDetalleState();
}

class _ProductoDetalleState extends State<ProductoDetalle> {
  List<Talla> todasTallas = [];
  List<Stock> stockProducto = [];
  List<Producto> productosCategoria = [];
  String? selectedTallaId;
  bool loading = true;
  bool loadingCategoria = true;

  @override
  void initState() {
    super.initState();
    _cargarTallasYStock();
    _cargarProductosCategoria();
  }

  Future<void> _cargarTallasYStock() async {
    try {
      final resTallas = await ioClient.get(
        Uri.parse("http://185.189.221.84/api.php/records/Tallas"),
      );
      final dataTallas = jsonDecode(resTallas.body);
      final List<dynamic> listaTallas = dataTallas["records"] ?? [];
      todasTallas = listaTallas.map((e) => Talla.fromJson(e)).toList();

      final resStock = await ioClient.get(
        Uri.parse("http://185.189.221.84/api.php/records/Stock"),
      );
      final dataStock = jsonDecode(resStock.body);
      final List<dynamic> listaStock = dataStock["records"] ?? [];
      List<Stock> allStock = listaStock.map((e) => Stock.fromJson(e)).toList();

      stockProducto =
          allStock.where((s) => s.idProducto == widget.producto.id).toList();

      stockProducto.sort((a, b) => a.idTalla.compareTo(b.idTalla));
    } catch (e) {
      print("Error cargando tallas/stock: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _cargarProductosCategoria() async {
    try {
      final res = await ioClient.get(
        Uri.parse(
            "http://185.189.221.84/api.php/records/Producto?filter=id_categoria,eq,${widget.producto.idCategoria}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> lista = data["records"] ?? [];
        productosCategoria =
            lista.map((e) => Producto.fromJson(e)).where((p) => p.id != widget.producto.id).toList();
      }
    } catch (e) {
      print("Error cargando productos de la categoría: $e");
    } finally {
      setState(() {
        loadingCategoria = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto.nombre,
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF00122B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            alignment: Alignment.center,
            child: Image.network(
              "https://185.189.221.84/images/${widget.producto.id}.jpg",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
              const Icon(Icons.broken_image, color: Colors.grey, size: 80),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.producto.nombre,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("${widget.producto.precio.toStringAsFixed(2)} €",
                      style: const TextStyle(
                          fontSize: 22,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),

                  if (stockProducto.isNotEmpty) ...[
                    const Text("Selecciona talla:",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedTallaId,
                      isExpanded: true,
                      hint: const Text("Selecciona talla"),
                      items: stockProducto.map((s) {
                        final talla = todasTallas.firstWhere(
                              (t) => t.id.toString() == s.idTalla.toString(),
                          orElse: () =>
                              Talla(id: s.idTalla, talla: "Desconocida"),
                        );
                        return DropdownMenuItem<String>(
                          value: s.idTalla.toString(),
                          child: Text(
                              "${talla.talla} (${s.cantidad} disponibles)"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTallaId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Color(0xFF0056B3), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    widget.producto.descripcion.isNotEmpty
                        ? widget.producto.descripcion
                        : "Sin descripción disponible",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),

                  if (!loadingCategoria && productosCategoria.isNotEmpty) ...[
                    const Text("Más productos de esta categoría:",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: productosCategoria.length,
                        itemBuilder: (context, index) {
                          final prod = productosCategoria[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductoDetalle(producto: prod),
                                ),
                              );
                            },
                            child: Container(
                              width: 120,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      "https://185.189.221.84/images/${prod.id}.jpg",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stack) =>
                                      const Icon(Icons.image,
                                          size: 50,
                                          color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    prod.nombre,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                  backgroundColor: const Color(0xFF0056B3),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                onPressed: selectedTallaId == null
                    ? null
                    : () async {
                  final stockSeleccionado = stockProducto.firstWhere(
                          (s) => s.idTalla.toString() == selectedTallaId);

                  await CestaService.agregarProducto(
                    producto: widget.producto,
                    stockSeleccionado: stockSeleccionado,
                  );
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Producto añadido al carrito correctamente"),
                    ),
                  );
                },
                child: const Text(
                  "Añadir al Carrito",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}