import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/cuenta_model.dart';

String mensajeOperacion(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    switch (error.response?.statusCode) {
      case 401:
        return 'Tu sesión venció. Inicia sesión nuevamente.';
      case 403:
        return 'Tu cuenta o plan no permite esta operación.';
      case 404:
        return 'El recurso no está disponible para tu cuenta.';
      case 429:
        return 'Se alcanzó el límite de solicitudes. Intenta más tarde.';
      case 503:
        return 'El servicio todavía no está configurado en el servidor.';
    }
    return 'No se pudo contactar al servidor. Revisa tu conexión e intenta nuevamente.';
  }
  return 'No se pudo procesar la respuesta. Intenta nuevamente.';
}

class OperacionesService {
  OperacionesService(this.dio);
  final Dio dio;

  Future<List<ContratoModel>> cuenta() async {
    final response = await dio.get<Map<String, dynamic>>('/api/mi-cuenta');
    return (response.data!['contratos'] as List)
        .map((e) => ContratoModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<TasacionModel> tasar(int id) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/ia/tasaciones',
      data: {'id_propiedad': id},
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    return TasacionModel.fromJson(response.data!);
  }

  Future<Uint8List> recibo(int id) async {
    final response = await dio.get<List<int>>(
      '/api/pagos/$id/recibo.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data!);
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('El servidor no devolvió un PDF');
    }
    return bytes;
  }

  Future<String> enviarRecibo(int id) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/pagos/$id/enviar-recibo',
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    if (response.data!['estado'] != 'aceptado_por_smtp') {
      throw const FormatException('El servidor no confirmó el envío');
    }
    return response.data!['destinatario'] as String;
  }
}
