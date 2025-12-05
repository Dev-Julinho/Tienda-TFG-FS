class Envio {
  final int idEnvio;
  final int idPedido;
  final int idEmpresa;
  final String? direccion;

  Envio({
    required this.idEnvio,
    required this.idPedido,
    required this.idEmpresa,
    this.direccion,
  });

  factory Envio.fromJson(Map<String, dynamic> json) {
    return Envio(
      idEnvio: int.tryParse(json["id_envio"]?.toString() ?? '0') ?? 0,
      idPedido: int.tryParse(json["id_pedido"]?.toString() ?? '0') ?? 0,
      idEmpresa: int.tryParse(json["id_empresa"]?.toString() ?? '0') ?? 0,
      direccion: json["direccion"]?.toString(),
    );
  }
}
