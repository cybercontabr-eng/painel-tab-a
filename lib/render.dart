import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'model.dart';

/// Relogios globais: um para animacoes (limitado a ~30 qps) e um por segundo.
class Ticks {
  static final ValueNotifier<double> t = ValueNotifier<double>(0);
  static final ValueNotifier<DateTime> now =
      ValueNotifier<DateTime>(DateTime.now());
  static final Stopwatch _sw = Stopwatch()..start();
  static Timer? _anim;
  static Timer? _sec;
  static int level = 2;

  static void start(int lv) {
    level = lv;
    _anim?.cancel();
    _sec?.cancel();
    _anim = null;
    _sec = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      now.value = DateTime.now();
    });
    if (lv > 0) {
      _anim = Timer.periodic(Duration(milliseconds: lv >= 2 ? 33 : 80),
          (Timer _) {
        t.value = _sw.elapsedMicroseconds / 1000000.0;
      });
    }
  }
}

const List<String> kFonts = <String>[
  'Sistema',
  'Mono',
  'Serif',
  'Orbitron',
  'Share Tech Mono',
  'Space Grotesk',
  'Inter',
  'Rajdhani',
  'Bebas Neue',
  'Pacifico',
];

const List<String> _semana = <String>[
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];
const List<String> _semanaCurta = <String>[
  'seg',
  'ter',
  'qua',
  'qui',
  'sex',
  'sáb',
  'dom',
];
const List<String> _meses = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _two(int n) => n < 10 ? '0$n' : '$n';

String clockText(String mode, DateTime d) {
  switch (mode) {
    case 'hms':
      return '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
    case 'ss':
      return _two(d.second);
    default:
      return '${_two(d.hour)}:${_two(d.minute)}';
  }
}

String dateText(String mode, DateTime d) {
  switch (mode) {
    case 'semana':
      return _semana[d.weekday - 1];
    case 'curta':
      return '${_semanaCurta[d.weekday - 1]}, ${d.day} ${_meses[d.month - 1].substring(0, 3)}';
    case 'numerica':
      return '${_two(d.day)}.${_two(d.month)}.${d.year}';
    default:
      return '${d.day} de ${_meses[d.month - 1]} de ${d.year}';
  }
}

int daysUntil(int month, int day, DateTime n) {
  final DateTime today = DateTime(n.year, n.month, n.day);
  DateTime target = DateTime(n.year, month, day);
  if (today.isAfter(target)) target = DateTime(n.year + 1, month, day);
  return (target.difference(today).inHours / 24).round();
}

double progressOf(String mode, DateTime d) {
  switch (mode) {
    case 'dia':
      return (d.hour * 3600 + d.minute * 60 + d.second) / 86400.0;
    case 'ano':
      final DateTime a = DateTime(d.year, 1, 1);
      final DateTime b = DateTime(d.year + 1, 1, 1);
      return d.difference(a).inSeconds / b.difference(a).inSeconds;
    default:
      return d.second / 60.0;
  }
}

TextStyle styleFor(Layer l, Size s) {
  final double fs = max(4.0, l.fontSize * s.height);
  final Color c = Color(l.color);
  final TextStyle base = TextStyle(
    color: c,
    fontSize: fs,
    height: 1.15,
    fontWeight: l.bold ? FontWeight.w700 : FontWeight.w400,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    shadows: l.glow
        ? <Shadow>[Shadow(color: c.withAlpha(200), blurRadius: fs * 0.28)]
        : null,
  );
  switch (l.font) {
    case 'Sistema':
      return base;
    case 'Mono':
      return base.copyWith(fontFamily: 'monospace');
    case 'Serif':
      return base.copyWith(fontFamily: 'serif');
    default:
      try {
        return GoogleFonts.getFont(l.font, textStyle: base);
      } catch (_) {
        return base;
      }
  }
}

Alignment _alignOf(String a) {
  switch (a) {
    case 'left':
      return Alignment.centerLeft;
    case 'right':
      return Alignment.centerRight;
    default:
      return Alignment.center;
  }
}

TextAlign _textAlignOf(String a) {
  switch (a) {
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    default:
      return TextAlign.center;
  }
}

class SceneView extends StatelessWidget {
  const SceneView({
    super.key,
    required this.scene,
    this.editing = false,
    this.selectedId,
    this.onSelect,
    this.onChanged,
  });

