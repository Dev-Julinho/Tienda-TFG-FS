class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int idCategoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.idCategoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json["id_producto"],
      nombre: json["nombre"],
      descripcion: json["descripcion"] ?? "",
      precio: double.tryParse(json["precio"].toString()) ?? 0,
      idCategoria: json["id_categoria"],
    );
  }
}
