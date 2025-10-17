// lib/taskbar.dart
import 'package:flutter/material.dart';
import 'page.dart';

// Bottom taskbar
class AppTaskbar extends StatelessWidget {
  final List<FitTrackPage> pages;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppTaskbar({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: pages
          .map(
            (p) => NavigationDestination(
          icon: Icon(p.icon),
          label: p.title,
        ),
      )
          .toList(),
    );
  }
}
