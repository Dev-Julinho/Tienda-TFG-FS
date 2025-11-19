class Categoria {
  final int id;
  final String nombre;
  final String descripcion;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json["id_categoria"],
      nombre: json["nombre"],
      descripcion: json["descripcion"] ?? "",
    );
  }
}
