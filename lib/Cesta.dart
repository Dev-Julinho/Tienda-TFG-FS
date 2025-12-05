import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as ioClient;

import 'services/cestaService.dart';
import 'models/stock.dart';
import 'models/talla.dart';
import 'realizarPedido.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});
  static List<Map<String, dynamic>> carrito = [];
  static List<Stock> carritoStock = [];
  static List<Talla> carritoTallas = [];

  @override
  _CarritoPageState createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  List<Stock> stockAll = [];
  List<Talla> tallasAll = [];

  @override
  void initState() {
    super.initState();
    cargarStockYTallas();
  }

  Future<void> cargarStockYTallas() async {
    try {
      final resStock =
      await ioClient.get(Uri.parse("http://185.189.221.84/api.php/records/Stock"));
      final dataStock = jsonDecode(resStock.body);
      stockAll =
          (dataStock["records"] as List).map((e) => Stock.fromJson(e)).toList();
      CarritoPage.carritoStock = stockAll;

      final resTallas =
      await ioClient.get(Uri.parse("http://185.189.221.84/api.php/records/Tallas"));
      final dataTallas = jsonDecode(resTallas.body);
      tallasAll =
          (dataTallas["records"] as List).map((e) => Talla.fromJson(e)).toList();
      CarritoPage.carritoTallas = tallasAll;

      await CestaService.cargarCarritoBBDD();
      setState(() {});
    } catch (e) {
      print("Error cargando stock/tallas: $e");
    }
  }

  List<Map<String, dynamic>> get carrito => CarritoPage.carrito;

  double get total => carrito.fold(
      0, (suma, item) => suma + (item["precio"] * item["cantidad"]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3ECF8),
      appBar: AppBar(
        backgroundColor: Color(0xFF00122B),
        centerTitle: true,
        elevation: 4,
        title: const Text(
          "Mi Carrito",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: carrito.isEmpty
          ? _carritoVacio()
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: carrito.length,
              itemBuilder: (context, index) {
                final item = carrito[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  elevation: 6,
                  shadowColor: Colors.blue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),

                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://185.189.221.84/images/${item["idProducto"]}.jpg",
                          width: 65,
                          height: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            width: 65,
                            height: 65,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),

                      title: Text(
                        item["nombre"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A3D62),
                        ),
                      ),
                      subtitle: Text(
                        "€${item["precio"].toStringAsFixed(2)}   |   Talla: ${item["talla"]}",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () async {
                              await CestaService.disminuirCantidad(
                                  item["idProducto"], item["idTalla"]);
                              setState(() {});
                            },
                          ),
                          Text(
                            item["cantidad"].toString(),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle,
                              color: item["cantidad"] >= item["stockMax"]
                                  ? Colors.grey
                                  : Color(0xFF0056B3),
                            ),
                            onPressed: item["cantidad"] >= item["stockMax"]
                                ? null
                                : () async {
                              await CestaService.incrementarCantidad(
                                item["idProducto"],
                                item["idTalla"],
                                item["stockMax"],
                              );
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          _footer(),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, -3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("€${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: () async {
                await CestaService.eliminarTodosLosProductos();
                setState(() {});
              },
              child: const Text("Eliminar todos los productos",
                  style: TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0056B3),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RealizarPedidoPage()),
                );
              },
              child: const Text(
                "Continuar",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _carritoVacio() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined,
            size: 85, color: Colors.grey),
        SizedBox(height: 20),
        Text("Tu carrito está vacío",
            style: TextStyle(fontSize: 22, color: Colors.grey)),
      ],
    ),
  );
}
