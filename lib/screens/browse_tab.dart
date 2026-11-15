import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/tmdb.dart';
import '../state/profile_store.dart';
import '../widgets/basics.dart';
import '../widgets/billboard.dart';
import '../widgets/chrome.dart';
import '../widgets/posters.dart';
import 'shell.dart';

/// A browse page: header, filter chips, and either rows of posters or one
/// category's grid.
///
/// The Home tab uses it with chips to switch between Home, Shows, Movies and
/// categories. The New & Hot tab uses it with [fixedView] and no chips.
class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key, this.fixedView});
  final String? fixedView;

  @override
  State<BrowseTab> createState() => BrowseTabState();
}

class BrowseTabState extends State<BrowseTab> {
  late String _view = widget.fixedView ?? 'home'; // 'home' | 'tv' | 'movies' | 'new'
  GenreCategory? _category; // set while a category grid is showing
  MediaType? _categoryOnly; // that grid's type limit (null = movies and shows)

  final _scroll = ScrollController();
  bool _scrolled = false;
  bool _chipsHidden = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The header frosts over once the page moves, and the chips tuck away
  /// while scrolling down and come back on the way up.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final y = _scroll.positions.last.pixels;
    final scrolled = y > 10;
    var hidden = _chipsHidden;
    if (y > 120 && y > _lastOffset + 6) {
      hidden = true;
    } else if (y <= 120 || y < _lastOffset - 6) {
      hidden = false;
    }
    _lastOffset = y;
    if (scrolled != _scrolled || hidden != _chipsHidden) {
      setState(() {
        _scrolled = scrolled;
        _chipsHidden = hidden;
      });
    }
  }

  void _show(String view, {GenreCategory? category, MediaType? only}) {
    setState(() {
      _view = view;
      _category = category;
      _categoryOnly = only;
      _scrolled = false;
      _chipsHidden = false;
      _lastOffset = 0;
    });
  }

  /// Back to the top of plain Home (the ✕ chip, or tapping the Home tab again).
  void goHome() {
    if (_view == 'home' && _category == null) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      return;
    }
    _show('home');
  }

  Future<void> _pickCategory() async {
    // Categories opened from Shows or Movies stay limited to that type
    final only = _category != null ? _categoryOnly : viewType[_view];
    final picked = await showCategoryPicker(context, only: only, current: _category);
    if (!mounted || picked == null) return;
    if (picked is GenreCategory) {
      _show(_view, category: picked, only: only);
    } else {
      _show(_view); // the first entry: back to the page the categories belong to
    }
  }

  List<Widget> _chips() {
    if (widget.fixedView != null) return const [];
    final close = PillChip.close(onTap: goHome);
    if (_category != null) {
      return [close, PillChip(label: _category!.name, active: true, caret: true, onTap: _pickCategory)];
    }
    final categoriesChip = PillChip(label: 'Categories', caret: true, onTap: _pickCategory);
    return switch (_view) {
      'tv' => [close, PillChip(label: 'Shows', active: true, onTap: () {}), categoriesChip],
      'movies' => [close, PillChip(label: 'Movies', active: true, onTap: () {}), categoriesChip],
      _ => [
          PillChip(label: 'Shows', onTap: () => _show('tv')),
          PillChip(label: 'Movies', onTap: () => _show('movies')),
          categoriesChip,
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final chips = _chips();
    final top = MediaQuery.paddingOf(context).top + headerHeight + (chips.isEmpty ? 6 : chipsHeight);

    return Stack(
      children: [
        // The key makes Flutter build a fresh page (scrolled to the top)
        // whenever the view or category changes.
        if (_category != null)
          _CategoryGrid(
            key: ValueKey('category ${_category!.name} $_categoryOnly'),
            category: _category!,
            only: _categoryOnly,
            controller: _scroll,
            topPadding: top + 8,
          )
        else
          _BrowseRows(key: ValueKey('rows $_view'), view: _view, controller: _scroll, topPadding: top),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppHeader(
            title: _category?.name ?? viewTitles[_view] ?? 'Home',
            scrolled: _scrolled,
            chips: chips,
            chipsHidden: _chipsHidden,
          ),
        ),
      ],
    );
  }
}

/// Billboard + rows for Home, Shows, Movies or New & Hot.
class _BrowseRows extends StatefulWidget {
  const _BrowseRows({super.key, required this.view, required this.controller, required this.topPadding});
  final String view;
  final ScrollController controller;
  final double topPadding;

