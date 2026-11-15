import 'package:flutter/material.dart';

import '../state/profile_store.dart';
import '../widgets/chrome.dart';
import 'browse_tab.dart';
import 'me_tab.dart';
import 'search_tab.dart';

/// The four tabs and the floating tab bar over them.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final _visited = <int>{0}; // a tab is only built the first time it is opened
  final _homeKey = GlobalKey<BrowseTabState>();

  void _select(int index) {
    // Tapping Home while already on it goes back to the top of Home
    if (index == 0 && _tab == 0) _homeKey.currentState?.goHome();
    setState(() {
      _tab = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final tabs = <Widget>[
      BrowseTab(key: _homeKey),
      const BrowseTab(fixedView: 'new'),
      const SearchTab(),
      const MeTab(),
    ];

    return Scaffold(
      // keep the tab bar at the bottom of the screen when the keyboard opens
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              for (var i = 0; i < tabs.length; i++) _visited.contains(i) ? tabs[i] : const SizedBox.shrink(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom > 0 ? bottom - 8 : 14,
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => GlassTabBar(index: _tab, onTap: _select, profile: store.active),
            ),
          ),
        ],
      ),
    );
  }
}

/// Space to leave at the bottom of a scrolling page so its last items can be
/// scrolled clear of the tab bar.
const tabBarClearance = 120.0;
