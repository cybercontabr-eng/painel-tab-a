import 'model.dart';

const int kCyan = 0xFF29E6FF;
const int kMagenta = 0xFFFF3D9A;
const int kGreen = 0xFF3DFFA2;
const int kGold = 0xFFFFD166;
const int kAmber = 0xFFF2B544;
const int kInk = 0xFF05080F;
const int kText = 0xFFD9F7FF;
const int kMuted = 0xFF7FB8C9;

Layer _l(String type, double x, double y, double w, double h) {
  final Layer l = Layer(type);
  l.x = x;
  l.y = y;
  l.w = w;
  l.h = h;
  return l;
}

class Templates {
  static const Map<String, String> names = <String, String>{
    'hud': 'Painel HUD',
    'classico': 'Painel clássico',
    'institucional': 'Institucional',
    'natal': 'Natal neon',
    'fotos': 'Porta-retratos',
    'branco': 'Em branco',
  };

  static Scene make(String key) {
    switch (key) {
      case 'hud':
        return hud();
      case 'classico':
        return classico();
      case 'institucional':
        return institucional();
      case 'natal':
        return natal();
      case 'fotos':
        return fotos();
      default:
        return branco();
    }
  }

  static List<Scene> all() =>
      <Scene>[hud(), classico(), institucional(), fotos(), natal()];

  static Scene branco() {
    final Scene s = Scene();
    s.name = 'Nova cena';
    s.layers.add(_l('clock', 0.5, 0.5, 0.6, 0.3)
      ..mode = 'hm'
      ..fontSize = 0.22
      ..bold = true);
    return s;
  }

  static Scene hud() {
    final Scene s = Scene();
    s.name = 'Painel HUD';
    s.bg = kInk;
    s.effect = 'hud';
    s.effectColor = kCyan;
    s.layers.addAll(<Layer>[
      _l('text', 0.17, 0.07, 0.3, 0.06)
        ..text = 'PAINEL // TAB-A'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.03
        ..color = kCyan
        ..align = 'left'
        ..anim = 'pulsar'
        ..animSpeed = 2,
      _l('date', 0.83, 0.07, 0.3, 0.06)
        ..mode = 'numerica'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.03
        ..color = kText
        ..align = 'right',
      _l('ring', 0.26, 0.52, 0.37, 0.59)
        ..mode = 'tracejado'
        ..color = kCyan
        ..stroke = 2
        ..anim = 'girar'
        ..animSpeed = 48,
      _l('ring', 0.26, 0.52, 0.32, 0.51)
        ..mode = 'segmentos'
        ..color = kCyan
        ..opacity = 0.55
        ..stroke = 6
        ..anim = 'girar_inv'
        ..animSpeed = 20,
      _l('ring', 0.26, 0.52, 0.28, 0.44)
        ..mode = 'arco'
        ..color = kMagenta
        ..stroke = 4
        ..anim = 'girar'
        ..animSpeed = 6,
      _l('date', 0.26, 0.41, 0.26, 0.05)
        ..mode = 'semana'
        ..upper = true
        ..font = 'Share Tech Mono'
        ..fontSize = 0.024
        ..color = kMuted,
      _l('clock', 0.26, 0.51, 0.26, 0.14)
        ..mode = 'hm'
        ..font = 'Orbitron'
        ..fontSize = 0.1
        ..bold = true
        ..glow = true
        ..color = 0xFFFFFFFF,
      _l('clock', 0.26, 0.62, 0.1, 0.06)
        ..mode = 'ss'
        ..font = 'Orbitron'
        ..fontSize = 0.04
        ..color = kCyan,
      _l('shape', 0.74, 0.34, 0.42, 0.3)
        ..shape = 'rect'
        ..filled = false
        ..stroke = 1.5
        ..color = kCyan
        ..opacity = 0.5,
      _l('text', 0.74, 0.24, 0.38, 0.05)
        ..text = 'AGENDA'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.024
        ..color = kCyan
        ..align = 'left',
      _l('text', 0.74, 0.37, 0.38, 0.18)
        ..text =
            '09:30  [COMPROMISSO 1]\n14:00  [COMPROMISSO 2]\n19:00  [COMPROMISSO 3]'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.032
        ..color = kText
        ..align = 'left',
      _l('text', 0.59, 0.6, 0.1, 0.04)
        ..text = 'MINUTO'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.024
        ..color = kMuted
        ..align = 'left',
      _l('progress', 0.8, 0.6, 0.3, 0.014)
        ..mode = 'minuto'
        ..color = kCyan,
      _l('text', 0.59, 0.67, 0.1, 0.04)
        ..text = 'DIA'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.024
        ..color = kMuted
        ..align = 'left',
      _l('progress', 0.8, 0.67, 0.3, 0.014)
        ..mode = 'dia'
        ..color = kCyan,
      _l('text', 0.59, 0.74, 0.1, 0.04)
        ..text = 'ANO'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.024
        ..color = kMuted
        ..align = 'left',
      _l('progress', 0.8, 0.74, 0.3, 0.014)
        ..mode = 'ano'
        ..color = kMagenta,
      _l('text', 0.74, 0.86, 0.42, 0.05)
        ..text = '> modo painel em execução_'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.028
        ..color = kMuted
        ..align = 'left'
        ..anim = 'digitar'
        ..animSpeed = 9,
    ]);
    return s;
  }

