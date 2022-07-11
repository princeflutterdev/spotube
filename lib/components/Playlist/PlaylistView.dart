import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotube/components/Shared/HeartButton.dart';
import 'package:spotube/components/Shared/TrackCollectionView.dart';
import 'package:spotube/helpers/image-to-url-string.dart';
import 'package:spotube/hooks/usePaletteColor.dart';
import 'package:spotube/models/CurrentPlaylist.dart';
import 'package:spotube/models/Logger.dart';
import 'package:spotube/provider/Auth.dart';
import 'package:spotube/provider/Playback.dart';
import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/provider/SpotifyDI.dart';
import 'package:spotube/provider/queries.dart';

class PlaylistView extends HookConsumerWidget {
  final logger = getLogger(PlaylistView);
  final PlaylistSimple playlist;
  PlaylistView(this.playlist, {Key? key}) : super(key: key);

  playPlaylist(Playback playback, List<Track> tracks,
      {Track? currentTrack}) async {
    currentTrack ??= tracks.first;
    final isPlaylistPlaying = playback.currentPlaylist?.id != null &&
        playback.currentPlaylist?.id == playlist.id;
    if (!isPlaylistPlaying) {
      playback.setCurrentPlaylist = CurrentPlaylist(
        tracks: tracks,
        id: playlist.id!,
        name: playlist.name!,
        thumbnail: imageToUrlString(playlist.images),
      );
      playback.setCurrentTrack = currentTrack;
    } else if (isPlaylistPlaying &&
        currentTrack.id != null &&
        currentTrack.id != playback.currentTrack?.id) {
      playback.setCurrentTrack = currentTrack;
    }
    await playback.startPlaying();
  }

  @override
  Widget build(BuildContext context, ref) {
    Playback playback = ref.watch(playbackProvider);
    final Auth auth = ref.watch(authProvider);
    SpotifyApi spotify = ref.watch(spotifyProvider);
    final isPlaylistPlaying = playback.currentPlaylist?.id != null &&
        playback.currentPlaylist?.id == playlist.id;

    final meQuery = useQuery(
      job: currentUserQueryJob,
      externalData: spotify,
    );

    final tracksQuery = useQuery(
      job: playlistTracksQueryJob(playlist.id!),
      externalData: {
        "spotify": spotify,
        "id": playlist.id,
      },
    );

    final playlistFollowingQuery = useQuery(
      job: playlistIsFollowedQueryJob(playlist.id!),
      externalData: {
        "spotify": spotify,
        "userId": meQuery.data?.id,
        "playlistId": playlist.id,
      },
    );

    final titleImage =
        useMemoized(() => imageToUrlString(playlist.images), [playlist.images]);

    final color = usePaletteGenerator(
      context,
      titleImage,
    ).dominantColor;

    return TrackCollectionView(
      id: playlist.id!,
      isPlaying: isPlaylistPlaying,
      title: playlist.name!,
      titleImage: titleImage,
      tracksQuery: tracksQuery,
      description: playlist.description,
      isOwned:
          playlist.owner?.id != null && playlist.owner!.id == meQuery.data?.id,
      onPlay: ([track]) {
        if (tracksQuery.hasData) {
          playPlaylist(
            playback,
            tracksQuery.data!,
            currentTrack: track,
          );
        }
      },
      showShare: playlist.id != "user-liked-tracks",
      routePath: "/playlist/${playlist.id}",
      onShare: () {
        final data = "https://open.spotify.com/playlist/${playlist.id}";
        Clipboard.setData(
          ClipboardData(text: data),
        ).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              width: 300,
              behavior: SnackBarBehavior.floating,
              content: Text(
                "Copied $data to clipboard",
                textAlign: TextAlign.center,
              ),
            ),
          );
        });
      },
      heartBtn: (auth.isLoggedIn && playlist.id != "user-liked-tracks"
          ? (meQuery.hasData && playlistFollowingQuery.hasData
              ? HeartButton(
                  isLiked: playlistFollowingQuery.data!,
                  color: color?.titleTextColor,
                  icon: playlist.owner?.id != null &&
                          meQuery.data!.id == playlist.owner?.id
                      ? Icons.delete_outline_rounded
                      : null,
                  onPressed: () async {
                    try {
                      playlistFollowingQuery.data!
                          ? await spotify.playlists
                              .unfollowPlaylist(playlist.id!)
                          : await spotify.playlists
                              .followPlaylist(playlist.id!);
                    } catch (e, stack) {
                      logger.e("FollowButton.onPressed", e, stack);
                    } finally {
                      playlistFollowingQuery.refetch();
                      QueryBowl.of(context).refetchQueries([
                        currentUserPlaylistsQueryJob.queryKey,
                      ]);
                    }
                  },
                )
              : const CircularProgressIndicator.adaptive())
          : null),
    );
  }
}
