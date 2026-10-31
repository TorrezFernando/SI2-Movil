import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/push_service.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final push = context.watch<PushService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.notifications_outlined, size: 64),
          const SizedBox(height: 24),
          Text(
            'Recordatorios de cuotas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Recibe avisos de cuotas próximas a vencer o pendientes. Al tocar un aviso se abre tu estado de cuenta.',
          ),
          const SizedBox(height: 24),
          Text(push.status),
          const SizedBox(height: 16),
          if (push.busy) const LinearProgressIndicator(),
          FilledButton(
            onPressed: !push.ready || push.busy ? null : push.activate,
            child: const Text('Activar / sincronizar'),
          ),
          OutlinedButton(
            onPressed: !push.ready || push.busy ? null : push.disable,
            child: const Text('Desactivar en este dispositivo'),
          ),
        ],
      ),
    );
  }
}
