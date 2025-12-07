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
        final producto = productos[0];

        pedido.primerProductoId =
            int.tryParse(producto["id_producto"].toString()) ?? 0;

        pedido.primerProductoNombre =
            producto["nombre"]?.toString() ?? "Producto";
      }

      final resEnvio = await ioClient.get(
        Uri.parse("$baseUrl/records/Envio?filter=id_pedido,eq,${pedido.idPedido}"),
      );

      if (resEnvio.statusCode == 200) {
        final dataEnv = jsonDecode(resEnvio.body);

        if (dataEnv["records"] != null && dataEnv["records"].isNotEmpty) {
          final envio = dataEnv["records"][0];
          final int? idEmpresa = int.tryParse(envio["id_empresa"].toString());

          if (idEmpresa != null) {
            final resEmpresa = await ioClient.get(
              Uri.parse("$baseUrl/records/Empresa/$idEmpresa"),
            );

            if (resEmpresa.statusCode == 200) {
              final dataEmp = jsonDecode(resEmpresa.body);
              pedido.nombreEmpresa = dataEmp["nombre"]?.toString() ?? "Empresa";
            }
          }
        }
      }
      setState(() {});

    } catch (_) {
      pedido.nombreEmpresa = "Empresa";
      setState(() {});
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

      final res = await ioClient.get(Uri.parse(
          "$baseUrl/records/Pedido?filter=id_cliente,eq,$idCliente&filter=id_estado,eq,2&sort=-fecha_pedido"));

      if (res.statusCode != 200) {
        setState(() {
          cargando = false;
          error = "Error del servidor: ${res.statusCode}";
        });
        return;
      }

      final data = jsonDecode(res.body);
      final List lista = data["records"] ?? [];

      pedidos = lista
          .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
          .toList();

      cargando = false;
      setState(() {});

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

  String _formatFecha(String? raw) {
    if (raw == null || raw.isEmpty) return "-";
    try {
      final dt = DateTime.parse(raw);
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}";
    } catch (_) {
      return raw;
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
      backgroundColor: const Color(0xFFE3ECF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00122B),
        centerTitle: true,
        title: const Text("Mis Pedidos", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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
              child: Text(error!,
                  style: const TextStyle(color: Colors.red)),
            ),
            Center(
              child: ElevatedButton(
                onPressed: _obtenerPedidosCerrados,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056B3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 25)),
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
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: pedido.primerProductoId != null &&
                    pedido.primerProductoId != 0
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    "https://185.189.221.84/images/${pedido.primerProductoId}.jpg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.receipt_long,
                        size: 40, color: Colors.grey),
                  ),
                )
                    : const Icon(Icons.receipt_long,
                    size: 40, color: Colors.grey),
                title: Text(
                  pedido.primerProductoNombre ??
                      "Pedido #${pedido.idPedido}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A3D62)),
                ),
                subtitle: Text(
                  "Fecha: ${_formatFecha(pedido.fecha)}\nEmpresa: ${pedido.nombreEmpresa ?? '...'}",
                  style: const TextStyle(color: Colors.black87),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 30,
                  color: Colors.white,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetallePedidoPage(pedidoId: pedido.idPedido),
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