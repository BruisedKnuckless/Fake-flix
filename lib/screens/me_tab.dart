import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/basics.dart';
import '../widgets/chrome.dart';
import '../widgets/posters.dart';
import 'saved_grid_screen.dart';
import 'shell.dart';

/// "My FakeFlix": the profile and everything saved on it, in one place.
class MeTab extends StatelessWidget {
  const MeTab({super.key});

  void _seeAll(BuildContext context, SavedKind kind) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(builder: (_) => SavedGridScreen(kind: kind)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + headerHeight;

    return Stack(
      children: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final profile = store.active;
            final empty = store.list.isEmpty && store.likes.isEmpty && store.resume.isEmpty && store.history.isEmpty;

            return ListView(
              padding: EdgeInsets.only(top: top + 14, bottom: tabBarClearance),
              children: [
                _profileBlock(profile),
                const SizedBox(height: 26),
                if (store.likes.isNotEmpty)
                  PosterRow(
                    title: "TV Shows & Movies You've Liked",
                    items: store.likes,
                    onSeeAll: () => _seeAll(context, SavedKind.likes),
                  ),
                if (store.list.isNotEmpty)
                  PosterRow(title: 'My List', items: store.list, onSeeAll: () => _seeAll(context, SavedKind.list)),
                if (store.resume.isNotEmpty) PosterRow(title: 'Continue Watching', items: store.resume, resume: true),
                if (store.history.isNotEmpty)
                  PosterRow(
                    title: 'Recently Watched',
                    items: store.history,
                    onSeeAll: () => _seeAll(context, SavedKind.history),
                  ),
                if (profile != null && empty)
                  const Notice('Titles you like, add to My List or watch will show up here.'),
                const _Credits(),
              ],
            );
          },
        ),
        const Positioned(top: 0, left: 0, right: 0, child: AppHeader(title: 'My FakeFlix', scrolled: true)),
      ],
    );
  }

  Widget _profileBlock(Profile? profile) {
    if (profile == null) {
      return Column(
        children: [
          const Avatar(colorIndex: null, size: 84, radius: 8),
          const SizedBox(height: 12),
          const Text('Guest', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Padding(
            padding: EdgeInsets.fromLTRB(40, 12, 40, 16),
            child: Text(
              "You're browsing as a guest, so nothing is saved. A profile keeps your list, likes and watch history on this device.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
            ),
          ),
          GhostButton(
            label: store.profiles.isEmpty ? 'Create a profile' : 'Choose a profile',
            solid: true,
            onTap: openProfiles,
          ),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: openProfiles,
      child: Column(
        children: [
          Avatar.of(profile, size: 84, radius: 8),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const Icon(Icons.arrow_drop_down_rounded, size: 28),
            ],
          ),
        ],
      ),
    );
  }
}

/// The footer credits.
class _Credits extends StatelessWidget {
  const _Credits();

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(color: AppColors.dim, fontSize: 12.5, height: 1.5);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(opacity: 0.55, child: Image.asset('assets/fakeflix-logo.png', height: 18)),
          const SizedBox(height: 12),
          const Text('This app is intended for personal use only and not for commercial purposes.', style: small),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Made by Viraj & Claude',
              style: TextStyle(color: AppColors.muted, fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
          const Text('This product uses the TMDB API but is not endorsed or certified by TMDB.', style: small),
        ],
      ),
    );
  }
}
