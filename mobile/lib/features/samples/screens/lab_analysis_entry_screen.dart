import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/lab_sample.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/lab_provider.dart';

class LabAnalysisEntryScreen extends StatefulWidget {
  final LabSample sample;

  const LabAnalysisEntryScreen({super.key, required this.sample});

  @override
  State<LabAnalysisEntryScreen> createState() => _LabAnalysisEntryScreenState();
}

class _LabAnalysisEntryScreenState extends State<LabAnalysisEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Chlorine fields
  final _cloroController = TextEditingController();

  // General fields
  String? _selectedResultado;
  final _protocoloController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _cloroController.dispose();
    _protocoloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Color _getTipoColor() {
    switch (widget.sample.tipoAnalisisCodigo) {
      case 'CLORO':
        return Colors.blue;
      case 'FQ':
        return Colors.purple;
      case 'MB':
        return Colors.teal;
      case 'OTRO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon() {
    switch (widget.sample.tipoAnalisisCodigo) {
      case 'CLORO':
        return Icons.water_drop;
      case 'FQ':
        return Icons.science;
      case 'MB':
        return Icons.biotech;
      case 'OTRO':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<LabProvider>();

      if (widget.sample.isCloro) {
        final cloroNivel = double.parse(_cloroController.text.replaceAll(',', '.'));
        await provider.submitCloroAnalysis(widget.sample.id, cloroNivel);
      } else {
        await provider.submitGeneralAnalysis(
          sampleId: widget.sample.id,
          resultado: _selectedResultado!,
          protocoloNumero: _protocoloController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Análisis guardado correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoColor = _getTipoColor();
    final tipoIcon = _getTipoIcon();
    final isCloro = widget.sample.isCloro;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analizar: ${widget.sample.tipoAnalisisNombre}'),
        backgroundColor: tipoColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sample info card
              Card(
                color: tipoColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(tipoIcon, color: tipoColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.sample.tipoAnalisisNombre,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: tipoColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Fuente', widget.sample.fuenteNombre),
                      _buildInfoRow('Tipo', widget.sample.fuenteTipo),
                      _buildInfoRow('Operario', widget.sample.operarioUsername),
                      _buildInfoRow('Fecha toma', '${widget.sample.fecha} ${widget.sample.hora.substring(0, 5)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Analysis form
              Text(
                isCloro ? 'Análisis de Cloro' : 'Análisis General',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              if (isCloro) ...[
                // Chlorine analysis form
                TextFormField(
                  controller: _cloroController,
                  decoration: InputDecoration(
                    labelText: 'Nivel de Cloro (mg/L)',
                    hintText: 'Ej: 0.5 o 1.25',
                    prefixIcon: const Icon(Icons.water_drop),
                    border: const OutlineInputBorder(),
                    helperText: 'Valor numérico con 1 o 2 decimales',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nivel de cloro';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) {
                      return 'Ingrese un valor numérico válido';
                    }
                    if (parsed < 0) {
                      return 'El nivel no puede ser negativo';
                    }
                    // Check decimal places
                    final parts = value.replaceAll(',', '.').split('.');
                    if (parts.length > 1 && parts[1].length > 2) {
                      return 'Máximo 2 decimales';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Referencia: 0.2 - 1.5 mg/L (según normativa local)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ] else ...[
                // General analysis form (MB, FQ, OTRO)
                DropdownButtonFormField<String>(
                  value: _selectedResultado,
                  decoration: InputDecoration(
                    labelText: 'Resultado',
                    prefixIcon: const Icon(Icons.assignment_turned_in),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'APTA', child: Text('✅ Apta')),
                    DropdownMenuItem(value: 'NO_APTA', child: Text('❌ No Apta')),
                  ],
                  onChanged: (value) => setState(() => _selectedResultado = value),
                  validator: (value) {
                    if (value == null) return 'Seleccione el resultado';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _protocoloController,
                  decoration: InputDecoration(
                    labelText: 'Número de Protocolo *',
                    hintText: 'Ej: PROT-2024-00123',
                    prefixIcon: const Icon(Icons.numbers),
                    border: const OutlineInputBorder(),
                    helperText: 'Obligatorio para MB, FQ y otros análisis',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El número de protocolo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Observaciones adicionales...',
                    prefixIcon: const Icon(Icons.description),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              FilledButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isCloro ? Icons.water_drop : Icons.save),
                label: Text(_isSubmitting ? 'Guardando...' : 'Guardar Análisis'),
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: tipoColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}