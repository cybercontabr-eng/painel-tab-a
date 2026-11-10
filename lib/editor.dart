import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'model.dart';
import 'render.dart';
import 'store.dart';

const List<int> kPalette = <int>[
  0xFFFFFFFF,
  0xFFD9F7FF,
  0xFF9AA7BD,
  0xFF4B5568,
  0xFF000000,
  0xFF05080F,
  0xFF0E1420,
  0xFF172033,
  0xFF29E6FF,
  0xFF3D8BFF,
  0xFF3DFFA2,
  0xFF1F6B4F,
  0xFFFFD166,
  0xFFF2B544,
  0xFFFF8A3D,
  0xFFE0523F,
  0xFFFF3D9A,
  0xFFB86BFF,
  0xE605080F,
  0x80000000,
];

const Map<String, String> kTypeNames = <String, String>{
  'text': 'Texto',
  'clock': 'Relógio',
  'date': 'Data',
  'countdown': 'Contagem regressiva',
  'image': 'Fotos',
  'video': 'Vídeo',
  'shape': 'Forma',
  'ring': 'Anel',
  'progress': 'Barra de progresso',
};

const Map<String, String> kAnimNames = <String, String>{
  'nenhuma': 'Nenhuma',
  'pulsar': 'Pulsar',
  'piscar': 'Piscar',
  'girar': 'Girar',
  'girar_inv': 'Girar (anti-horário)',
  'flutuar': 'Flutuar',
  'zoom': 'Zoom suave',
  'deslizar': 'Deslizar pela tela',
  'tremular': 'Tremular (neon)',
  'glitch': 'Glitch',
  'digitar': 'Digitar (só texto)',
};

const Map<String, String> kEffectNames = <String, String>{
  'nenhum': 'Nenhum',
  'grade': 'Grade',
  'scanlines': 'Linhas de varredura',
  'varredura': 'Faixa de luz',
  'hud': 'Grade + faixa de luz',
  'chuva': 'Chuva de dados',
  'neve': 'Neve',
};