  final Scene scene;
  final bool editing;
  final String? selectedId;
  final void Function(String? id)? onSelect;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints cons) {
      final Size s = Size(cons.maxWidth, cons.maxHeight);
      Layer? sel;
      for (final Layer l in scene.layers) {
        if (l.id == selectedId) sel = l;
      }
      final List<Widget> kids = <Widget>[
        Positioned.fill(
          child: editing
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect?.call(null),
                  child: ColoredBox(color: Color(scene.bg)),
                )
              : ColoredBox(color: Color(scene.bg)),
        ),
      ];
      if (scene.effect != 'nenhum') {
        kids.add(Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: BackgroundFx(
                  effect: scene.effect, colorInt: scene.effectColor),
            ),
          ),
        ));
      }
      for (final Layer l in scene.layers) {
        kids.add(_positioned(l, s));
      }
      if (editing && sel != null) {
        kids.add(_handle(sel, s));
      }
      return ClipRect(child: Stack(children: kids));
    });
  }

  Widget _positioned(Layer l, Size s) {
    final double w = max(4.0, l.w * s.width);
    final double h = max(4.0, l.h * s.height);
    Widget child = LayerAnimator(
      layer: l,
      size: s,
      child: RepaintBoundary(
        child: LayerContent(layer: l, size: s, editing: editing),
      ),
    );
    child = Opacity(
        opacity: l.opacity.clamp(0.0, 1.0).toDouble(), child: child);
    child = Transform.rotate(angle: l.rotation * pi / 180, child: child);
    if (editing) {
      final bool isSel = l.id == selectedId;
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect?.call(l.id),
        onPanStart: (DragStartDetails _) => onSelect?.call(l.id),
        onPanUpdate: (DragUpdateDetails d) {
          l.x = (l.x + d.delta.dx / s.width).clamp(0.0, 1.0).toDouble();
          l.y = (l.y + d.delta.dy / s.height).clamp(0.0, 1.0).toDouble();
          onChanged?.call();
        },
        child: Container(
          foregroundDecoration: isSel
              ? BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFD166), width: 2))
              : null,
          child: child,
        ),
      );
    }
    return Positioned(
      key: ValueKey<String>(l.id),
      left: l.x * s.width - w / 2,
      top: l.y * s.height - h / 2,
      width: w,
      height: h,
      child: child,
    );
  }

  Widget _handle(Layer l, Size s) {
    const double k = 36;
    return Positioned(
      left: (l.x + l.w / 2) * s.width - k / 2,
      top: (l.y + l.h / 2) * s.height - k / 2,
      width: k,
      height: k,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (DragUpdateDetails d) {
          l.w = (l.w + 2 * d.delta.dx / s.width).clamp(0.01, 2.0).toDouble();
          l.h = (l.h + 2 * d.delta.dy / s.height).clamp(0.01, 2.0).toDouble();
          onChanged?.call();
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const Icon(Icons.open_in_full, size: 18, color: Colors.black),
        ),
      ),
    );
  }
}

/// Aplica a animacao escolhida por cima do conteudo ja desenhado, sem
/// redesenhar o conteudo (so move, gira ou muda a opacidade).
class LayerAnimator extends StatelessWidget {
  const LayerAnimator({
    super.key,
    required this.layer,
    required this.size,
    required this.child,
  });

  final Layer layer;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String a = layer.anim;
    if (a == 'nenhuma' || a == 'digitar' || Ticks.level == 0) return child;
    final double speed = max(0.2, layer.animSpeed);
    return ValueListenableBuilder<double>(
      valueListenable: Ticks.t,
      child: child,
      builder: (BuildContext context, double t, Widget? ch) {
        final Widget c = ch!;
        final double p = (t / speed) % 1.0;
        final double wave = sin(2 * pi * p);
        switch (a) {
          case 'pulsar':
            return Opacity(opacity: 0.3 + 0.7 * (0.5 + 0.5 * wave), child: c);
          case 'piscar':
            return Opacity(opacity: p < 0.5 ? 1.0 : 0.12, child: c);
          case 'girar':
            return Transform.rotate(angle: 2 * pi * p, child: c);
          case 'girar_inv':
            return Transform.rotate(angle: -2 * pi * p, child: c);
          case 'flutuar':
            return Transform.translate(
                offset: Offset(0, wave * size.height * 0.02), child: c);
          case 'zoom':
            return Transform.scale(scale: 1 + 0.06 * wave, child: c);
          case 'deslizar':
            return Transform.translate(
                offset: Offset((0.5 - p) * 2 * size.width, 0), child: c);
          case 'tremular':
            final int kt = (t * 14).floor();
            final bool dip = p > 0.44 && p < 0.56 && (kt * 7919) % 10 < 5;
            return Opacity(opacity: dip ? 0.45 : 1.0, child: c);
          case 'glitch':
            final bool on = p >= 0.9;
            final int kg = (t * 20).floor();
            final double dx = on ? (((kg * 7919) % 15) - 7).toDouble() : 0.0;
            final double dy = on ? (((kg * 104729) % 5) - 2).toDouble() : 0.0;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Opacity(opacity: on && kg.isOdd ? 0.65 : 1.0, child: c),
            );
          default:
            return c;
        }
      },
    );
  }
}

