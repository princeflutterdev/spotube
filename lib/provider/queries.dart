import 'package:fl_query/fl_query.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/helpers/getLyrics.dart';
import 'package:spotube/helpers/image-to-url-string.dart';
import 'package:collection/collection.dart';
import 'package:spotube/helpers/timed-lyrics.dart';
import 'package:spotube/models/SpotubeTrack.dart';

final categoriesInfiniteQueryJob =
    InfiniteQueryJob<Page<Category>, Map<String, dynamic>, int>(
  queryKey: "categories-query",
  initialParam: 0,
  getNextPageParam: (lastPage, lastParam) => lastPage.nextOffset,
  getPreviousPageParam: (lastPage, lastParam) => lastPage.nextOffset - 16,
  task: (queryKey, pageParam, data) {
    final SpotifyApi spotify = data["spotify"] as SpotifyApi;
    final String recommendationMarket = data["recommendationMarket"];
    return spotify.categories
        .list(country: recommendationMarket)
        .getPage(15, pageParam);
  },
);

final currentUserPlaylistsQueryJob =
    QueryJob<Iterable<PlaylistSimple>, SpotifyApi>(
  queryKey: "current-user-playlist-query",
  task: (_, spotify) async {
    return await spotify.playlists.me.all();
  },
);

final artistProfileQueryJob =
    QueryJob.withVariableKey<Artist, Map<String, dynamic>>(
  preQueryKey: "artist-profile-query",
  task: (_, data) async {
    final String id = data["id"] as String;
    final SpotifyApi spotify = data["spotify"] as SpotifyApi;
    return await spotify.artists.get(id);
  },
);

final artistTopTracksQueryJob =
    QueryJob.withVariableKey<Iterable<Track>, Map<String, dynamic>>(
  preQueryKey: "artist-top-track-query",
  task: (ref, data) {
    final String id = data["id"] as String;
    final SpotifyApi spotify = data["spotify"] as SpotifyApi;
    return spotify.artists.getTopTracks(id, "US");
  },
);

final artistAlbumsQueryJob =
    QueryJob.withVariableKey<Page<Album>, Map<String, dynamic>>(
  preQueryKey: "artist-albums-query",
  task: (ref, data) {
    final String id = data["id"] as String;
    final SpotifyApi spotify = data["spotify"] as SpotifyApi;
    return spotify.artists.albums(id).getPage(5, 0);
  },
);

final artistRelatedArtistsQueryJob =
    QueryJob.withVariableKey<Iterable<Artist>, Map<String, dynamic>>(
  preQueryKey: "artist-related-artist-query",
  task: (ref, data) {
    final String id = data["id"] as String;
    final SpotifyApi spotify = data["spotify"] as SpotifyApi;
    return spotify.artists.getRelatedArtists(id);
  },
);

final currentUserFollowsArtistQueryJob =
    QueryJob.withVariableKey<bool, Map<String, dynamic>>(
  preQueryKey: "user-follows-artists-query",
  task: (ref, data) async {
    final String artistId = data["id"] as String;
    final SpotifyApi spotify = data["spotify"] as SpotifyApi;
    final result = await spotify.me.isFollowing(
      FollowingType.artist,
      [artistId],
    );
    return result.first;
  },
);

final currentUserSavedTracksQueryJob = QueryJob<List<Track>, SpotifyApi>(
  queryKey: "user-saved-tracks",
  task: (_, spotify) {
    return spotify.tracks.me.saved.all().then(
          (tracks) => tracks.map((e) => e.track!).toList(),
        );
  },
);

final playlistTracksQueryJob =
    QueryJob.withVariableKey<List<Track>, Map<String, dynamic>>(
  preQueryKey: "playlist-tracks",
  task: (_, externalData) {
    final spotify = externalData["spotify"] as SpotifyApi;
    final id = externalData["id"] as String;
    return id != "user-liked-tracks"
        ? spotify.playlists.getTracksByPlaylistId(id).all().then(
              (value) => value.toList(),
            )
        : spotify.tracks.me.saved.all().then(
              (tracks) => tracks.map((e) => e.track!).toList(),
            );
  },
);

final currentUserQueryJob = QueryJob<User, SpotifyApi>(
  queryKey: "current-user",
  task: (_, spotify) async {
    final me = await spotify.me.get();
    if (me.images == null || me.images?.isEmpty == true) {
      me.images = [
        Image()
          ..height = 50
          ..width = 50
          ..url = imageToUrlString(me.images),
      ];
    }
    return me;
  },
);

