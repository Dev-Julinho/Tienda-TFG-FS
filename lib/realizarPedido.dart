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

  final TextEditingController nombre = TextEditingController();
  final TextEditingController apellidos = TextEditingController();
  final TextEditingController telefono = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController direccion = TextEditingController();
  final TextEditingController codigoPostal = TextEditingController();

  String? metodoPago;

  List<String> metodosPago = [];
  List<Map<String, dynamic>> empresas = [];

  Map<String, dynamic>? empresaSeleccionada;
  double precioEnvio = 0;

  final String apiClienteUrl =
      "https://185.189.221.84/api.php/records/Cliente";
  final String apiMetodosPagoUrl =
      "https://185.189.221.84/api.php/records/Metodo_Pago";
  final String apiEmpresasUrl =
      "https://185.189.221.84/api.php/records/Empresa";

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
        metodosPago = lista.map<String>((m) => m["tipo"].toString()).toList();
      });
    }
  }

  Future<void> _cargarEmpresas() async {
    final res = await http.get(Uri.parse(apiEmpresasUrl));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List lista = data["records"];

      setState(() {
        empresas = lista.cast<Map<String, dynamic>>();
      });
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
              title: const Text("Modificar datos del usuario"),
              value: permitirEdicion,
              onChanged: (value) {
                setState(() {
                  permitirEdicion = value ?? false;
                });
              },
            ),

            _campo("Nombre", nombre),
            _campo("Apellidos", apellidos),
            _campo("Teléfono", telefono, tipo: TextInputType.phone),
            _campo("Email", email, tipo: TextInputType.emailAddress),
            _campo("Dirección", direccion),
            _campo("Código postal", codigoPostal,
                tipo: TextInputType.number),

            const SizedBox(height: 20),

            const Text(
              "Método de pago",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            DropdownButtonFormField<String>(
              isExpanded: true,
              value: metodoPago,
              hint: const Text("Selecciona un método de pago"),
              items: metodosPago
                  .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => metodoPago = value);
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Empresa de envío",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Column(
              children: List.generate(empresas.length, (index) {
                final empresa = empresas[index];
                final seleccionada = empresaSeleccionada == empresa;

                double costo = 0;
                if (index == 0) costo = 5.99;
                if (index == 1) costo = 9.99;
                if (index >= 2) costo = 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      empresa["nombre"],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(empresa["descripcion"] ?? ""),
                    trailing: Text(
                      costo == 0 ? "Gratis" : "€$costo",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    selected: seleccionada,
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
              "Total a pagar: €${(totalCarrito + precioEnvio).toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (metodoPago == null || empresaSeleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Completa todos los campos")),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Compra realizada con éxito")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Realizar Pedido",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
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
