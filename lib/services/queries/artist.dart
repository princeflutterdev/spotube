import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/artist_simple.dart';
import 'package:spotube/extensions/pagination.dart';
import 'package:spotube/extensions/track.dart';

class ArtistQueries {
  final get = QueryJob.withVariableKey<Artist, SpotifyApi>(
    preQueryKey: "artist-profile",
    serialize: (data) => jsonEncode(data.toJson()),
    deserialize: (data) => Artist.fromJson(jsonDecode(data)),
    task: (queryKey, externalData) =>
        externalData.artists.get(getVariable(queryKey)),
  );

  final followedByMe = InfiniteQueryJob<CursorPage<Artist>, SpotifyApi, String>(
    queryKey: "user-following-artists",
    initialParam: "",
    serialize: (data) => jsonEncode(
      data.toJson(),
    ),
    deserialize: (data) => CursorPageJson.fromJson(
      jsonDecode(data),
      (item) => Artist.fromJson(item),
    ),
    serializePageParam: (data) => data,
    deserializePageParam: (data) => data,
    getNextPageParam: (lastPage, lastParam) => lastPage.after,
    getPreviousPageParam: (lastPage, lastParam) =>
        lastPage.metadata.previous ?? "",
    task: (queryKey, pageKey, spotify) {
      return spotify.me.following(FollowingType.artist).getPage(15, pageKey);
    },
  );

  final doIFollow = QueryJob.withVariableKey<bool, SpotifyApi>(
    preQueryKey: "user-follows-artists-query",
    serialize: (data) => data.toString(),
    deserialize: (data) => data == "true",
    task: (artistId, spotify) async {
      final result = await spotify.me.isFollowing(
        FollowingType.artist,
        [getVariable(artistId)],
      );
      return result.first;
    },
  );

  final topTracksOf = QueryJob.withVariableKey<Iterable<Track>, SpotifyApi>(
    preQueryKey: "artist-top-track-query",
    serialize: (data) => jsonEncode(data.map((e) => e.toJson()).toList()),
    deserialize: (data) {
      return List.from(jsonDecode(data)).map((e) => Track.fromJson(e));
    },
    task: (queryKey, spotify) {
      return spotify.artists.getTopTracks(getVariable(queryKey), "US");
    },
  );

  final albumsOf =
      InfiniteQueryJob.withVariableKey<Page<Album>, SpotifyApi, int>(
    preQueryKey: "artist-albums",
    initialParam: 0,
    serialize: (data) => jsonEncode(
      data.toJson(),
    ),
    deserialize: (data) => PageJson.fromJson(
      jsonDecode(data),
      (item) => Album.fromJson(item),
    ),
    serializePageParam: (data) => data.toString(),
    deserializePageParam: (data) => int.parse(data),
    getNextPageParam: (lastPage, lastParam) => lastPage.nextOffset,
    getPreviousPageParam: (lastPage, lastParam) => lastPage.nextOffset - 6,
    task: (queryKey, pageKey, spotify) {
      final id = getVariable(queryKey);
      return spotify.artists.albums(id).getPage(5, pageKey);
    },
  );

  final relatedArtistsOf =
      QueryJob.withVariableKey<Iterable<Artist>, SpotifyApi>(
    preQueryKey: "artist-related-artist-query",
    serialize: (data) => jsonEncode(
      data.map((e) => e.toJson()).toList(),
    ),
    deserialize: (data) {
      return List.from(jsonDecode(data)).map((e) => Artist.fromJson(e));
    },
    task: (queryKey, spotify) {
      return spotify.artists.getRelatedArtists(getVariable(queryKey));
    },
  );
}
