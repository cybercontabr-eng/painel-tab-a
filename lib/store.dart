import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'model.dart';
import 'templates.dart';

class Store extends ChangeNotifier {
  Project project = Project();
  Directory? _dir;
  Timer? _debounce;

  Future<void> load() async {
    _dir = await getApplicationDocumentsDirectory();
    final File f = File('${_dir!.path}/painel.json');
    if (await f.exists()) {
      try {
        final dynamic j = jsonDecode(await f.readAsString());
        if (j is Map) {
          project = Project.fromJson(Map<String, dynamic>.from(j));
        }
      } catch (_) {
        project = Project();
      }
    }
    if (project.scenes.isEmpty) {
      project.scenes = Templates.all();
      project.currentId = project.scenes.first.id;
    }
  }

  /// Avisa a interface e grava em disco pouco depois.
  void touch() {
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), save);
  }

  Future<void> save() async {
    final Directory? d = _dir;
    if (d == null) return;
    try {
      final File tmp = File('${d.path}/painel.json.tmp');
      await tmp.writeAsString(jsonEncode(project.toJson()));
      await tmp.rename('${d.path}/painel.json');
    } catch (_) {}
  }

  /// Copia uma foto ou video escolhido para a pasta do app.
  Future<String> importFile(String src) async {
    final Directory media = Directory('${_dir!.path}/media');
    await media.create(recursive: true);
    final int dot = src.lastIndexOf('.');
    final String ext =
        (dot >= 0 && src.length - dot <= 6) ? src.substring(dot) : '';
    final String dst = '${media.path}/${newId()}$ext';
    await File(src).copy(dst);
    return dst;
  }

  Scene current() {
    for (final Scene s in project.scenes) {
      if (s.id == project.currentId) return s;
    }
    return project.scenes.first;
  }

  /// Cena a exibir agora: uma agendada para a data, ou a escolhida.
  Scene activeScene(DateTime now, {bool ignoreSchedule = false}) {
    if (project.auto && !ignoreSchedule) {
      for (final Scene s in project.scenes) {
        if (s.schedOn && s.matches(now)) return s;
      }
    }
    return current();
  }

  Scene? byId(String id) {
    for (final Scene s in project.scenes) {
      if (s.id == id) return s;
    }
    return null;
  }
}
