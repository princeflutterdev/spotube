import 'dart:async';

import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/album_simple.dart';
import 'package:spotube/extensions/artist_simple.dart';
import 'package:spotube/models/matched_track.dart';
import 'package:spotube/services/youtube/youtube.dart';
import 'package:spotube/utils/service_utils.dart';
import 'package:collection/collection.dart';

class SpotubeTrack extends Track {
  final YoutubeVideoInfo ytTrack;
  final String ytUri;

  final List<YoutubeVideoInfo> siblings;

  SpotubeTrack(
    this.ytTrack,
    this.ytUri,
    this.siblings,
  ) : super();

  SpotubeTrack.fromTrack({
    required Track track,
    required this.ytTrack,
    required this.ytUri,
    required this.siblings,
  }) : super() {
    album = track.album;
    artists = track.artists;
    availableMarkets = track.availableMarkets;
    discNumber = track.discNumber;
    durationMs = track.durationMs;
    explicit = track.explicit;
    externalIds = track.externalIds;
    externalUrls = track.externalUrls;
    href = track.href;
    id = track.id;
    isPlayable = track.isPlayable;
    linkedFrom = track.linkedFrom;
    name = track.name;
    popularity = track.popularity;
    previewUrl = track.previewUrl;
    trackNumber = track.trackNumber;
    type = track.type;
    uri = track.uri;
  }

  static Future<List<YoutubeVideoInfo>> fetchSiblings(
    Track track,
    YoutubeEndpoints client,
  ) async {
    final artists = (track.artists ?? [])
        .map((ar) => ar.name)
        .toList()
        .whereNotNull()
        .toList();

    final title = ServiceUtils.getTitle(
      track.name!,
      artists: artists,
      onlyCleanArtist: true,
    ).trim();

    final List<YoutubeVideoInfo> siblings =
        await client.search("$title - ${artists.join(", ")}").then(
      (res) {
        final siblings = res
            .where((item) {
              return artists.any(
                (artist) =>
                    artist.toLowerCase() == item.channelName.toLowerCase(),
              );
            })
            .take(10)
            .toList();

        if (siblings.isEmpty) {
          return res.take(10).toList();
        }

        return siblings;
      },
    );

    return siblings;
  }

  static Future<SpotubeTrack> fetchFromTrack(
    Track track,
    YoutubeEndpoints client,
  ) async {
    final matchedCachedTrack = await MatchedTrack.box.get(track.id!);
    var siblings = <YoutubeVideoInfo>[];
    YoutubeVideoInfo ytVideo;
    String ytStreamUrl;
    if (matchedCachedTrack != null &&
        matchedCachedTrack.searchMode == client.preferences.searchMode) {
      (ytVideo, ytStreamUrl) = await client.video(
        matchedCachedTrack.youtubeId,
        matchedCachedTrack.searchMode,
      );
    } else {
      siblings = await fetchSiblings(track, client);
      if (siblings.isEmpty) {
        throw Exception("Failed to find any results for ${track.name}");
      }
      (ytVideo, ytStreamUrl) =
          await client.video(siblings.first.id, siblings.first.searchMode);

      await MatchedTrack.box.put(
        track.id!,
        MatchedTrack(
          youtubeId: ytVideo.id,
          spotifyId: track.id!,
          searchMode: siblings.first.searchMode,
        ),
      );
    }

    return SpotubeTrack.fromTrack(
      track: track,
      ytTrack: ytVideo,
      ytUri: ytStreamUrl,
      siblings: siblings,
    );
  }

  Future<SpotubeTrack?> swappedCopy(
    YoutubeVideoInfo video,
    YoutubeEndpoints client,
  ) async {
    // sibling tracks that were manually searched and swapped
    final isStepSibling = siblings.none((element) => element.id == video.id);

    final (ytVideo, ytStreamUrl) =
        await client.video(video.id, siblings.first.searchMode);

    if (!isStepSibling) {
      await MatchedTrack.box.put(
        id!,
        MatchedTrack(
          youtubeId: video.id,
          spotifyId: id!,
          searchMode: siblings.first.searchMode,
        ),
      );
    }

    return SpotubeTrack.fromTrack(
      track: this,
      ytTrack: ytVideo,
      ytUri: ytStreamUrl,
      siblings: [
        video,
        ...siblings.where((element) => element.id != video.id),
      ],
    );
  }

  static SpotubeTrack fromJson(Map<String, dynamic> map) {
    return SpotubeTrack.fromTrack(
      track: Track.fromJson(map),
      ytTrack: YoutubeVideoInfo.fromJson(map["ytTrack"]),
      ytUri: map["ytUri"],
      siblings: List.castFrom<dynamic, Map<String, dynamic>>(map["siblings"])
          .map((sibling) => YoutubeVideoInfo.fromJson(sibling))
          .toList(),
    );
  }

  Future<SpotubeTrack> populatedCopy(YoutubeEndpoints client) async {
    if (this.siblings.isNotEmpty) return this;

    final siblings = await fetchSiblings(
      this,
      client,
    );

    return SpotubeTrack.fromTrack(
      track: this,
      ytTrack: ytTrack,
      ytUri: ytUri,
      siblings: siblings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // super values
      "album": album?.toJson(),
      "artists": artists?.map((artist) => artist.toJson()).toList(),
      "availableMarkets": availableMarkets,
      "discNumber": discNumber,
      "duration": duration.toString(),
      "durationMs": durationMs,
      "explicit": explicit,
      "href": href,
      "id": id,
      "isPlayable": isPlayable,
      "name": name,
      "popularity": popularity,
      "previewUrl": previewUrl,
      "trackNumber": trackNumber,
      "type": type,
      "uri": uri,
      // this values
      "ytTrack": ytTrack.toJson(),
      "ytUri": ytUri,
      "siblings": siblings.map((sibling) => sibling.toJson()).toList(),
    };
  }
}
