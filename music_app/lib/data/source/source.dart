import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/song.dart';

abstract interface class DataSource {
  Future<List<Song>?> loadData();
}

class RemoteDataSource implements DataSource {
  @override
  Future<List<Song>?> loadData() async {
    const url = 'https://thantrieu.com/resources/braniumapis/songs.json';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final bodyContent = utf8.decode(response.bodyBytes);
      var songwraper = json.decode(bodyContent) as Map;
      var songsList = songwraper['songs'] as List;
      List<Song> songs = songsList.map((song) => Song.fromJson(song)).toList();
      return songs;
    } else {
      return null;
    }
  }
}

class LocalDataSource implements DataSource {
  @override
  Future<List<Song>?> loadData() {
    throw UnimplementedError();
  }
}
