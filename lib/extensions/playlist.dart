import 'package:spotube/extensions/image.dart';
import 'package:spotube/extensions/user.dart';
import 'package:spotube/extensions/pagination.dart';
import 'package:spotify/spotify.dart';

extension PlaylistSimpleJson on PlaylistSimple {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'images': images?.map((e) => e.toJson()).toList(),
        'owner': owner?.toJson(),
        'public': public,
        'snapshotId': snapshotId,
        'type': type,
        'uri': uri,
        "collaborative": collaborative,
        "href": href,
        "tracksLink": {
          "href": tracksLink?.href,
          "total": tracksLink?.total,
        },
      };
}

extension PlaylistJson on Playlist {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'images': images?.map((e) => e.toJson()).toList(),
        'owner': owner?.toJson(),
        'public': public,
        'snapshotId': snapshotId,
        'type': type,
        'uri': uri,
        "collaborative": collaborative,
        "href": href,
        "tracksLink": {
          "href": tracksLink?.href,
          "total": tracksLink?.total,
        },
        "followers": followers?.toJson(),
        "tracks": tracks?.toJson(),
      };
}