  @override
  State<_BrowseRows> createState() => _BrowseRowsState();
}

class _BrowseRowsState extends State<_BrowseRows> {
  late final List<RowDef> _defs = browseRows[widget.view]!;
  late List<Future<List<MediaItem>>> _futures;
  MediaItem? _hero;
  bool _failed = false;

  // "Because you liked …": recommendations for the most recent thumbs up
  MediaItem? _likedSource;
  Future<List<MediaItem>>? _because;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _futures = _defs.map(tmdb.row).toList();
    _hero = null;
    _failed = false;

    // The billboard features a random title from the first row
    _futures.first.then((items) {
      final picks = items.where((i) => i.backdropPath != null && i.overview.isNotEmpty).take(8).toList();
      if (mounted && picks.isNotEmpty) setState(() => _hero = picks[Random().nextInt(picks.length)]);
    }, onError: (_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Notice(
          "Couldn't load titles from TMDB.\nCheck your internet connection and try again.",
          action: GhostButton(label: 'Retry', solid: true, onTap: () => setState(_load)),
        ),
      );
    }

    // Rebuilds whenever something is saved or the profile changes
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final hero = _hero;
        return ListView(
          controller: widget.controller,
          padding: const EdgeInsets.only(bottom: tabBarClearance),
          children: [
            if (hero != null)
              Billboard(key: ValueKey('hero ${hero.type.name} ${hero.id}'), item: hero, topPadding: widget.topPadding)
            else
              BillboardSkeleton(topPadding: widget.topPadding),
            PosterRow(title: _defs.first.title, future: _futures.first, top10: _defs.first.top10),
            ..._personalRows(),
            for (var i = 1; i < _defs.length; i++)
              PosterRow(title: _defs[i].title, future: _futures[i], top10: _defs[i].top10),
          ],
        );
      },
    );
  }

  /// The active profile's rows, kept right under the first row. Guests have
  /// none, and only Home, Shows and Movies show them.
  List<Widget> _personalRows() {
    if (!viewType.containsKey(widget.view)) return const [];
    final only = viewType[widget.view];
    bool wanted(MediaItem item) => only == null || item.type == only;

    final resume = store.resume.where(wanted).toList();
    final list = store.list.where(wanted).toList();
    final liked = store.likes.where(wanted).firstOrNull;

    // Only ask for new recommendations when the most recent like changes
    if (liked?.id != _likedSource?.id || liked?.type != _likedSource?.type) {
      _likedSource = liked;
      _because = liked == null
          ? null
          : tmdb.recommendations(liked.type, liked.id).then((items) => items.where(wanted).toList());
    }

    return [
      if (resume.isNotEmpty)
        PosterRow(title: 'Continue Watching for ${store.active?.name ?? 'you'}', items: resume, resume: true),
      if (list.isNotEmpty) PosterRow(title: 'My List', items: list),
      if (liked != null && _because != null)
        PosterRow(
          key: ValueKey('because ${liked.type.name} ${liked.id}'),
          title: 'Because you liked ${liked.title}',
          future: _because,
        ),
    ];
  }
}

/// Everything in one category, as a grid.
class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid({
    super.key,
    required this.category,
    required this.only,
    required this.controller,
    required this.topPadding,
  });
  final GenreCategory category;
  final MediaType? only;
  final ScrollController controller;
  final double topPadding;

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  late Future<List<MediaItem>> _future = tmdb.category(widget.category, only: widget.only);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaItem>>(
      future: _future,
      builder: (context, snap) {
        final Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const SkeletonSliverGrid();
        } else if (snap.hasError) {
          body = SliverToBoxAdapter(
            child: Notice(
              "Couldn't load this category.\nCheck your connection and try again.",
              action: GhostButton(
                label: 'Retry',
                solid: true,
                onTap: () => setState(() => _future = tmdb.category(widget.category, only: widget.only)),
              ),
            ),
          );
        } else if (snap.data!.isEmpty) {
          body = const SliverToBoxAdapter(child: Notice('Nothing in this category yet.'));
        } else {
          body = PosterSliverGrid(items: snap.data!);
        }
        return CustomScrollView(
          controller: widget.controller,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, widget.topPadding, 16, tabBarClearance),
              sliver: body,
            ),
          ],
        );
      },
    );
  }
}
