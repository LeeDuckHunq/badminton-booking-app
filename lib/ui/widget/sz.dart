// Bộ component dùng chung theo design system "SmashZone Athletic Modern".
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/notify/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════ ĐỊNH DẠNG ═══════════════════════════════

class Fmt {
  Fmt._();

  static final _money = NumberFormat.decimalPattern('vi_VN');
  static const _weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _weekdayLong = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

  /// 150000 → "150.000 ₫"
  static String money(num value) => '${_money.format(value.round())}\u00A0₫';

  /// 150000 → "150.000"
  static String number(num value) => _money.format(value.round());

  static String two(int n) => n.toString().padLeft(2, '0');

  /// DateTime → "08:30"
  static String hhmm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  /// "05:00:00" / "05:00" → "05:00"
  static String time(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  /// "05:00:00", "23:00:00" → "05:00 – 23:00"
  static String hours(String open, String close) => '${time(open)} – ${time(close)}';

  static String range(DateTime a, DateTime b) => '${hhmm(a)} – ${hhmm(b)}';

  /// 18/11/2026
  static String date(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

  /// T4
  static String weekdayShort(DateTime d) => _weekdayShort[d.weekday - 1];

  /// Thứ Tư, 18/11/2026
  static String dateLong(DateTime d) => '${_weekdayLong[d.weekday - 1]}, ${date(d)}';

  /// T4, 18/11
  static String dateShort(DateTime d) => '${weekdayShort(d)}, ${two(d.day)}/${two(d.month)}';

  /// 1.5 → "1,5 giờ"; 2 → "2 giờ"
  static String hoursCount(double h) {
    final s = h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1).replaceAll('.', ',');
    return '$s giờ';
  }

  /// Mã ngắn dễ đọc cho id dài: "PD_2520d1fa-..." → "#2520D1FA"
  static String shortCode(String id) {
    final cleaned = id.replaceAll(RegExp(r'^[A-Za-z]+_'), '').replaceAll('-', '');
    final head = cleaned.length > 8 ? cleaned.substring(0, 8) : cleaned;
    return '#${head.toUpperCase()}';
  }

  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    return (words[words.length - 2][0] + words.last[0]).toUpperCase();
  }
}

// ═══════════════════════════════ TRẠNG THÁI ĐƠN ═══════════════════════════════

class BookingStatus {
  final String label;
  final Color bg;
  final Color fg;
  final Color line;
  final Color accent;
  final IconData icon;

  const BookingStatus(this.label, this.bg, this.fg, this.line, this.accent, this.icon);

  static BookingStatus of(String code) => switch (code) {
        'CHO_XAC_NHAN' => const BookingStatus('Chờ xác nhận', Color(0xFFFEF3C7), Color(0xFFB45309), Color(0xFFFCD34D), AppColor.pending, Icons.hourglass_top_rounded),
        'DA_XAC_NHAN' => const BookingStatus('Đã xác nhận', Color(0xFFDBEAFE), Color(0xFF1D4ED8), Color(0xFF93C5FD), AppColor.confirmed, Icons.verified_rounded),
        'DA_HOAN_THANH' => const BookingStatus('Hoàn thành', Color(0xFFDCFCE7), Color(0xFF15803D), Color(0xFF86EFAC), AppColor.completed, Icons.check_circle_rounded),
        'DA_HUY' => const BookingStatus('Đã huỷ', Color(0xFFFEE2E2), Color(0xFFB91C1C), Color(0xFFFCA5A5), AppColor.danger, Icons.cancel_rounded),
        _ => const BookingStatus('Không xác định', AppColor.slot, AppColor.textMuted, AppColor.border, AppColor.textMuted, Icons.help_outline_rounded),
      };
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  const StatusBadge(this.status, {super.key, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    final s = BookingStatus.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: s.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (showIcon) ...[Icon(s.icon, size: 12, color: s.fg), const SizedBox(width: 4)],
        Text(s.label, style: AppText.labelSm(color: s.fg)),
      ]),
    );
  }
}