class LayerContent extends StatelessWidget {
  const LayerContent({
    super.key,
    required this.layer,
    required this.size,
    this.editing = false,
  });

  final Layer layer;
  final Size size;
  final bool editing;

  Widget _textBox(String txt) {
    final Layer l = layer;
    return Align(
      alignment: _alignOf(l.align),
      child: Text(
        l.upper ? txt.toUpperCase() : txt,
        textAlign: _textAlignOf(l.align),
        softWrap: true,
        overflow: TextOverflow.visible,
        style: styleFor(l, size),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Layer l = layer;
    switch (l.type) {
      case 'text':
        if (l.anim == 'digitar' && Ticks.level > 0) {
          return ValueListenableBuilder<double>(
            valueListenable: Ticks.t,
            builder: (BuildContext context, double t, Widget? _) {
              final double p = (t / max(0.5, l.animSpeed)) % 1.0;
              final int n = l.text.length;
              final int k = p < 0.6
                  ? (p / 0.6 * n).floor()
                  : (p < 0.94 ? n : 0);
              return _textBox(l.text.substring(0, min(k, n)));
            },
          );
        }
        return _textBox(l.text);
      case 'clock':
        return ValueListenableBuilder<DateTime>(
          valueListenable: Ticks.now,
          builder: (BuildContext context, DateTime d, Widget? _) =>
              _textBox(clockText(l.mode, d)),
        );
      case 'date':
        return ValueListenableBuilder<DateTime>(
          valueListenable: Ticks.now,
          builder: (BuildContext context, DateTime d, Widget? _) =>
              _textBox(dateText(l.mode, d)),
        );
      case 'countdown':
        return ValueListenableBuilder<DateTime>(
          valueListenable: Ticks.now,
          builder: (BuildContext context, DateTime d, Widget? _) {
            final int n = daysUntil(l.targetMonth, l.targetDay, d);
            final String base = l.text.isEmpty ? 'Faltam {dias} dias' : l.text;
            return _textBox(base.replaceAll('{dias}', '$n'));
          },
        );
      case 'image':
        if (l.paths.isEmpty) {
          return _placeholder(Icons.photo_library_outlined,
              'Sem fotos. Abra o editor e escolha as fotos.');
        }
        return Slideshow(
          paths: l.paths,
          interval: l.interval,
          fit: l.fit == 'contain' ? BoxFit.contain : BoxFit.cover,
        );
      case 'video':
        if (l.paths.isEmpty) {
          return _placeholder(Icons.movie_outlined,
              'Sem vídeo. Abra o editor e escolha um vídeo.');
        }
        return VideoBox(
          path: l.paths.first,
          muted: l.muted,
          fit: l.fit == 'contain' ? BoxFit.contain : BoxFit.cover,
        );
      case 'shape':
        return CustomPaint(
          painter: ShapePainter(
              l.shape, Color(l.color), l.filled, l.stroke),
          size: Size.infinite,
        );
      case 'ring':
        return CustomPaint(
          painter: RingPainter(l.mode, Color(l.color), l.stroke),
          size: Size.infinite,
        );
      case 'progress':
        return ValueListenableBuilder<DateTime>(
          valueListenable: Ticks.now,
          builder: (BuildContext context, DateTime d, Widget? _) {
            final double f =
                progressOf(l.mode, d).clamp(0.0, 1.0).toDouble();
            final Color c = Color(l.color);
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: c.withAlpha(45)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: max(0.001, f),
                  child: ColoredBox(color: c),
                ),
              ],
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _placeholder(IconData icon, String msg) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2538),
        border: Border.all(color: const Color(0xFF4A5A78), width: 2),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF9AA7BD), size: 40),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD9E0EA), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class Slideshow extends StatefulWidget {
  const Slideshow({
    super.key,
    required this.paths,
    required this.interval,
    required this.fit,
  });

  final List<String> paths;
  final double interval;
  final BoxFit fit;

  @override
  State<Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<Slideshow> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    final int ms = (max(2.0, widget.interval) * 1000).round();
    _timer = Timer.periodic(Duration(milliseconds: ms), (Timer _) {
      if (!mounted || widget.paths.length < 2) return;
      setState(() => _i = (_i + 1) % widget.paths.length);
    });
  }

