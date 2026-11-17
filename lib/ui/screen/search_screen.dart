// lib/ui/screen/search_screen.dart
import 'package:application/model/cum_san_model.dart';
import 'package:application/ui/screen/booking_schedule_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Scope { all, name, address }

enum _Sort { relevant, cheapest }

/// M5 – Tìm kiếm cụm sân (lọc trên danh sách đã tải ở Trang chủ).
class SearchScreen extends StatefulWidget {
  final List<CumSanModel> courtList;
  final Map<String, String> courtImage;

  const SearchScreen({super.key, required this.courtList, required this.courtImage});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _recentKey = 'recent_searches';
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  _Scope _scope = _Scope.all;
  _Sort _sort = _Sort.relevant;
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _recent = p.getStringList(_recentKey) ?? []);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _match(CumSanModel c, _Scope scope, String q) => switch (scope) {
        _Scope.all => c.tenCumSan.toLowerCase().contains(q) || c.diaChi.toLowerCase().contains(q),
        _Scope.name => c.tenCumSan.toLowerCase().contains(q),
        _Scope.address => c.diaChi.toLowerCase().contains(q),
      };

  int _count(_Scope scope) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ? widget.courtList.length : widget.courtList.where((c) => _match(c, scope, q)).length;
  }

  List<CumSanModel> get _results {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty ? [...widget.courtList] : widget.courtList.where((c) => _match(c, _scope, q)).toList();
    if (_sort == _Sort.cheapest) {
      list.sort((a, b) => (a.giaTu ?? double.infinity).compareTo(b.giaTu ?? double.infinity));
    }
    return list;
  }

  Future<void> _remember(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ..._recent.where((r) => r.toLowerCase() != q.toLowerCase())].take(6).toList();
    setState(() => _recent = next);
    (await SharedPreferences.getInstance()).setStringList(_recentKey, next);
  }

  Future<void> _setRecent(List<String> list) async {
    setState(() => _recent = list);
    (await SharedPreferences.getInstance()).setStringList(_recentKey, list);
  }

  void _applyQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
  }

  void _open(CumSanModel court) {
    _remember(_query);
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScheduleScreen(cumSan: court)));
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: const SzTopBar(title: 'Tìm kiếm sân cầu lông'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SzTextField(
              controller: _controller,
              hint: 'Tên sân hoặc địa chỉ…',
              icon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: _remember,
              suffix: _query.isEmpty ? null : SzIconButton(Icons.cancel_outlined, size: 44, color: AppColor.textMuted, onPressed: () => _applyQuery('')),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              SzChip('Tất cả', count: _count(_Scope.all), selected: _scope == _Scope.all, onTap: () => setState(() => _scope = _Scope.all)),
              const SizedBox(width: 8),
              SzChip('Tên sân', count: _count(_Scope.name), selected: _scope == _Scope.name, onTap: () => setState(() => _scope = _Scope.name)),
              const SizedBox(width: 8),
              SzChip('Địa chỉ / Quận', count: _count(_Scope.address), selected: _scope == _Scope.address, onTap: () => setState(() => _scope = _Scope.address)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(children: [
              Expanded(
                child: Text.rich(TextSpan(style: AppText.body(color: AppColor.textMuted), children: [
                  const TextSpan(text: 'Tìm thấy '),
                  TextSpan(text: '${results.length}', style: AppText.labelLg()),
                  TextSpan(text: _query.trim().isEmpty ? ' cụm sân' : ' cụm sân cho "'),
                  if (_query.trim().isNotEmpty) TextSpan(text: _query.trim(), style: AppText.labelLg()),
                  if (_query.trim().isNotEmpty) const TextSpan(text: '"'),
                ])),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _sort = _sort == _Sort.cheapest ? _Sort.relevant : _Sort.cheapest),
                icon: Icon(Icons.swap_vert_rounded, size: 18, color: _sort == _Sort.cheapest ? AppColor.primary : AppColor.textMuted),
                label: Text('Giá thấp nhất', style: AppText.labelLg(color: _sort == _Sort.cheapest ? AppColor.primary : AppColor.textMuted)),
              ),
            ]),
          ),
          if (results.isEmpty)
            SzEmptyState(icon: Icons.search_off_rounded, title: 'Không tìm thấy sân nào', message: 'Thử từ khoá khác, ví dụ tên quận hoặc tên đường.')
          else
            for (final court in results) _ResultCard(court: court, image: widget.courtImage[court.maCumSan], query: _query.trim(), onTap: () => _open(court)),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SzCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.history_rounded, color: AppColor.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Tìm kiếm gần đây', style: AppText.headlineSm())),
                    TextButton(onPressed: () => _setRecent([]), child: Text('Xoá tất cả', style: AppText.label(color: AppColor.textMuted))),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final r in _recent)
                      InputChip(
                        label: Text(r, style: AppText.body()),
                        avatar: const Icon(Icons.schedule_rounded, size: 16, color: AppColor.textMuted),
                        backgroundColor: AppColor.mint,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        onPressed: () => _applyQuery(r),
                        onDeleted: () => _setRecent(_recent.where((x) => x != r).toList()),
                        deleteIconColor: AppColor.textMuted,
                      ),
                  ]),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final CumSanModel court;
  final String? image;
  final String query;
  final VoidCallback onTap;

  const _ResultCard({required this.court, required this.image, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SzCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: SzNetworkImage(image, width: 96, height: 84)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Highlighted(court.tenCumSan, query, AppText.headlineSm(color: AppColor.forest)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColor.textMuted),
                    const SizedBox(width: 4),
                    Expanded(child: _Highlighted(court.diaChi, query, AppText.bodySm())),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColor.primary),
                    const SizedBox(width: 4),
                    Text(Fmt.hours(court.gioMoCua, court.gioDongCua), style: AppText.label(color: AppColor.primary)),
                  ]),
                  if (court.soSan > 0) ...[const SizedBox(height: 6), SzPill('${court.soSan} sân', bold: false)],
                ]),
              ),
            ]),
          ),
          Container(
            color: AppColor.canvas,
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(children: [
              Expanded(
                child: court.giaTu == null
                    ? Text('Chưa có giá', style: AppText.body(color: AppColor.textMuted))
                    : Text.rich(TextSpan(children: [
                        TextSpan(text: 'Giá từ  ', style: AppText.bodySm()),
                        TextSpan(text: Fmt.money(court.giaTu!), style: AppText.stat(size: 20, color: AppColor.primaryDark)),
                        TextSpan(text: ' /h', style: AppText.bodySm()),
                      ])),
              ),
              SzButton.small('Đặt sân', kind: SzButtonKind.dark, trailingIcon: Icons.chevron_right_rounded, onPressed: onTap),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Tô vàng phần khớp từ khoá.
class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  const _Highlighted(this.text, this.query, this.style);

  @override
  Widget build(BuildContext context) {
    final i = query.isEmpty ? -1 : text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, i)),
        TextSpan(text: text.substring(i, i + query.length), style: const TextStyle(backgroundColor: Color(0xFFFFF0A3))),
        TextSpan(text: text.substring(i + query.length)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
