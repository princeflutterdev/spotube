import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/image.dart';

extension AlbumSimpleJson on AlbumSimple {
  Map<String, dynamic> toJson() {
    return {
      "albumType": albumType,
      "id": id,
      "name": name,
      "images": images
          ?.map((image) => {
                "height": image.height,
                "url": image.url,
                "width": image.width,
              })
          .toList(),
    };
  }
}

extension AlbumJson on Album {
  Map<String, dynamic> toJson() {
    return {
      "albumType": albumType,
      "id": id,
      "name": name,
      "images": images?.map((image) => image.toJson()).toList(),
      "copyrights": copyrights
          ?.map((e) => {
                "text": e.text,
                "type": e.type,
              })
          .toList(),
      "externalIds": {
        "upc": externalIds?.upc,
        "isrc": externalIds?.isrc,
        "ean": externalIds?.ean,
      },
      "genres": genres,
      "label": label,
      "popularity": popularity,
    };
  }
}
