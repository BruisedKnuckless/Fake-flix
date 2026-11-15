/// The app's frame: page header, filter chips, floating tab bar and the
/// full-screen category picker.
library;

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import 'basics.dart';

/// Height of the header's title row (without the status bar or chips).
const headerHeight = 52.0;

/// Height the chips row adds under the title.
const chipsHeight = 54.0;

/// F logo + page name + profile avatar, floating over the page. It turns
/// into frosted glass once the page is scrolled, and the chips under it
/// tuck away while scrolling down.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.scrolled = false,
    this.chips = const [],
    this.chipsHidden = false,
  });

  final String title;
  final bool scrolled;
  final List<Widget> chips;
  final bool chipsHidden;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final showChips = chips.isNotEmpty && !chipsHidden;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: scrolled ? const Color(0xC7121212) : Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, top + 4, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: headerHeight - 4,
            child: Row(
              children: [
                Image.asset('assets/fakeflix-icon.png', height: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                ),
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: openProfiles,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
                      child: Avatar.of(store.active, size: 30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: showChips
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: SizedBox(
                      height: 38,
                      child: Row(
                        children: [
                          for (final chip in chips) Padding(padding: const EdgeInsets.only(right: 8), child: chip),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 6),
          ),
        ],
      ),
    );

    if (!scrolled) return content;
    return ClipRect(
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: content),
    );
  }
}

/// One filter chip under the header. [caret] adds the little ▾ that marks a
/// picker; [close] makes it the round ✕ that goes back to Home.
class PillChip extends StatelessWidget {
  const PillChip({super.key, this.label = '', required this.onTap, this.active = false, this.caret = false})
      : close = false;

  const PillChip.close({super.key, required this.onTap})
      : label = '',
        active = false,
        caret = false,
        close = true;

  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool caret;
  final bool close;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 38,
        width: close ? 38 : null,
        alignment: Alignment.center,
        padding: close ? null : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.30 : 0.13),
          borderRadius: BorderRadius.circular(close ? 19 : 12),
          border: Border.all(color: Colors.white.withValues(alpha: active ? 0.45 : 0.26)),
        ),
        child: close
            ? const Icon(Icons.close, size: 18, color: Colors.white)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  if (caret) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

/// The floating frosted pill with the four tabs.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.index, required this.onTap, required this.profile});
  final int index;
  final ValueChanged<int> onTap;
  final Profile? profile;

  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    Widget tab(int i, String label, Widget Function(Color color) icon) {
      final color = i == index ? Colors.white : const Color(0xFF8F8F8F);
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 28, child: Center(child: icon(color))),
              const SizedBox(height: 3),
              Text(label, maxLines: 1, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  height: height,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xBD282828),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    children: [
                      tab(0, 'Home', (c) => Icon(index == 0 ? CupertinoIcons.house_fill : CupertinoIcons.house, color: c, size: 24)),
                      tab(1, 'New & Hot', (c) => Icon(index == 1 ? CupertinoIcons.flame_fill : CupertinoIcons.flame, color: c, size: 24)),
                      tab(2, 'Search', (c) => Icon(CupertinoIcons.search, color: c, size: 25)),
                      tab(
                        3,
                        'My FakeFlix',
                        (c) => Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: index == 3 ? Colors.white : Colors.transparent, width: 1.5),
                          ),
                          child: Avatar.of(profile, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the category picker returns for its first entry ("Home", "TV Shows"
/// or "Movies"): go back to the page the categories belong to.
const pickedParent = 'parent';

/// Full-screen blurred list of categories. Returns the chosen
/// [GenreCategory], [pickedParent], or null if it was just closed.
/// [only] limits the list to categories that exist for that type.
Future<Object?> showCategoryPicker(BuildContext context, {MediaType? only, GenreCategory? current}) {
  return Navigator.of(context, rootNavigator: true).push<Object?>(
    PageRouteBuilder<Object?>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, animation, _) => FadeTransition(
        opacity: animation,
        child: _CategoryPicker(only: only, current: current),
      ),
    ),
  );
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({this.only, this.current});
  final MediaType? only;
  final GenreCategory? current;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final parent = switch (only) {
      MediaType.tv => 'TV Shows',
      MediaType.movie => 'Movies',
      null => 'Home',
    };

    Widget entry(String label, bool selected, Object value) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: selected
                ? const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)
                : const TextStyle(fontSize: 19, color: AppColors.muted),
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: ColoredBox(
          color: const Color(0xDB0A0A0A),
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(24, padding.top + 70, 24, 160),
                children: [
                  entry(parent, current == null, pickedParent),
                  for (final c in categories)
                    if (only == null || c.idFor(only!) != null) entry(c.name, c == current, c),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: padding.bottom + 34,
                child: Center(
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 6))],
                      ),
                      child: const Icon(Icons.close, color: Colors.black, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
