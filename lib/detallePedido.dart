import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetallePedidoPage extends StatefulWidget {
  final int pedidoId;

  const DetallePedidoPage({super.key, required this.pedidoId});

  @override
  State<DetallePedidoPage> createState() => _DetallePedidoPageState();
}

class _DetallePedidoPageState extends State<DetallePedidoPage> {
  final String baseUrl = "https://185.189.221.84/api.php";

  bool loading = true;
  bool error = false;
  String errorMsg = "";

  List<dynamic> lineas = [];
  Map<String, dynamic>? pedidoInfo;

  @override
  void initState() {
    super.initState();
    _fetchDetallePedido();
  }

  Future<void> _fetchDetallePedido() async {
    setState(() {
      loading = true;
      error = false;
    });

    try {
      // 1️⃣ Obtener info básica del pedido
      final pedidoRes = await http.get(
        Uri.parse("$baseUrl/records/Pedido/${widget.pedidoId}"),
      );

      // 2️⃣ Obtener líneas del pedido
      final lineasRes = await http.get(
        Uri.parse(
          "$baseUrl/records/Detalle_Pedido?filter=id_pedido,eq,${widget.pedidoId}",
        ),
      );

      if (pedidoRes.statusCode != 200 || lineasRes.statusCode != 200) {
        throw Exception("Error al cargar datos del pedido");
      }

      final pedidoData = jsonDecode(pedidoRes.body);
      final lineasData = jsonDecode(lineasRes.body);

      setState(() {
        pedidoInfo = pedidoData;
        lineas = lineasData['records'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = true;
        errorMsg = "Error cargando detalle: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pedido #${widget.pedidoId}"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? Center(
        child: Text(
          errorMsg,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoPedido(),
            const SizedBox(height: 25),
            const Text(
              "Productos",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...lineas.map((item) => _buildProducto(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPedido() {
    if (pedidoInfo == null) return const SizedBox();

    final String fecha = pedidoInfo!['fecha_pedido'] ?? '-';
    final String total = pedidoInfo!['total']?.toString() ?? "0";
    final String metodoPago =
        pedidoInfo!['id_metodo_pago']?.toString() ?? "-";
    final String empresa = pedidoInfo!['id_empresa']?.toString() ?? "-";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información del pedido",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoRow("Fecha:", fecha),
            _infoRow("Empresa:", empresa),
            _infoRow("Método de pago:", metodoPago),
            const Divider(height: 25),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total: €$total",
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProducto(Map<String, dynamic> item) {
    final String producto =
        item['nombre_producto']?.toString() ?? "Producto";
    final String talla = item['talla']?.toString() ?? "-";
    final int cantidad =
        int.tryParse(item['cantidad']?.toString() ?? '1') ?? 1;
    final double precio =
        double.tryParse(item['precio']?.toString() ?? '0') ?? 0;

    final double subtotal = cantidad * precio;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Talla: $talla"),
            Text("Cantidad: $cantidad"),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "€${precio.toStringAsFixed(2)} / ud",
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  "Subtotal: €${subtotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
