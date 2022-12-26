import 'package:spotify/spotify.dart';

extension ImageJson on Image {
  Map<String, dynamic> toJson() => {
        'height': height,
        'url': url,
        'width': width,
      };
}
