import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/tmdb.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/basics.dart';

/// Full-screen player. The video itself is the streaming provider's own
/// page, shown in a web view.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.item, this.season, this.episode});
  final MediaItem item;

  /// Only for shows.
  final int? season;
  final int? episode;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  late final String _url;
  late String _label = widget.item.title;
  ({int season, int episode})? _next;
  bool _loading = true;
  bool _failed = false;

  bool get _isShow => widget.item.type == MediaType.tv;
  int get _season => widget.season ?? 1;
  int get _episode => widget.episode ?? 1;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _url = _isShow ? tvUrl(item.id, _season, _episode) : movieUrl(item.id);
    if (_isShow) _label = '${item.title} · S$_season E$_episode';

    // The player may turn sideways; the rest of the app stays portrait
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    _controller = _buildWebView()..loadRequest(Uri.parse(_url));

    // Remember it for Continue Watching and the history (after this screen
    // has finished opening, since saving redraws the pages underneath)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.recordWatch(item, season: _isShow ? _season : null, episode: _isShow ? _episode : null);
    });

    if (_isShow) _findNextEpisode();
  }

  WebViewController _buildWebView() {
    // iOS: play inside the page (not Apple's separate player) and allow
    // playback to start without an extra tap.
    final PlatformWebViewControllerCreationParams params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();

    final playerHost = Uri.parse(apiBase).host;

    return WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          // The web view stays on the player's own site. It never opens new
          // windows, and links that would take the whole page somewhere else
          // are not followed. Frames inside the page load as usual.
          onNavigationRequest: (request) {
            if (!request.isMainFrame) return NavigationDecision.navigate;
            final host = Uri.tryParse(request.url)?.host ?? '';
            final onPlayer = host == playerHost || host.endsWith('.$playerHost');
            return onPlayer ? NavigationDecision.navigate : NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && (error.isForMainFrame ?? false)) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
        ),
      );
  }

  Future<void> _findNextEpisode() async {
    try {
      final details = await tmdb.details(MediaType.tv, widget.item.id);
      final next = nextEpisode(details.seasons, _season, _episode);
      if (mounted && next != null) setState(() => _next = next);
    } catch (_) {
      // no Next Episode button, playback is unaffected
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _controller.loadRequest(Uri.parse(_url));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CupertinoIcons.back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (next != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 8),
                      child: Pressable(
                        onTap: () => openPlayer(
                          context,
                          widget.item,
                          season: next.season,
                          episode: next.episode,
                          replace: true,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: const Text(
                            'Next Episode',
                            style: TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading) const ColoredBox(color: Colors.black, child: Center(child: CupertinoActivityIndicator())),
                  if (_failed)
                    ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "The player couldn't load.\nCheck your connection and try again.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
                            ),
                            const SizedBox(height: 18),
                            GhostButton(label: 'Retry', solid: true, onTap: _retry),
                          ],
                        ),
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
