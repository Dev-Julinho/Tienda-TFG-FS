import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import '../models/producto.dart';
import '../models/stock.dart';
import '../Cesta.dart';
import '../models/talla.dart';

class CestaService {
  static const String baseUrl = "https://185.189.221.84/api.php";

  // Cliente HTTP que ignora certificados inválidos (solo pruebas)
  static final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  static final IOClient _ioClient = IOClient(_httpClient);

  // Usuario
  static int get idCliente => 1;

  // ======================================
  // 1. Obtener pedido abierto
  // ======================================
  static Future<int?> obtenerPedidoAbierto() async {
    try {
      final res = await _ioClient.get(Uri.parse(
          "$baseUrl/records/Pedido?filter=id_cliente,eq,$idCliente&filter=id_estado,eq,1"));
      final data = jsonDecode(res.body);
      if (data["records"] != null && data["records"].isNotEmpty) {
        return int.parse(data["records"][0]["id_pedido"].toString());
      }
    } catch (e) {
      print("Error obtener pedido: $e");
    }
    return null;
  }

  // ======================================
  // 2. Crear pedido
  // ======================================
  static Future<int?> crearPedido() async {
    try {
      final response = await _ioClient.post(
        Uri.parse("$baseUrl/records/Pedido"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_cliente": idCliente,
          "id_estado": 1,
          "fecha_pedido": DateTime.now().toIso8601String()
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = int.tryParse(response.body.trim());
        return id;
      } else {
        print("Error creando pedido, status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error crear pedido: $e");
    }
    return null;
  }

  // ======================================
  // 3. Agregar producto al pedido
  // ======================================
  static Future<void> agregarProducto({
    required Producto producto,
    required Stock stockSeleccionado,
  }) async {
    int? idPedido = await obtenerPedidoAbierto();
    if (idPedido == null) idPedido = await crearPedido();
    if (idPedido == null) return;

    try {
      // ⚠️ OJO: ahora también filtramos por id_talla
      final resDetalle = await _ioClient.get(Uri.parse(
          "$baseUrl/records/Detalle_Pedido?filter=id_pedido,eq,$idPedido"
              "&filter=id_producto,eq,${producto.id}"
              "&filter=id_talla,eq,${stockSeleccionado.idTalla}"
      ));

      final dataDetalle = jsonDecode(resDetalle.body);

      if (dataDetalle["records"] != null && dataDetalle["records"].isNotEmpty) {
        final detalle = dataDetalle["records"][0];
        final idDetalle = detalle["id_detalle"];

        int nuevaCantidad = int.parse(detalle["cantidad"].toString()) + 1;

        if (nuevaCantidad > stockSeleccionado.cantidad) {
          nuevaCantidad = stockSeleccionado.cantidad;
        }

        await _ioClient.put(
          Uri.parse("$baseUrl/records/Detalle_Pedido/$idDetalle"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"cantidad": nuevaCantidad}),
        );
      } else {
        // INSERTAR con talla
        await _ioClient.post(
          Uri.parse("$baseUrl/records/Detalle_Pedido"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id_pedido": idPedido,
            "id_producto": producto.id,
            "id_talla": stockSeleccionado.idTalla,
            "cantidad": 1,
            "precio_unitario": producto.precio
          }),
        );
      }
    } catch (e) {
      print("Error creando/actualizando detalle pedido: $e");
    }

    await cargarCarritoBBDD();
  }

  // ======================================
  // 4. Incrementar cantidad (botón +)
  // ======================================
  static Future<void> incrementarCantidad(int idProducto, int idTalla, int stockMax) async {
    int? idPedido = await obtenerPedidoAbierto();
    if (idPedido == null) return;

    final resDetalle = await _ioClient.get(Uri.parse(
        "$baseUrl/records/Detalle_Pedido?filter=id_pedido,eq,$idPedido"
            "&filter=id_producto,eq,$idProducto"
            "&filter=id_talla,eq,$idTalla"
    ));

    final dataDetalle = jsonDecode(resDetalle.body);
    if (dataDetalle["records"] == null || dataDetalle["records"].isEmpty) return;

    final detalle = dataDetalle["records"][0];
    final idDetalle = detalle["id_detalle"];
    int cantidadActual = int.parse(detalle["cantidad"].toString());

    if (cantidadActual >= stockMax) return;

    await _ioClient.put(
      Uri.parse("$baseUrl/records/Detalle_Pedido/$idDetalle"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"cantidad": cantidadActual + 1}),
    );

