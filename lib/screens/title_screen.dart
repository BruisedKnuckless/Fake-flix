import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/tmdb.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/basics.dart';
import '../widgets/posters.dart';

/// Everything about one movie or show: play it, save it, read about it,
/// pick an episode, find similar titles.
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key, required this.preview});

  /// What the card that was tapped already knew, shown while the rest loads.
  final MediaItem preview;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late Future<MediaDetails> _details;
  int? _season;
  Future<List<Episode>>? _episodes;
  bool _scrolled = false; // true once the backdrop has scrolled out of view

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final preview = widget.preview;
    _details = tmdb.details(preview.type, preview.id).then((details) {
      // Open on the season you were watching, otherwise the first one
      if (details.seasons.isNotEmpty) {
        final resumeSeason = store.resumeFor(details.item)?.season;
        final known = details.seasons.any((s) => s.number == resumeSeason);
        _pickSeason(details, known ? resumeSeason! : details.seasons.first.number);
      }
      return details;
    });
  }

  void _pickSeason(MediaDetails details, int season) {
    _season = season;
    final info = details.seasons.firstWhere((s) => s.number == season);
    _episodes = tmdb.episodes(details.item.id, season, info.episodeCount);
  }

  Future<void> _chooseSeason(MediaDetails details) async {
    final picked = await showCupertinoModalPopup<int>(
      context: context,
      builder: (sheet) => CupertinoActionSheet(
        actions: [
          for (final s in details.seasons)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheet, s.number),
              child: Text('Season ${s.number}'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(sheet), child: const Text('Cancel')),
      ),
    );
    if (picked != null && mounted) setState(() => _pickSeason(details, picked));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          FutureBuilder<MediaDetails>(
            future: _details,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Notice(
                    "Couldn't load this title.\nCheck your connection and try again.",
                    action: GhostButton(label: 'Retry', solid: true, onTap: () => setState(_load)),
                  ),
                );
              }
              // Rebuilds when the list, likes or watch history change
              return NotificationListener<ScrollUpdateNotification>(
                onNotification: (scroll) {
                  final covered = scroll.metrics.axis == Axis.vertical && scroll.metrics.pixels > 150;
                  if (scroll.metrics.axis == Axis.vertical && covered != _scrolled) {
                    setState(() => _scrolled = covered);
                  }
                  return false;
                },
                child: ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => _page(context, snap.data),
                ),
              );
            },
          ),
          // Once the picture has scrolled away, a solid strip keeps the text
          // from running under the clock and the close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _scrolled ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(height: top + 50, color: AppColors.surface),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            right: 10,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Color(0xD1181818), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [details] is null while loading: the page shows what the card knew.
  Widget _page(BuildContext context, MediaDetails? details) {
    final item = details?.item ?? widget.preview;
    final resume = store.resumeFor(item);
    final seasons = details?.seasons ?? const <SeasonInfo>[];
    final resuming = item.type == MediaType.tv && resume?.season != null && resume?.episode != null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: NetImage(
              imageUrl(item.backdropPath ?? item.posterPath, 'w780'),
              alignment: const Alignment(0, -0.6),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverList.list(
            children: [
              Text(item.title, style: const TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              WideButton(
                label: resuming ? 'Play S${resume!.season} E${resume.episode}' : 'Play',
                icon: Icons.play_arrow_rounded,
                onTap: () => playItem(context, item, seasons: seasons),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _IconAction(
                    icon: store.inList(item) ? Icons.check_rounded : Icons.add_rounded,
                    label: 'My List',
                    onTap: () {
                      if (requireProfile(context)) store.toggleList(item);
                    },
                  ),
                  const SizedBox(width: 26),
                  _IconAction(
                    icon: store.isLiked(item) ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    label: store.isLiked(item) ? 'Liked' : 'Like',
                    onTap: () {
                      if (requireProfile(context)) store.toggleLike(item);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _meta(item, details),
              if (details != null && details.tagline.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  details.tagline,
                  style: const TextStyle(color: AppColors.muted, fontSize: 15, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                item.overview.isEmpty ? 'No description available.' : item.overview,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (details == null)
                const Padding(padding: EdgeInsets.all(28), child: CupertinoActivityIndicator())
              else ...[
                const SizedBox(height: 14),
                _fact('Cast', details.cast),
                _fact('Genres', details.genres),
                _fact(item.type == MediaType.tv ? 'Created by' : 'Director', details.makers),
              ],
            ],
          ),
        ),
        if (details != null && seasons.isNotEmpty) ..._episodeSlivers(context, details),
        if (details != null && details.recommendations.isNotEmpty) ...[
          const SliverToBoxAdapter(child: _SectionHead('More Like This')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: PosterSliverGrid(items: details.recommendations),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }

  /// "90% Match  2008  5 Seasons  HD"
  Widget _meta(MediaItem item, MediaDetails? details) {
    final seasons = details?.seasons.length ?? 0;
    final length = item.type == MediaType.movie
        ? runtimeText(details?.runtime)
        : (seasons == 0 ? '' : '$seasons Season${seasons > 1 ? 's' : ''}');
    const plain = TextStyle(color: AppColors.muted, fontSize: 15);

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.vote > 0)
          Text(
            '${item.matchPercent}% Match',
            style: const TextStyle(color: AppColors.green, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        if (item.year.isNotEmpty) Text(item.year, style: plain),
        if (length.isNotEmpty) Text(length, style: plain),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text('HD', style: TextStyle(color: AppColors.soft, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _fact(String label, List<String> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 14, height: 1.45),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.dim)),
            TextSpan(text: values.join(', ')),
          ],
        ),
      ),
    );
  }

  /// Season picker + the episode list for the chosen season.
  List<Widget> _episodeSlivers(BuildContext context, MediaDetails details) {
    final item = details.item;
    final season = _season ?? details.seasons.first.number;
    final resume = store.resumeFor(item);
    final watched = store.historyFor(item)?.episodes ?? const <String>[];

    return [
      SliverToBoxAdapter(
        child: _SectionHead(
          'Episodes',
          trailing: Pressable(
            onTap: () => _chooseSeason(details),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                border: Border.all(color: const Color(0xFF4D4D4D)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Season $season', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Icon(Icons.arrow_drop_down_rounded, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      FutureBuilder<List<Episode>>(
        key: ValueKey('episodes $season'),
        future: _episodes,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(28), child: CupertinoActivityIndicator()),
            );
          }
          final episodes = snap.data ?? const <Episode>[];
          return SliverList.builder(
            itemCount: episodes.length,
            itemBuilder: (context, i) {
              final ep = episodes[i];
              return _EpisodeRow(
                episode: ep,
                current: resume?.season == season && resume?.episode == ep.number,
                watched: watched.contains(episodeTag(season, ep.number)),
                onTap: () => openPlayer(context, item, season: season, episode: ep.number),
              );
            },
          );
        },
      ),
    ];
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Icon with a label under it (My List, Like).
class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: Colors.white),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.current, required this.watched, required this.onTap});
  final Episode episode;
  final bool current; // the episode Continue Watching points at
  final bool watched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final runtime = runtimeText(episode.runtime);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: current ? const Color(0xFF333333) : null,
          border: const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('${episode.number}', style: const TextStyle(fontSize: 16, color: Color(0xFFD2D2D2))),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 112,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(imageUrl(episode.stillPath, 'w300')),
                      const Center(child: Icon(Icons.play_circle_outline_rounded, size: 30, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.name.isEmpty ? 'Episode ${episode.number}' : episode.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (runtime.isNotEmpty || watched)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (runtime.isNotEmpty)
                            Text(runtime, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          if (watched)
                            Padding(
                              padding: EdgeInsets.only(left: runtime.isEmpty ? 0 : 8),
                              child: const Text(
                                'WATCHED',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (episode.overview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        episode.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFD2D2D2), fontSize: 12.5, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