Map<String, String> _range(int a, int b) => <String, String>{
      for (int i = a; i <= b; i++) '$i': '$i',
    };

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.store, required this.sceneId});

  final Store store;
  final String sceneId;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String? _sel;

  Scene get _scene =>
      widget.store.byId(widget.sceneId) ?? widget.store.current();

  Layer? get _layer {
    for (final Layer l in _scene.layers) {
      if (l.id == _sel) return l;
    }
    return null;
  }

  void _up([VoidCallback? f]) {
    setState(() {
      if (f != null) f();
    });
    widget.store.touch();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _add(String type) {
    final Layer l = Layer(type);
    switch (type) {
      case 'text':
        l.text = 'Novo texto';
        l.w = 0.5;
        l.h = 0.14;
        break;
      case 'clock':
        l.mode = 'hm';
        l.fontSize = 0.16;
        l.bold = true;
        l.w = 0.5;
        l.h = 0.24;
        break;
      case 'date':
        l.mode = 'longa';
        l.fontSize = 0.04;
        l.w = 0.5;
        l.h = 0.08;
        break;
      case 'countdown':
        l.text = 'Faltam {dias} dias';
        l.fontSize = 0.05;
        l.w = 0.6;
        l.h = 0.1;
        break;
      case 'image':
      case 'video':
        l.w = 0.5;
        l.h = 0.5;
        break;
      case 'shape':
        l.w = 0.2;
        l.h = 0.2;
        l.color = 0xFF29E6FF;
        break;
      case 'ring':
        l.mode = 'tracejado';
        l.w = 0.25;
        l.h = 0.4;
        l.color = 0xFF29E6FF;
        l.anim = 'girar';
        l.animSpeed = 20;
        break;
      case 'progress':
        l.mode = 'dia';
        l.w = 0.4;
        l.h = 0.02;
        l.color = 0xFF29E6FF;
        break;
      default:
        break;
    }
    _up(() {
      _scene.layers.add(l);
      _sel = l.id;
    });
  }

  Future<void> _pickPhotos(Layer l) async {
    try {
      final List<XFile> xs =
          await ImagePicker().pickMultiImage(maxWidth: 1920, imageQuality: 88);
      if (xs.isEmpty) return;
      final List<String> out = <String>[];
      for (final XFile x in xs) {
        out.add(await widget.store.importFile(x.path));
      }
      _up(() => l.paths = <String>[...l.paths, ...out]);
    } catch (e) {
      _msg('Não foi possível abrir as fotos: $e');
    }
  }

  Future<void> _pickVideo(Layer l) async {
    try {
      final XFile? x =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (x == null) return;
      final String p = await widget.store.importFile(x.path);
      _up(() => l.paths = <String>[p]);
    } catch (e) {
      _msg('Não foi possível abrir o vídeo: $e');
    }
  }

  Future<void> _hexDialog(int v, ValueChanged<int> on) async {
    final TextEditingController c = TextEditingController(
        text: v.toRadixString(16).padLeft(8, '0').toUpperCase());
    final String? r = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cor em hexadecimal'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'AARRGGBB ou RRGGBB',
            prefixText: '#',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (r == null) return;
    String h = r.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final int? n = h.length == 8 ? int.tryParse(h, radix: 16) : null;
    if (n == null) {
      _msg('Cor inválida. Use 6 ou 8 dígitos hexadecimais.');
      return;
    }
    _up(() => on(n));
  }

  // ---------- controles reutilizaveis ----------

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          t.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF29E6FF),
          ),
        ),
      );

  Widget _sl(String label, double v, double mn, double mx,
      ValueChanged<double> on,
      {int dec = 2}) {
    final double val = v.clamp(mn, mx).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('$label: ${val.toStringAsFixed(dec)}',
              style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ),
        Slider(
          value: val,
          min: mn,
          max: mx,
          onChanged: (double x) => _up(() => on(x)),
        ),
      ],
    );
  }

  Widget _dd(String label, String v, Map<String, String> opts,
      ValueChanged<String> on) {
    final String val = opts.containsKey(v) ? v : opts.keys.first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            isExpanded: true,
            isDense: true,
            items: <DropdownMenuItem<String>>[
              for (final MapEntry<String, String> e in opts.entries)
                DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
            ],
            onChanged: (String? x) {
              if (x != null) _up(() => on(x));
            },
          ),
        ),
      ),
    );
  }

  Widget _sw(String label, bool v, ValueChanged<bool> on) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label),
        value: v,
        onChanged: (bool x) => _up(() => on(x)),
      );

  Widget _color(String label, int v, ValueChanged<int> on) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            TextButton(
              onPressed: () => _hexDialog(v, on),
              child: Text(
                  '#${v.toRadixString(16).padLeft(8, '0').toUpperCase()}'),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final int c in kPalette)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _up(() => on(c)),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c == v ? Colors.white : Colors.white30,
                      width: c == v ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------- painel da cena ----------

  List<Widget> _sceneProps(Scene sc) {
    return <Widget>[
      _title('Cena'),
      TextFormField(
        key: ValueKey<String>('nome-${sc.id}'),
        initialValue: sc.name,
        decoration: const InputDecoration(
            labelText: 'Nome da cena', border: OutlineInputBorder()),
        onChanged: (String v) => _up(() => sc.name = v),
      ),
      const SizedBox(height: 8),
      _color('Cor de fundo', sc.bg, (int c) => sc.bg = c),
      _title('Efeito de fundo'),
      _dd('Efeito', sc.effect, kEffectNames, (String v) => sc.effect = v),
      if (sc.effect != 'nenhum' && sc.effect != 'scanlines')
        _color('Cor do efeito', sc.effectColor, (int c) => sc.effectColor = c),
      _title('Data comemorativa'),
      _sw('Mostrar sozinha neste período', sc.schedOn,
          (bool v) => sc.schedOn = v),
      if (sc.schedOn) ...<Widget>[
        Row(
          children: <Widget>[
            Expanded(
                child: _dd('De: dia', '${sc.sd}', _range(1, 31),
                    (String v) => sc.sd = int.parse(v))),
            const SizedBox(width: 8),
            Expanded(
                child: _dd('mês', '${sc.sm}', _range(1, 12),
                    (String v) => sc.sm = int.parse(v))),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
                child: _dd('Até: dia', '${sc.ed}', _range(1, 31),
                    (String v) => sc.ed = int.parse(v))),
            const SizedBox(width: 8),
            Expanded(
                child: _dd('mês', '${sc.em}', _range(1, 12),
                    (String v) => sc.em = int.parse(v))),
          ],
        ),
      ],
      _title('Camadas (de cima para baixo)'),
      if (sc.layers.isEmpty)
        const Text('Nenhuma camada. Use o botão + para adicionar.'),
      for (final Layer l in sc.layers.reversed)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(_iconOf(l.type)),
          title: Text(kTypeNames[l.type] ?? l.type),
          subtitle: l.text.isEmpty
              ? null
              : Text(l.text, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => setState(() => _sel = l.id),
        ),
    ];
  }

  IconData _iconOf(String type) {
    switch (type) {
      case 'clock':
        return Icons.schedule;
      case 'date':
        return Icons.calendar_today;
      case 'countdown':
        return Icons.hourglass_bottom;
      case 'image':
        return Icons.photo_library_outlined;
      case 'video':
        return Icons.movie_outlined;
      case 'shape':
        return Icons.category_outlined;
      case 'ring':
        return Icons.radio_button_unchecked;
      case 'progress':
        return Icons.linear_scale;
      default:
        return Icons.text_fields;
    }
  }

  // ---------- painel da camada ----------

  List<Widget> _layerProps(Scene sc, Layer l) {
    final bool isText = l.type == 'text' ||
        l.type == 'clock' ||
        l.type == 'date' ||
        l.type == 'countdown';
    final List<Widget> out = <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              kTypeNames[l.type] ?? l.type,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Fechar camada',
            onPressed: () => setState(() => _sel = null),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      Wrap(
        spacing: 4,
        children: <Widget>[
          IconButton(
            tooltip: 'Duplicar',
            onPressed: () => _up(() {
              final Layer c = l.copy();
              c.x = (c.x + 0.03).clamp(0.0, 1.0).toDouble();
              c.y = (c.y + 0.03).clamp(0.0, 1.0).toDouble();
              sc.layers.add(c);
              _sel = c.id;
            }),
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Trazer para frente',
            onPressed: () => _up(() {
              final int i = sc.layers.indexOf(l);
              if (i >= 0 && i < sc.layers.length - 1) {
                sc.layers.removeAt(i);
                sc.layers.insert(i + 1, l);
              }
            }),
            icon: const Icon(Icons.flip_to_front),
          ),
          IconButton(
            tooltip: 'Enviar para trás',
            onPressed: () => _up(() {
              final int i = sc.layers.indexOf(l);
              if (i > 0) {
                sc.layers.removeAt(i);
                sc.layers.insert(i - 1, l);
              }
            }),
            icon: const Icon(Icons.flip_to_back),
          ),
          IconButton(
            tooltip: 'Excluir camada',
            onPressed: () => _up(() {
              sc.layers.remove(l);
              _sel = null;
            }),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ];

    if (l.type == 'text' || l.type == 'countdown') {
      out.addAll(<Widget>[
        _title('Texto'),
        TextFormField(
          key: ValueKey<String>('txt-${l.id}'),
          initialValue: l.text,
          maxLines: null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText: l.type == 'countdown'
                ? 'Use {dias} onde o número deve aparecer'
                : null,
          ),
          onChanged: (String v) => _up(() => l.text = v),
        ),
      ]);
    }
    if (l.type == 'countdown') {
      out.add(Row(
        children: <Widget>[
          Expanded(
              child: _dd('Dia', '${l.targetDay}', _range(1, 31),
                  (String v) => l.targetDay = int.parse(v))),
          const SizedBox(width: 8),
          Expanded(
              child: _dd('Mês', '${l.targetMonth}', _range(1, 12),
                  (String v) => l.targetMonth = int.parse(v))),
        ],
      ));
    }
    if (l.type == 'clock') {
      out.add(_dd(
          'Formato',
          l.mode,
          const <String, String>{
            'hm': 'Horas e minutos',
            'hms': 'Com segundos',
            'ss': 'Só segundos',
          },
          (String v) => l.mode = v));
    }
    if (l.type == 'date') {
      out.add(_dd(
          'Formato',
          l.mode,
          const <String, String>{
            'longa': '9 de novembro de 2026',
            'curta': 'seg, 9 nov',
            'semana': 'Dia da semana',
            'numerica': '09.11.2026',
          },
          (String v) => l.mode = v));
    }
    if (isText) {
      out.addAll(<Widget>[
        _title('Letra'),
        _dd('Fonte', l.font,
            <String, String>{for (final String f in kFonts) f: f},
            (String v) => l.font = v),
        _sl('Tamanho', l.fontSize, 0.015, 0.6, (double v) => l.fontSize = v,
            dec: 3),
        _dd(
            'Alinhamento',
            l.align,
            const <String, String>{
              'left': 'Esquerda',
              'center': 'Centro',
              'right': 'Direita',
            },
            (String v) => l.align = v),
        _sw('Negrito', l.bold, (bool v) => l.bold = v),
        _sw('Maiúsculas', l.upper, (bool v) => l.upper = v),
        _sw('Brilho neon', l.glow, (bool v) => l.glow = v),
      ]);
    }
    if (l.type == 'image') {
      out.addAll(<Widget>[
        _title('Fotos (${l.paths.length})'),
        FilledButton.icon(
          onPressed: () => _pickPhotos(l),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Adicionar fotos'),
        ),
        if (l.paths.isNotEmpty)
          TextButton.icon(
            onPressed: () => _up(() => l.paths = <String>[]),
            icon: const Icon(Icons.clear_all),
            label: const Text('Remover todas'),
          ),
        _sl('Segundos por foto', l.interval, 3, 120,
            (double v) => l.interval = v.roundToDouble(),
            dec: 0),
      ]);
    }
    if (l.type == 'video') {
      out.addAll(<Widget>[
        _title('Vídeo'),
        FilledButton.icon(
          onPressed: () => _pickVideo(l),
          icon: const Icon(Icons.video_library_outlined),
          label: Text(l.paths.isEmpty ? 'Escolher vídeo' : 'Trocar vídeo'),
        ),
        _sw('Sem som', l.muted, (bool v) => l.muted = v),
      ]);
    }
    if (l.type == 'image' || l.type == 'video') {
      out.add(_dd(
          'Enquadramento',
          l.fit,
          const <String, String>{
            'cover': 'Preencher (corta as bordas)',
            'contain': 'Inteiro (pode sobrar faixa)',
          },
          (String v) => l.fit = v));
    }
    if (l.type == 'shape') {
      out.addAll(<Widget>[
        _title('Forma'),
        _dd(
            'Tipo',
            l.shape,
            const <String, String>{
              'rect': 'Retângulo',
              'circulo': 'Círculo',
              'linha': 'Linha',
              'triangulo': 'Triângulo',
              'estrela': 'Estrela',
            },
            (String v) => l.shape = v),
        _sw('Preenchida', l.filled, (bool v) => l.filled = v),
        _sl('Espessura do traço', l.stroke, 1, 20, (double v) => l.stroke = v,
            dec: 1),
      ]);
    }
    if (l.type == 'ring') {
      out.addAll(<Widget>[
        _title('Anel'),
        _dd(
            'Estilo',
            l.mode,
            const <String, String>{
              'tracejado': 'Tracejado',
              'segmentos': 'Segmentos',
              'arco': 'Arco curto',
              'solido': 'Círculo inteiro',
            },
            (String v) => l.mode = v),
        _sl('Espessura', l.stroke, 1, 20, (double v) => l.stroke = v, dec: 1),
      ]);
    }
    if (l.type == 'progress') {
      out.add(_dd(
          'Mostra o avanço do',
          l.mode,
          const <String, String>{
            'minuto': 'Minuto',
            'dia': 'Dia',
            'ano': 'Ano',
          },
          (String v) => l.mode = v));
    }
    if (l.type != 'image' && l.type != 'video') {
      out.add(_color('Cor', l.color, (int c) => l.color = c));
    }
    out.addAll(<Widget>[
      _title('Animação'),
      _dd('Tipo', l.anim, kAnimNames, (String v) => l.anim = v),
      if (l.anim != 'nenhuma')
        _sl('Duração do ciclo (s)', l.animSpeed, 0.5, 60,
            (double v) => l.animSpeed = v,
            dec: 1),
      _title('Posição e tamanho'),
      _sl('Horizontal', l.x, 0, 1, (double v) => l.x = v),
      _sl('Vertical', l.y, 0, 1, (double v) => l.y = v),
      _sl('Largura', l.w, 0.01, 1.2, (double v) => l.w = v),
      _sl('Altura', l.h, 0.01, 1.2, (double v) => l.h = v),
      _sl('Rotação (graus)', l.rotation, -180, 180,
          (double v) => l.rotation = v.roundToDouble(),
          dec: 0),
      _sl('Opacidade', l.opacity, 0.05, 1, (double v) => l.opacity = v),
      const SizedBox(height: 24),
    ]);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final Scene sc = _scene;
    final Layer? l = _layer;
    final double aspect = MediaQuery.of(context).size.aspectRatio;
    return Scaffold(
      backgroundColor: const Color(0xFF10141C),
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text('Editando: ${sc.name}'),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: 'Adicionar camada',
            icon: const Icon(Icons.add_circle_outline),
            onSelected: _add,
            itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
              for (final MapEntry<String, String> e in kTypeNames.entries)
                PopupMenuItem<String>(
                  value: e.key,
                  child: Row(
                    children: <Widget>[
                      Icon(_iconOf(e.key), size: 20),
                      const SizedBox(width: 12),
                      Text(e.value),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Concluir'),
            ),
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspect <= 0 ? 1.6 : aspect,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24)),
                    child: SceneView(
                      scene: sc,
                      editing: true,
                      selectedId: _sel,
                      onSelect: (String? id) => setState(() => _sel = id),
                      onChanged: () => _up(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 340,
            color: const Color(0xFF161C28),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              children: l == null ? _sceneProps(sc) : _layerProps(sc, l),
            ),
          ),
        ],
      ),
    );
  }
}
