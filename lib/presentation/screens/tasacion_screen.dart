import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/cuenta_model.dart';
import '../../data/models/propiedad_model.dart';
import '../../data/services/operaciones_service.dart';

class TasacionScreen extends StatefulWidget {
  const TasacionScreen({super.key, required this.propiedad});
  final PropiedadModel propiedad;
  @override
  State<TasacionScreen> createState() => _TasacionScreenState();
}

class _TasacionScreenState extends State<TasacionScreen> {
  bool _loading = false;
  String? _error;
  TasacionModel? _result;

  Future<void> _tasar() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await context.read<OperacionesService>().tasar(
        widget.propiedad.idPropiedad,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeOperacion(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tasación con IA')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          widget.propiedad.titulo,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${widget.propiedad.direccion}\nOperación: ${widget.propiedad.tipoOperacion}',
        ),
        const SizedBox(height: 24),
        const Text(
          'Se utilizan los datos registrados del inmueble y al menos tres anuncios comparables de tu inmobiliaria. Esta función requiere plan Premium.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _tasar,
          icon: const Icon(Icons.auto_awesome),
          label: Text(_loading ? 'Calculando…' : 'Calcular estimación'),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_result case final result?) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Valor estimado'),
                  Text(
                    importe(result.estimado),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Rango: ${importe(result.minimo)} – ${importe(result.maximo)}',
                  ),
                  const Text(
                    'En la moneda del inmueble; no se realiza conversión.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(result.explicacion),
        ],
        const SizedBox(height: 24),
        const Text(
          'Estimación orientativa basada en anuncios internos, no en ventas verificadas. No es una tasación certificada y no modifica el precio publicado.',
        ),
      ],
    ),
  );
}
