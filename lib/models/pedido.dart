class Pedido {
  final int idPedido;
  final String fecha;
  final int idMetodoPago;
  final int idEmpresa;
  String? primerProductoNombre;
  String? primerProductoImagen;

  Pedido({
    required this.idPedido,
    required this.fecha,
    required this.idMetodoPago,
    required this.idEmpresa,
    this.primerProductoNombre,
    this.primerProductoImagen,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: int.tryParse(json["id_pedido"]?.toString() ?? '0') ?? 0,
      fecha: json["fecha_pedido"]?.toString() ?? "",
      idMetodoPago: int.tryParse(json["id_metodo_pago"]?.toString() ?? '0') ?? 0,
      idEmpresa: int.tryParse(json["id_empresa"]?.toString() ?? '0') ?? 0,
    );
  }
}
