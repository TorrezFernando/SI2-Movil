import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inmobiliaria_mobile/data/models/cuenta_model.dart';
import 'package:inmobiliaria_mobile/data/services/operaciones_service.dart';
import 'package:inmobiliaria_mobile/presentation/screens/cuenta_screen.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

Map<String, dynamic> contrato() => {
  'id_contrato': 12,
  'tipo': 'Alquiler',
  'monto_total': '100.00',
  'pagado': '33.33',
  'saldo': '66.67',
  'cronograma_disponible': true,
  'cuotas': [
    {
      'id': 2,
      'numero': 2,
      'vencimiento': '2026-11-30',
      'monto': '33.33',
      'pagado': '0',
      'saldo': '33.33',
      'estado': 'pendiente',
    },
    {
      'id': 1,
      'numero': 1,
      'vencimiento': '2026-10-31',
      'monto': '33.33',
      'pagado': '33.33',
      'saldo': '0',
      'estado': 'pagada',
    },
  ],
  'pagos': [
    {'id_pago': 1, 'monto': '10.00', 'fecha': null, 'recibo': null},
    {
      'id_pago': 2,
      'monto': '23.33',
      'fecha': '2026-10-29T12:00:00',
      'recibo': 'DEMO-1-2',
    },
  ],
};

void main() {
  test('Importes exactos y rechazo de valores corruptos', () {
    expect(centavos('0.01'), 1);
    expect(centavos('9999999999.99'), 999999999999);
    expect(centavos(10.5), 1050);
    expect(importe(3333 + 3333 + 3334), '100.00');
    for (final invalid in [null, '-1', 'NaN', '1.001']) {
      expect(() => centavos(invalid), throwsFormatException);
    }
  });

  test('Contrato ordena cuotas y pagos y admite recibo/fecha ausentes', () {
    final c = ContratoModel.fromJson(contrato());
    expect(c.saldo, 6667);
    expect(c.cuotas.first.numero, 1);
    expect(c.pagos.first.id, 2);
    expect(c.pagos.last.recibo, isNull);
  });

  test('Tasación rechaza un rango inconsistente', () {
    expect(
      () => TasacionModel.fromJson({
        'minimo': '100',
        'estimado': '90',
        'maximo': '110',
        'explicacion': 'Ejemplo',
      }),
      throwsFormatException,
    );
  });

  test(
    'Servicios usan el contrato de API y no envían identidad arbitraria',
    () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter((o) {
        if (o.path == '/api/mi-cuenta') {
          expect(o.queryParameters, isEmpty);
          return jsonBody({
            'contratos': [contrato()],
          });
        }
        expect(o.path, '/api/ia/tasaciones');
        expect(o.data, {'id_propiedad': 17});
        return jsonBody({
          'minimo': '80',
          'estimado': '100',
          'maximo': '120',
          'explicacion': 'Comparables internos',
        });
      });
      final api = OperacionesService(dio);
      expect((await api.cuenta()).single.id, 12);
      expect((await api.tasar(17)).estimado, 10000);
    },
  );

  test('PDF valida contenido; correo exige confirmación SMTP', () async {
    final dio = Dio();
    dio.httpClientAdapter = FakeAdapter((o) {
      if (o.path.endsWith('.pdf'))
        return ResponseBody.fromBytes(utf8.encode('%PDF-1.7\ntest'), 200);
      return jsonBody({
        'estado': 'aceptado_por_smtp',
        'destinatario': 'cliente@example.test',
      });
    });
    final api = OperacionesService(dio);
    expect(String.fromCharCodes((await api.recibo(2)).take(5)), '%PDF-');
    expect(await api.enviarRecibo(2), 'cliente@example.test');
    dio.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({'estado': 'pendiente'}),
    );
    await expectLater(api.recibo(2), throwsFormatException);
    await expectLater(api.enviarRecibo(2), throwsFormatException);
  });

  test(
    'Errores del backend conservan explicación del plan o comparables',
    () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter(
        (_) => jsonBody({'detail': 'Se requieren tres comparables.'}, 422),
      );
      try {
        await OperacionesService(dio).tasar(1);
        fail('Se esperaba un error');
      } catch (e) {
        expect(mensajeOperacion(e), 'Se requieren tres comparables.');
      }
    },
  );

  testWidgets('Cuenta permite reintentar y muestra estado vacío', (
    tester,
  ) async {
    var requests = 0;
    final dio = Dio();
    dio.httpClientAdapter = FakeAdapter(
      (_) => ++requests == 1
          ? jsonBody({'detail': 'Error temporal'}, 503)
          : jsonBody({'contratos': []}),
    );
    await tester.pumpWidget(
      Provider.value(
        value: OperacionesService(dio),
        child: const MaterialApp(home: CuentaScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Error temporal'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no tienes contratos'), findsOneWidget);
  });

  testWidgets('Cuenta muestra cuotas y acciones de recibos del servidor', (
    tester,
  ) async {
    final dio = Dio();
    dio.httpClientAdapter = FakeAdapter(
      (_) => jsonBody({
        'contratos': [contrato()],
      }),
    );
    await tester.pumpWidget(
      Provider.value(
        value: OperacionesService(dio),
        child: const MaterialApp(home: CuentaScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saldo pendiente: 66.67'), findsOneWidget);
    expect(find.text('Cuota 1 · pagada'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Descargar PDF').first, 200);
    expect(find.textContaining('DEMO-1-2'), findsOneWidget);
    expect(find.text('Enviar a mi correo'), findsWidgets);
  });
}
