// lib/ui/home/widgets/home_bottom_nav.dart
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum HomeNavTab { home, community, chat, explore, account }

/// Thanh tab dưới 5 mục.
class HomeBottomNav extends StatelessWidget {
  final HomeNavTab currentTab;
  final ValueChanged<HomeNavTab> onTabChanged;

  const HomeBottomNav({super.key, required this.currentTab, required this.onTabChanged});

  static const _tabs = [
    (HomeNavTab.home, Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    (HomeNavTab.community, Icons.groups_outlined, Icons.groups_rounded, 'Cộng đồng'),
    (HomeNavTab.chat, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Tin nhắn'),
    (HomeNavTab.explore, Icons.confirmation_number_outlined, Icons.confirmation_number_rounded, 'Khám phá'),
    (HomeNavTab.account, Icons.person_outline_rounded, Icons.person_rounded, 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F0D2E18), blurRadius: 16, spreadRadius: -2, offset: Offset(0, -4))]),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (final (tab, icon, activeIcon, label) in _tabs)
              Expanded(
                child: InkWell(
                  onTap: () => onTabChanged(tab),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(color: tab == currentTab ? AppColor.mint : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                      child: Icon(tab == currentTab ? activeIcon : icon, size: 24, color: tab == currentTab ? AppColor.primary : AppColor.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: (tab == currentTab ? AppText.label(color: AppColor.primary) : AppText.label(color: AppColor.textMuted)).copyWith(fontSize: 11, fontWeight: tab == currentTab ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
