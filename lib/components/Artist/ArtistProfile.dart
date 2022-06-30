import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/Album/AlbumCard.dart';
import 'package:spotube/components/Artist/ArtistCard.dart';
import 'package:spotube/components/LoaderShimmers/ShimmerArtistProfile.dart';
import 'package:spotube/components/LoaderShimmers/ShimmerTrackTile.dart';
import 'package:spotube/components/Shared/PageWindowTitleBar.dart';
import 'package:spotube/components/Shared/TrackTile.dart';
import 'package:spotube/helpers/image-to-url-string.dart';
import 'package:spotube/helpers/readable-number.dart';
import 'package:spotube/helpers/zero-pad-num-str.dart';
import 'package:spotube/hooks/useBreakpointValue.dart';
import 'package:spotube/hooks/useBreakpoints.dart';
import 'package:spotube/models/CurrentPlaylist.dart';
import 'package:spotube/models/Logger.dart';
import 'package:spotube/provider/Playback.dart';
import 'package:spotube/provider/SpotifyDI.dart';
import 'package:spotube/provider/SpotifyRequests.dart';
import 'package:spotube/provider/queries.dart';

class ArtistProfile extends HookConsumerWidget {
  final String artistId;
  final logger = getLogger(ArtistProfile);
  ArtistProfile(this.artistId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    SpotifyApi spotify = ref.watch(spotifyProvider);
    final scrollController = useScrollController();
    final parentScrollController = useScrollController();
    final textTheme = Theme.of(context).textTheme;
    final chipTextVariant = useBreakpointValue(
      sm: textTheme.bodySmall,
      md: textTheme.bodyMedium,
      lg: textTheme.headline6,
      xl: textTheme.headline6,
      xxl: textTheme.headline6,
    );

    final avatarWidth = useBreakpointValue(
      sm: MediaQuery.of(context).size.width * 0.50,
      md: MediaQuery.of(context).size.width * 0.40,
      lg: MediaQuery.of(context).size.width * 0.18,
      xl: MediaQuery.of(context).size.width * 0.18,
      xxl: MediaQuery.of(context).size.width * 0.18,
    );

    final breakpoint = useBreakpoints();

    final Playback playback = ref.watch(playbackProvider);

    final query = useQuery(
      job: useMemoized(() => artistProfileQueryJob(artistId), [artistId]),
      externalData: {"id": artistId, "spotify": spotify},
    );

    final albumsQuery = useQuery(
      job: useMemoized(() => artistAlbumsQueryJob(artistId), [artistId]),
      externalData: {"id": artistId, "spotify": spotify},
    );

    final relatedArtistsQuery = useQuery(
      job:
          useMemoized(() => artistRelatedArtistsQueryJob(artistId), [artistId]),
      externalData: {"id": artistId, "spotify": spotify},
    );

    final topTracksQuery = useQuery(
      job: useMemoized(() => artistTopTracksQueryJob(artistId), [artistId]),
      externalData: {"id": artistId, "spotify": spotify},
    );

    final isFollowingQuery = useQuery(
      job: useMemoized(
          () => currentUserFollowsArtistQueryJob(artistId), [artistId]),
      externalData: {"id": artistId, "spotify": spotify},
    );

    return SafeArea(
        child: Scaffold(
            appBar: const PageWindowTitleBar(
              leading: BackButton(),
            ),
            body: Builder(builder: (context) {
              if (query.isLoading || !query.hasData) {
                return const ShimmerArtistProfile();
              } else if (query.hasError) {
                return const Text("Life's miserable");
              }
              return SingleChildScrollView(
                controller: parentScrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        const SizedBox(width: 50),
                        CircleAvatar(
                          radius: avatarWidth,
                          backgroundImage: CachedNetworkImageProvider(
                            imageToUrlString(query.data!.images),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(50)),
                                child: Text(query.data!.type!.toUpperCase(),
                                    style: chipTextVariant?.copyWith(
                                        color: Colors.white)),
                              ),
                              Text(
                                query.data!.name!,
                                style: breakpoint.isSm
                                    ? textTheme.headline4
                                    : textTheme.headline2,
                              ),
                              Text(
                                "${toReadableNumber(query.data!.followers!.total!.toDouble())} followers",
                                style: breakpoint.isSm
                                    ? textTheme.bodyText1
                                    : textTheme.headline5,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isFollowingQuery.isLoading ||
                                          !isFollowingQuery.hasData
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton(
                                          onPressed: () async {
                                            try {
                                              isFollowingQuery.data!
                                                  ? await spotify.me.unfollow(
                                                      FollowingType.artist,
                                                      [artistId],
                                                    )
                                                  : await spotify.me.follow(
                                                      FollowingType.artist,
                                                      [artistId],
                                                    );
                                            } catch (e, stack) {
                                              logger.e(
                                                "FollowButton.onPressed",
                                                e,
                                                stack,
                                              );
                                            } finally {
                                              QueryBowl.of(context)
                                                  .refetchQueries([
                                                currentUserFollowsArtistQueryJob(
                                                  artistId,
                                                ).queryKey,
                                              ]);
                                            }
                                          },
                                          child: Text(
                                            isFollowingQuery.data!
                                                ? "Following"
                                                : "Follow",
                                          ),
                                        ),
                                  IconButton(
                                    icon: const Icon(Icons.share_rounded),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                            text: query
                                                .data!.externalUrls?.spotify),
                                      ).then((val) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            width: 300,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              "Artist URL copied to clipboard",
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      });
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Builder(builder: (context) {
                      if (topTracksQuery.isLoading || !topTracksQuery.hasData) {
                        return const ShimmerTrackTile(noSliver: true);
                      }
                      final topTracks = topTracksQuery.data!;
                      final isPlaylistPlaying =
                          playback.currentPlaylist?.id == query.data!.id;
                      playPlaylist(List<Track> tracks,
                          {Track? currentTrack}) async {
                        currentTrack ??= tracks.first;
                        if (!isPlaylistPlaying) {
                          playback.setCurrentPlaylist = CurrentPlaylist(
                            tracks: tracks,
                            id: query.data!.id!,
                            name: "${query.data!.name!} To Tracks",
                            thumbnail: imageToUrlString(query.data!.images),
                          );
                          playback.setCurrentTrack = currentTrack;
                        } else if (isPlaylistPlaying &&
                            currentTrack.id != null &&
                            currentTrack.id != playback.currentTrack?.id) {
                          playback.setCurrentTrack = currentTrack;
                        }
                        await playback.startPlaying();
                      }

                      return Column(children: [
                        Row(
                          children: [
                            Text(
                              "Top Tracks",
                              style: Theme.of(context).textTheme.headline4,
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: IconButton(
                                icon: Icon(isPlaylistPlaying
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded),
                                color: Colors.white,
                                onPressed: () =>
                                    playPlaylist(topTracks.toList()),
                              ),
                            )
                          ],
                        ),
                        ...topTracks.toList().asMap().entries.map((track) {
                          String duration =
                              "${track.value.duration?.inMinutes.remainder(60)}:${zeroPadNumStr(track.value.duration?.inSeconds.remainder(60) ?? 0)}";
                          String? thumbnailUrl = imageToUrlString(
                              track.value.album?.images,
                              index:
                                  (track.value.album?.images?.length ?? 1) - 1);
                          return TrackTile(
                            playback,
                            duration: duration,
                            track: track,
                            thumbnailUrl: thumbnailUrl,
                            onTrackPlayButtonPressed: (currentTrack) =>
                                playPlaylist(
                              topTracks.toList(),
                              currentTrack: track.value,
                            ),
                          );
                        }),
                      ]);
                    }),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Albums",
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        TextButton(
                          child: const Text("See All"),
                          onPressed: () {
                            GoRouter.of(context).push(
                              "/artist-album/$artistId",
                              extra: query.data!.name ?? "KRTX",
                            );
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    albumsQuery.isLoading || !albumsQuery.hasData
                        ? const CircularProgressIndicator.adaptive()
                        : Scrollbar(
                            controller: scrollController,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: albumsQuery.data!.items
                                        ?.map((album) => AlbumCard(album))
                                        .toList() ??
                                    [],
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    Text(
                      "Fans also likes",
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    const SizedBox(height: 10),
                    relatedArtistsQuery.isLoading ||
                            !relatedArtistsQuery.hasData
                        ? const CircularProgressIndicator.adaptive()
                        : Center(
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: relatedArtistsQuery.data!
                                  .map((artist) => ArtistCard(artist))
                                  .toList(),
                            ),
                          )
                  ],
                ),
              );
            })));
  }
}
