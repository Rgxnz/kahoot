import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultsScreen extends StatelessWidget {
  final String gameId;

  const ResultsScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';

    return Scaffold(
      backgroundColor: const Color(0xFF46178f),
      appBar: AppBar(
        title: const Text('Resultados Finales', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            '¡PARTIDA FINALIZADA!',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Sección de Mis Estadísticas
          _buildMyStats(userId),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'RANKING GLOBAL',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('games')
                  .doc(gameId)
                  .collection('players')
                  .orderBy('points', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                
                final players = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final data = players[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Anónimo';
                    final points = data['points'] ?? 0;
                    final isMe = data['uid'] == userId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isMe ? Colors.white.withOpacity(0.9) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isMe ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index < 3 ? Colors.amber : Colors.grey[300],
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          name + (isMe ? ' (Tú)' : ''),
                          style: TextStyle(fontWeight: isMe ? FontWeight.w900 : FontWeight.bold),
                        ),
                        trailing: Text('$points pts', style: const TextStyle(fontSize: 18, color: Color(0xFF46178f), fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF46178f),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VOLVER AL INICIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMyStats(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('respuestas')
          .where('idPartida', isEqualTo: gameId)
          .where('idAlumno', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final respuestas = snapshot.data!.docs;
        if (respuestas.isEmpty) return const SizedBox.shrink();

        int correctas = respuestas.where((doc) => doc['esCorrecta'] == true).length;
        int incorrectas = respuestas.where((doc) => doc['esCorrecta'] == false).length;
        int total = respuestas.length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              const Text(
                'TUS ESTADÍSTICAS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(Icons.check_circle, Colors.green, 'Correctas', correctas),
                  _statItem(Icons.cancel, Colors.red, 'Fallos', incorrectas),
                  _statItem(Icons.percent, Colors.blue, 'Acierto', total > 0 ? ((correctas / total) * 100).toInt() : 0, isPercent: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(IconData icon, Color color, String label, int value, {bool isPercent = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          isPercent ? '$value%' : '$value',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
