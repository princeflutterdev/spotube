import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/helpers/artist-to-string.dart';
import 'package:spotube/hooks/useBreakpoints.dart';
import 'package:spotube/provider/Playback.dart';
import 'package:spotube/provider/SpotifyRequests.dart';
import 'package:spotube/provider/UserPreferences.dart';
import 'package:spotube/provider/queries.dart';

class Lyrics extends HookConsumerWidget {
  const Lyrics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    Playback playback = ref.watch(playbackProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final breakpoint = useBreakpoints();
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              playback.currentTrack?.name ?? "",
              style: breakpoint >= Breakpoints.md
                  ? textTheme.headline3
                  : textTheme.headline4?.copyWith(fontSize: 25),
            ),
          ),
          Center(
            child: Text(
              artistsToString<Artist>(playback.currentTrack?.artists ?? []),
              style: breakpoint >= Breakpoints.md
                  ? textTheme.headline5
                  : textTheme.headline6,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: QueryBuilder<String, Map<String, dynamic>>(
                    job: geniusLyricsQueryJob,
                    externalData: {
                      "currentTrack": playback.currentTrack,
                      "geniusAccessToken": preferences.geniusAccessToken,
                    },
                    builder: (context, query) {
                      if (query.hasError) {
                        return Text(
                            "Sorry, no Lyrics were found for `${playback.currentTrack?.name}` :'(");
                      } else if (!query.hasData || query.isLoading) {
                        return const CircularProgressIndicator();
                      }
                      return Text(
                        query.data!,
                        style: textTheme.headline6
                            ?.copyWith(color: textTheme.headline1?.color),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Powered by genius.com"),
            ),
          )
        ],
      ),
    );
  }
}
