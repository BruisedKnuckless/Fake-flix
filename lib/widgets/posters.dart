import 'package:flutter/material.dart';

import '../config.dart';
import '../data/models.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import 'basics.dart';

/// One poster. Fills whatever box its parent gives it (usually 2:3).
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.badge,
    this.showPlay = false,
    this.onRemove,
  });

  final MediaItem item;

  /// Defaults to opening the title page.
  final VoidCallback? onTap;
  final String? badge;
  final bool showPlay;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap ?? () => openTitle(context, item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.posterPath != null)
              NetImage(imageUrl(item.posterPath, 'w342'))
            else
              Container(
                color: AppColors.surface2,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            if (showPlay)
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
              ),
            if (badge != null && badge!.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(3)),
                  child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            if (onRemove != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xD9141414),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A Continue Watching card: it plays straight away, shows which episode you
/// were on, and has a ✕ to drop it from the row.
Widget resumeCard(BuildContext context, MediaItem item) {
  final isShow = item.type == MediaType.tv && item.season != null && item.episode != null;
  return PosterCard(
    item: item,
    showPlay: true,
    badge: isShow ? 'S${item.season} E${item.episode}' : null,
    onRemove: () => store.removeResume(item),
    onTap: () => openPlayer(context, item, season: item.season, episode: item.episode),
  );
}

/// A titled row of posters that scrolls sideways.
///
/// Give it either [items] (shown straight away) or a [future] (grey
/// placeholders until it arrives; the row disappears if it fails or is empty).
class PosterRow extends StatelessWidget {
  const PosterRow({
    super.key,
    required this.title,
    this.items,
    this.future,
    this.top10 = false,
    this.resume = false,
    this.onSeeAll,
  });

  final String title;
  final List<MediaItem>? items;
  final Future<List<MediaItem>>? future;
  final bool top10;
  final bool resume;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (items != null) return _row(context, items!);
    return FutureBuilder<List<MediaItem>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _row(context, null);
        final data = snap.data ?? const <MediaItem>[];
        if (snap.hasError || data.isEmpty) return const SizedBox.shrink();
        return _row(context, top10 ? data.take(10).toList() : data);
      },
    );
  }

  /// [list] null = still loading.
  Widget _row(BuildContext context, List<MediaItem>? list) {
    final cardW = MediaQuery.sizeOf(context).width * 0.29;
    final cardH = cardW * 1.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                if (onSeeAll != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSeeAll,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('See All', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list?.length ?? 6,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (list == null) {
                  return Container(
                    width: cardW,
                    decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(6)),
                  );
                }
                final item = list[i];
                if (top10) return _RankedCard(item: item, rank: i + 1, cardW: cardW);
                return SizedBox(
                  width: cardW,
                  child: resume ? resumeCard(context, item) : PosterCard(item: item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Top 10: a big outlined number tucked behind the poster.
class _RankedCard extends StatelessWidget {
  const _RankedCard({required this.item, required this.rank, required this.cardW});
  final MediaItem item;
  final int rank;
  final double cardW;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardW * (rank >= 10 ? 2.05 : 1.55),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: -cardW * 0.14,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: cardW * 1.2,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -cardW * 0.08,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = const Color(0xFF6A6A6A),
              ),
            ),
          ),
          Positioned(top: 0, bottom: 0, right: 0, width: cardW, child: PosterCard(item: item)),
        ],
      ),
    );
  }
}

/// A three-column grid of posters, as a sliver so pages can put things above it.
class PosterSliverGrid extends StatelessWidget {
  const PosterSliverGrid({super.key, required this.items, this.badgeFor});
  final List<MediaItem> items;
  final String? Function(MediaItem item)? badgeFor;

  static const delegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    childAspectRatio: 2 / 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 10,
  );

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: delegate,
      itemCount: items.length,
      itemBuilder: (context, i) => PosterCard(item: items[i], badge: badgeFor?.call(items[i])),
    );
  }
}

/// Grey boxes shown while a grid loads.
class SkeletonSliverGrid extends StatelessWidget {
  const SkeletonSliverGrid({super.key, this.count = 15});
  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: PosterSliverGrid.delegate,
      itemCount: count,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

/// Centered grey message for empty and error states.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}
