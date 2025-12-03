import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'services/cestaService.dart';

class DetallePedidoPage extends StatefulWidget {
  final int pedidoId;

  const DetallePedidoPage({super.key, required this.pedidoId});

  @override
  State<DetallePedidoPage> createState() => _DetallePedidoPageState();
}

class _DetallePedidoPageState extends State<DetallePedidoPage> {
  late IOClient ioClient;
  bool cargando = true;
  String? error;
  List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();

    // HttpClient que acepta certificados inválidos (solo pruebas)
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    ioClient = IOClient(httpClient);

    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      // Usamos CestaService para obtener los productos del pedido
      final res = await ioClient.get(Uri.parse(
          "${CestaService.baseUrl}/records/Detalle_Pedido?filter=id_pedido,eq,${widget.pedidoId}"));

      if (res.statusCode != 200) {
        setState(() {
          cargando = false;
          error = "Error del servidor: ${res.statusCode}";
        });
        return;
      }

      final data = jsonDecode(res.body);
      final List<dynamic> lista = data["records"] ?? [];

      // Obtenemos info de cada producto
      List<Map<String, dynamic>> temp = [];
      for (var item in lista) {
        final idProducto = item["id_producto"];
        final resProd = await ioClient.get(Uri.parse("${CestaService.baseUrl}/records/Producto/$idProducto"));
        final dataProd = jsonDecode(resProd.body);

        temp.add({
          "nombre": dataProd["nombre"] ?? "Producto",
          "imagen": "https://185.189.221.84/images/$idProducto.jpg",
          "cantidad": int.parse(item["cantidad"].toString()),
          "precio_unitario": double.parse(item["precio_unitario"].toString()),
          "talla": item["id_talla"].toString(), // podrías mapear a la talla real si quieres
        });
      }

      setState(() {
        productos = temp;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        cargando = false;
        error = "Error cargando productos: $e";
      });
    }
  }

  double get total =>
      productos.fold(0, (sum, p) => sum + p["precio_unitario"] * p["cantidad"]);

  @override
  void dispose() {
    ioClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pedido #${widget.pedidoId}"),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final prod = productos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: prod["imagen"] != null
                        ? Image.network(prod["imagen"], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 50),
                    title: Text(prod["nombre"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Talla: ${prod["talla"]}\nCantidad: ${prod["cantidad"]}"),
                    trailing: Text(
                      "€${(prod["precio_unitario"] * prod["cantidad"]).toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text("€${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
