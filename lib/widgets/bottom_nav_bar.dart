import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Custom frosted bottom navigation bar.
/// Receives the active [selectedIndex] and fires [onDestinationSelected].
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined,   activeIcon: Icons.home_rounded,       label: 'Accueil'),
    _NavItem(icon: Icons.camera_alt_outlined, activeIcon: Icons.camera_alt_rounded, label: 'Photo'),
    _NavItem(icon: Icons.map_outlined,    activeIcon: Icons.map_rounded,        label: 'Carte'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: SiteColors.bg,
        border: Border(top: BorderSide(color: SiteColors.border, width: 0.5)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onDestinationSelected(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        active ? _items[i].activeIcon : _items[i].icon,
                        key: ValueKey(active),
                        size: 22,
                        color: active ? SiteColors.amber : SiteColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _items[i].label,
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 10,
                        color: active ? SiteColors.amber : SiteColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}