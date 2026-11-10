import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'editor.dart';
import 'model.dart';
import 'render.dart';
import 'store.dart';
import 'templates.dart';

Future<void> _immersive() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await _immersive();
  final Store store = Store();
  await store.load();
  try {
    await WakelockPlus.enable();
  } catch (_) {}
  Ticks.start(store.project.effects);
  runApp(PainelApp(store: store));
}

class PainelApp extends StatelessWidget {
  const PainelApp({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel Tab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29E6FF),
          brightness: Brightness.dark,
        ),
      ),
      home: PlayerPage(store: store),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.store});

  final Store store;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  bool _bar = false;
  bool _manual = false; // escolha manual ignora o agendamento
  Timer? _minute;

  Store get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_onStore);
    _minute = Timer.periodic(const Duration(minutes: 1), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.removeListener(_onStore);
    _minute?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _immersive();
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused) {
      store.save();
    }
  }

  Future<void> _edit(Scene s) async {
    setState(() => _bar = false);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext _) => EditorPage(store: store, sceneId: s.id),
    ));
    await store.save();
    await _immersive();
    if (mounted) setState(() {});
  }

  void _newScene(String key) {
    final Scene s = Templates.make(key);
    store.project.scenes.add(s);
    store.project.currentId = s.id;
    _manual = true;
    store.touch();
  }

  Future<void> _deleteScene(Scene s) async {
    if (store.project.scenes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('É preciso manter pelo menos uma cena.')));
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Excluir "${s.name}"?'),
        content: const Text('A cena e as camadas dela serão apagadas.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    store.project.scenes.removeWhere((Scene x) => x.id == s.id);
    store.project.currentId = store.project.scenes.first.id;
    store.touch();
  }

  Future<void> _settings() async {
    final Project p = store.project;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setS) {
          void ch(VoidCallback f) {
            setS(f);
            store.touch();
          }

          Widget hour(String label, int v, ValueChanged<int> on) => Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: v.clamp(0, 23).toInt(),
                      isExpanded: true,
                      isDense: true,
                      items: <DropdownMenuItem<int>>[
                        for (int i = 0; i < 24; i++)
                          DropdownMenuItem<int>(
                              value: i, child: Text('${i}h')),
                      ],
                      onChanged: (int? x) {
                        if (x != null) ch(() => on(x));
                      },
                    ),
                  ),
                ),
              );

          return AlertDialog(
            title: const Text('Configurações'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Animações e efeitos'),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const <ButtonSegment<int>>[
                        ButtonSegment<int>(
                            value: 0, label: Text('Desligado')),
                        ButtonSegment<int>(value: 1, label: Text('Baixo')),
                        ButtonSegment<int>(value: 2, label: Text('Alto')),
                      ],
                      selected: <int>{p.effects.clamp(0, 2).toInt()},
                      onSelectionChanged: (Set<int> s) => ch(() {
                        p.effects = s.first;
                        Ticks.start(p.effects);
                      }),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Baixo usa menos quadros por segundo e esquenta menos.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Trocar sozinho em datas marcadas'),
                      subtitle: const Text(
                          'Cenas com período definido aparecem na época certa.'),
                      value: p.auto,
                      onChanged: (bool v) => ch(() {
                        p.auto = v;
                        _manual = false;
                      }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Escurecer à noite'),
                      value: p.nightOn,
                      onChanged: (bool v) => ch(() => p.nightOn = v),
                    ),
                    if (p.nightOn) ...<Widget>[
                      Row(
                        children: <Widget>[
                          hour('Das', p.nightStart,
                              (int v) => p.nightStart = v),
                          const SizedBox(width: 8),
                          hour('Até', p.nightEnd, (int v) => p.nightEnd = v),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Intensidade: ${(p.nightDim * 100).round()}%'),
                      Slider(
                        value: p.nightDim.clamp(0.1, 0.95).toDouble(),
                        min: 0.1,
                        max: 0.95,
                        onChanged: (double v) => ch(() => p.nightDim = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      ),
    );
    await _immersive();
  }

  Widget _toolbar(Scene active) {
    final Project p = store.project;
    return Container(
      color: const Color(0xE6101620),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final Scene s in p.scenes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(s.name),
                        ),
                        avatar: s.schedOn
                            ? const Icon(Icons.event, size: 18)
                            : null,
                        selected: s.id == active.id,
                        onSelected: (bool _) {
                          p.currentId = s.id;
                          _manual = true;
                          store.touch();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Editar esta cena',
            iconSize: 28,
            onPressed: () => _edit(active),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Nova cena',
            iconSize: 28,
            icon: const Icon(Icons.add_box_outlined),
            onSelected: _newScene,
            itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
              for (final MapEntry<String, String> e
                  in Templates.names.entries)
                PopupMenuItem<String>(
                    value: e.key, child: Text('Nova: ${e.value}')),
            ],
          ),
          IconButton(
            tooltip: 'Duplicar esta cena',
            iconSize: 28,
            onPressed: () {
              final Scene c = active.copy();
              c.name = '${active.name} (cópia)';
              c.schedOn = false;
              p.scenes.add(c);
              p.currentId = c.id;
              _manual = true;
              store.touch();
            },
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            tooltip: 'Excluir esta cena',
            iconSize: 28,
            onPressed: () => _deleteScene(active),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Configurações',
            iconSize: 28,
            onPressed: _settings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final Project p = store.project;
    final Scene scene = store.activeScene(now, ignoreSchedule: _manual);
    final bool night = p.isNight(now);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _bar = !_bar),
              child: SceneView(
                key: ValueKey<String>('${scene.id}-${p.effects}'),
                scene: scene,
              ),
            ),
          ),
          if (night && !_bar)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withAlpha(
                      (p.nightDim.clamp(0.0, 0.95) * 255).round()),
                ),
              ),
            ),
          if (_bar)
            Positioned(left: 0, right: 0, bottom: 0, child: _toolbar(scene)),
        ],
      ),
    );
  }
}
