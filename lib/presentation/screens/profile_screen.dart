import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(radius: 38, child: Text(user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase())),
          const SizedBox(height: 16),
          Center(child: Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall)),
          Center(child: Text(user.email)),
          const SizedBox(height: 28),
          Text('Información de cuenta', style: Theme.of(context).textTheme.titleLarge),
          ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('ID de usuario'), trailing: Text('${user.id}')),
          ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('Estado'), trailing: Text(user.isActive ? 'Activo' : 'Inactivo')),
          const SizedBox(height: 12),
          Text('Roles y permisos', style: Theme.of(context).textTheme.titleLarge),
          if (user.roles.isEmpty) const ListTile(title: Text('Sin roles asignados')),
          ...user.roles.map((role) => Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(role.name),
                  subtitle: Text(role.permissions.isEmpty ? 'Sin permisos' : role.permissions.join(' · ')),
                ),
              )),
        ],
      ),
    );
  }
}