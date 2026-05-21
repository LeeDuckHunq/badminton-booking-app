// lib/ui/home/widgets/home_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

enum HomeNavTab { home, chat, explore, highlight, account }

class HomeBottomNav extends StatelessWidget {
  final HomeNavTab currentTab;
  final ValueChanged<HomeNavTab> onTabChanged;

  const HomeBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  static const _tabs = [
    _NavItem(tab: HomeNavTab.home,      icon: Icons.home_rounded,        label: 'Trang chủ'),
    _NavItem(tab: HomeNavTab.chat,      icon: Icons.chat_bubble_outline_rounded,     label: 'Tin nhắn'),
    _NavItem(tab: HomeNavTab.explore,   icon: Icons.article_outlined,    label: 'Khám phá',  isCentral: true),
    _NavItem(tab: HomeNavTab.highlight, icon: Icons.local_fire_department_outlined, label: 'Nổi bật'),
    _NavItem(tab: HomeNavTab.account,   icon: Icons.person_outline_rounded, label: 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColor.kLineWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: _tabs.map((item) {
          final isActive = currentTab == item.tab;

          if (item.isCentral) {
            // Explore — floating center button
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(item.tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColor.kCourtGreen
                            : AppColor.kLineWhite,
                        border: Border.all(
                          color: AppColor.kCourtGreen,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.kCourtGreen.withOpacity(0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        color: isActive
                            ? AppColor.kLineWhite
                            : AppColor.kCourtGreen,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(item.tab),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColor.kCourtGreen.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: isActive
                          ? AppColor.kCourtGreen
                          : Colors.grey[500],
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isActive
                          ? AppColor.kCourtGreen
                          : Colors.grey[500]!,
                      fontSize: 10.5,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final HomeNavTab tab;
  final IconData icon;
  final String label;
  final bool isCentral;

  const _NavItem({
    required this.tab,
    required this.icon,
    required this.label,
    this.isCentral = false,
  });
}