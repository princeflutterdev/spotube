import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/Album/AlbumCard.dart';
import 'package:spotube/components/LoaderShimmers/ShimmerPlaybuttonCard.dart';
import 'package:spotube/helpers/simple-album-to-album.dart';
import 'package:spotube/provider/SpotifyDI.dart';
import 'package:spotube/provider/queries.dart';

class UserAlbums extends ConsumerWidget {
  const UserAlbums({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final spotify = ref.watch(spotifyProvider);

    return QueryBuilder<Iterable<AlbumSimple>, SpotifyApi>(
      job: currentUserAlbumsQueryJob,
      externalData: spotify,
      builder: (context, query) {
        if (query.hasError) {
          return const Text("Failure is the pillar of success");
        } else if (!query.hasData || query.isLoading) {
          return const Center(child: ShimmerPlaybuttonCard(count: 7));
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 20, // gap between adjacent chips
              runSpacing: 20, // gap between lines
              alignment: WrapAlignment.center,
              children: query.data!
                  .map((album) => AlbumCard(simpleAlbumToAlbum(album)))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
