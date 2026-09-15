import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_topbar.dart';

/// Kila ukurasa wa ndani ya app (baada ya login) unatumia hii kama muundo
/// wake wa nje. Ina tabia ya responsive kama mockup:
///   - width < 800  -> Sidebar inakuwa Drawer (simu/tablet ndogo)
///   - width >= 800 -> Sidebar ya kudumu, inaweza "collapse" kuwa nyembamba
class AppShell extends StatefulWidget {
  final String title;
  final Widget child;

  const AppShell({super.key, required this.title, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _collapsed = false;

  static const _mobileBreakpoint = 800.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < _mobileBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? const Drawer(child: AppSidebar(mobile: true)) : null,
      body: Row(
        children: [
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _collapsed ? 78 : 260,
              child: AppSidebar(collapsed: _collapsed),
            ),
          Expanded(
            child: Column(
              children: [
                AppTopbar(
                  title: widget.title,
                  onMenu: () {
                    if (isMobile) {
                      _scaffoldKey.currentState?.openDrawer();
                    } else {
                      setState(() => _collapsed = !_collapsed);
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
