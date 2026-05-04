import 'dart:convert';

// ═══════════════════════════════════════════════════════════════════════════
// MODELOS DEL ARCHIVO .tree (JSON v2)
//
// Esquema compartido entre Flutter (Web móvil) y Unity 3D.
// La extensión es .tree pero el contenido es JSON válido.
//
// MATRIZ DE RESPONSABILIDADES:
//   🟢 Flutter/Web escribe: usuario.id/nombre, recursos.*, planta.id,
//      instance_id, subid, desbloqueada, estado.fase, visual_estado,
//      recursos_aplicados.
//   🔴 Unity escribe: usuario.nivel/xp, planta.estado.salud/hp_actual,
//      planta.progreso.*, planta.uso.*, semillas[].
//
// Flutter NUNCA sobreescribe campos 🔴. Unity NUNCA sobreescribe campos 🟢.
// ═══════════════════════════════════════════════════════════════════════════

// ── Usuario ──────────────────────────────────────────────────────────────────

class TreeUsuario {
  /// 🟢 Flutter
  final String id;

  /// 🟢 Flutter
  final String nombre;

  /// 🔴 Unity — Flutter preserva este valor, nunca lo sobreescribe
  final int nivel;

  /// 🔴 Unity — Flutter preserva este valor, nunca lo sobreescribe
  final int xp;

  const TreeUsuario({
    required this.id,
    required this.nombre,
    this.nivel = 0,
    this.xp = 0,
  });

