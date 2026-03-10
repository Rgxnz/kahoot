import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> loginAnonymously() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('DEBUG ERROR AUTH: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createGame() async {
    try {
      await loginAnonymously();
      int code = Random().nextInt(900000) + 100000;

      DocumentReference doc = await _db.collection('games').add({
        'code': code,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'id': doc.id,
        'code': code,
      };
    } catch (e) {
      debugPrint('DEBUG ERROR FIRESTORE (createGame): $e');
      rethrow;
    }
  }

  static Future<String> joinGame(int code, String name) async {
    try {
      await loginAnonymously();
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonimo';

      final query = await _db.collection('games')
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'waiting')
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Partida no encontrada o ya ha comenzado.');
      }

      String gameId = query.docs.first.id;
      
      // Comprobar si el jugador ya está en la partida
      final existingPlayer = await _db.collection('games')
          .doc(gameId)
          .collection('players')
          .where('uid', isEqualTo: userId)
          .get();

      if (existingPlayer.docs.isEmpty) {
        await _db.collection('games').doc(gameId).collection('players').add({
          'uid': userId,
          'name': name,
          'points': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      return gameId;
    } catch (e) {
      debugPrint('DEBUG ERROR FIRESTORE (joinGame): $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getPlayersStream(String gameId) {
    return _db.collection('games').doc(gameId).collection('players').orderBy('points', descending: true).snapshots();
  }

  static Stream<DocumentSnapshot> getGameStream(String gameId) {
    return _db.collection('games').doc(gameId).snapshots();
  }
}
