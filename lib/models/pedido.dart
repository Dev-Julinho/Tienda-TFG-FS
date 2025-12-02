class Pedido {
  final int idPedido;
  final String fecha;
  final int idMetodoPago;
  final int idEmpresa;

  Pedido({
    required this.idPedido,
    required this.fecha,
    required this.idMetodoPago,
    required this.idEmpresa,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: int.tryParse(json["id_pedido"]?.toString() ?? '0') ?? 0,
      fecha: json["fecha_pedido"]?.toString() ?? "",
      idEmpresa: int.tryParse(json["id_empresa"]?.toString() ?? '0') ?? 0,
      idMetodoPago: int.tryParse(json["id_metodo_pago"]?.toString() ?? '0') ?? 0,
    );
  }
}
