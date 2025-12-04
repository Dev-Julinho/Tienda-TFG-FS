import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';

import 'Cesta.dart';
import 'ProductosCategoria.dart';
import 'miCuenta.dart';
import 'models/categoria.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late IOClient ioClient;
  List<Categoria> categorias = [];
  late AnimationController _controller;

  final List<Color> borderColors = [
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.yellow.shade600,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    ioClient = IOClient(httpClient);

    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    categorias = await traerCategorias(ioClient: ioClient);
    _controller.forward();
    setState(() {});
  }

  Future<List<Categoria>> traerCategorias({required IOClient ioClient}) async {
    final res = await ioClient.get(
      Uri.parse("http://185.189.221.84/api.php/records/Categoria"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["records"] as List)
          .map((e) => Categoria.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  void dispose() {
    ioClient.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3ECF8),

      appBar: AppBar(
        backgroundColor: Color(0xFF00122B),
        elevation: 4,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'FitZone',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 90,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MiCuentaPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CarritoPage()),
              );
            },
          ),
        ],
      ),

      body: categorias.isEmpty
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final Color borderColor = borderColors[index % borderColors.length];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductosCategoria(categoria: categoria),
                ),
              );
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border(
                  left: BorderSide(color: borderColor, width: 5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parte superior con gradiente negro → color card
                  // Parte superior con gradiente más negro → color card
                  // Parte superior con negro dominante y difuminado sutil
                  // Parte superior con color del borde y difuminado hacia la card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          borderColor.withOpacity(0.95), // color dominante de la parte superior
                          borderColor.withOpacity(0.3),  // degradado hacia la card
                          Colors.white.withOpacity(0.05), // solo un toque hacia la card
                        ],
                        stops: [0.0, 0.7, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      categoria.nombre,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),


                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                    child: Image.network(
                      "https://185.189.221.84/images/c${categoria.id}.jpg",
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey.shade600, size: 40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