  @override
  void didUpdateWidget(Slideshow old) {
    super.didUpdateWidget(old);
    if (old.interval != widget.interval) _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) return const SizedBox.shrink();
    final String p = widget.paths[_i % widget.paths.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      child: SizedBox.expand(
        key: ValueKey<String>(p),
        child: Image.file(
          File(p),
          fit: widget.fit,
          cacheWidth: 1280,
          gaplessPlayback: true,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) =>
                  const ColoredBox(color: Color(0xFF1B2538)),
        ),
      ),
    );
  }
}

class VideoBox extends StatefulWidget {
  const VideoBox({
    super.key,
    required this.path,
    required this.muted,
    required this.fit,
  });

  final String path;
  final bool muted;
  final BoxFit fit;

  @override
  State<VideoBox> createState() => _VideoBoxState();
}

class _VideoBoxState extends State<VideoBox> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final VideoPlayerController c =
        VideoPlayerController.file(File(widget.path));
    _c = c;
    _failed = false;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(widget.muted ? 0 : 1);
      await c.play();
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(VideoBox old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      final VideoPlayerController? prev = _c;
      _c = null;
      prev?.dispose();
      _open();
    } else if (old.muted != widget.muted) {
      _c?.setVolume(widget.muted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? c = _c;
    if (_failed || c == null || !c.value.isInitialized) {
      return ColoredBox(
        color: const Color(0xFF1B2538),
        child: Center(
          child: Text(
            _failed ? 'Não foi possível abrir o vídeo.' : 'Carregando vídeo...',
            style: const TextStyle(color: Color(0xFFD9E0EA), fontSize: 16),
          ),
        ),
      );
    }
    final Size vs = c.value.size;
    return ClipRect(
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: max(1.0, vs.width),
          height: max(1.0, vs.height),
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  ShapePainter(this.shape, this.color, this.filled, this.stroke);

  final String shape;
  final Color color;
  final bool filled;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    final Offset c = size.center(Offset.zero);
    final double r = min(size.width, size.height) / 2;
    switch (shape) {
      case 'circulo':
        canvas.drawCircle(c, filled ? r : r - stroke / 2, p);
        break;
      case 'linha':
        final Paint lp = Paint()
          ..color = color
          ..strokeWidth = max(1.0, stroke)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(0, c.dy), Offset(size.width, c.dy), lp);
        break;
      case 'triangulo':
        final Path tri = Path()
          ..moveTo(size.width / 2, stroke)
          ..lineTo(size.width - stroke, size.height - stroke)
          ..lineTo(stroke, size.height - stroke)
          ..close();
        canvas.drawPath(tri, p);
        break;
      case 'estrela':
        final Path path = Path();
        for (int i = 0; i < 10; i++) {
          final double rr = i.isEven ? r : r * 0.42;
          final double a = -pi / 2 + i * pi / 5;
          final Offset pt = Offset(c.dx + rr * cos(a), c.dy + rr * sin(a));
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, p);
        break;
      default:
        final double inset = filled ? 0 : stroke / 2;
        canvas.drawRect(
            Rect.fromLTWH(inset, inset, size.width - 2 * inset,
                size.height - 2 * inset),
            p);
    }
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.filled != filled ||
      old.stroke != stroke;
}

class RingPainter extends CustomPainter {
  RingPainter(this.mode, this.color, this.stroke);

  final String mode;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, stroke)
      ..strokeCap = StrokeCap.butt;
    final Offset c = size.center(Offset.zero);
    final double r = min(size.width, size.height) / 2 - stroke;
    if (r <= 1) return;
    final Rect rect = Rect.fromCircle(center: c, radius: r);
    switch (mode) {
      case 'tracejado':
        const int n = 72;
        for (int i = 0; i < n; i++) {
          canvas.drawArc(rect, i * 2 * pi / n, 2 * pi / n * 0.2, false, p);
        }
        break;
      case 'segmentos':
        const List<double> segs = <double>[0.0, 0.42, 0.56, 0.9];
        const List<double> lens = <double>[0.34, 0.08, 0.26, 0.06];
        for (int i = 0; i < segs.length; i++) {
          canvas.drawArc(rect, segs[i] * 2 * pi, lens[i] * 2 * pi, false, p);
        }
        break;
      case 'arco':
        p.strokeCap = StrokeCap.round;
        canvas.drawArc(rect, 0, pi / 4, false, p);
        break;
      default:
        canvas.drawCircle(c, r, p);
    }
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.mode != mode || old.color != color || old.stroke != stroke;
}

