import 'package:flutter/material.dart';

//////////////////////////////////////////////////////////
///                PÁGINA DEL CARRITO                  ///
//////////////////////////////////////////////////////////

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  _CarritoPageState createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  // Ejemplo de productos en el carrito
  List<Map<String, dynamic>> carrito = [
    {
      "nombre": "Producto 1",
      "precio": 25.99,
      "cantidad": 1,
    },
    {
      "nombre": "Producto 2",
      "precio": 14.50,
      "cantidad": 2,
    },
  ];

  double get total {
    return carrito.fold(
      0,
          (suma, item) => suma + (item["precio"] * item["cantidad"]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Carrito"),
        centerTitle: true,
      ),
      body: carrito.isEmpty
          ? _carritoVacio()
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: carrito.length,
              itemBuilder: (context, index) {
                final item = carrito[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.shopping_bag, color: Colors.blue),
                    ),
                    title: Text(item["nombre"],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "€${item["precio"].toStringAsFixed(2)} • Cantidad: ${item["cantidad"]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          carrito.removeAt(index);
                        });
                      },
                    ),
                    onTap: () {
                      _cambiarCantidad(index);
                    },
                  ),
                );
              },
            ),
          ),

          // TOTAL Y BOTÓN DE PAGO
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -3),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:",
                        style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      "€${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Compra realizada con éxito")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Finalizar compra",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Vista cuando el carrito está vacío
  Widget _carritoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text("Tu carrito está vacío",
              style: TextStyle(fontSize: 22, color: Colors.grey)),
        ],
      ),
    );
  }

  // Cambiar cantidad del producto
  void _cambiarCantidad(int index) {
    showDialog(
      context: context,
      builder: (context) {
        int cantidadTemp = carrito[index]["cantidad"];
        return AlertDialog(
          title: Text("Cantidad de ${carrito[index]["nombre"]}"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    if (cantidadTemp > 1) cantidadTemp--;
                  });
                },
              ),
              Text(cantidadTemp.toString(),
                  style: const TextStyle(fontSize: 22)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    cantidadTemp++;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () {
                setState(() {
                  carrito[index]["cantidad"] = cantidadTemp;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
