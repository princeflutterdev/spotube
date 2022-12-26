import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/album_simple.dart';
import 'package:spotube/extensions/track.dart';

class AlbumQueries {
  final ofMine = QueryJob<Iterable<AlbumSimple>, SpotifyApi>(
    queryKey: "current-user-albums",
    serialize: (data) {
      return jsonEncode(data.map((e) => e.toJson()).toList());
    },
    deserialize: (data) {
      return List.from(jsonDecode(data)).map((e) => AlbumSimple.fromJson(e));
    },
    task: (_, spotify) {
      return spotify.me.savedAlbums().all();
    },
  );

  final tracksOf = QueryJob.withVariableKey<List<TrackSimple>, SpotifyApi>(
    preQueryKey: "album-tracks",
    serialize: (data) => jsonEncode(data.map((e) => e.toJson()).toList()),
    deserialize: (data) {
      return List.from(jsonDecode(data))
          .map((e) => TrackSimple.fromJson(e))
          .toList();
    },
    task: (queryKey, spotify) {
      final id = getVariable(queryKey);
      return spotify.albums.getTracks(id).all().then((value) => value.toList());
    },
  );

  final isSavedForMe = QueryJob.withVariableKey<bool, SpotifyApi>(
    preQueryKey: "is-saved-album",
    serialize: (data) => data.toString(),
    deserialize: (data) => data == "true",
    task: (queryKey, spotify) {
      return spotify.me
          .isSavedAlbums([getVariable(queryKey)]).then((value) => value.first);
    },
  );
}
