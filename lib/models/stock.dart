class Stock {
  final int idProducto;
  final int idTalla;
  final int cantidad;

  Stock({required this.idProducto, required this.idTalla, required this.cantidad});

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      idProducto: json["id_producto"],
      idTalla: json["id_talla"],
      cantidad: json["cantidad"],
    );
  }
}