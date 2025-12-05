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

  Map<String, dynamic>? empresaEnvio;
  double precioEnvio = 0;

  @override
  void initState() {
    super.initState();

    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    ioClient = IOClient(httpClient);

    _cargarProductos();
    _cargarEmpresaEnvio();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
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

      List<Map<String, dynamic>> temp = [];

      for (var item in lista) {
        final idProducto = item["id_producto"];
        final idTalla = item["id_talla"];

        final resProd = await ioClient.get(
            Uri.parse("${CestaService.baseUrl}/records/Producto/$idProducto"));

        final dataProd = jsonDecode(resProd.body);

        String talla = "Única";

        if (idTalla != null) {
          final resTalla = await ioClient
              .get(Uri.parse("${CestaService.baseUrl}/records/Tallas/$idTalla"));

          if (resTalla.statusCode == 200) {
            final dataTalla = jsonDecode(resTalla.body);

            if (dataTalla["talla"] != null) {
              talla = dataTalla["talla"].toString();
            } else if (dataTalla["nombre"] != null) {
              talla = dataTalla["nombre"].toString();
            }
          }
        }

        temp.add({
          "nombre": dataProd["nombre"] ?? "Producto",
          "imagen": "https://185.189.221.84/images/$idProducto.jpg",
          "cantidad": int.parse(item["cantidad"].toString()),
          "precio_unitario":
          double.parse(item["precio_unitario"].toString()),
          "talla": talla,
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

  Future<void> _cargarEmpresaEnvio() async {
    try {
      final resEnvio = await ioClient.get(Uri.parse(
          "${CestaService.baseUrl}/records/Envio?filter=id_pedido,eq,${widget.pedidoId}"));

      if (resEnvio.statusCode == 200) {
        final data = jsonDecode(resEnvio.body);
        final lista = data["records"];

        if (lista != null && lista.isNotEmpty) {
          final envio = lista[0];

          final idEmpresa = envio["id_empresa"];

          double precio = 0;

          if (idEmpresa == 8) {
            precio = 4.99;
          } else if (idEmpresa == 7) {
            precio = 9.99;
          } else {
            precio = 0;
          }

          final resEmpresa = await ioClient.get(
              Uri.parse("${CestaService.baseUrl}/records/Empresa/$idEmpresa"));

          if (resEmpresa.statusCode == 200) {
            final dataEmp = jsonDecode(resEmpresa.body);

            setState(() {
              empresaEnvio = {
                "nombre": dataEmp["nombre"] ?? "-",
                "descripcion": dataEmp["descripcion"] ?? "",
                "precio": precio,
              };
              precioEnvio = precio;
            });
          }
        }
      }
    } catch (e) {
      print("Error cargando empresa de envío: $e");
    }
  }

  double get totalProductos =>
      productos.fold(0, (sum, p) => sum + p["precio_unitario"] * p["cantidad"]);

  double get total => totalProductos + precioEnvio;

  @override
  void dispose() {
    ioClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3ECF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00122B),
        centerTitle: true,
        elevation: 4,
        title: Text(
          "Pedido #${widget.pedidoId}",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
          child:
          Text(error!, style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount:
              productos.length + (empresaEnvio != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (empresaEnvio != null &&
                    index == productos.length) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        "Empresa de envío: ${empresaEnvio!["nombre"]}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${empresaEnvio!["descripcion"]}\nCosto adicional: ${empresaEnvio!["precio"] == 0 ? "Gratis" : "€${empresaEnvio!["precio"].toStringAsFixed(2)}"}",
                      ),
                    ),
                  );
                }

                final prod = productos[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Image.network(
                      prod["imagen"],
                      width: 50,
                      height: 50,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image),
                    ),
                    title: Text(
                      prod["nombre"],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        "Talla: ${prod["talla"]}\nCantidad: ${prod["cantidad"]}"),
                    trailing: Text(
                      "€${(prod["precio_unitario"] * prod["cantidad"]).toStringAsFixed(2)}",
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
