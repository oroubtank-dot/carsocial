import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: 'home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications_outlined),
          activeIcon: const Icon(Icons.notifications),
          label: 'notifications'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.add_box_outlined),
          activeIcon: const Icon(Icons.add_box),
          label: 'add'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.build_outlined),
          activeIcon: const Icon(Icons.build),
          label: 'services'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: 'profile'.tr(),
        ),
      ],
    );
  }
}