import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/basics.dart';
import '../widgets/posters.dart';

enum SavedKind { list, likes, history }

/// The "See All" page for My List, Liked or Watch History.
class SavedGridScreen extends StatelessWidget {
  const SavedGridScreen({super.key, required this.kind});
  final SavedKind kind;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// "Nov 14": when a title was last watched.
  static String? _watchedOn(MediaItem item) {
    final at = item.watchedAt;
    if (at == null) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(at);
    return '${_months[date.month - 1]} ${date.day}';
  }

  Future<void> _confirmClear(BuildContext context) async {
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialog) => CupertinoAlertDialog(
        title: const Text('Clear watch history?'),
        content: const Text('Continue Watching is kept.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (yes == true) store.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final (title, emptyText) = switch (kind) {
      SavedKind.list => ('My List', "You haven't added anything to your list yet."),
      SavedKind.likes => ('Liked', 'Titles you give a thumbs up will show up here.'),
      SavedKind.history => ('Watch History', 'Nothing watched on this profile yet.'),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final items = switch (kind) {
              SavedKind.list => store.list,
              SavedKind.likes => store.likes,
              SavedKind.history => store.history,
            };

            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      if (kind == SavedKind.history && items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _confirmClear(context),
                            child: const Text('Clear', style: TextStyle(color: AppColors.muted, fontSize: 15)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: store.isGuest
                              ? Notice(
                                  "You're browsing as a guest, so nothing is saved.",
                                  action: GhostButton(label: 'Create a profile', solid: true, onTap: openProfiles),
                                )
                              : Notice(emptyText),
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                              sliver: PosterSliverGrid(
                                items: items,
                                badgeFor: kind == SavedKind.history ? _watchedOn : null,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
