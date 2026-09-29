import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/plant.dart';
import '../../auth/providers/auth_provider.dart';

class WaterSourcesAdminScreen extends StatefulWidget {
  const WaterSourcesAdminScreen({super.key});

  @override
  State<WaterSourcesAdminScreen> createState() => _WaterSourcesAdminScreenState();
}

class _WaterSourcesAdminScreenState extends State<WaterSourcesAdminScreen> {
  List<WaterSource> _sources = [];
  List<Plant> _plants = [];
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
      final results = await Future.wait([
        api.getSources(),
        api.getPlants(),
      ]);
      if (!mounted) return;
      setState(() {
        _sources = results[0] as List<WaterSource>;
        _plants = results[1] as List<Plant>;
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

  Future<void> _createOrEdit({WaterSource? existing}) async {
    if (_plants.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay plantas disponibles. Cree una planta primero.'),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String dialogTipo = existing?.tipo ?? 'GRIFO';
        String dialogPlanta = existing?.plantaId ?? _plants.first.id;
        final dialogNombreController = TextEditingController(text: existing?.nombre ?? '');
        final dialogUbicacionController = TextEditingController(text: existing?.ubicacion ?? '');

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Nueva fuente de agua' : 'Editar fuente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dialogNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'ej: Grifo de cocina, Pozo norte',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dialogUbicacionController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación (opcional)',
                      hintText: 'ej: Planta baja - cocina',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: dialogTipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: ['GRIFO', 'POZO', 'RIO', 'LAGO', 'OTRO']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => dialogTipo = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: dialogPlanta,
                    decoration: const InputDecoration(
                      labelText: 'Planta',
                      prefixIcon: Icon(Icons.factory),
                    ),
                    items: _plants
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => dialogPlanta = v!),
                  ),
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
                  if (dialogNombreController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'nombre': dialogNombreController.text.trim(),
                    'ubicacion': dialogUbicacionController.text.trim(),
                    'tipo': dialogTipo,
                    'planta_id': dialogPlanta,
                  });
                },
                child: Text(existing == null ? 'Crear' : 'Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      await _saveSource(
        nombre: result['nombre']!,
        ubicacion: result['ubicacion']!.isEmpty ? null : result['ubicacion'],
        tipo: result['tipo']!,
        plantaId: result['planta_id']!,
        existing: existing,
      );
    }
  }

  Future<void> _saveSource({
    required String nombre,
    String? ubicacion,
    required String tipo,
    required String plantaId,
    WaterSource? existing,
  }) async {
    try {
      final api = context.read<AuthProvider>().api;

      if (existing == null) {
        await api.createSource(plantaId, nombre, tipo, ubicacion: ubicacion);
      } else {
        await api.updateSource(
          existing.id,
          nombre,
          tipo,
          ubicacion: ubicacion,
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Fuente "$nombre" creada'
              : 'Fuente "$nombre" actualizada'),
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

  Future<void> _delete(WaterSource source) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar fuente de agua'),
        content: Text('¿Eliminar "${source.nombre}"? No se puede deshacer.'),
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
      await api.deleteSource(source.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${source.nombre}" eliminado')),
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

  IconData _iconForType(String tipo) {
    switch (tipo) {
      case 'GRIFO':
        return Icons.water_drop;
      case 'POZO':
        return Icons.opacity;
      case 'RIO':
        return Icons.waves;
      case 'LAGO':
        return Icons.pool;
      default:
        return Icons.water_drop_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuentes de Agua'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createOrEdit(),
            tooltip: 'Nueva fuente de agua',
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
              : _sources.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_drop_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No hay fuentes de agua'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Crear la primera'),
                            onPressed: () => _createOrEdit(),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _sources.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final source = _sources[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              _iconForType(source.tipo),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(source.nombre),
                          subtitle: Text(
                            '${source.tipo} · ${_plants.firstWhere((p) => p.id == source.plantaId, orElse: () => Plant(id: '', tenantId: '', nombre: 'Desconocida', activa: false, createdAt: '')).nombre}${source.ubicacion != null ? ' · ${source.ubicacion}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _createOrEdit(existing: source),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Theme.of(context).colorScheme.error),
                                onPressed: () => _delete(source),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}