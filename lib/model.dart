import 'dart:convert';
import 'dart:math';

final Random _rnd = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${_rnd.nextInt(9999)}';

double _d(dynamic v, double def) => v is num ? v.toDouble() : def;
int _i(dynamic v, int def) => v is num ? v.toInt() : def;
String _s(dynamic v, String def) => v is String ? v : def;
bool _b(dynamic v, bool def) => v is bool ? v : def;

/// Tipos de camada: text, clock, date, countdown, image, video, shape, ring,
/// progress.
class Layer {
  String id = newId();
  String type;

  // Posicao do centro e tamanho, em fracao da tela (0 a 1).
  double x = 0.5;
  double y = 0.5;
  double w = 0.4;
  double h = 0.2;
  double rotation = 0; // graus
  double opacity = 1;

  int color = 0xFFFFFFFF;
  String text = '';
  String font = 'Sistema';
  double fontSize = 0.08; // fracao da altura da tela
  bool bold = false;
  bool glow = false;
  bool upper = false;
  String align = 'center'; // left, center, right

  String anim = 'nenhuma';
  double animSpeed = 4; // segundos por ciclo

  List<String> paths = <String>[]; // fotos ou video
  double interval = 10; // segundos por foto
  String fit = 'cover'; // cover, contain
  bool muted = true;

  String shape = 'rect'; // rect, circulo, linha, triangulo, estrela
  bool filled = true;
  double stroke = 3;

  // clock: hm, hms, ss | date: longa, curta, semana, numerica
  // ring: tracejado, arco, solido | progress: minuto, dia, ano
  String mode = '';

  int targetMonth = 12;
  int targetDay = 25;

  Layer(this.type);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'rotation': rotation,
        'opacity': opacity,
        'color': color,
        'text': text,
        'font': font,
        'fontSize': fontSize,
        'bold': bold,
        'glow': glow,
        'upper': upper,
        'align': align,
        'anim': anim,
        'animSpeed': animSpeed,
        'paths': paths,
        'interval': interval,
        'fit': fit,
        'muted': muted,
        'shape': shape,
        'filled': filled,
        'stroke': stroke,
        'mode': mode,
        'targetMonth': targetMonth,
        'targetDay': targetDay,
      };

  static Layer fromJson(Map<String, dynamic> j) {
    final Layer l = Layer(_s(j['type'], 'text'));
    l.id = _s(j['id'], newId());
    l.x = _d(j['x'], 0.5);
    l.y = _d(j['y'], 0.5);
    l.w = _d(j['w'], 0.4);
    l.h = _d(j['h'], 0.2);
    l.rotation = _d(j['rotation'], 0);
    l.opacity = _d(j['opacity'], 1);
    l.color = _i(j['color'], 0xFFFFFFFF);
    l.text = _s(j['text'], '');
    l.font = _s(j['font'], 'Sistema');
    l.fontSize = _d(j['fontSize'], 0.08);
    l.bold = _b(j['bold'], false);
    l.glow = _b(j['glow'], false);
    l.upper = _b(j['upper'], false);
    l.align = _s(j['align'], 'center');
    l.anim = _s(j['anim'], 'nenhuma');
    l.animSpeed = _d(j['animSpeed'], 4);
    final dynamic ps = j['paths'];
    l.paths = ps is List ? ps.whereType<String>().toList() : <String>[];
    l.interval = _d(j['interval'], 10);
    l.fit = _s(j['fit'], 'cover');
    l.muted = _b(j['muted'], true);
    l.shape = _s(j['shape'], 'rect');
    l.filled = _b(j['filled'], true);
    l.stroke = _d(j['stroke'], 3);
    l.mode = _s(j['mode'], '');
    l.targetMonth = _i(j['targetMonth'], 12);
    l.targetDay = _i(j['targetDay'], 25);
    return l;
  }

  Layer copy() {
    final Layer l = Layer.fromJson(
        jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>);
    l.id = newId();
    return l;
  }
}

class Scene {
  String id = newId();
  String name = 'Cena';
  int bg = 0xFF05080F;

  // nenhum, grade, scanlines, varredura, hud, chuva, neve
  String effect = 'nenhum';
  int effectColor = 0xFF29E6FF;

  // Agendamento sazonal (dia/mes inicial e final).
  bool schedOn = false;
  int sm = 12;
  int sd = 1;
  int em = 12;
  int ed = 26;

  List<Layer> layers = <Layer>[];

  bool matches(DateTime n) {
    final int a = sm * 100 + sd;
    final int b = em * 100 + ed;
    final int c = n.month * 100 + n.day;
    return a <= b ? (c >= a && c <= b) : (c >= a || c <= b);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'bg': bg,
        'effect': effect,
        'effectColor': effectColor,
        'schedOn': schedOn,
        'sm': sm,
        'sd': sd,
        'em': em,
        'ed': ed,
        'layers': layers.map((Layer l) => l.toJson()).toList(),
      };

  static Scene fromJson(Map<String, dynamic> j) {
    final Scene s = Scene();
    s.id = _s(j['id'], newId());
    s.name = _s(j['name'], 'Cena');
    s.bg = _i(j['bg'], 0xFF05080F);
    s.effect = _s(j['effect'], 'nenhum');
    s.effectColor = _i(j['effectColor'], 0xFF29E6FF);
    s.schedOn = _b(j['schedOn'], false);
    s.sm = _i(j['sm'], 12);
    s.sd = _i(j['sd'], 1);
    s.em = _i(j['em'], 12);
    s.ed = _i(j['ed'], 26);
    final dynamic ls = j['layers'];
    if (ls is List) {
      for (final dynamic e in ls) {
        if (e is Map) {
          s.layers.add(Layer.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return s;
  }

  Scene copy() {
    final Scene s = Scene.fromJson(
        jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>);
    s.id = newId();
    for (final Layer l in s.layers) {
      l.id = newId();
    }
    return s;
  }
}

class Project {
  List<Scene> scenes = <Scene>[];
  String currentId = '';
  bool auto = true; // troca sozinho para cenas agendadas
  int effects = 2; // 0 desligado, 1 baixo, 2 alto
  bool nightOn = false;
  int nightStart = 22;
  int nightEnd = 6;
  double nightDim = 0.7;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scenes': scenes.map((Scene s) => s.toJson()).toList(),
        'currentId': currentId,
        'auto': auto,
        'effects': effects,
        'nightOn': nightOn,
        'nightStart': nightStart,
        'nightEnd': nightEnd,
        'nightDim': nightDim,
      };

  static Project fromJson(Map<String, dynamic> j) {
    final Project p = Project();
    final dynamic ss = j['scenes'];
    if (ss is List) {
      for (final dynamic e in ss) {
        if (e is Map) {
          p.scenes.add(Scene.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    p.currentId = _s(j['currentId'], '');
    p.auto = _b(j['auto'], true);
    p.effects = _i(j['effects'], 2);
    p.nightOn = _b(j['nightOn'], false);
    p.nightStart = _i(j['nightStart'], 22);
    p.nightEnd = _i(j['nightEnd'], 6);
    p.nightDim = _d(j['nightDim'], 0.7);
    return p;
  }

  bool isNight(DateTime n) {
    if (!nightOn) return false;
    final int h = n.hour;
    return nightStart <= nightEnd
        ? (h >= nightStart && h < nightEnd)
        : (h >= nightStart || h < nightEnd);
  }
}
