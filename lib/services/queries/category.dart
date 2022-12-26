import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/extensions/pagination.dart';

class CategoryQueries {
  final list = InfiniteQueryJob<Page<Category>, Map<String, dynamic>, int>(
    queryKey: "categories-query",
    initialParam: 0,
    serialize: (data) => jsonEncode(data.toJson()),
    deserialize: (data) => PageJson.fromJson(
      jsonDecode(data),
      (item) => Category.fromJson(item),
    ),
    serializePageParam: (data) => data.toString(),
    deserializePageParam: (data) => int.parse(data),
    getNextPageParam: (lastPage, lastParam) =>
        lastPage.isLast ? null : lastPage.nextOffset,
    getPreviousPageParam: (lastPage, lastParam) => lastPage.nextOffset - 16,
    refetchOnExternalDataChange: true,
    task: (queryKey, pageParam, data) async {
      final SpotifyApi spotify = data["spotify"] as SpotifyApi;
      final String recommendationMarket = data["recommendationMarket"];
      final categories = await spotify.categories
          .list(country: recommendationMarket)
          .getPage(15, pageParam);

      return categories;
    },
  );

  final playlistsOf =
      InfiniteQueryJob.withVariableKey<Page<PlaylistSimple>, SpotifyApi, int>(
    preQueryKey: "category-playlists",
    initialParam: 0,
    serialize: (data) => jsonEncode(data.toJson()),
    deserialize: (data) => PageJson.fromJson(
      jsonDecode(data),
      (item) => PlaylistSimple.fromJson(item),
    ),
    serializePageParam: (data) => data.toString(),
    deserializePageParam: (data) => int.parse(data),
    getNextPageParam: (lastPage, lastParam) => lastPage.nextOffset,
    getPreviousPageParam: (lastPage, lastParam) => lastPage.nextOffset - 6,
    task: (queryKey, pageKey, spotify) async {
      final id = getVariable(queryKey);
      try {
        if (id == "user-featured-playlists") {
          return await spotify.playlists.featured.getPage(5, pageKey);
        }
        return await spotify.playlists.getByCategoryId(id).getPage(5, pageKey);
      } catch (e) {
        print("Error($queryKey): $e");
        rethrow;
      }
    },
  );
}
