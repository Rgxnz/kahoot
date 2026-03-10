import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pregunta.dart';
import 'results_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final bool isTeacher;

  const GameScreen({super.key, required this.gameId, required this.isTeacher});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Pregunta> preguntas = [];
  bool isLoading = true;
  String? error;
  int indicePreguntaActual = 0;
  int? indiceSeleccionado;
  bool yaRespondio = false;
  StreamSubscription? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
    _escucharCambiosPartida();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  void _escucharCambiosPartida() {
    _gameSubscription = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        
        if (data['status'] == 'finalizada') {
          _gameSubscription?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ResultsScreen(gameId: widget.gameId)),
            );
          }
          return;
        }

        final nuevoIndice = data['indicePreguntaActual'] ?? 0;
        if (nuevoIndice != indicePreguntaActual) {
          if (mounted) {
            setState(() {
              indicePreguntaActual = nuevoIndice;
              indiceSeleccionado = null;
              yaRespondio = false;
            });
          }
        }
      }
    });
  }

  Future<void> _cargarPreguntas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('preguntas')
          .get()
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          preguntas = snapshot.docs
              .map((doc) => Pregunta.fromMap(doc.id, doc.data()))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); isLoading = false; });
    }
  }

  Future<void> _enviarRespuesta(int indice) async {
    if (yaRespondio) return;

    final preguntaActual = preguntas[indicePreguntaActual];
    final esCorrecta = (indice == preguntaActual.indiceCorrecto);

    setState(() {
      indiceSeleccionado = indice;
      yaRespondio = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonimo';

      await FirebaseFirestore.instance.collection('respuestas').add({
        'idPartida': widget.gameId,
        'idPregunta': preguntaActual.id,
        'idAlumno': userId,
        'indiceRespuesta': indice,
        'esCorrecta': esCorrecta,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (esCorrecta) {
        final playerQuery = await FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .collection('players')
            .where('uid', isEqualTo: userId)
            .get();

        if (playerQuery.docs.isNotEmpty) {
          await playerQuery.docs.first.reference.update({
            'points': FieldValue.increment(100)
          });
        }
      }
    } catch (e) {
      debugPrint('DEBUG RESPUESTA ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacher ? 'Panel del Profesor' : '¡Responde!'),
        backgroundColor: const Color(0xFF46178f),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : _buildQuestionsView(),
    );
  }

  Widget _buildQuestionsView() {
    if (indicePreguntaActual >= preguntas.length) {
      return const Center(child: Text('Esperando al profesor...'));
    }

    final pregunta = preguntas[indicePreguntaActual];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(pregunta.enunciado, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: pregunta.opciones.length,
              itemBuilder: (context, index) {
                final esCorrecta = index == pregunta.indiceCorrecto;
                final esSeleccionada = indiceSeleccionado == index;
                
                Color colorBoton = Colors.white;
                if (yaRespondio) {
                  if (esSeleccionada) {
                    colorBoton = esCorrecta ? Colors.green : Colors.red;
                  } else if (esCorrecta) {
                    // Opcional: Mostrar la correcta en verde suave si el alumno falló
                    colorBoton = Colors.green.withOpacity(0.3);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: (widget.isTeacher || yaRespondio) ? null : () => _enviarRespuesta(index),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: colorBoton,
                      disabledBackgroundColor: colorBoton, // Para mantener el color cuando ya respondió
                      foregroundColor: yaRespondio && (esSeleccionada || (esCorrecta && colorBoton == Colors.green)) ? Colors.white : Colors.black87,
                      disabledForegroundColor: yaRespondio && esSeleccionada ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: yaRespondio && esSeleccionada ? Colors.transparent : const Color(0xFF46178f),
                        width: 2,
                      ),
                    ),
                    child: Text(pregunta.opciones[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          if (widget.isTeacher) 
            ElevatedButton(
              onPressed: () {
                final ref = FirebaseFirestore.instance.collection('games').doc(widget.gameId);
                if (indicePreguntaActual < preguntas.length - 1) {
                  ref.update({'indicePreguntaActual': indicePreguntaActual + 1});
                } else {
                  ref.update({'status': 'finalizada'});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: indicePreguntaActual < preguntas.length - 1 ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
              ),
              child: Text(indicePreguntaActual < preguntas.length - 1 ? 'SIGUIENTE PREGUNTA' : 'FINALIZAR PARTIDA'),
            ),
        ],
      ),
    );
  }
}
