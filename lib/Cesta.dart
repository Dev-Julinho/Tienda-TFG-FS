import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as ioClient;
import 'services/cestaService.dart';
import 'package:TFGPruebas/models/stock.dart';
import 'package:TFGPruebas/models/talla.dart';
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
    // Cargar stock y tallas y luego carrito
    cargarStockYTallas();
  }

  Future<void> cargarStockYTallas() async {
    try {
      // Traer stockAll desde tu API directamente
      final resStock = await ioClient.get(Uri.parse("http://185.189.221.84/api.php/records/Stock"));
      final dataStock = jsonDecode(resStock.body);
      final List<dynamic> listaStock = dataStock["records"] ?? [];
      stockAll = listaStock.map((e) => Stock.fromJson(e)).toList(); // ✅ mapea cada elemento a Stock
      CarritoPage.carritoStock = stockAll; // opcional: guardar en la clase estática

      // Traer tallasAll desde tu API directamente
      final resTallas = await ioClient.get(Uri.parse("http://185.189.221.84/api.php/records/Tallas"));
      final dataTallas = jsonDecode(resTallas.body);
      final List<dynamic> listaTallas = dataTallas["records"] ?? [];
      tallasAll = listaTallas.map((e) => Talla.fromJson(e)).toList(); // ✅ mapea cada elemento a Talla
      CarritoPage.carritoTallas = tallasAll; // opcional: guardar en la clase estática

      // Ahora carga carrito y pasa stockAll
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
      appBar: AppBar(title: const Text("Mi Carrito"), centerTitle: true),
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
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    title: Text(item["nombre"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text("€${item["precio"].toStringAsFixed(2)} | Talla: ${item["talla"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () async {
                            await CestaService.disminuirCantidad(item["idProducto"], item["idTalla"]);
                            setState(() {}); // refresca la UI con la cantidad actualizada
                          },
                        ),
                        Text(
                          item["cantidad"].toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: item["cantidad"] >= item["stockMax"] ? Colors.grey : Colors.green,
                          ),
                          onPressed: item["cantidad"] >= item["stockMax"]
                              ? null
                              : () async {
                            await CestaService.incrementarCantidad(
                              item["idProducto"],
                              item["idTalla"],
                              item["stockMax"],
                            );
                            setState(() {}); // refresca la UI con la cantidad actualizada
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -3))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("€${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RealizarPedidoPage()));
                      },
                      child: const Text("Continuar", style: TextStyle(fontSize: 18, color: Colors.white))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carritoVacio() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey), SizedBox(height: 20), Text("Tu carrito está vacío", style: TextStyle(fontSize: 22, color: Colors.grey))],
    ),
  );
}
