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
      id: int.parse(json["id_producto"].toString()),
      nombre: json["nombre"] ?? "Sin nombre",
      descripcion: json["descripcion"] ?? "",
      precio: double.tryParse(json["precio"].toString()) ?? 0,
      idCategoria: int.parse(json["id_categoria"].toString()),
    );
  }
}
