import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/album_simple.dart';
import 'package:spotube/extensions/artist_simple.dart';

extension TrackJson on Track {
  Map<String, dynamic> toJson() {
    return {
      "album": album?.toJson(),
      "artists": artists?.map((artist) => artist.toJson()).toList(),
      "availableMarkets": availableMarkets,
      "discNumber": discNumber,
      "duration": duration.toString(),
      "durationMs": durationMs,
      "explicit": explicit,
      // "externalIds": externalIds,
      // "externalUrls": externalUrls,
      "href": href,
      "id": id,
      "isPlayable": isPlayable,
      // "linkedFrom": linkedFrom,
      "name": name,
      "popularity": popularity,
      "previewUrl": previewUrl,
      "trackNumber": trackNumber,
      "type": type,
      "uri": uri,
    };
  }
}

extension TrackSimpleJson on TrackSimple {
  Map<String, dynamic> toJson() {
    return {
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
      "previewUrl": previewUrl,
      "trackNumber": trackNumber,
      "type": type,
      "uri": uri,
    };
  }
}
