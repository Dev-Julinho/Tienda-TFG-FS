class Talla {
  final int id;
  final String talla;

  Talla({required this.id, required this.talla});

  factory Talla.fromJson(Map<String, dynamic> json) {
    return Talla(
      id: json["id_talla"],
      talla: json["talla"],
    );
  }
}