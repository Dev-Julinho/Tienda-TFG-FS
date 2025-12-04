import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CambiarDatosClientePage extends StatefulWidget {
  const CambiarDatosClientePage({super.key});

  @override
  State<CambiarDatosClientePage> createState() =>
      _CambiarDatosClientePageState();
}

class _CambiarDatosClientePageState extends State<CambiarDatosClientePage> {
  late IOClient ioClient;

  TextEditingController nombreController = TextEditingController();
  TextEditingController apellidosController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contrasenaController = TextEditingController();
  TextEditingController telefonoController = TextEditingController();
  TextEditingController direccionController = TextEditingController();
  TextEditingController ciudadController = TextEditingController();
  TextEditingController codigoPostalController = TextEditingController();
  TextEditingController paisController = TextEditingController();

  bool cargando = true;
  final String apiUrl = "https://185.189.221.84/api.php/records/Cliente";

  @override
  void initState() {
    super.initState();

    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    ioClient = IOClient(httpClient);

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCliente = prefs.getInt("id_cliente");

    if (idCliente == null) {
      setState(() => cargando = false);
      return;
    }

    final res = await ioClient.get(Uri.parse("$apiUrl/$idCliente"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      nombreController.text = data['nombre'] ?? "";
      apellidosController.text = data['apellidos'] ?? "";
      emailController.text = data['email'] ?? "";
      contrasenaController.text = data['contrasena'] ?? "";
      telefonoController.text = data['telefono'] ?? "";
      direccionController.text = data['direccion'] ?? "";
      ciudadController.text = data['ciudad'] ?? "";
      codigoPostalController.text = data['codigoPostal'] ?? "";
      paisController.text = data['pais'] ?? "";
    }

    setState(() => cargando = false);
  }

  Future<void> _modificarDatos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCliente = prefs.getInt("id_cliente");

    if (idCliente == null) return;

    final body = jsonEncode({
      "nombre": nombreController.text.trim(),
      "apellidos": apellidosController.text.trim(),
      "email": emailController.text.trim(),
      "contrasena": contrasenaController.text.trim(),
      "telefono": telefonoController.text.trim(),
      "direccion": direccionController.text.trim(),
      "ciudad": ciudadController.text.trim(),
      "codigoPostal": codigoPostalController.text.trim(),
      "pais": paisController.text.trim(),
    });

    final res = await ioClient.put(
      Uri.parse("$apiUrl/$idCliente"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos modificados correctamente")),
      );

      Navigator.pop(context); // Vuelve a miCuenta.dart
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al modificar los datos")),
      );
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
        backgroundColor: const Color(0xFF00122B),
        centerTitle: true,
        title: const Text(
          "Modificar datos",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: apellidosController,
              decoration: const InputDecoration(labelText: "Apellidos"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: contrasenaController,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: "Teléfono"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: direccionController,
              decoration: const InputDecoration(labelText: "Dirección"),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: ciudadController,
              decoration: const InputDecoration(labelText: "Ciudad"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: codigoPostalController,
              decoration: const InputDecoration(labelText: "Código Postal"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: paisController,
              decoration: const InputDecoration(labelText: "País"),
            ),
            const SizedBox(height: 15),

            // Botón cancelar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón modificar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _modificarDatos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Modificar datos",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}