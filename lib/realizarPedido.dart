import 'dart:convert';
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

  TextEditingController nombre = TextEditingController();
  TextEditingController apellidos = TextEditingController();
  TextEditingController telefono = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController direccion = TextEditingController();
  TextEditingController codigoPostal = TextEditingController();

  String? metodoPago;
  String? empresaSeleccionada;

  List<String> metodosPago = [];
  List<String> empresas = [];

  final String apiClienteUrl = "https://185.189.221.84/api.php/records/Cliente";
  final String apiMetodosPagoUrl = "https://185.189.221.84/api.php/records/Metodo_Pago";
  final String apiEmpresasUrl = "https://185.189.221.84/api.php/records/Empresa";

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
      setState(() {
        cargando = false;
      });
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
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _cargarMetodosPago() async {
    try {
      final res = await http.get(Uri.parse(apiMetodosPagoUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("Métodos de pago: ${data['records']}"); // debug
        setState(() {
          metodosPago = List<String>.from(
              data["records"].map((m) => m["nombre_metodo"] ?? "")
          );
        });
      } else {
        print("Error al cargar métodos de pago: ${res.statusCode}");
      }
    } catch (e) {
      print("Error cargando métodos de pago: $e");
    }
  }

  Future<void> _cargarEmpresas() async {
    try {
      final res = await http.get(Uri.parse(apiEmpresasUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          empresas = List<String>.from(
              data["records"].map((e) => "${e["nombre"]} (${e["descripcion"] ?? ""})")
          );
        });
      } else {
        print("Error al cargar empresas: ${res.statusCode}");
      }
    } catch (e) {
      print("Error cargando empresas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Realizar Pedido"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Datos del Usuario",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            CheckboxListTile(
              title: const Text("Modificar datos del usuario para el pedido"),
              value: permitirEdicion,
              onChanged: (value) {
                setState(() {
                  permitirEdicion = value!;
                });
              },
            ),

            _campo("Nombre", nombre),
            _campo("Apellidos", apellidos),
            _campo("Teléfono", telefono, tipo: TextInputType.phone),
            _campo("Email", email, tipo: TextInputType.emailAddress),
            _campo("Dirección", direccion),
            _campo("Código postal", codigoPostal, tipo: TextInputType.number),

            const SizedBox(height: 20),

            const Text(
              "Método de pago",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: metodoPago != null && metodosPago.contains(metodoPago) ? metodoPago : null,
              hint: const Text("Selecciona un Método de Pago"),
              items: metodosPago
                  .where((m) => m.isNotEmpty)
                  .toSet()
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  metodoPago = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Empresa de Envío",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: empresaSeleccionada != null && empresas.contains(empresaSeleccionada) ? empresaSeleccionada : null,
              hint: const Text("Selecciona una Empresa de Envío"),
              items: empresas
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  empresaSeleccionada = value;
                });
              },
            ),

            const SizedBox(height: 30),

            Text(
              "Total a pagar: €${totalCarrito.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Compra realizada con éxito"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  "Realizar Pedido",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
      String label,
      TextEditingController controller, {
        TextInputType tipo = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        readOnly: !permitirEdicion,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}