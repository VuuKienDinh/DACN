import 'package:flutter/material.dart';

import '../widgets/dailyfit_bottom_nav.dart';
import '../widgets/glass_scaffold.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'outfit_screen.dart';
import 'profile_screen.dart';
import 'wardrobe_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  String? _requestedOccasion;

  void _switchTab(int index, {String? occasion}) {
    setState(() {
      _selectedIndex = index;
      if (occasion != null) {
        _requestedOccasion = occasion;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onSwitchTab: _switchTab),
      OutfitScreen(initialOccasion: _requestedOccasion),
      const WardrobeScreen(),
      CalendarScreen(
        onOpenRecommendations: () => _switchTab(1),
      ),
      const ProfileScreen(),
    ];

    return GlassScaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: DailyFitBottomNav(
        currentIndex: _selectedIndex,
        onTap: (idx) => _switchTab(idx),
      ),
    );
  }
}

