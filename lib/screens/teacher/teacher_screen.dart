import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../game_screen.dart';
import 'create_question_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String? gameId;
  int? gameCode;
  bool isLoading = false;

  void _createGame() async {
    setState(() => isLoading = true);
    try {
      final gameData = await FirebaseService.createGame();
      setState(() {
        gameId = gameData['id'];
        gameCode = gameData['code'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startGame() async {
    if (gameId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .update({'status': 'empezada'});
      debugPrint("🔥 Partida iniciada correctamente");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(gameId: gameId!, isTeacher: true),
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG START GAME: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF46178f),
      appBar: AppBar(
        title: const Text('Panel del Profesor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: 'Crear Preguntas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateQuestionScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : gameId == null
                ? _buildCreateGameView()
                : _buildLobbyView(),
      ),
    );
  }

  Widget _buildCreateGameView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cast_for_education, size: 100, color: Colors.white),
        const SizedBox(height: 24),
        const Text(
          '¿Listo para empezar?',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _createGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF46178f),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('CREAR PARTIDA NUEVA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLobbyView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Text('PIN DEL JUEGO', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('$gameCode', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF46178f))),
            ],
          ),
        ),
        const Text('Alumnos conectados:', style: TextStyle(color: Colors.white, fontSize: 20)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.getPlayersStream(gameId!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
              final players = snapshot.data!.docs;
              
              if (players.isEmpty) {
                return const Center(child: Text('Esperando a que se unan...', style: TextStyle(color: Colors.white70)));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final name = players[index]['name'];
                  return Card(
                    color: Colors.white.withOpacity(0.2),
                    child: Center(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('¡EMPEZAR JUEGO!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}
