import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantController = TextEditingController();
  bool _isLoading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadTenantId();
  }

  Future<void> _loadTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('tenant_id') ?? '';
    _tenantController.text = tenantId;
    setState(() => _isLoading = false);
  }

  Future<void> _saveTenantId() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tenant_id', _tenantController.text.trim());

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  void dispose() {
    _tenantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: Company
                    Text(
                      'Empresa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Identificador de tu empresa en el sistema. '
                      'Se utiliza para conectar con la base de datos correcta.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _tenantController,
                      decoration: const InputDecoration(
                        labelText: 'ID de Empresa',
                        prefixIcon: Icon(Icons.business),
                        hintText: 'ej: empresa-abc',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresá el ID de tu empresa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton.icon(
                      onPressed: _saveTenantId,
                      icon: Icon(_saved ? Icons.check : Icons.save),
                      label: Text(_saved ? 'Guardado' : 'Guardar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
