/// Shortcuts for moving between screens.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data/models.dart';
import 'screens/player_screen.dart';
import 'screens/profiles_screen.dart';
import 'screens/title_screen.dart';
import 'state/profile_store.dart';
import 'theme.dart';

/// Lets code without a BuildContext (e.g. a message's button) open screens.
final navigatorKey = GlobalKey<NavigatorState>();

/// The title page slides up over everything, like a sheet.
void openTitle(BuildContext context, MediaItem item) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute<void>(fullscreenDialog: true, builder: (_) => TitleScreen(preview: item)),
  );
}

void openPlayer(BuildContext context, MediaItem item, {int? season, int? episode, bool replace = false}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => PlayerScreen(item: item, season: season, episode: episode),
  );
  final navigator = Navigator.of(context, rootNavigator: true);
  if (replace) {
    navigator.pushReplacement(route);
  } else {
    navigator.push(route);
  }
}

/// Where "Play" should go: movies play directly, shows resume where you
/// left off or start at the first episode.
void playItem(BuildContext context, MediaItem item, {List<SeasonInfo> seasons = const []}) {
  if (item.type == MediaType.movie) return openPlayer(context, item);
  final resume = store.resumeFor(item);
  if (resume?.season != null && resume?.episode != null) {
    return openPlayer(context, item, season: resume!.season, episode: resume.episode);
  }
  openPlayer(context, item, season: seasons.isNotEmpty ? seasons.first.number : 1, episode: 1);
}

void openProfiles() {
  navigatorKey.currentState?.push(
    CupertinoPageRoute<void>(fullscreenDialog: true, builder: (_) => const ProfilesScreen()),
  );
}

/// Saving needs a profile. Guests get a nudge instead (returns false).
bool requireProfile(BuildContext context) {
  if (!store.isGuest) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        actionOverflowThreshold: 1, // keep the button on the same line as the text
        content: const Text(
          'Create a profile to save your list, likes and progress.',
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
        action: SnackBarAction(
          label: store.profiles.isEmpty ? 'Create profile' : 'Choose profile',
          textColor: AppColors.red,
          onPressed: openProfiles,
        ),
      ),
    );
  return false;
}
