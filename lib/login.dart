import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:TFGPruebas/registro.dart';
import 'package:TFGPruebas/tutorial.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  final String apiUrl = "http://185.189.221.84/api.php/records/Cliente";

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      IOClient ioClient = IOClient(httpClient);

      final response = await ioClient.get(
        Uri.parse(
            "https://185.189.221.84/api.php/records/Cliente?filter[]=email,eq,$email&filter[]=contrasena,eq,$password"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["records"].isNotEmpty) {
          final user = data["records"][0];
          SharedPreferences prefs = await SharedPreferences.getInstance();

          int idCliente = user["id_cliente"];

          await prefs.setInt("id_cliente", idCliente);
          await prefs.setString("userNombre", user["nombre"]);
          await prefs.setString("userEmail", user["email"]);

          if (_rememberMe) {
            await prefs.setBool("isLoggedIn", true);
          }

          String claveTutorial = "tutorial_visto_$idCliente";

          bool tutorialVisto = prefs.getBool(claveTutorial) ?? false;

          if (!tutorialVisto) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TutorialPage(
                idCliente: idCliente,
              )),
            );
          } else {
            Navigator.pushReplacementNamed(context, "/home");
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales incorrectas')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error del servidor: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Container(color: Colors.black),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const Text(
                        'Entrena. Mejora. Supera.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                          _inputDecoration('Correo electrónico', Icons.email),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Contraseña',
                            Icons.lock,
                            suffix: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                              checkColor: Colors.black,
                              activeColor: const Color(0xFF007BFF),
                            ),
                            const Text("Recordarme",
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : Ink(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF007BFF),
                                    Color(0xFF0056B3)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.all(
                                    Radius.circular(14)),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PantallaRegistro()));
                        },
                        child: const Text('Crear cuenta',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
        const BorderSide(color: Color(0xFF5BD1E5), width: 1.5),
      ),
    );
  }
}