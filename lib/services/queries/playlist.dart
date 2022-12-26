import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/playlist.dart';
import 'package:spotube/extensions/track.dart';

class PlaylistQueries {
  final doesUserFollow = QueryJob.withVariableKey<bool, SpotifyApi>(
    preQueryKey: "playlist-is-followed",
    serialize: (data) => data.toString(),
    deserialize: (data) => data == "true",
    task: (queryKey, spotify) {
      final idMap = getVariable(queryKey).split(":");

      return spotify.playlists.followedBy(idMap.first, [idMap.last]).then(
        (value) => value.first,
      );
    },
  );

  final ofMine = QueryJob<Iterable<PlaylistSimple>, SpotifyApi>(
    queryKey: "current-user-playlists",
    serialize: (data) => jsonEncode(data.map((e) => e.toJson()).toList()),
    deserialize: (data) {
      return jsonDecode(data)
          .map<PlaylistSimple>((e) => PlaylistSimple.fromJson(e))
          .toList();
    },
    task: (_, spotify) {
      return spotify.playlists.me.all();
    },
  );

  final tracksOf = QueryJob.withVariableKey<List<Track>, SpotifyApi>(
    preQueryKey: "playlist-tracks",
    serialize: (data) => jsonEncode(data.map((e) => e.toJson()).toList()),
    deserialize: (data) {
      return jsonDecode(data).map<Track>((e) => Track.fromJson(e)).toList();
    },
    task: (queryKey, spotify) {
      final id = getVariable(queryKey);
      return id != "user-liked-tracks"
          ? spotify.playlists.getTracksByPlaylistId(id).all().then(
                (value) => value.toList(),
              )
          : spotify.tracks.me.saved.all().then(
                (tracks) => tracks.map((e) => e.track!).toList(),
              );
    },
  );
}
