import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class AnalysisTypesAdminScreen extends StatefulWidget {
  const AnalysisTypesAdminScreen({super.key});

  @override
  State<AnalysisTypesAdminScreen> createState() => _AnalysisTypesAdminScreenState();
}

class _AnalysisTypesAdminScreenState extends State<AnalysisTypesAdminScreen> {
  List<AnalysisType> _analysisTypes = [];
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
      final types = await api.getAnalysisTypes();
      if (!mounted) return;
      setState(() {
        _analysisTypes = types;
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

  Future<void> _createOrEdit({AnalysisType? existing}) async {
    final controller = TextEditingController(text: existing?.nombre ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nuevo tipo de análisis' : 'Editar tipo'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: existing == null ? 'ej: Análisis de pH' : null,
            prefixIcon: const Icon(Icons.science_outlined),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(existing == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      await _saveAnalysisType(nombre: result, existing: existing);
    }
  }

  Future<void> _saveAnalysisType({
    required String nombre,
    AnalysisType? existing,
  }) async {
    try {
      final api = context.read<AuthProvider>().api;
      // Auto-generate code from name
      final codigo = nombre
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '')
          .substring(0, min(10, nombre.length));

      AnalysisType newType;
      if (existing == null) {
        newType = await api.createAnalysisType(
          codigo,
          nombre,
          requiereDescripcion: true,
        );
      } else {
        newType = await api.updateAnalysisType(
          existing.id,
          nombre,
          requiereDescripcion: true,
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Análisis "$nombre" creado'
              : 'Análisis "$nombre" actualizado'),
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

  Future<void> _delete(AnalysisType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tipo de análisis'),
        content: Text('¿Eliminar "${type.nombre}"? No se puede deshacer.'),
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
      await api.deleteAnalysisType(type.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${type.nombre}" eliminado')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de Análisis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createOrEdit(),
            tooltip: 'Nuevo tipo de análisis',
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
              : _analysisTypes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.science_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No hay tipos de análisis'),
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
                      itemCount: _analysisTypes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final type = _analysisTypes[index];
                        final isSystem =
                            ['CLORO', 'FQ', 'MB', 'OTRO'].contains(type.codigo);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSystem
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.tertiaryContainer,
                            child: Icon(
                              isSystem
                                  ? Icons.shield
                                  : Icons.science_outlined,
                              color: isSystem
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          title: Text(type.nombre),
                          subtitle: Text(
                            'Código: ${type.codigo}${isSystem ? ' · Sistema' : ' · Personalizado'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isSystem)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _createOrEdit(existing: type),
                                  tooltip: 'Editar',
                                ),
                              if (!isSystem)
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Theme.of(context).colorScheme.error),
                                  onPressed: () => _delete(type),
                                  tooltip: 'Eliminar',
                                ),
                              if (isSystem)
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