  factory TreeUsuario.fromJson(Map<String, dynamic> json) => TreeUsuario(
        id: (json['id'] as String?) ?? '',
        nombre: (json['nombre'] as String?) ?? '',
        nivel: (json['nivel'] as int?) ?? 0,
        xp: (json['xp'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'nivel': nivel,
        'xp': xp,
      };

  /// Crea una copia preservando los campos 🔴 de Unity y actualizando solo
  /// los campos 🟢 de Flutter.
  TreeUsuario copyWithFlutter({String? id, String? nombre}) => TreeUsuario(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        nivel: nivel, // 🔴 preservado
        xp: xp, // 🔴 preservado
      );
}

// ── Recursos ─────────────────────────────────────────────────────────────────

/// Un recurso individual con su cantidad.
class TreeRecurso {
  /// 🟢 Flutter
  int cantidad;

  TreeRecurso({this.cantidad = 0});

  factory TreeRecurso.fromJson(Map<String, dynamic> json) =>
      TreeRecurso(cantidad: (json['cantidad'] as int?) ?? 0);

  Map<String, dynamic> toJson() => {'cantidad': cantidad};
}

/// Inventario de recursos del usuario.
/// Nota: 'fertilizante' es interno a Flutter y NO aparece en el .tree.
class TreeRecursos {
  /// 🟢 Flutter
  TreeRecurso agua;

  /// 🟢 Flutter
  TreeRecurso sol;

  /// 🟢 Flutter
  TreeRecurso composta;

  TreeRecursos({
    TreeRecurso? agua,
    TreeRecurso? sol,
    TreeRecurso? composta,
  })  : agua = agua ?? TreeRecurso(),
        sol = sol ?? TreeRecurso(),
        composta = composta ?? TreeRecurso();

  factory TreeRecursos.fromJson(Map<String, dynamic> json) => TreeRecursos(
        agua: TreeRecurso.fromJson((json['agua'] as Map<String, dynamic>?) ?? {}),
        sol: TreeRecurso.fromJson((json['sol'] as Map<String, dynamic>?) ?? {}),
        composta:
            TreeRecurso.fromJson((json['composta'] as Map<String, dynamic>?) ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'agua': agua.toJson(),
        'sol': sol.toJson(),
        'composta': composta.toJson(),
      };
}

// ── Estado de planta ──────────────────────────────────────────────────────────

class TreeEstado {
  /// 🟢 Flutter — fase de crecimiento: semilla, arbusto, planta, ent
  String fase;

  /// 🔴 Unity — saludable, dañado, critico, muerto
  final String salud;

  /// 🔴 Unity — HP numérico
  final int hpActual;

  TreeEstado({
    required this.fase,
    this.salud = 'saludable',
    this.hpActual = 1000,
  });

  factory TreeEstado.fromJson(Map<String, dynamic> json) => TreeEstado(
        fase: (json['fase'] as String?) ?? 'semilla',
        salud: (json['salud'] as String?) ?? 'saludable',
        hpActual: (json['hp_actual'] as int?) ?? 1000,
      );

  Map<String, dynamic> toJson() => {
        'fase': fase,
        'salud': salud,
        'hp_actual': hpActual,
      };

  /// Actualiza solo los campos 🟢 de Flutter (fase).
  TreeEstado copyWithFlutter({String? fase}) => TreeEstado(
        fase: fase ?? this.fase,
        salud: salud, // 🔴 preservado
        hpActual: hpActual, // 🔴 preservado
      );
}

// ── Progreso (Unity) ──────────────────────────────────────────────────────────

class TreeProgreso {
  /// 🔴 Unity
  final int nivel;

  /// 🔴 Unity
  final int xp;

  const TreeProgreso({this.nivel = 0, this.xp = 0});

  factory TreeProgreso.fromJson(Map<String, dynamic> json) => TreeProgreso(
        nivel: (json['nivel'] as int?) ?? 0,
        xp: (json['xp'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {'nivel': nivel, 'xp': xp};
}

// ── Visual Estado (Flutter) ───────────────────────────────────────────────────

class TreeVisualEstado {
  /// 🟢 Flutter
  String skin;

  /// 🟢 Flutter
  String variacion;

  TreeVisualEstado({this.skin = 'default', this.variacion = 'normal'});

  factory TreeVisualEstado.fromJson(Map<String, dynamic> json) =>
      TreeVisualEstado(
        skin: (json['skin'] as String?) ?? 'default',
        variacion: (json['variacion'] as String?) ?? 'normal',
      );

  Map<String, dynamic> toJson() => {
        'skin': skin,
        'variacion': variacion,
      };
}

// ── Uso (Unity) ───────────────────────────────────────────────────────────────

class TreeUso {
  /// 🔴 Unity
  final bool seleccionada;

  /// 🔴 Unity
  final bool enCombate;

  const TreeUso({this.seleccionada = false, this.enCombate = false});

  factory TreeUso.fromJson(Map<String, dynamic> json) => TreeUso(
        seleccionada: (json['seleccionada'] as bool?) ?? false,
        enCombate: (json['en_combate'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'seleccionada': seleccionada,
        'en_combate': enCombate,
      };
}

// ── Recursos Aplicados (Flutter) ──────────────────────────────────────────────

class TreeRecursosAplicados {
  /// 🟢 Flutter
  int agua;

  /// 🟢 Flutter
  int sol;

  /// 🟢 Flutter
  int composta;

  TreeRecursosAplicados({this.agua = 0, this.sol = 0, this.composta = 0});

  factory TreeRecursosAplicados.fromJson(Map<String, dynamic> json) =>
      TreeRecursosAplicados(
        agua: (json['agua'] as int?) ?? 0,
        sol: (json['sol'] as int?) ?? 0,
        composta: (json['composta'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'agua': agua,
        'sol': sol,
        'composta': composta,
      };
}

// ── Planta ────────────────────────────────────────────────────────────────────

class TreePlanta {
  /// 🟢 Flutter — ID de especie (coincide con prefab en Unity)
  String id;

  /// 🟢 Flutter — ID único de instancia, INMUTABLE
  final String instanceId;

  /// 🟢 Flutter — variante de modelo en Unity
  String subid;

  /// 🟢 Flutter
  bool desbloqueada;

  /// fase (🟢) + salud/hp_actual (🔴)
  TreeEstado estado;

  /// 🔴 Unity
  final TreeProgreso progreso;

  /// 🟢 Flutter
  TreeVisualEstado visualEstado;

  /// 🔴 Unity
  final TreeUso uso;

  /// 🟢 Flutter
  TreeRecursosAplicados recursosAplicados;

  TreePlanta({
    required this.id,
    required this.instanceId,
    String? subid,
    this.desbloqueada = true,
    TreeEstado? estado,
    TreeProgreso? progreso,
    TreeVisualEstado? visualEstado,
    TreeUso? uso,
    TreeRecursosAplicados? recursosAplicados,
  })  : subid = subid ?? id,
        estado = estado ?? TreeEstado(fase: 'semilla'),
        progreso = progreso ?? const TreeProgreso(),
        visualEstado = visualEstado ?? TreeVisualEstado(),
        uso = uso ?? const TreeUso(),
        recursosAplicados = recursosAplicados ?? TreeRecursosAplicados();

  factory TreePlanta.fromJson(Map<String, dynamic> json) => TreePlanta(
        id: (json['id'] as String?) ?? '',
        instanceId: (json['instance_id'] as String?) ?? '',
        subid: (json['subid'] as String?) ?? (json['id'] as String?) ?? '',
        desbloqueada: (json['desbloqueada'] as bool?) ?? true,
        estado: TreeEstado.fromJson(
            (json['estado'] as Map<String, dynamic>?) ?? {}),
        progreso: TreeProgreso.fromJson(
            (json['progreso'] as Map<String, dynamic>?) ?? {}),
        visualEstado: TreeVisualEstado.fromJson(
            (json['visual_estado'] as Map<String, dynamic>?) ?? {}),
        uso: TreeUso.fromJson((json['uso'] as Map<String, dynamic>?) ?? {}),
        recursosAplicados: TreeRecursosAplicados.fromJson(
            (json['recursos_aplicados'] as Map<String, dynamic>?) ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'instance_id': instanceId,
        'subid': subid,
        'desbloqueada': desbloqueada,
        'estado': estado.toJson(),
        'progreso': progreso.toJson(),
        'visual_estado': visualEstado.toJson(),
        'uso': uso.toJson(),
        'recursos_aplicados': recursosAplicados.toJson(),
      };
}

// ── Semilla ───────────────────────────────────────────────────────────────────

class TreeSemilla {
  /// 🔴 Unity
  final String seedId;

  /// 🔴 Unity
  final String speciesId;

  /// 🔴 Unity
  final String categoria;

  /// 🔴 Unity — timestamp en milisegundos UTC
  final int recibidaEn;

  const TreeSemilla({
    required this.seedId,
    required this.speciesId,
    required this.categoria,
    required this.recibidaEn,
  });

  factory TreeSemilla.fromJson(Map<String, dynamic> json) => TreeSemilla(
        seedId: (json['seed_id'] as String?) ?? '',
        speciesId: (json['species_id'] as String?) ?? '',
        categoria: (json['categoria'] as String?) ?? '',
        recibidaEn: (json['recibida_en'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'seed_id': seedId,
        'species_id': speciesId,
        'categoria': categoria,
        'recibida_en': recibidaEn,
      };
}

// ── Raíz del .tree ────────────────────────────────────────────────────────────

/// Modelo raíz del archivo .tree (JSON v2).
/// Es la única fuente de verdad compartida entre Flutter y Unity.
class TreeData {
  /// Siempre 2. Flutter migra automáticamente desde v1 si fuera necesario.
  final int version;

  TreeUsuario usuario;
  TreeRecursos recursos;
  List<TreePlanta> plantas;

  /// 🔴 Unity — Semillas creadas en 3D que se suman al inventario web
  List<TreeSemilla> semillas;

  TreeData({
    this.version = 2,
    required this.usuario,
    TreeRecursos? recursos,
    List<TreePlanta>? plantas,
    List<TreeSemilla>? semillas,
  })  : recursos = recursos ?? TreeRecursos(),
        plantas = plantas ?? [],
        semillas = semillas ?? [];

  factory TreeData.fromJson(Map<String, dynamic> json) => TreeData(
        version: (json['version'] as int?) ?? 2,
        usuario: TreeUsuario.fromJson(
            (json['usuario'] as Map<String, dynamic>?) ?? {}),
        recursos: TreeRecursos.fromJson(
            (json['recursos'] as Map<String, dynamic>?) ?? {}),
        plantas: ((json['plantas'] as List?) ?? [])
            .map((p) => TreePlanta.fromJson(p as Map<String, dynamic>))
            .toList(),
        semillas: ((json['semillas'] as List?) ?? [])
            .map((s) => TreeSemilla.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'usuario': usuario.toJson(),
        'recursos': recursos.toJson(),
        'plantas': plantas.map((p) => p.toJson()).toList(),
        'semillas': semillas.map((s) => s.toJson()).toList(),
      };

  String toJsonString({bool pretty = false}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }
}
