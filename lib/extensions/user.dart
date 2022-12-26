import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/image.dart';

extension FollowersJson on Followers {
  Map<String, dynamic> toJson() {
    return {
      "href": href,
      "total": total,
    };
  }
}

extension UserJson on User {
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "displayName": displayName,
      "email": email,
      "followers": followers?.toJson(),
      "href": href,
      "images": images?.map((image) => image.toJson()).toList(),
      "type": type,
      "uri": uri,
      "birthdate": birthdate,
      "country": country,
      "product": product,
    };
  }
}