// ═══════════════════════════════ NÚT ═══════════════════════════════

enum SzButtonKind { primary, dark, outline, soft, danger, dangerSoft, ghost }

class SzButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final SzButtonKind kind;
  final bool loading;
  final bool expand;
  final double height;
  final bool uppercase;

  const SzButton(this.label, {super.key, this.onPressed, this.icon, this.trailingIcon, this.kind = SzButtonKind.primary, this.loading = false, this.expand = false, this.height = 52, this.uppercase = false});

  const SzButton.small(this.label, {super.key, this.onPressed, this.icon, this.trailingIcon, this.kind = SzButtonKind.primary, this.loading = false, this.expand = false, this.uppercase = false}) : height = 40;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (kind) {
      SzButtonKind.primary => (AppColor.primary, Colors.white, null),
      SzButtonKind.dark => (AppColor.primaryDark, Colors.white, null),
      SzButtonKind.outline => (Colors.transparent, AppColor.primary, AppColor.primary),
      SzButtonKind.soft => (AppColor.mint, AppColor.primaryDark, null),
      SzButtonKind.danger => (AppColor.danger, Colors.white, null),
      SzButtonKind.dangerSoft => (AppColor.dangerSoft, AppColor.danger, null),
      SzButtonKind.ghost => (Colors.transparent, AppColor.primary, null),
    };
    final effectiveBg = enabled ? bg : (bg == Colors.transparent ? bg : AppColor.border);
    final effectiveFg = enabled ? fg : AppColor.textSubtle;
    final small = height < 48;
    final style = (small ? AppText.label(color: effectiveFg) : AppText.labelLg(color: effectiveFg)).copyWith(fontWeight: FontWeight.w700, letterSpacing: uppercase ? 0.6 : 0);

    final content = loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: effectiveFg == Colors.white ? Colors.white : AppColor.primary))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: small ? 16 : 20, color: effectiveFg), const SizedBox(width: 8)],
            Flexible(child: Text(uppercase ? label.toUpperCase() : label, style: style, overflow: TextOverflow.ellipsis)),
            if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: small ? 16 : 20, color: effectiveFg)],
          ]);

    final button = Material(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(small ? AppRadius.sm : AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(small ? AppRadius.sm : AppRadius.md),
        onTap: enabled ? onPressed : null,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 22),
          decoration: border == null ? null : BoxDecoration(borderRadius: BorderRadius.circular(small ? AppRadius.sm : AppRadius.md), border: Border.all(color: enabled ? border : AppColor.border, width: 1.5)),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
    final shadowed = kind == SzButtonKind.primary && enabled && !small
        ? DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadow.primaryGlow), child: button)
        : button;
    return expand ? SizedBox(width: double.infinity, child: shadowed) : shadowed;
  }
}

class SzIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color background;
  final double size;
  final String? tooltip;
  final Widget? badge;

  const SzIconButton(this.icon, {super.key, this.onPressed, this.color = AppColor.text, this.background = Colors.transparent, this.size = 40, this.tooltip, this.badge});

  @override
  Widget build(BuildContext context) {
    Widget w = Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(width: size, height: size, child: Icon(icon, color: color, size: size * 0.55)),
      ),
    );
    if (badge != null) w = Stack(clipBehavior: Clip.none, children: [w, Positioned(top: 4, right: 4, child: badge!)]);
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

// ═══════════════════════════════ BỀ MẶT ═══════════════════════════════

class SzCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final double radius;
  final BoxBorder? border;
  final bool shadow;
  final Clip clip;

  const SzCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = AppColor.card, this.onTap, this.radius = AppRadius.lg, this.border, this.shadow = true, this.clip = Clip.antiAlias});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), boxShadow: shadow ? AppShadow.card : null, border: border),
      clipBehavior: clip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Tiêu đề khối trong card: icon ô vuông mint + tiêu đề + phần phải.
class SzSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color iconBg;
  final Color iconColor;

  const SzSectionTitle(this.icon, this.title, {super.key, this.trailing, this.iconBg = AppColor.mint, this.iconColor = AppColor.primary});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: iconColor)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: AppText.headlineSm())),
      if (trailing != null) trailing!,
    ]);
  }
}

class SzPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final bool bold;

  const SzPill(this.text, {super.key, this.bg = AppColor.mint, this.fg = AppColor.primaryDark, this.icon, this.bold = true});

  const SzPill.accent(this.text, {super.key, this.icon, this.bold = true})
      : bg = AppColor.accent,
        fg = AppColor.text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
        Text(text, style: AppText.label(color: fg).copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }
}

class SzChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;
  final Color? dot;

  const SzChip(this.label, {super.key, this.selected = false, this.onTap, this.icon, this.count, this.dot});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColor.text;
    return Material(
      color: selected ? AppColor.primaryDark : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColor.primaryDark : AppColor.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (dot != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 6)],
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
            Text(label, style: AppText.labelLg(color: fg)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: 0.2) : AppColor.mint, borderRadius: BorderRadius.circular(999)),
                child: Text('$count', style: AppText.labelSm(color: selected ? Colors.white : AppColor.primaryDark)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class SzAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color bg;
  final Color fg;
  final bool online;

  const SzAvatar(this.name, {super.key, this.size = 44, this.bg = AppColor.primaryDark, this.fg = Colors.white, this.online = false});

  const SzAvatar.soft(this.name, {super.key, this.size = 44, this.online = false})
      : bg = AppColor.mintStrong,
        fg = AppColor.primaryDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text(Fmt.initials(name), style: AppText.headlineSm(color: fg).copyWith(fontSize: size * 0.36)),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(width: size * 0.28, height: size * 0.28, decoration: BoxDecoration(color: AppColor.completed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
          ),
      ]),
    );
  }
}

/// Ô logo SmashZone (vợt trên nền xanh).
class SzLogo extends StatelessWidget {
  final double size;
  const SzLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColor.primaryDark, borderRadius: BorderRadius.circular(size * 0.27), boxShadow: AppShadow.primaryGlow),
      child: Icon(Icons.sports_tennis_rounded, color: Colors.white, size: size * 0.58),
    );
  }
}

/// Header thương hiệu ở đầu các tab: logo + "SmashZone" + tên tab + chuông + avatar.
class SzBrandHeader extends StatelessWidget {
  final String subtitle;
  final String? userName;
  final VoidCallback? onAvatarTap;
  final List<Widget> actions;
  final bool showBell;

  const SzBrandHeader({super.key, required this.subtitle, this.userName, this.onAvatarTap, this.actions = const [], this.showBell = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 12, 10),
      child: Row(children: [
        const SzLogo(size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SmashZone', style: AppText.headlineSm(color: AppColor.primaryDark).copyWith(fontSize: 18)),
            Text(subtitle, style: AppText.bodySm()),
          ]),
        ),
        ...actions,
        if (showBell) const NotificationBell(),
        GestureDetector(
          onTap: onAvatarTap,
          child: userName == null || userName!.isEmpty
              ? Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColor.primaryDark, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: Colors.white, size: 22))
              : SzAvatar(userName!, size: 40),
        ),
      ]),
    );
  }
}

