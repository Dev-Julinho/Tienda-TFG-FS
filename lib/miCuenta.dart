import 'package:flutter/material.dart';

class MiCuentaPage extends StatelessWidget {
  const MiCuentaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo (puedes conectar con tu BD o API)
    final String nombre = "Juan Pérez";
    final String email = "juanperez@example.com";
    final String telefono = "+34 600 123 456";
    final String imagenPerfil =
        "https://i.pravatar.cc/300"; // Imagen de perfil de prueba

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Cuenta"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto de perfil
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(imagenPerfil),
            ),
            const SizedBox(height: 20),

            // Nombre
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // Email
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 30),

            // Tarjeta con datos
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sesión cerrada"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Cerrar sesión",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