  static Scene classico() {
    final Scene s = Scene();
    s.name = 'Painel clássico';
    s.bg = 0xFF0E1420;
    s.layers.addAll(<Layer>[
      _l('date', 0.3, 0.27, 0.5, 0.06)
        ..mode = 'semana'
        ..upper = true
        ..font = 'Inter'
        ..fontSize = 0.03
        ..color = kAmber
        ..align = 'left',
      _l('clock', 0.3, 0.46, 0.5, 0.32)
        ..mode = 'hm'
        ..font = 'Space Grotesk'
        ..fontSize = 0.27
        ..color = 0xFFF2F4F8
        ..align = 'left',
      _l('date', 0.3, 0.66, 0.5, 0.06)
        ..mode = 'longa'
        ..font = 'Inter'
        ..fontSize = 0.038
        ..color = 0xFF9AA7BD
        ..align = 'left',
      _l('shape', 0.77, 0.47, 0.36, 0.5)
        ..shape = 'rect'
        ..filled = true
        ..color = 0xFF172033,
      _l('text', 0.77, 0.29, 0.31, 0.05)
        ..text = 'HOJE'
        ..font = 'Inter'
        ..fontSize = 0.022
        ..bold = true
        ..color = 0xFF9AA7BD
        ..align = 'left',
      _l('text', 0.77, 0.5, 0.31, 0.34)
        ..text =
            '09:30  [COMPROMISSO 1]\n14:00  [COMPROMISSO 2]\n19:00  [COMPROMISSO 3]\n\n[TAREFA DO DIA]'
        ..font = 'Inter'
        ..fontSize = 0.03
        ..color = 0xFFF2F4F8
        ..align = 'left',
    ]);
    return s;
  }

  static Scene institucional() {
    final Scene s = Scene();
    s.name = 'Institucional';
    s.bg = kInk;
    s.effect = 'chuva';
    s.effectColor = kCyan;
    s.layers.addAll(<Layer>[
      _l('text', 0.2, 0.08, 0.34, 0.06)
        ..text = 'MODO INSTITUCIONAL'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.028
        ..color = kCyan
        ..align = 'left',
      _l('clock', 0.88, 0.08, 0.2, 0.08)
        ..mode = 'hm'
        ..font = 'Orbitron'
        ..fontSize = 0.05
        ..bold = true
        ..align = 'right',
      _l('shape', 0.5, 0.45, 0.92, 0.5)
        ..shape = 'rect'
        ..filled = true
        ..color = 0xE605080F,
      _l('shape', 0.5, 0.45, 0.92, 0.5)
        ..shape = 'rect'
        ..filled = false
        ..stroke = 1.5
        ..color = kCyan
        ..opacity = 0.6,
      _l('ring', 0.17, 0.45, 0.19, 0.3)
        ..mode = 'segmentos'
        ..color = kCyan
        ..stroke = 3
        ..anim = 'girar'
        ..animSpeed = 24,
      _l('text', 0.17, 0.45, 0.12, 0.1)
        ..text = '[LOGO]'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.026
        ..color = kText,
      _l('text', 0.62, 0.41, 0.62, 0.3)
        ..text = 'Ministério Público do Estado de Goiás'
        ..font = 'Orbitron'
        ..fontSize = 0.075
        ..bold = true
        ..glow = true
        ..color = 0xFFFFFFFF
        ..align = 'left'
        ..anim = 'glitch'
        ..animSpeed = 6,
      _l('text', 0.62, 0.62, 0.62, 0.06)
        ..text = '[UNIDADE OU SETOR]'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.036
        ..color = kCyan
        ..align = 'left',
      _l('shape', 0.5, 0.84, 0.92, 0.1)
        ..shape = 'rect'
        ..filled = true
        ..color = 0xE605080F,
      _l('shape', 0.5, 0.84, 0.92, 0.1)
        ..shape = 'rect'
        ..filled = false
        ..stroke = 1.5
        ..color = kMagenta
        ..opacity = 0.7,
      _l('shape', 0.075, 0.84, 0.014, 0.022)
        ..shape = 'rect'
        ..filled = true
        ..color = kMagenta
        ..anim = 'piscar'
        ..animSpeed = 1.4,
      _l('text', 0.36, 0.84, 0.5, 0.06)
        ..text = 'FORA DA MESA NO MOMENTO'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.032
        ..color = kText
        ..align = 'left',
      _l('text', 0.78, 0.84, 0.32, 0.06)
        ..text = 'RETORNO: [HORÁRIO]'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.03
        ..color = kMuted
        ..align = 'right',
    ]);
    return s;
  }

