import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/user.dart';
import '../../auth/providers/auth_provider.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final users = await api.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _createOrEdit({User? existing}) async {
    final usernameController = TextEditingController(text: existing?.username ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final passwordController = TextEditingController();
    String selectedRol = existing?.rol ?? 'OPERARIO';
    bool activo = existing?.activo ?? true;

    final roles = ['ADMIN', 'OPERARIO', 'LABORATORISTA'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nuevo usuario' : 'Editar usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing == null) ...[
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario *',
                      hintText: 'ej: juan.perez',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'ej: juan@empresa.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña *',
                      hintText: 'Mínimo 8 caracteres',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                ] else ...[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRol,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: roles.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedRol = v!),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Activo'),
                    value: activo,
                    onChanged: (v) => setDialogState(() => activo = v),
                    secondary: Icon(
                      activo ? Icons.check_circle : Icons.cancel,
                      color: activo ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Restablecer contraseña'),
                    onPressed: () => _resetPasswordDialog(existing),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (existing == null) {
                  if (usernameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completá todos los campos obligatorios')),
                    );
                    return;
                  }
                }
                Navigator.pop(context, {
                  'username': usernameController.text.trim(),
                  'email': emailController.text.trim(),
                  'password': passwordController.text.trim(),
                  'rol': selectedRol,
                  'activo': activo,
                });
              },
              child: Text(existing == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      if (existing == null) {
        await _saveUser(
          username: result['username'],
          email: result['email'],
          password: result['password'],
          rol: result['rol'],
        );
      } else {
        await _saveUser(
          existing: existing,
          email: result['email'],
          rol: result['rol'],
          activo: result['activo'],
        );
      }
    }
  }

  Future<void> _resetPasswordDialog(User user) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restablecer contraseña de ${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres')),
                );
                return;
              }
              if (controller.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden')),
                );
                return;
              }
              Navigator.pop(context, controller.text);
            },
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await _resetPassword(user.id, result);
    }
  }

  Future<void> _saveUser({
    String? username,
    String? email,
    String? password,
    String? rol,
    bool? activo,
    User? existing,
  }) async {
    try {
      final api = context.read<AuthProvider>().api;

      if (existing == null) {
        await api.createUser(username!, email!, password!, rol!);
      } else {
        await api.updateUser(
          existing.id,
          email: email,
          rol: rol,
          activo: activo,
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Usuario "$username" creado'
              : 'Usuario "${existing.username}" actualizado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _resetPassword(String userId, String newPassword) async {
    try {
      final api = context.read<AuthProvider>().api;
      await api.resetUserPassword(userId, newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña restablecida correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _delete(User user) async {
    // No permitir auto-eliminación
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser != null && currentUser.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No podés eliminarte a vos mismo')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar "${user.username}"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final api = context.read<AuthProvider>().api;
      await api.deleteUser(user.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${user.username}" eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Color _roleColor(String rol) {
    switch (rol) {
      case 'ADMIN':
        return Colors.red;
      case 'OPERARIO':
        return Colors.blue;
      case 'LABORATORISTA':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String rol) {
    switch (rol) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'OPERARIO':
        return Icons.engineering;
      case 'LABORATORISTA':
        return Icons.science;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createOrEdit(),
            tooltip: 'Nuevo usuario',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No hay usuarios'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Crear el primero'),
                            onPressed: () => _createOrEdit(),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isCurrentUser = context.read<AuthProvider>().user?.id == user.id;
                        final roleColor = _roleColor(user.rol);
                        final roleIcon = _roleIcon(user.rol);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Icon(
                              roleIcon,
                              color: roleColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(user.username)),
                              if (isCurrentUser)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Chip(
                                    label: Text('Vos', style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    child: Text(
                                      user.rol,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
decoration: BoxDecoration(
                                        color: user.activo
                                            ? Colors.green.withValues(alpha: 0.15)
                                            : Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    child: Text(
                                      user.activo ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: user.activo ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _createOrEdit(existing: user),
                                tooltip: 'Editar',
                              ),
                              if (!isCurrentUser)
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Theme.of(context).colorScheme.error),
                                  onPressed: () => _delete(user),
                                  tooltip: 'Eliminar',
                                ),
                              if (isCurrentUser)
                                const Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Icon(Icons.lock_outline, size: 20),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}