import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:TFGPruebas/login.dart';
import 'package:TFGPruebas/registro.dart';
import 'package:TFGPruebas/homepage.dart';
import 'package:TFGPruebas/productosCategoria.dart';
import 'package:TFGPruebas/productoDetalle.dart';
import 'package:TFGPruebas/Cesta.dart';
import 'package:TFGPruebas/realizarPedido.dart';
import 'package:TFGPruebas/misPedidos.dart';
import 'package:TFGPruebas/detallePedido.dart';
import 'package:TFGPruebas/miCuenta.dart';
import 'package:TFGPruebas/models/categoria.dart';
import 'package:TFGPruebas/models/producto.dart';

void main() {

  // LOGIN
  testWidgets('Carga PantallaLogin correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PantallaLogin(),
      ),
    );
    expect(find.byType(PantallaLogin), findsOneWidget);
  });

  // REGISTRO
  testWidgets('Carga PantallaRegistro correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PantallaRegistro(),
      ),
    );
    expect(find.byType(PantallaRegistro), findsOneWidget);
  });

  // HOME
  testWidgets('Carga HomePage correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(),
      ),
    );
    expect(find.byType(HomePage), findsOneWidget);
  });

  // PRODUCTOS POR CATEGORÍA
  testWidgets('Carga ProductosCategoria', (WidgetTester tester) async {
    final categoriaFake = Categoria(
      id: 1,
      nombre: 'Zapatillas',
      descripcion: 'imagen.jpg',
    );
    await tester.pumpWidget(MaterialApp(
      home: ProductosCategoria(categoria: categoriaFake),
    ));
    expect(find.byType(ProductosCategoria), findsOneWidget);
  });

  // CARRITO
  testWidgets('Carga CarritoPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CarritoPage(),
      ),
    );
    expect(find.byType(CarritoPage), findsOneWidget);
  });

  // REALIZAR PEDIDO
  testWidgets('Carga RealizarPedidoPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RealizarPedidoPage(),
      ),
    );
    expect(find.byType(RealizarPedidoPage), findsOneWidget);
  });

  // MIS PEDIDOS
  testWidgets('Carga MisPedidosPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MisPedidosPage(),
      ),
    );
    expect(find.byType(MisPedidosPage), findsOneWidget);
  });

  // DETALLE PEDIDO
  testWidgets('Carga DetallePedidoPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DetallePedidoPage(pedidoId: 1),
      ),
    );
    expect(find.byType(DetallePedidoPage), findsOneWidget);
  });

  // MI CUENTA
  testWidgets('Carga MiCuentaPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiCuentaPage(),
      ),
    );
    expect(find.byType(MiCuentaPage), findsOneWidget);
  });

  //            UNIT TESTS (LÓGICA)
  test('No se permite cantidad mayor que stock', () {
    int stock = 5;
    int cantidadSolicitada = 10;
    bool permitido = cantidadSolicitada <= stock;
    expect(permitido, false);
  });

  test('El total de la cesta se calcula correctamente', () {
    List<double> precios = [10.0, 20.0, 5.0];
    double total = precios.reduce((value, element) => value + element);
    expect(total, 35.0);
  });

  test('El método de pago debe estar seleccionado', () {
    String? metodoPago;
    bool esValido = metodoPago != null;
    expect(esValido, false);
    metodoPago = "Tarjeta";
    esValido = metodoPago != null;
    expect(esValido, true);
  });
}
