import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'misPedidos.dart';
import 'cambiarDatosCliente.dart';

class MiCuentaPage extends StatefulWidget {
  const MiCuentaPage({super.key});

  @override
  State<MiCuentaPage> createState() => _MiCuentaPageState();
}

class _MiCuentaPageState extends State<MiCuentaPage> {
  late IOClient ioClient;
  String nombre = "";
  String email = "";
  String telefono = "";
  String direccion = "";
  bool cargando = true;

  final String apiUrl = "https://185.189.221.84/api.php/records/Cliente";

  @override
  void initState() {
    super.initState();

    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    ioClient = IOClient(httpClient);

    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idCliente = prefs.getInt("id_cliente");

    if (idCliente == null) {
      setState(() => cargando = false);
      return;
    }

    final res = await ioClient.get(Uri.parse("$apiUrl/$idCliente"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        nombre = data['nombre'] ?? "";
        email = data['email'] ?? "";
        telefono = data['telefono'] ?? "";
        direccion = data['direccion'] ?? "";
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
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
          "Mi Cuenta",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                  "https://api.dicebear.com/6.x/identicon/png?seed=${DateTime.now().millisecondsSinceEpoch}"),
            ),
            const SizedBox(height: 20),

            Text(
              nombre,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 28),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            telefono,
                            style: const TextStyle(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 25),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 28),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 25),
                    Row(
                      children: [
                        const Icon(Icons.directions, size: 28),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            direccion,
                            style: const TextStyle(fontSize: 17),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MisPedidosPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B5EB6), Color(0xFF002B51)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.receipt_long,
                        color: Colors.white, size: 30),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Mis pedidos",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CambiarDatosClientePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Cambiar datos",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("isLoggedIn", false);

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Cerrar sesión",
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