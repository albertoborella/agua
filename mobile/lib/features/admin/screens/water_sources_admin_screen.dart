import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/plant.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class WaterSourcesAdminScreen extends StatefulWidget {
  const WaterSourcesAdminScreen({super.key});

  @override
  State<WaterSourcesAdminScreen> createState() => _WaterSourcesAdminScreenState();
}

class _WaterSourcesAdminScreenState extends State<WaterSourcesAdminScreen> {
  List<Map<String, dynamic>> _sources = [];
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
        _sources = List<Map<String, dynamic>>.from(results[0]);
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

  Future<void> _showSourceDialog({Map<String, dynamic>? existing}) async {
    if (_plants.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay plantas disponibles. Cree una planta primero.'),
        ),
      );
      return;
    }

    final nombreController = TextEditingController(text: existing?['nombre'] ?? '');
    String localTipo = existing?['tipo'] ?? 'GRIFO';
    String localPlanta = existing?['planta_id'] ?? _plants.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) {
        String localTipo = existing?['tipo'] ?? 'GRIFO';
        String localPlanta = existing?['planta_id'] ?? _plants.first.id;
        final nombreController = TextEditingController(text: existing?['nombre'] ?? '');

        return AlertDialog(
          title: Text(existing == null ? 'Nueva fuente de agua' : 'Editar fuente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: existing?['nombre'] ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'ej: Grifo de cocina, Pozo norte',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: localTipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ['GRIFO', 'POZO', 'RIO', 'LAGO', 'OTRO']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => localTipo = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: localPlanta,
                  decoration: const InputDecoration(
                    labelText: 'Planta',
                    prefixIcon: Icon(Icons.factory),
                  ),
                  items: _plants
                      .whereType<Plant>().map((Plant p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                      .toList(),
                  onChanged: (v) => localPlanta = v!,
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
                final nombre = ''; // placeholder
                Navigator.pop(context, {
                  'nombre': nombre,
                  'tipo': localTipo,
                  'planta_id': localPlanta,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ).then((_) {
      // placeholder
    });
  }
}