final playlistIsFollowedQueryJob =
    QueryJob.withVariableKey<bool, Map<String, dynamic>>(
  preQueryKey: "playlist-is-followed",
  task: (_, externalData) {
    final playlistId = externalData["playlistId"] as String;
    final userId = externalData["userId"] as String;
    final spotify = externalData["spotify"] as SpotifyApi;
    return spotify.playlists
        .followedBy(playlistId, [userId]).then((value) => value.first);
  },
);

final albumIsSavedForCurrentUserQueryJob =
    QueryJob.withVariableKey<bool, Map<String, dynamic>>(
        task: (ref, externalData) {
  final spotify = externalData["spotify"] as SpotifyApi;
  final albumId = externalData["id"] as String;
  return spotify.me.isSavedAlbums([albumId]).then((value) => value.first);
});

final searchMutationJob = MutationJob<List<Page>, Map<String, dynamic>>(
  mutationKey: "search-query",
  task: (ref, variables) {
    final spotify = variables["spotify"] as SpotifyApi;
    final queryString = variables["query"];
    if (queryString.isEmpty) return [];
    return spotify.search.get(queryString).first(10);
  },
);

final geniusLyricsQueryJob = QueryJob<String, Map<String, dynamic>>(
  queryKey: "genius-lyrics-query",
  task: (_, externalData) async {
    final currentTrack = externalData["currentTrack"] as Track?;
    final geniusAccessToken = externalData["geniusAccessToken"] as String;
    if (currentTrack == null) {
      return "“Give this player a track to play”\n- S'Challa";
    }
    final lyrics = await getLyrics(
      currentTrack.name!,
      currentTrack.artists?.map((s) => s.name).whereNotNull().toList() ?? [],
      apiKey: geniusAccessToken,
      optimizeQuery: true,
    );

    if (lyrics == null) throw Exception("Unable find lyrics");
    return lyrics;
  },
);

final rentanadviserLyricsQueryJob =
    QueryJob<SubtitleSimple, Map<String, dynamic>>(
  queryKey: "synced-lyrics",
  retries: 0,
  task: (_, externalData) async {
    final currentTrack = externalData["currentTrack"] as SpotubeTrack?;
    if (currentTrack == null) throw "No track currently";

    final timedLyrics = await getTimedLyrics(currentTrack);
    if (timedLyrics == null) throw Exception("Unable to find lyrics");

    return timedLyrics;
  },
);

final albumTracksQueryJob =
    QueryJob.withVariableKey<List<TrackSimple>, Map<String, dynamic>>(
  preQueryKey: "album-tracks",
  task: (_, data) {
    final spotify = data["spotify"] as SpotifyApi;
    final id = data["id"] as String;
    return spotify.albums.getTracks(id).all().then((value) => value.toList());
  },
);

final currentUserAlbumsQueryJob = QueryJob<Iterable<AlbumSimple>, SpotifyApi>(
  queryKey: "current-user-albums",
  task: (_, spotify) {
    return spotify.me.savedAlbums().all();
  },
);

final categoryPlaylistsInfiniteQueryJob =
    InfiniteQueryJob.withVariableKey<Page<PlaylistSimple>, SpotifyApi, int>(
  preQueryKey: "category-playlists",
  initialParam: 0,
  getNextPageParam: (lastPage, lastParam) => lastPage.nextOffset,
  getPreviousPageParam: (lastPage, lastParam) => lastPage.nextOffset - 4,
  task: (queryKey, pageKey, spotify) {
    final id = getVariable(queryKey);
    return (id != "user-featured-playlists"
            ? spotify.playlists.getByCategoryId(id)
            : spotify.playlists.featured)
        .getPage(3, pageKey);
  },
);

final currentUserFollowingArtistsInfiniteQueryJob =
    InfiniteQueryJob<CursorPage<Artist>, SpotifyApi, String>(
  queryKey: "current-user-followed-artists",
  initialParam: "",
  getNextPageParam: (lastPage, lastParam) => lastPage.items!.last.id!,
  getPreviousPageParam: (lastPage, lastParam) => lastPage.items!.first.id!,
  task: (queryKey, pageParam, spotify) {
    return spotify.me.following(FollowingType.artist).getPage(
          15,
          pageParam,
        );
  },
);
