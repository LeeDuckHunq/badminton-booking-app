// lib/ui/home/widgets/home_header.dart

import 'package:flutter/material.dart';
import 'package:application/ui/theme/app_color.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String dateLabel;       // e.g. "Thứ năm, 14/05/2026"
  final String avartarUrl;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.dateLabel,
    required this.avartarUrl,
    this.notificationCount = 0,
    required this.onNotificationTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.kDeepGreen,
                border: Border.all(
                    color: AppColor.kLineWhite.withOpacity(0.5), width: 2),
                image: DecorationImage(
                  image: NetworkImage(avartarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Date + Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: AppColor.kLineWhite.withOpacity(0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    color: AppColor.kAccentYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Flag icon (Vietnam)
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.kDeepGreen.withOpacity(0.4),
              border: Border.all(
                  color: AppColor.kLineWhite.withOpacity(0.25), width: 1),
            ),
            child: const Center(
              child: Text('🇻🇳', style: TextStyle(fontSize: 18)),
            ),
          ),

          // Notification bell
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.kDeepGreen.withOpacity(0.4),
                    border: Border.all(
                        color: AppColor.kLineWhite.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColor.kLineWhite, size: 20),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
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