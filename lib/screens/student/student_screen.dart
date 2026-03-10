import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../game_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool isLoading = false;
  String? joinedGameId;

  void _joinGame() async {
    if (_codeController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el código y tu nombre')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final code = int.parse(_codeController.text);
      final gameId = await FirebaseService.joinGame(code, _nameController.text);
      setState(() {
        joinedGameId = gameId;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF46178f), Color(0xFF250850)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: joinedGameId == null ? _buildJoinForm() : _buildWaitingLobby(),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'KAHOOT!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF46178f),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PIN de Juego',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tu Apodo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _joinGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('¡LISTO!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingLobby() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseService.getGameStream(joinedGameId!),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final gameData = snapshot.data!.data() as Map<String, dynamic>;
          if (gameData['status'] == 'empezada') {
            // Sincronización instantánea: saltar a la pantalla de juego
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(gameId: joinedGameId!, isTeacher: false),
                  ),
                );
              }
            });
          }
        }

        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              '¡Ya estás dentro!',
              style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _nameController.text,
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Esperando a que el profesor inicie el juego...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        );
      },
    );
  }
}
