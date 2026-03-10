import 'package:flutter/material.dart';
import 'student/student_screen.dart';
import 'teacher/teacher_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF46178f), Color(0xFF250850)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado o estilizado
              TweenAnimationBuilder(
                duration: const Duration(seconds: 1),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        size: 80,
                        color: Color(0xFF46178f),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'KAHOOT!',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              _buildNavButton(
                context,
                icon: Icons.school_rounded,
                label: 'MODO PROFESOR',
                subtitle: 'Crea y dirige la partida',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeacherScreen()),
                ),
                color: const Color(0xFF1368ce),
              ),
              const SizedBox(height: 20),
              _buildNavButton(
                context,
                icon: Icons.play_arrow_rounded,
                label: 'MODO ESTUDIANTE',
                subtitle: 'Únete con un PIN',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentScreen()),
                ),
                color: const Color(0xFF26890c),
              ),
              const SizedBox(height: 40),
              const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
