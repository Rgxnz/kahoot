import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pregunta.dart';

class CreateQuestionScreen extends StatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enunciadoController = TextEditingController();
  final List<TextEditingController> _opcionesControllers = 
      List.generate(4, (_) => TextEditingController());
  int _indiceCorrecto = 0;
  bool _isSaving = false;

  Future<void> _guardarPregunta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final nuevaPregunta = Pregunta(
        enunciado: _enunciadoController.text.trim(),
        opciones: _opcionesControllers.map((c) => c.text.trim()).toList(),
        indiceCorrecto: _indiceCorrecto,
      );

      await FirebaseFirestore.instance
          .collection('preguntas')
          .add(nuevaPregunta.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pregunta guardada con éxito')),
        );
        _limpiarFormulario();
      }
    } catch (e) {
      debugPrint('❌ ERROR FIRESTORE (guardarPregunta): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _limpiarFormulario() {
    _enunciadoController.clear();
    for (var controller in _opcionesControllers) {
      controller.clear();
    }
    setState(() => _indiceCorrecto = 0);
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    for (var controller in _opcionesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Pregunta'),
        backgroundColor: const Color(0xFF46178f),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _enunciadoController,
                decoration: const InputDecoration(
                  labelText: 'Enunciado de la pregunta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce la pregunta' : null,
              ),
              const SizedBox(height: 24),
              const Text('Opciones (marca la correcta):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _indiceCorrecto,
                        onChanged: (val) =>
                            setState(() => _indiceCorrecto = val!),
                        activeColor: const Color(0xFF46178f),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _opcionesControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Opción ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Rellena esta opción'
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _guardarPregunta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF46178f),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR PREGUNTA',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