/// AppBar trắng cho màn con: nút quay lại + tiêu đề (+ phụ đề) + hành động.
class SzTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final IconData backIcon;

  const SzTopBar({super.key, required this.title, this.subtitle, this.actions = const [], this.onBack, this.backIcon = Icons.arrow_back_rounded});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 64,
        child: Row(children: [
          const SizedBox(width: 4),
          SzIconButton(backIcon, size: 44, onPressed: onBack ?? () => Navigator.maybePop(context)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.headlineSm().copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) Text(subtitle!, style: AppText.bodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          ...actions,
          const SizedBox(width: 8),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════ Ô NHẬP ═══════════════════════════════

class SzTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? labelHint;
  final String hint;
  final IconData? icon;
  final bool password;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? suffix;

  const SzTextField({super.key, required this.controller, this.label, this.labelHint, required this.hint, this.icon, this.password = false, this.error, this.keyboardType, this.textInputAction, this.onSubmitted, this.onChanged, this.autofocus = false, this.suffix});

  @override
  State<SzTextField> createState() => _SzTextFieldState();
}

class _SzTextFieldState extends State<SzTextField> {
  bool _obscure = true;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final focused = _focus.hasFocus;
    final borderColor = hasError ? AppColor.danger : (focused ? AppColor.primary : AppColor.border);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.label != null) ...[
        Row(children: [
          Expanded(child: Text(widget.label!, style: AppText.labelLg())),
          if (widget.labelHint != null) Text(widget.labelHint!, style: AppText.labelSm()),
        ]),
        const SizedBox(height: 8),
      ],
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: borderColor, width: focused || hasError ? 1.5 : 1),
          boxShadow: focused ? [BoxShadow(color: (hasError ? AppColor.danger : AppColor.primary).withValues(alpha: 0.15), spreadRadius: 3)] : null,
        ),
        child: Row(children: [
          if (widget.icon != null) Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(widget.icon, size: 20, color: focused ? AppColor.primary : AppColor.textMuted)) else const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              obscureText: widget.password && _obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              style: AppText.bodyLg(),
              cursorColor: AppColor.primary,
              decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: widget.hint, hintStyle: AppText.bodyLg(color: AppColor.textSubtle)),
            ),
          ),
          if (widget.password)
            SzIconButton(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 44, color: AppColor.textMuted, onPressed: () => setState(() => _obscure = !_obscure))
          else if (widget.suffix != null)
            widget.suffix!
          else
            const SizedBox(width: 14),
        ]),
      ),
      if (hasError) ...[
        const SizedBox(height: 4),
        Text(widget.error!, style: AppText.bodySm(color: AppColor.danger)),
      ],
    ]);
  }
}

// ═══════════════════════════════ BOTTOM SHEET ═══════════════════════════════

class SzSheetHandle extends StatelessWidget {
  const SzSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(margin: const EdgeInsets.only(top: 8, bottom: 8), width: 36, height: 4, decoration: BoxDecoration(color: AppColor.borderStrong, borderRadius: BorderRadius.circular(2))),
      );
}

class SzSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;

  const SzSheetHeader({super.key, required this.title, this.subtitle, this.icon, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (icon != null) ...[
        Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColor.mint, shape: BoxShape.circle), child: Icon(icon, color: AppColor.primary, size: 22)),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.headlineLg(color: AppColor.text)),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppText.body(color: AppColor.textMuted))],
        ]),
      ),
      SzIconButton(Icons.close_rounded, color: AppColor.textMuted, onPressed: onClose ?? () => Navigator.pop(context)),
    ]);
  }
}

// ═══════════════════════════════ TRẠNG THÁI MÀN ═══════════════════════════════

class SzEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SzEmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 88, height: 88, decoration: const BoxDecoration(color: AppColor.mint, shape: BoxShape.circle), child: Icon(icon, size: 40, color: AppColor.primary)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: AppText.headlineMd()),
          if (message != null) ...[const SizedBox(height: 8), Text(message!, textAlign: TextAlign.center, style: AppText.body(color: AppColor.textMuted))],
          if (actionLabel != null && onAction != null) ...[const SizedBox(height: 20), SzButton(actionLabel!, onPressed: onAction, kind: SzButtonKind.soft, height: 44)],
        ]),
      ),
    );
  }
}

class SzErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SzErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => SzEmptyState(icon: Icons.wifi_off_rounded, title: 'Có lỗi xảy ra', message: message, actionLabel: 'Thử lại', onAction: onRetry);
}

class SzLoading extends StatelessWidget {
  final String? message;
  const SzLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
        if (message != null) ...[const SizedBox(height: 14), Text(message!, style: AppText.body(color: AppColor.textMuted))],
      ]),
    );
  }
}

