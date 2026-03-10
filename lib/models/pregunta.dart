class Pregunta {
  final String? id;
  final String enunciado;
  final List<String> opciones;
  final int indiceCorrecto;

  Pregunta({
    this.id,
    required this.enunciado,
    required this.opciones,
    required this.indiceCorrecto,
  });

  Map<String, dynamic> toMap() {
    return {
      'enunciado': enunciado,
      'opciones': opciones,
      'indiceCorrecto': indiceCorrecto,
    };
  }

  factory Pregunta.fromMap(String id, Map<String, dynamic> map) {
    return Pregunta(
      id: id,
      enunciado: map['enunciado'] ?? '',
      opciones: List<String>.from(map['opciones'] ?? []),
      indiceCorrecto: map['indiceCorrecto'] ?? 0,
    );
  }
}
