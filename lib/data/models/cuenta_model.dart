// Los importes del backend son decimales. Se conservan centavos exactos.
int centavos(Object? value) {
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch('$value');
  if (match == null) throw const FormatException('Importe inválido');
  return int.parse(match[1]!) * 100 +
      int.parse((match[2] ?? '').padRight(2, '0'));
}

String importe(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
String fechaCorta(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class CuotaModel {
  CuotaModel.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      numero = json['numero'] as int,
      vencimiento = DateTime.parse(json['vencimiento'] as String),
      monto = centavos(json['monto']),
      pagado = centavos(json['pagado']),
      saldo = centavos(json['saldo']),
      estado = json['estado'] as String;
  final int id, numero, monto, pagado, saldo;
  final DateTime vencimiento;
  final String estado;
}

class PagoModel {
  PagoModel.fromJson(Map<String, dynamic> json)
    : id = json['id_pago'] as int,
      monto = centavos(json['monto']),
      fecha = json['fecha'] == null
          ? null
          : DateTime.parse(json['fecha'] as String),
      recibo = json['recibo'] as String?;
  final int id, monto;
  final DateTime? fecha;
  final String? recibo;
}

class ContratoModel {
  ContratoModel.fromJson(Map<String, dynamic> json)
    : id = json['id_contrato'] as int,
      tipo = json['tipo'] as String,
      monto = centavos(json['monto_total']),
      pagado = centavos(json['pagado']),
      saldo = centavos(json['saldo']),
      cronogramaDisponible = json['cronograma_disponible'] as bool,
      cuotas = (json['cuotas'] as List)
          .map((e) => CuotaModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pagos = (json['pagos'] as List)
          .map((e) => PagoModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() {
    cuotas.sort((a, b) => a.vencimiento.compareTo(b.vencimiento));
    pagos.sort(
      (a, b) =>
          (b.fecha ?? DateTime(1970)).compareTo(a.fecha ?? DateTime(1970)),
    );
  }
  final int id, monto, pagado, saldo;
  final String tipo;
  final bool cronogramaDisponible;
  final List<CuotaModel> cuotas;
  final List<PagoModel> pagos;
}

class TasacionModel {
  TasacionModel.fromJson(Map<String, dynamic> json)
    : minimo = centavos(json['minimo']),
      estimado = centavos(json['estimado']),
      maximo = centavos(json['maximo']),
      explicacion = json['explicacion'] as String {
    if (minimo <= 0 || minimo > estimado || estimado > maximo) {
      throw const FormatException('Rango de tasación inválido');
    }
  }
  final int minimo, estimado, maximo;
  final String explicacion;
}