/// Khối xám nhấp nháy dùng làm skeleton.
class SzSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SzSkeleton({super.key, this.width = double.infinity, required this.height, this.radius = AppRadius.sm});

  @override
  State<SzSkeleton> createState() => _SzSkeletonState();
}

class _SzSkeletonState extends State<SzSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(width: widget.width, height: widget.height, decoration: BoxDecoration(color: const Color(0xFFE7EEE9), borderRadius: BorderRadius.circular(widget.radius))),
    );
  }
}

// ═══════════════════════════════ KHÁC ═══════════════════════════════

/// Dòng "nhãn — giá trị" trong card thông tin.
class SzInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;
  final Widget? trailing;

  const SzInfoRow(this.label, this.value, {super.key, this.strong = false, this.valueColor, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(constraints: const BoxConstraints(minWidth: 96, maxWidth: 170), child: Text(label, style: AppText.body(color: AppColor.textMuted))),
        const SizedBox(width: 8),
        Expanded(
          child: value.contains('\n')
              ? Text(value, textAlign: TextAlign.right, style: (strong ? AppText.headlineSm() : AppText.labelLg()).copyWith(color: valueColor))
              : FittedBox(
                  // Giá trị 1 dòng (email, số tiền…) thu nhỏ thay vì ngắt giữa chữ.
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value, maxLines: 1, style: (strong ? AppText.headlineSm() : AppText.labelLg()).copyWith(color: valueColor)),
                ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}

/// Đường gạch đứt ngang (vé, hoá đơn).
class SzDashedDivider extends StatelessWidget {
  final Color color;
  const SzDashedDivider({super.key, this.color = AppColor.borderStrong});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final count = (c.maxWidth / 10).floor();
      return Row(children: List.generate(count, (_) => Expanded(child: Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 2.5), color: color))));
    });
  }
}

/// Ảnh mạng có placeholder và ảnh dự phòng.
class SzNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SzNetworkImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColor.mintStrong,
      alignment: Alignment.center,
      child: const Icon(Icons.sports_tennis_rounded, color: AppColor.primary, size: 36),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      // Web: ảnh không có CORS (vd. Google Drive) thì hiển thị bằng thẻ <img>.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : SzSkeleton(width: width ?? double.infinity, height: height ?? 120, radius: 0),
    );
  }
}

enum SzToast { success, error, warning, info }

void showSzSnack(BuildContext context, String message, {SzToast type = SzToast.success}) {
  final (color, icon) = switch (type) {
    SzToast.success => (AppColor.primary, Icons.check_circle_rounded),
    SzToast.error => (AppColor.danger, Icons.error_rounded),
    SzToast.warning => (AppColor.pending, Icons.warning_amber_rounded),
    SzToast.info => (AppColor.confirmed, Icons.info_rounded),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    backgroundColor: Colors.white,
    elevation: 8,
    padding: EdgeInsets.zero,
    duration: Duration(milliseconds: type == SzToast.error ? 5000 : 3500),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    content: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border(left: BorderSide(color: color, width: 4))),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: AppText.labelLg())),
      ]),
    ),
  ));
}

/// Dialog xác nhận theo design system (tiêu đề, mô tả, 2 nút).
Future<bool> showSzConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Huỷ',
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: destructive ? AppColor.dangerSoft : AppColor.mint, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: destructive ? AppColor.danger : AppColor.primary),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: AppText.headlineMd()),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppText.body(color: AppColor.textMuted)),
          const SizedBox(height: 24),
          SzButton(confirmLabel, expand: true, kind: destructive ? SzButtonKind.danger : SzButtonKind.primary, onPressed: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 8),
          SzButton(cancelLabel, expand: true, kind: SzButtonKind.ghost, onPressed: () => Navigator.pop(ctx, false)),
        ]),
      ),
    ),
  );
  return result ?? false;
}
