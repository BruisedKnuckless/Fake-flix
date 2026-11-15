import 'dart:ui';

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/tmdb.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import 'basics.dart';

/// The big poster card at the top of a browse page, sitting on a glow
/// sampled from the poster.
class Billboard extends StatefulWidget {
  const Billboard({super.key, required this.item, required this.topPadding});
  final MediaItem item;

  /// Room for the header (and chips) that float above the page.
  final double topPadding;

  @override
  State<Billboard> createState() => _BillboardState();
}

class _BillboardState extends State<Billboard> {
  Color? _ambient;
  String? _cleanPoster; // a version of the poster with no words on it
  String? _logoPath; // the title's logo, laid over the clean poster
  String _genres = '';

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  /// Extras that arrive after the card is on screen: the glow colour, the
  /// title's logo art, and its genres.
  void _loadExtras() {
    final item = widget.item;
    void apply(VoidCallback change) {
      if (mounted) setState(change);
    }

    tmdb.ambientColor(imageUrl(item.posterPath, 'w92')).then((c) => apply(() => _ambient = c));
    // The usual poster already has the title printed on it. If TMDB has a
    // clean poster AND a logo, switch to that pair, like a streaming app's
    // billboard. Otherwise keep the usual poster as it is.
    tmdb.billboardArt(item.type, item.id).then(
      (art) => apply(() {
        if (art.cleanPoster != null && art.logo != null) {
          _cleanPoster = art.cleanPoster;
          _logoPath = art.logo;
        }
      }),
      onError: (_) {},
    );
    tmdb.genreNames(item.type).then(
      (names) => apply(() {
        _genres = item.genreIds.map((id) => names[id]).whereType<String>().take(3).join(' • ');
      }),
      onError: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.only(top: widget.topPadding, bottom: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ambient ?? const Color(0xFF2A2A2A), AppColors.bg],
          stops: const [0, 0.96],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: AspectRatio(aspectRatio: 7 / 10, child: _card(context, item)),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, MediaItem item) {
    return GestureDetector(
      onTap: () => openTitle(context, item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 50, offset: Offset(0, 18))],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(imageUrl(_cleanPoster ?? item.posterPath, 'w780'), alignment: Alignment.topCenter),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF0000000), Color(0x99000000), Colors.transparent],
                    stops: [0, 0.24, 0.5],
                  ),
                ),
              ),
              Positioned(left: 14, right: 14, bottom: 14, child: _body(context, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MediaItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only over a clean poster: the usual poster has its own title
        if (_logoPath != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/fakeflix-icon.png', height: 16),
              const SizedBox(width: 7),
              Text(
                item.type == MediaType.tv ? 'SERIES' : 'FILM',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3.6, color: AppColors.soft),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 88,
            child: NetImage(imageUrl(_logoPath, 'w500'), fit: BoxFit.contain, alignment: Alignment.bottomCenter),
          ),
        ],
        if (_genres.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_genres, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5)),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: WideButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                radius: 999,
                onTap: () => playItem(context, item),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              // Rebuilds when the profile's list changes
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: WideButton(
                      label: 'My List',
                      icon: store.inList(item) ? Icons.check_rounded : Icons.add_rounded,
                      filled: false,
                      radius: 999,
                      onTap: () {
                        if (requireProfile(context)) store.toggleList(item);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Grey stand-in with the same shape while the billboard's title is loading.
class BillboardSkeleton extends StatelessWidget {
  const BillboardSkeleton({super.key, required this.topPadding});
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: topPadding, bottom: 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A2A), AppColors.bg],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: AspectRatio(
              aspectRatio: 7 / 10,
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
