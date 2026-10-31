import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../data/models/cuenta_model.dart';
import '../../data/services/operaciones_service.dart';

class CuentaScreen extends StatefulWidget {
  const CuentaScreen({super.key});
  @override
  State<CuentaScreen> createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  List<ContratoModel>? _contratos;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<OperacionesService>().cuenta();
      if (mounted) setState(() => _contratos = result);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeOperacion(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi estado de cuenta'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                  if (_contratos != null)
                    const Text(
                      'Se muestran los datos de la consulta anterior. No se pudieron actualizar.',
                    ),
                ],
                const Text(
                  'Importes en la moneda acordada en cada contrato. Los recibos de demostración no representan cobros bancarios.',
                ),
                const SizedBox(height: 16),
                if (_contratos?.isEmpty == true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'Todavía no tienes contratos asociados. La inmobiliaria debe registrar tu contrato para mostrar cuotas y pagos.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final c in _contratos ?? <ContratoModel>[])
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contrato #${c.id} · ${c.tipo}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Saldo pendiente: ${importe(c.saldo)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Total: ${importe(c.monto)} · Pagado: ${importe(c.pagado)}',
                          ),
                          const Divider(height: 32),
                          Text(
                            'Cuotas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (!c.cronogramaDisponible)
                            const Text(
                              'Este contrato no tiene un cronograma registrado. Consulta con la inmobiliaria.',
                            ),
                          for (final q in c.cuotas)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                q.estado == 'pagada'
                                    ? Icons.check_circle_outline
                                    : q.estado == 'vencida'
                                    ? Icons.error_outline
                                    : Icons.schedule,
                              ),
                              title: Text('Cuota ${q.numero} · ${q.estado}'),
                              subtitle: Text(
                                'Vence ${fechaCorta(q.vencimiento)}\nImporte ${importe(q.monto)} · Abonado ${importe(q.pagado)}\nSaldo ${importe(q.saldo)}',
                              ),
                            ),
                          const Divider(height: 32),
                          Text(
                            'Pagos y recibos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (c.pagos.isEmpty)
                            const Text('No hay pagos registrados.'),
                          for (final p in c.pagos)
                            _ReciboTile(key: ValueKey(p.id), pago: p),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class _ReciboTile extends StatefulWidget {
  const _ReciboTile({super.key, required this.pago});
  final PagoModel pago;
  @override
  State<_ReciboTile> createState() => _ReciboTileState();
}

class _ReciboTileState extends State<_ReciboTile> {
  bool _busy = false;
  Future<void> _run(bool email) async {
    setState(() => _busy = true);
    final api = context.read<OperacionesService>();
    try {
      if (email) {
        final recipient = await api.enviarRecibo(widget.pago.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El servidor de correo aceptó el envío a $recipient. Revisa también spam.',
              ),
            ),
          );
        }
      } else {
        final bytes = await api.recibo(widget.pago.id);
        if (mounted) {
          await Printing.sharePdf(
            bytes: bytes,
            filename: 'recibo-${widget.pago.id}.pdf',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeOperacion(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.pago.recibo ?? 'Pago #${widget.pago.id}'} · ${importe(widget.pago.monto)}',
        ),
        Text(
          widget.pago.fecha == null
              ? 'Fecha no registrada'
              : fechaCorta(widget.pago.fecha!),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(false),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar PDF'),
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _run(true),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Enviar a mi correo'),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
