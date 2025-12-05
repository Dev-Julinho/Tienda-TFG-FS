class Pedido {
  final int idPedido;
  final String fecha;
  final int idMetodoPago;

  String? primerProductoNombre;
  int? primerProductoId;
  String? nombreEmpresa; // ahora viene de ENVIO

  Pedido({
    required this.idPedido,
    required this.fecha,
    required this.idMetodoPago,
    this.primerProductoId,
    this.primerProductoNombre,
    this.nombreEmpresa,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: int.tryParse(json["id_pedido"]?.toString() ?? '0') ?? 0,
      fecha: json["fecha_pedido"]?.toString() ?? "",
      idMetodoPago:
      int.tryParse(json["id_metodo_pago"]?.toString() ?? '0') ?? 0,
    );
  }
}