class BackgroundFx extends StatelessWidget {
  const BackgroundFx({super.key, required this.effect, required this.colorInt});

  final String effect;
  final int colorInt;

  @override
  Widget build(BuildContext context) {
    final bool animated =
        effect != 'grade' && effect != 'scanlines' && Ticks.level > 0;
    return CustomPaint(
      painter: FxPainter(effect, colorInt, animated ? Ticks.t : null),
      size: Size.infinite,
    );
  }
}

class FxPainter extends CustomPainter {
  FxPainter(this.effect, this.colorInt, Listenable? repaint)
      : super(repaint: repaint);

  final String effect;
  final int colorInt;

  static final Map<int, List<TextPainter>> _rainCache =
      <int, List<TextPainter>>{};
  static const String _hex = '0123456789ABCDEF';

  List<TextPainter> _rain() {
    final List<TextPainter>? hit = _rainCache[colorInt];
    if (hit != null) return hit;
    final List<TextPainter> out = <TextPainter>[];
    for (int i = 0; i < 16; i++) {
      final StringBuffer sb = StringBuffer();
      for (int j = 0; j < 26; j++) {
        sb.write(_hex[(i * 7 + j * 13 + (i * j) % 5) % 16]);
        if (j < 25) sb.write('\n');
      }
      final int alpha = 60 + (i * 37) % 70;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: sb.toString(),
          style: TextStyle(
            color: Color(colorInt).withAlpha(alpha),
            fontSize: 18,
            height: 1.2,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      out.add(tp);
    }
    if (_rainCache.length > 6) _rainCache.clear();
    _rainCache[colorInt] = out;
    return out;
  }

  void _grid(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Color(colorInt).withAlpha(20)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _sweep(Canvas canvas, Size size, double t) {
    final double bh = size.height * 0.2;
    final double y = ((t / 7) % 1.0) * (size.height + bh) - bh;
    final Rect r = Rect.fromLTWH(0, y, size.width, bh);
    final Color c = Color(colorInt);
    final Paint p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[c.withAlpha(0), c.withAlpha(70)],
      ).createShader(r);
    canvas.drawRect(r, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double t = Ticks.t.value;
    switch (effect) {
      case 'grade':
        _grid(canvas, size);
        break;
      case 'scanlines':
        final Paint sp = Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 1;
        for (double y = 0; y <= size.height; y += 4) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), sp);
        }
        break;
      case 'varredura':
        _sweep(canvas, size, t);
        break;
      case 'hud':
        _grid(canvas, size);
        _sweep(canvas, size, t);
        break;
      case 'chuva':
        final List<TextPainter> cols = _rain();
        final int nc = max(1, (size.width / 80).floor());
        for (int i = 0; i < nc; i++) {
          final TextPainter tp = cols[i % cols.length];
          final double dur = 7.0 + (i * 5) % 8;
          final double phase = (i * 0.37) % 1.0;
          final double y = ((t / dur + phase) % 1.0) *
                  (size.height + tp.height) -
              tp.height;
          tp.paint(canvas, Offset(30.0 + i * 80.0, y));
        }
        break;
      case 'neve':
        final Paint np = Paint()..isAntiAlias = true;
        final int nn = Ticks.level >= 2 ? 44 : 22;
        for (int i = 0; i < nn; i++) {
          final double x0 = ((i * 0.6180339) % 1.0) * size.width;
          final double speed = 9.0 + (i % 7);
          final double phase = (i * 0.37) % 1.0;
          final double y =
              ((t / speed + phase) % 1.0) * (size.height + 20) - 10;
          final double x = x0 + sin(t * 0.5 + i) * 12;
          np.color = Color(colorInt).withAlpha(90 + (i * 29) % 110);
          canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), np);
        }
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(FxPainter old) =>
      old.effect != effect || old.colorInt != colorInt;
}
