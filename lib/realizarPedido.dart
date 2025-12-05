import 'dart:convert';
import 'package:TFGPruebas/services/cestaService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Cesta.dart';

class RealizarPedidoPage extends StatefulWidget {
  const RealizarPedidoPage({super.key});

  @override
  State<RealizarPedidoPage> createState() => _RealizarPedidoPageState();
}

class _RealizarPedidoPageState extends State<RealizarPedidoPage> {
  bool permitirEdicion = false;
  bool cargando = true;

  final TextEditingController nombre = TextEditingController();
  final TextEditingController apellidos = TextEditingController();
  final TextEditingController telefono = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController direccion = TextEditingController();
  final TextEditingController codigoPostal = TextEditingController();

  Map<String, dynamic>? empresaSeleccionada;
  String? metodoPago;
  double precioEnvio = 0;

  List<Map<String, dynamic>> metodosPagoList = [];
  List<Map<String, dynamic>> empresasList = [];

  final String apiClienteUrl =
      "https://185.189.221.84/api.php/records/Cliente";
  final String apiMetodosPagoUrl =
      "https://185.189.221.84/api.php/records/Metodo_Pago";
  final String apiEmpresasUrl =
      "https://185.189.221.84/api.php/records/Empresa";
  final String apiEnvioUrl =
      "https://185.189.221.84/api.php/records/Envio";

  double get totalCarrito {
    return CarritoPage.carrito.fold(
      0,
          (suma, item) => suma + (item["precio"] * item["cantidad"]),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarMetodosPago();
    _cargarEmpresas();
  }

  Future<void> _cargarDatosUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCliente = prefs.getInt("id_cliente");

    if (idCliente == null) {
      setState(() => cargando = false);
      return;
    }

    final res = await http.get(Uri.parse("$apiClienteUrl/$idCliente"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        nombre.text = data["nombre"] ?? "";
        apellidos.text = data["apellidos"] ?? "";
        telefono.text = data["telefono"] ?? "";
        email.text = data["email"] ?? "";
        direccion.text = data["direccion"] ?? "";
        codigoPostal.text = data["codigo_postal"] ?? "";
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  Future<void> _cargarMetodosPago() async {
    final res = await http.get(Uri.parse(apiMetodosPagoUrl));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List lista = data["records"];
      setState(() {
        metodosPagoList = lista.map<Map<String, dynamic>>((m) => {
          "id": m["id_metodo_pago"],
          "tipo": m["tipo"],
        }).toList();
      });
    }
  }

  Future<void> _cargarEmpresas() async {
    final res = await http.get(Uri.parse(apiEmpresasUrl));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List lista = data["records"];
      setState(() {
        empresasList = lista.map<Map<String, dynamic>>((e) => {
          "id": e["id_empresa"],
          "nombre": e["nombre"],
          "descripcion": e["descripcion"],
        }).toList();
      });
    }
  }

  Future<void> _cerrarPedido() async {
    try {
      final idPedido = await CestaService.obtenerPedidoAbierto();
      if (idPedido == null) return;

      final idMetodoPago = metodosPagoList.firstWhere(
            (m) => m["tipo"] == metodoPago,
        orElse: () => {"id": 0},
      )["id"];

      final response = await http.put(
        Uri.parse("https://185.189.221.84/api.php/records/Pedido/$idPedido"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_estado": 2,
          "id_metodo_pago": idMetodoPago,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _crearEnvio(empresaSeleccionada!["id"], idPedido);

        CarritoPage.carrito.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pedido realizado y envío creado con éxito")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cerrando pedido: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cerrando pedido: $e")),
      );
    }
  }

  Future<void> _crearEnvio(int idEmpresa, int idPedido) async {
    try {
      final response = await http.post(
        Uri.parse(apiEnvioUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "numero_seguimiento": "ENV-${DateTime.now().millisecondsSinceEpoch}",
          "coste_envio": precioEnvio,
          "fecha_envio": DateTime.now().toIso8601String(),
          "id_empresa": idEmpresa,
          "id_pedido": idPedido,
        }),

      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Error creando envío: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error en creación de envío: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00122B),
        centerTitle: true,
        elevation: 4,
        title: const Text(
          "Realizar Pedido",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Datos del Usuario",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            CheckboxListTile(
              title: const Text("Modificar datos del usuario"),
              value: permitirEdicion,
              onChanged: (value) => setState(() => permitirEdicion = value ?? false),
            ),

            _campo("Nombre", nombre),
            _campo("Apellidos", apellidos),
            _campo("Teléfono", telefono, tipo: TextInputType.phone),
            _campo("Email", email, tipo: TextInputType.emailAddress),
            _campo("Dirección", direccion),
            _campo("Código postal", codigoPostal, tipo: TextInputType.number),

            const SizedBox(height: 20),

            const Text("Método de pago",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            DropdownButtonFormField<String>(
              isExpanded: true,
              value: metodoPago,
              hint: const Text("Selecciona un método de pago"),
              items: metodosPagoList
                  .map((m) => DropdownMenuItem<String>(
                value: m["tipo"].toString(),
                child: Text(m["tipo"].toString()),
              ))
                  .toList(),
              onChanged: (value) => setState(() => metodoPago = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Empresa de envío",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            Column(
              children: List.generate(empresasList.length, (index) {
                final empresa = empresasList[index];
                final seleccionada = empresaSeleccionada == empresa;

                double costo = index == 0 ? 9.99 : index == 1 ? 4.99 : 0;

                return Card(
                  color: seleccionada ? const Color(0xFF0056B3) : Colors.white,
                  child: ListTile(
                    title: Text(
                      empresa["nombre"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: seleccionada ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(empresa["descripcion"] ?? ""),
                    trailing: Text(
                      costo == 0 ? "Gratis" : "€$costo",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: seleccionada ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        empresaSeleccionada = empresa;
                        precioEnvio = costo;
                      });
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            Text(
              "Total de los productos: €${totalCarrito.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Text(
              "Gastos de envío: €${precioEnvio.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Text(
              "Total a pagar: €${(totalCarrito + precioEnvio).toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (metodoPago == null || empresaSeleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Completa todos los campos")),
                    );
                    return;
                  }

                  await _cerrarPedido();
                  Navigator.pop(context);
                },
                child: const Text("Realizar Pedido"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController controller,
      {TextInputType tipo = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        readOnly: !permitirEdicion,
        keyboardType: tipo,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
