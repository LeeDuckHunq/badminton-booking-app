import 'package:flutter/material.dart';

/// Bảng màu "SmashZone Athletic Modern" (design/stitch_smashzone_design_system/.../DESIGN.md).
class AppColor {
  AppColor._();

  // ── Thương hiệu ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A7A3C); // nút chính, tab đang chọn
  static const Color primaryDark = Color(0xFF00602A); // hover / nhấn, nút đậm
  static const Color forest = Color(0xFF0F4D25); // tiêu đề lớn
  static const Color accent = Color(0xFFFFD600); // HOT, voucher, điểm nhấn
  static const Color accentDeep = Color(0xFFCAA900);
  static const Color mint = Color(0xFFE6F5EC); // nền chip, ô đang chọn
  static const Color mintStrong = Color(0xFFD1F8D5);
  static const Color successBright = Color(0xFF4CAF72);

  // ── Bề mặt & chữ ──────────────────────────────────────────────────────────
  static const Color canvas = Color(0xFFF8FAF8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color text = Color(0xFF0D2E18);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color slot = Color(0xFFF1F5F9); // ô đã đặt / khoá

  // ── Trạng thái ────────────────────────────────────────────────────────────
  static const Color pending = Color(0xFFF59E0B);
  static const Color confirmed = Color(0xFF2563EB);
  static const Color completed = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);

  // ── Tên cũ (giữ để các widget chưa chuyển đổi vẫn biên dịch) ─────────────
  static const Color kCourtGreen = primary;
  static const Color kDeepGreen = forest;
  static const Color kLineWhite = Color(0xFFFFFFFF);
  static const Color kAccentYellow = accent;
  static const Color kShuttleWhite = Color(0xFFF5F5F5);
  static const Color kCardWhite = card;
  static const Color kTextDark = text;
  static const Color kMintField = mint;
  static const Color kGreenLight = successBright;
}

/// Bóng đổ nhẹ ánh xanh rừng theo các mức elevation của design system.
class AppShadow {
  AppShadow._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0D2E18), blurRadius: 8, spreadRadius: -2, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x080D2E18), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> sticky = [
    BoxShadow(color: Color(0x140D2E18), blurRadius: 16, spreadRadius: -2, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x290D2E18), blurRadius: 32, spreadRadius: -4, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(color: Color(0x331A7A3C), blurRadius: 16, spreadRadius: -4, offset: Offset(0, 8)),
  ];
}

class AppRadius {
  AppRadius._();
  static const double sm = 8; // ô nhập, nút nhỏ, ô lịch
  static const double md = 12;
  static const double lg = 16; // card, dialog, voucher
  static const double xl = 24; // bottom sheet
}
