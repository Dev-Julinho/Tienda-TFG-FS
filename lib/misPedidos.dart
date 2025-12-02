import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detallePedido.dart';
import 'models/pedido.dart';
import 'services/cestaService.dart';

class MisPedidosPage extends StatefulWidget {
  const MisPedidosPage({super.key});

  @override
  State<MisPedidosPage> createState() => _MisPedidosPageState();
}

class _MisPedidosPageState extends State<MisPedidosPage> {
  late IOClient ioClient;
  bool cargando = true;
  String? error;
  List<Pedido> pedidos = [];

  final String baseUrl = "https://185.189.221.84/api.php";

  @override
  void initState() {
    super.initState();

    // HttpClient que acepta certificados inválidos (solo pruebas)
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    ioClient = IOClient(httpClient);

    _obtenerPedidosCerrados();
  }

  Future<void> _obtenerPrimerProducto(Pedido pedido) async {
    try {
      final productos = await CestaService.obtenerProductosPedido(pedido.idPedido);
      if (productos.isNotEmpty) {
        setState(() {
          pedido.primerProductoNombre = productos[0]["nombre"] ?? "Producto";
          pedido.primerProductoImagen = productos[0]["imagen"] ?? null;
        });
      }
    } catch (e) {
      // ignoramos errores aquí, solo no ponemos nombre/imagen
    }
  }

  Future<void> _obtenerPedidosCerrados() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? idCliente = prefs.getInt("id_cliente");

      if (idCliente == null) {
        setState(() {
          cargando = false;
          error = "Usuario no identificado. Inicia sesión.";
        });
        return;
      }

      final uri = Uri.parse(
          "$baseUrl/records/Pedido?filter=id_cliente,eq,$idCliente&filter=id_estado,eq,2&sort=-fecha_pedido");
      final res = await ioClient.get(uri);

      if (res.statusCode != 200) {
        setState(() {
          cargando = false;
          error = "Error del servidor: ${res.statusCode}";
        });
        return;
      }

      final data = jsonDecode(res.body);
      final List<dynamic> lista = data["records"] ?? [];

      final List<Pedido> nuevas = lista
          .map<Pedido>((e) => Pedido.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        pedidos = nuevas;
        cargando = false;
      });

      // Ahora obtenemos el primer producto de cada pedido
      for (var pedido in pedidos) {
        _obtenerPrimerProducto(pedido);
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = "Error cargando pedidos: $e";
      });
    }
  }

  String _formatFecha(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (_) {
      return raw.isNotEmpty ? raw : "-";
    }
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
        title: const Text("Mis Pedidos"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _obtenerPedidosCerrados,
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
            Center(
              child: ElevatedButton(
                onPressed: _obtenerPedidosCerrados,
                child: const Text("Reintentar"),
              ),
            ),
          ],
        )
            : pedidos.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 120),
            Center(
                child: Icon(Icons.receipt_long,
                    size: 80, color: Colors.grey)),
            SizedBox(height: 20),
            Center(
                child: Text("No tienes pedidos cerrados aún",
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey))),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            final pedido = pedidos[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: pedido.primerProductoImagen != null
                    ? Image.network(
                  pedido.primerProductoImagen!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.receipt_long, size: 40),
                title: Text(
                  pedido.primerProductoNombre ?? "Pedido #${pedido.idPedido}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    "Fecha: ${_formatFecha(pedido.fecha)}\nEmpresa ID: ${pedido.idEmpresa}"),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 30,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetallePedidoPage(
                        pedidoId: pedido.idPedido,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
