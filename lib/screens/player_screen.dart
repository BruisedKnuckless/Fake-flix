import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/tmdb.dart';
import '../nav.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/basics.dart';

/// Full-screen landscape player. The video itself is the streaming
/// provider's own page, shown in a web view.
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
  InAppWebViewController? _web;
  late final String _url;
  ({int season, int episode})? _next;
  bool _loading = true;
  bool _failed = false;

  // Next Episode fades away after a few seconds and the back button dims;
  // both come back on any touch, like a video app's controls.
  bool _controls = true;
  Timer? _hideTimer;

  bool get _isShow => widget.item.type == MediaType.tv;
  int get _season => widget.season ?? 1;
  int get _episode => widget.episode ?? 1;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _url = _isShow ? tvUrl(item.id, _season, _episode) : movieUrl(item.id);

    // Turn the phone sideways and hide the status bar while playing
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Remember it for Continue Watching and the history (after this screen
    // has finished opening, since saving redraws the pages underneath)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.recordWatch(item, season: _isShow ? _season : null, episode: _isShow ? _episode : null);
    });

    if (_isShow) _findNextEpisode();
    _showControls();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    // Back to an upright app with its status bar
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _showControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _controls = false);
    });
    if (!_controls && mounted) setState(() => _controls = true);
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
    _web?.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        // Sees every touch without taking it away from the video underneath
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _showControls(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Keep the video clear of the camera cut-out on either side
            SafeArea(top: false, bottom: false, child: _webView()),
            if (_loading) const ColoredBox(color: Colors.black, child: Center(child: CupertinoActivityIndicator())),
            if (_failed) _failedMessage(),
            ..._controlButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _webView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_url)),
      initialSettings: playerWebSettings(),
      initialUserScripts: UnmodifiableListView([wrapperCleanupScript]),
      onWebViewCreated: (controller) => _web = controller,
      // Pop-up windows and new tabs are never opened
      onCreateWindow: (_, _) async => false,
      // The web view stays on the player's own site: links that would take
      // the whole page somewhere else are not followed. Frames inside the
      // page load as usual.
      shouldOverrideUrlLoading: (_, action) async {
        if (!action.isForMainFrame) return NavigationActionPolicy.ALLOW;
        return isPlayerHost(action.request.url?.host ?? '') ? NavigationActionPolicy.ALLOW : NavigationActionPolicy.CANCEL;
      },
      onLoadStop: (_, _) {
        if (mounted) setState(() => _loading = false);
      },
      onReceivedError: (_, request, _) {
        if (mounted && (request.isForMainFrame ?? false)) {
          setState(() {
            _loading = false;
            _failed = true;
          });
        }
      },
    );
  }

  Widget _failedMessage() {
    return ColoredBox(
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
    );
  }

  /// Back and Next Episode, drawn over the player.
  ///
  /// Sideways, an iPhone has an empty black margin next to the camera
  /// cut-out. The back button sits there so it never covers the video, and
  /// stays faintly visible so there is always a way out. Next Episode fades
  /// away completely until the screen is touched again.
  List<Widget> _controlButtons(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final hasMargin = insets.left >= 44;
    final next = _next;
    const fade = Duration(milliseconds: 250);

    return [
      Positioned(
        left: 0,
        top: 0,
        width: hasMargin ? insets.left : 60,
        height: 60,
        child: AnimatedOpacity(
          opacity: _controls ? 1 : 0.45,
          duration: fade,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                // no margin to sit in: give it a dark disc so it shows over the video
                decoration: hasMargin ? null : const BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.back, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
      if (next != null)
        Positioned(
          right: insets.right + 12,
          top: 12,
          child: IgnorePointer(
            ignoring: !_controls,
            child: AnimatedOpacity(
              opacity: _controls ? 1 : 0,
              duration: fade,
              child: Pressable(
                onTap: () => openPlayer(context, widget.item, season: next.season, episode: next.episode, replace: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    'Next Episode  ·  S${next.season} E${next.episode}',
                    style: const TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

// =========================================================
//  AD AND POP-UP BLOCKING
//
//  The provider's page (vidsrc.mov/embed/…) is a thin wrapper: one frame
//  that holds the real player, plus advertising and tracking scripts loaded
//  from other sites. Those scripts draw the banners, fake "are you a robot"
//  boxes and pop-ups over the video.
//
//  Three layers, the same ideas a blocking browser uses:
//    1. Network: the wrapper page may not load scripts from other sites.
//    2. Windows: pop-ups and new tabs are refused (see onCreateWindow).
//    3. Page: anything in the wrapper besides the player frame is hidden.
//
//  The player frame itself is left alone, so playback is unaffected.
// =========================================================

final _playerHost = Uri.parse(apiBase).host;

/// True for the provider's own site (and its subdomains).
bool isPlayerHost(String host) => host == _playerHost || host.endsWith('.$_playerHost');

InAppWebViewSettings playerWebSettings() {
  return InAppWebViewSettings(
    // Play inside the page (not Apple's separate player) and let playback
    // start without an extra tap
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsPictureInPictureMediaPlayback: true,
    isElementFullscreenEnabled: true,

    // Needed for shouldOverrideUrlLoading above to be asked
    useShouldOverrideUrlLoading: true,
    javaScriptCanOpenWindowsAutomatically: false,
    supportMultipleWindows: true, // so onCreateWindow is asked, and says no

    transparentBackground: true,
    allowsBackForwardNavigationGestures: false,
    disallowOverScroll: true,
    supportZoom: false,

    contentBlockers: [
      // Layer 1. "TOP_FRAME" = requested by the wrapper page itself, not by
      // the player frame inside it. "THIRD_PARTY" = from a different site.
      // The wrapper needs none of these; they are all ads and trackers.
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*',
          resourceType: [ContentBlockerTriggerResourceType.SCRIPT],
          loadType: [ContentBlockerTriggerLoadType.THIRD_PARTY],
          loadContext: [ContentBlockerTriggerLoadContext.TOP_FRAME],
        ),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      ),
    ],
  );
}

/// Layer 3. Runs in the wrapper page only (not inside the player frame),
/// before anything else on it. It adds one style sheet that makes the player
/// frame fill the screen and hides every other element, so an ad that still
/// gets added to the wrapper is never seen.
final wrapperCleanupScript = UserScript(
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  forMainFrameOnly: true,
  source: '''
(function () {
  var css =
    'html, body { margin: 0 !important; height: 100% !important; background: #000 !important; overflow: hidden !important; }' +
    'body > iframe:first-of-type { position: fixed !important; inset: 0 !important; width: 100% !important; height: 100% !important; border: 0 !important; }' +
    'html > *:not(head):not(body), body > *:not(iframe), body > iframe ~ iframe { display: none !important; }';
  var style = document.createElement('style');
  style.textContent = css;
  (document.head || document.documentElement).appendChild(style);
})();
''',
);