  static Scene natal() {
    final Scene s = Scene();
    s.name = 'Natal neon';
    s.bg = kInk;
    s.effect = 'neve';
    s.effectColor = kText;
    s.schedOn = true;
    s.sm = 12;
    s.sd = 1;
    s.em = 12;
    s.ed = 26;
    Layer luz(double x, double y, int cor, double vel) =>
        _l('shape', x, y, 0.016, 0.026)
          ..shape = 'circulo'
          ..filled = true
          ..color = cor
          ..anim = 'pulsar'
          ..animSpeed = vel;
    s.layers.addAll(<Layer>[
      _l('text', 0.15, 0.07, 0.26, 0.06)
        ..text = 'TEMA // NATAL'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.03
        ..color = kGreen
        ..align = 'left',
      _l('date', 0.83, 0.07, 0.3, 0.06)
        ..mode = 'numerica'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.03
        ..color = kText
        ..align = 'right',
      _l('shape', 0.2, 0.82, 0.03, 0.08)
        ..shape = 'rect'
        ..filled = false
        ..stroke = 3
        ..color = kGreen
        ..opacity = 0.7,
      _l('shape', 0.2, 0.32, 0.13, 0.2)
        ..shape = 'triangulo'
        ..filled = false
        ..stroke = 4
        ..color = kGreen,
      _l('shape', 0.2, 0.47, 0.19, 0.24)
        ..shape = 'triangulo'
        ..filled = false
        ..stroke = 4
        ..color = kGreen,
      _l('shape', 0.2, 0.64, 0.26, 0.28)
        ..shape = 'triangulo'
        ..filled = false
        ..stroke = 4
        ..color = kGreen,
      _l('shape', 0.2, 0.18, 0.05, 0.08)
        ..shape = 'estrela'
        ..filled = true
        ..color = kGold
        ..anim = 'pulsar'
        ..animSpeed = 2.4,
      luz(0.19, 0.36, kMagenta, 1.8),
      luz(0.22, 0.5, kCyan, 2.2),
      luz(0.17, 0.55, kGold, 1.6),
      luz(0.24, 0.66, kMagenta, 2.0),
      luz(0.14, 0.72, kCyan, 2.6),
      luz(0.2, 0.74, kGold, 1.9),
      luz(0.27, 0.74, kMagenta, 2.3),
      _l('clock', 0.66, 0.36, 0.56, 0.26)
        ..mode = 'hm'
        ..font = 'Orbitron'
        ..fontSize = 0.2
        ..bold = true
        ..glow = true
        ..color = 0xFFFFFFFF
        ..align = 'left',
      _l('text', 0.66, 0.58, 0.56, 0.12)
        ..text = 'FELIZ NATAL'
        ..font = 'Orbitron'
        ..fontSize = 0.08
        ..bold = true
        ..glow = true
        ..color = kMagenta
        ..align = 'left'
        ..anim = 'tremular'
        ..animSpeed = 5,
      _l('countdown', 0.66, 0.72, 0.56, 0.08)
        ..text = 'FALTAM {dias} DIAS'
        ..font = 'Share Tech Mono'
        ..fontSize = 0.045
        ..color = kGold
        ..align = 'left'
        ..targetMonth = 12
        ..targetDay = 25,
    ]);
    return s;
  }

  static Scene fotos() {
    final Scene s = Scene();
    s.name = 'Porta-retratos';
    s.bg = 0xFF000000;
    s.layers.addAll(<Layer>[
      _l('image', 0.5, 0.5, 1, 1)
        ..fit = 'cover'
        ..interval = 15,
      _l('clock', 0.16, 0.84, 0.28, 0.14)
        ..mode = 'hm'
        ..font = 'Space Grotesk'
        ..fontSize = 0.11
        ..color = 0xFFFFFFFF
        ..glow = true
        ..align = 'left',
      _l('date', 0.16, 0.93, 0.28, 0.05)
        ..mode = 'curta'
        ..font = 'Inter'
        ..fontSize = 0.03
        ..color = 0xFFE6EAF0
        ..align = 'left',
    ]);
    return s;
  }
}