    await cargarCarritoBBDD();
  }

  // ======================================
  // 5. Disminuir cantidad (botón -)
  // ======================================
  static Future<void> disminuirCantidad(int idProducto, int idTalla) async {
    int? idPedido = await obtenerPedidoAbierto();
    if (idPedido == null) return;

    final resDetalle = await _ioClient.get(Uri.parse(
        "$baseUrl/records/Detalle_Pedido?filter=id_pedido,eq,$idPedido"
            "&filter=id_producto,eq,$idProducto"
            "&filter=id_talla,eq,$idTalla"
    ));

    final dataDetalle = jsonDecode(resDetalle.body);
    if (dataDetalle["records"] == null || dataDetalle["records"].isEmpty) return;

    final detalle = dataDetalle["records"][0];
    final idDetalle = detalle["id_detalle"];
    int cantidadActual = int.parse(detalle["cantidad"].toString());

    if (cantidadActual <= 1) {
      await _ioClient.delete(Uri.parse("$baseUrl/records/Detalle_Pedido/$idDetalle"));
    } else {
      await _ioClient.put(
        Uri.parse("$baseUrl/records/Detalle_Pedido/$idDetalle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cantidad": cantidadActual - 1}),
      );
    }

    await cargarCarritoBBDD();
  }

  // ======================================
  // 6. Cargar carrito desde BBDD
  // ======================================
  static Future<void> cargarCarritoBBDD() async {
    int? idPedido = await obtenerPedidoAbierto();
    if (idPedido == null) return;

    final res = await _ioClient.get(
        Uri.parse("$baseUrl/records/Detalle_Pedido?filter=id_pedido,eq,$idPedido"));
    final data = jsonDecode(res.body);
    if (data["records"] == null) return;

    CarritoPage.carrito.clear();

    for (var item in data["records"]) {
      final int idProd = int.parse(item["id_producto"].toString());
      final int idTalla = int.parse(item["id_talla"].toString());

      // Producto
      final resProducto = await _ioClient.get(Uri.parse("$baseUrl/records/Producto/$idProd"));
      final dataProducto = jsonDecode(resProducto.body);

      // Stock real usando la lista cargada
      final stock = CarritoPage.carritoStock.firstWhere(
            (s) => s.idProducto == idProd && s.idTalla == idTalla,
        orElse: () => Stock(idProducto: idProd, idTalla: idTalla, cantidad: 0),
      );

      // Talla real usando la lista cargada
      final talla = CarritoPage.carritoTallas.firstWhere(
            (t) => t.id == idTalla,
        orElse: () => Talla(id: idTalla, talla: "Única"),
      );

      CarritoPage.carrito.add({
        "nombre": dataProducto["nombre"] ?? "Sin nombre",
        "precio": double.parse(item["precio_unitario"].toString()),
        "talla": talla.talla,
        "idProducto": idProd,
        "idTalla": idTalla,
        "cantidad": int.parse(item["cantidad"].toString()),
        "stockMax": stock.cantidad,
      });
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerProductosPedido(int idPedido) async {
    try {
      final res = await _ioClient.get(
          Uri.parse("$baseUrl/records/Detalle_Pedido?filter=id_pedido,eq,$idPedido")
      );

      final data = jsonDecode(res.body);
      if (data["records"] != null) {
        List<Map<String, dynamic>> productos = [];

        for (var item in data["records"]) {
          // Recuperamos info del producto
          final idProd = int.parse(item["id_producto"].toString());
          final resProd = await _ioClient.get(Uri.parse("$baseUrl/records/Producto/$idProd"));
          final prodData = jsonDecode(resProd.body);

          productos.add({
            "nombre": prodData["nombre"] ?? "Producto",
            "imagen": prodData["imagen"] ?? null,
            "cantidad": int.parse(item["cantidad"].toString()),
            "precio": double.parse(item["precio_unitario"].toString()),
          });
        }

        return productos;
      }
    } catch (e) {
      print("Error obteniendo productos del pedido $idPedido: $e");
    }

    return [];
  }

}
