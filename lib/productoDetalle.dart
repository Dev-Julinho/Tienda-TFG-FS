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
  String? selectedTallaId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargarTallasYStock();
  }

  Future<void> _cargarTallasYStock() async {
    try {
      // Traer todas las tallas
      final resTallas = await ioClient.get(
        Uri.parse("http://185.189.221.84/api.php/records/Tallas"),
      );
      final dataTallas = jsonDecode(resTallas.body);
      final List<dynamic> listaTallas = dataTallas["records"] ?? [];
      todasTallas = listaTallas.map((e) => Talla.fromJson(e)).toList();

      // Traer todo el stock
      final resStock = await ioClient.get(
        Uri.parse("http://185.189.221.84/api.php/records/Stock"),
      );
      final dataStock = jsonDecode(resStock.body);
      final List<dynamic> listaStock = dataStock["records"] ?? [];
      List<Stock> allStock = listaStock.map((e) => Stock.fromJson(e)).toList();

      // Filtrar solo el stock del producto actual
      stockProducto =
          allStock.where((s) => s.idProducto == widget.producto.id).toList();

      // Ordenar stockProducto por idTalla de menor a mayor
      stockProducto.sort((a, b) => a.idTalla.compareTo(b.idTalla));
    } catch (e) {
      print("Error cargando tallas/stock: $e");
    } finally {
      setState(() {
        loading = false;
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
        title: Text(widget.producto.nombre),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Imagen del producto
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

                  // Dropdown de tallas
                  if (stockProducto.isNotEmpty) ...[
                    const Text("Selecciona talla:",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
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
                          child: Text("${talla.talla} (${s.cantidad} disponibles)"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTallaId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Descripción del producto
                  Text(
                    widget.producto.descripcion.isNotEmpty
                        ? widget.producto.descripcion
                        : "Sin descripción disponible",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          // Botón añadir al carrito
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 20)),
                onPressed: selectedTallaId == null
                    ? null
                    : () async {
                  final stockSeleccionado = stockProducto.firstWhere(
                          (s) => s.idTalla.toString() == selectedTallaId);

                  // Agregar producto al pedido y carrito
                  await CestaService.agregarProducto(
                    producto: widget.producto,
                    stockSeleccionado: stockSeleccionado,
                  );

                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Producto añadido al carrito correctamente"),
                    ),
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
