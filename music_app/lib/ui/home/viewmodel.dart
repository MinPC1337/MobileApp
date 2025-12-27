import 'dart:async';

import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/repository/repository.dart';

class MusicAppViewModel {
  StreamController<List<Song>> songStream = StreamController();

  void loadSongs() async {
    final repository = DefaultRepository();
    repository.loadData().then((value) {
      songStream.add(value!);
    });
  }
}
