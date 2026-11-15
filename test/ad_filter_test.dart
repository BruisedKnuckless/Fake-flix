import 'package:fakeflix/screens/player_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Android request filter: what the provider's wrapper page may load.
void main() {
  const fromWrapper = {'Referer': 'https://vidsrc.mov/', 'Accept': '*/*'};
  const fromPlayerFrame = {'Referer': 'https://vidsrc.sh/', 'Accept': '*/*'};

  bool blocked(String url, Map<String, String> headers, {bool mainFrame = false}) =>
      isWrapperAdRequest(url: Uri.parse(url), mainFrame: mainFrame, headers: headers);

  test('blocks scripts the wrapper page loads from other sites', () {
    expect(blocked('https://ads.example.org/14/ca0843f2a5e7', fromWrapper), isTrue);
    expect(blocked('https://s10.histats.com/js15_as.js', {'referer': 'https://vidsrc.mov/embed/movie/550'}), isTrue);
  });

  test('lets the wrapper page and its own files through', () {
    expect(blocked('https://vidsrc.mov/embed/movie/550', const {}, mainFrame: true), isFalse);
    expect(blocked('https://vidsrc.mov/style.css', fromWrapper), isFalse);
  });

  test('lets the player frame load', () {
    final frame = {'Referer': 'https://vidsrc.mov/', 'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8'};
    expect(blocked('https://vidsrc.sh/embed/movie/550/', frame), isFalse);
  });

  test('leaves everything the player frame asks for alone', () {
    expect(blocked('https://cdn.example.net/player.js', fromPlayerFrame), isFalse);
    expect(blocked('https://cdn.example.net/video/seg-1.ts', fromPlayerFrame), isFalse);
  });

  test('leaves requests with no Referer alone', () {
    expect(blocked('https://cdn.example.net/player.js', const {}), isFalse);
  });
}
