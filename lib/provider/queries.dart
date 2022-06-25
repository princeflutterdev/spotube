import 'package:fl_query/fl_query.dart';
import 'package:spotify/spotify.dart';

final categoriesQueryJob = QueryJob<Page<Category>, Map<String, dynamic>>(
  queryKey: "categories-query",
  task: (_, data, __) {
    final SpotifyApi spotify = data["spotify"];
    final String recommendationMarket = data["recommendationMarket"];
    final int pageKey = data["pageKey"];
    return spotify.categories
        .list(country: recommendationMarket)
        .getPage(15, pageKey);
  },
);

final currentUserPlaylistsQueryJob =
    QueryJob<Iterable<PlaylistSimple>, SpotifyApi>(
  queryKey: "current-user-playlist-query",
  task: (_, spotify, __) async {
    return await spotify.playlists.me.all();
  },
);

final artistProfileQueryJob =
    QueryJob.withVariableKey<Artist, Map<String, dynamic>>(
  preQueryKey: "artist-profile-query",
  task: (_, data, __) async {
    final String id = data["id"];
    final SpotifyApi spotify = data["spotify"];
    return await spotify.artists.get(id);
  },
);

final artistTopTracksQueryJob =
    QueryJob.withVariableKey<Iterable<Track>, Map<String, dynamic>>(
  preQueryKey: "artist-top-track-query",
  task: (ref, data, __) {
    final String id = data["id"];
    final SpotifyApi spotify = data["spotify"];
    return spotify.artists.getTopTracks(id, "US");
  },
);

final artistAlbumsQueryJob =
    QueryJob.withVariableKey<Page<Album>, Map<String, dynamic>>(
  preQueryKey: "artist-albums-query",
  task: (ref, data, __) {
    final String id = data["id"];
    final SpotifyApi spotify = data["spotify"];
    return spotify.artists.albums(id).getPage(5, 0);
  },
);

final artistRelatedArtistsQueryJob =
    QueryJob.withVariableKey<Iterable<Artist>, Map<String, dynamic>>(
  preQueryKey: "artist-related-artist-query",
  task: (ref, data, __) {
    final String id = data["id"];
    final SpotifyApi spotify = data["spotify"];
    return spotify.artists.getRelatedArtists(id);
  },
);

final currentUserFollowsArtistQueryJob =
    QueryJob.withVariableKey<bool, Map<String, dynamic>>(
  preQueryKey: "user-follows-artists-query",
  task: (ref, data, __) async {
    final String artistId = data["id"];
    final SpotifyApi spotify = data["spotify"];
    final result = await spotify.me.isFollowing(
      FollowingType.artist,
      [artistId],
    );
    return result.first;
  },
);
