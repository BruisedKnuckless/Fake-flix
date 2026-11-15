import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../data/tmdb.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets/basics.dart';
import '../widgets/posters.dart';
import 'shell.dart';

/// Search tab: a field, a "Top Searches" list until something is typed, then
/// a grid of results.
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<List<MediaItem>>? _results;

  // What's popular this week, shown before anything is typed
  late Future<List<MediaItem>> _top = _loadTop();

  Future<List<MediaItem>> _loadTop() async {
    final items = await tmdb.row(const RowDef('', '/trending/all/week'));
    return items.where((i) => i.backdropPath != null).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  /// Wait until typing pauses for 300ms, then search (2+ letters).
  void _onChanged(String text) {
    setState(() {}); // shows or hides the ✕
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = text.trim();
      if (!mounted || q == _query) return;
      setState(() {
        _query = q;
        _results = q.length < 2 ? null : tmdb.search(q);
      });
    });
  }

  void _clear() {
    _debounce?.cancel();
    _input.clear();
    setState(() {
      _query = '';
      _results = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final searching = _results != null;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 14),
            child: _field(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              searching ? 'Results for “$_query”' : 'Top Searches',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (searching) _resultsSliver() else _topSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: tabBarClearance)),
      ],
    );
  }

  Widget _field() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, color: AppColors.muted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _input,
              onChanged: _onChanged,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              cursorColor: Colors.white,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: const InputDecoration.collapsed(
                hintText: 'Titles, movies, shows',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ),
          ),
          if (_input.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(CupertinoIcons.clear_circled_solid, color: AppColors.muted, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultsSliver() {
    return FutureBuilder<List<MediaItem>>(
      key: ValueKey(_query), // a newer search replaces an older one outright
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 16), sliver: SkeletonSliverGrid(count: 12));
        }
        if (snap.hasError) {
          return const SliverToBoxAdapter(child: Notice('Search failed.\nCheck your connection and try again.'));
        }
        final items = snap.data ?? const <MediaItem>[];
        if (items.isEmpty) {
          return SliverToBoxAdapter(child: Notice('No movies or shows match “$_query”.'));
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: PosterSliverGrid(items: items),
        );
      },
    );
  }

  Widget _topSliver() {
    return FutureBuilder<List<MediaItem>>(
      future: _top,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CupertinoActivityIndicator())));
        }
        if (snap.hasError) {
          return SliverToBoxAdapter(
            child: Notice(
              "Couldn't load suggestions.\nCheck your connection and try again.",
              action: GhostButton(label: 'Retry', solid: true, onTap: () => setState(() => _top = _loadTop())),
            ),
          );
        }
        final items = snap.data ?? const <MediaItem>[];
        return SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => _TopRow(item: items[i]),
        );
      },
    );
  }
}

/// One line of the Top Searches list: thumbnail, title, play icon.
class _TopRow extends StatelessWidget {
  const _TopRow({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Pressable(
        onTap: () => openTitle(context, item),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ColoredBox(
            color: const Color(0xFF1F1F1F),
            child: Row(
              children: [
                SizedBox(
                  width: 132,
                  child: AspectRatio(aspectRatio: 16 / 9, child: NetImage(imageUrl(item.backdropPath, 'w300'))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.play_arrow_rounded, size: 30, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
