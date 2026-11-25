import 'package:application/api/community_api.dart';
import 'package:application/ui/community/community_common.dart';
import 'package:application/ui/community/create_match_screen.dart';
import 'package:application/ui/community/group_detail_screen.dart';
import 'package:application/ui/community/group_sheets.dart';
import 'package:application/ui/community/match_detail_screen.dart';
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/material.dart';

enum _Tab { find, mine, groups }

/// Tab Cộng đồng: tìm trận vãng lai, trận của tôi, hội nhóm.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with AutomaticKeepAliveClientMixin {
  _Tab _tab = _Tab.find;

  // Tìm trận
  List<MatchInfo>? _found;
  Object? _findError;
  int _dayOffset = -1; // -1 = mọi ngày
  String? _level;
  String? _type;
  bool _onlyOpen = true;

  // Trận của tôi
  List<MatchInfo>? _mine;
  Object? _mineError;
  bool _showPast = false;

  // Nhóm
  List<GroupInfo>? _myGroups;
  List<GroupInfo>? _discover;
  Object? _groupError;
  final _groupQuery = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFind();
  }

  @override
  void dispose() {
    _groupQuery.dispose();
    super.dispose();
  }

  String? get _day {
    if (_dayOffset < 0) return null;
    final d = DateTime.now().add(Duration(days: _dayOffset));
    return '${d.year}-${Fmt.two(d.month)}-${Fmt.two(d.day)}';
  }

  Future<void> _loadFind() async {
    setState(() => _findError = null);
    try {
      final list = await CommunityApi.search(ngay: _day, trinhDo: _level, kieuChoi: _type, conCho: _onlyOpen);
      if (mounted) setState(() => _found = list);
    } catch (e) {
      if (mounted) setState(() => _findError = e);
    }
  }

  Future<void> _loadMine() async {
    setState(() => _mineError = null);
    try {
      final list = await CommunityApi.myMatches();
      if (mounted) setState(() => _mine = list);
    } catch (e) {
      if (mounted) setState(() => _mineError = e);
    }
  }

  Future<void> _loadGroups() async {
    setState(() => _groupError = null);
    try {
      final r = await Future.wait([CommunityApi.myGroups(), CommunityApi.discover(q: _groupQuery.text.trim())]);
      if (mounted) setState(() { _myGroups = r[0]; _discover = r[1]; });
    } catch (e) {
      if (mounted) setState(() => _groupError = e);
    }
  }

  void _switch(_Tab t) {
    setState(() => _tab = t);
    if (t == _Tab.mine) _loadMine();
    if (t == _Tab.groups) _loadGroups();
    if (t == _Tab.find) _loadFind();
  }

  Future<void> _openMatch(MatchInfo m) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.maTran)));
    _refreshCurrent();
  }

  Future<void> _openGroup(GroupInfo g) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: g.maNhom)));
    _refreshCurrent();
  }

  Future<void> _createMatch() async {
    final created = await Navigator.push<MatchInfo>(context, MaterialPageRoute(builder: (_) => const CreateMatchScreen()));
    if (created != null && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: created.maTran)));
    }
    _refreshCurrent();
  }

  void _refreshCurrent() {
    if (!mounted) return;
    switch (_tab) {
      case _Tab.find: _loadFind();
      case _Tab.mine: _loadMine();
      case _Tab.groups: _loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColor.canvas,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'community-fab',
        onPressed: _tab == _Tab.groups ? () async {
          final g = await showGroupFormSheet(context);
          if (g != null && mounted) _openGroup(g);
        } : _createMatch,
        backgroundColor: AppColor.primaryDark,
        foregroundColor: Colors.white,
        icon: Icon(_tab == _Tab.groups ? Icons.group_add_rounded : Icons.add_circle_outline_rounded),
        label: Text(_tab == _Tab.groups ? 'Tạo nhóm' : 'Mở trận', style: AppText.labelLg(color: Colors.white)),
      ),
      body: Column(children: [
        const SzBrandHeader(subtitle: 'Cộng đồng'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refreshCurrent(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const _Hero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: SzSegmented<_Tab>(options: const [(_Tab.find, 'Tìm trận'), (_Tab.mine, 'Trận của tôi'), (_Tab.groups, 'Hội nhóm')], value: _tab, onChanged: _switch),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(key: ValueKey(_tab), child: switch (_tab) {
                    _Tab.find => _buildFind(),
                    _Tab.mine => _buildMine(),
                    _Tab.groups => _buildGroups(),
                  }),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _chips(List<Widget> chips) => SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), children: [
          for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ]),
      );

  Widget _buildFind() {
    final now = DateTime.now();
    String dayLabel(int i) {
      if (i == 0) return 'Hôm nay';
      if (i == 1) return 'Ngày mai';
      final d = now.add(Duration(days: i));
      return '${Fmt.weekdayShort(d)} ${d.day}/${d.month}';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 6),
      _chips([
        SzChip('Mọi ngày', selected: _dayOffset < 0, onTap: () { setState(() => _dayOffset = -1); _loadFind(); }),
        for (var i = 0; i < 7; i++) SzChip(dayLabel(i), selected: _dayOffset == i, onTap: () { setState(() => _dayOffset = i); _loadFind(); }),
      ]),
      _chips([
        SzChip('Mọi kiểu', selected: _type == null, onTap: () { setState(() => _type = null); _loadFind(); }),
        for (final (code, label, _) in playTypes) SzChip(label, selected: _type == code, onTap: () { setState(() => _type = code); _loadFind(); }),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Row(children: [
          Expanded(child: LevelDropdown(value: _level, allLabel: 'Mọi trình độ', onChanged: (v) { setState(() => _level = v); _loadFind(); })),
          const SizedBox(width: 10),
          FilterChip(
            label: const Text('Còn chỗ'),
            selected: _onlyOpen,
            onSelected: (v) { setState(() => _onlyOpen = v); _loadFind(); },
            selectedColor: AppColor.mint,
            checkmarkColor: AppColor.primaryDark,
          ),
        ]),
      ),
      const SizedBox(height: 12),
      if (_findError != null)
        SzErrorState(message: '$_findError', onRetry: _loadFind)
      else if (_found == null)
        ..._skeletons()
      else if (_found!.isEmpty)
        SzEmptyState(icon: Icons.event_busy_rounded, title: 'Chưa có trận phù hợp', message: 'Thử đổi ngày hoặc trình độ. Hoặc tự mở trận từ sân bạn đã đặt!', actionLabel: 'Mở trận', onAction: _createMatch)
      else ...[
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text('${_found!.length} trận đang tìm người', style: AppText.label(color: AppColor.textMuted))),
        for (final (i, m) in _found!.indexed) _animated(i, Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: MatchCard(m: m, onTap: () => _openMatch(m)))),
      ],
    ]);
  }

  Widget _buildMine() {
    final list = (_mine ?? []).where((m) => _showPast ? m.finished : !m.finished).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 6),
      _chips([
        SzChip('Sắp diễn ra', selected: !_showPast, count: _mine?.where((m) => !m.finished).length, onTap: () => setState(() => _showPast = false)),
        SzChip('Đã qua / đã huỷ', selected: _showPast, count: _mine?.where((m) => m.finished).length, onTap: () => setState(() => _showPast = true)),
      ]),
      const SizedBox(height: 8),
      if (_mineError != null)
        SzErrorState(message: '$_mineError', onRetry: _loadMine)
      else if (_mine == null)
        ..._skeletons()
      else if (list.isEmpty)
        SzEmptyState(icon: Icons.sports_tennis_rounded, title: _showPast ? 'Chưa có trận nào đã qua' : 'Bạn chưa có trận nào sắp tới', message: 'Tìm kèo vãng lai hợp trình độ, hoặc mở trận từ sân bạn đã đặt.', actionLabel: 'Mở trận', onAction: _createMatch)
      else
        for (final (i, m) in list.indexed) _animated(i, Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: MatchCard(m: m, onTap: () => _openMatch(m)))),
    ]);
  }

  Widget _buildGroups() {
    final myIds = (_myGroups ?? []).map((g) => g.maNhom).toSet();
    final others = (_discover ?? []).where((g) => !myIds.contains(g.maNhom)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          Expanded(child: SzButton('Nhập mã mời', icon: Icons.vpn_key_rounded, kind: SzButtonKind.soft, height: 46, onPressed: () async {
            final g = await showJoinCodeSheet(context);
            if (g != null && mounted) _openGroup(g);
          })),
        ]),
      ),
      if (_groupError != null)
        SzErrorState(message: '$_groupError', onRetry: _loadGroups)
      else if (_myGroups == null)
        ..._skeletons()
      else ...[
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: SzSectionTitle(Icons.groups_rounded, 'Nhóm của tôi', trailing: SzPill('${_myGroups!.length}'))),
        if (_myGroups!.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Bạn chưa tham gia nhóm nào. Tạo nhóm cho hội bạn chơi cố định hoặc xin vào một nhóm bên dưới.', style: AppText.body(color: AppColor.textMuted)))
        else
          for (final (i, g) in _myGroups!.indexed) _animated(i, Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: GroupCard(g: g, onTap: () => _openGroup(g)))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), child: SzSectionTitle(Icons.explore_rounded, 'Khám phá nhóm')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _groupQuery,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadGroups(),
            decoration: szInputDecoration(hint: 'Tên nhóm, khu vực…').copyWith(prefixIcon: const Icon(Icons.search_rounded, color: AppColor.textSubtle)),
          ),
        ),
        if (others.isEmpty)
          const SzEmptyState(icon: Icons.travel_explore_rounded, title: 'Không có nhóm phù hợp', message: 'Thử từ khoá khác, hoặc tự lập nhóm của riêng bạn.')
        else
          for (final (i, g) in others.indexed) _animated(i, Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: GroupCard(g: g, onTap: () => _openGroup(g)))),
      ],
    ]);
  }

  List<Widget> _skeletons() => [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: SzSkeleton(height: 150, radius: AppRadius.lg))];

  Widget _animated(int i, Widget child) => TweenAnimationBuilder<double>(
        key: ValueKey('a$i${child.hashCode}'),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 320 + (i.clamp(0, 8)) * 60),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c)),
        child: child,
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF23955A), AppColor.primaryDark, AppColor.forest], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: AppShadow.primaryGlow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          const Positioned(right: 14, top: 10, child: _FloatingShuttle()),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SzPill.accent('CỘNG ĐỒNG', icon: Icons.emoji_events_rounded),
              const SizedBox(height: 10),
              Text('Ghép trận, tìm kèo\nvà lập hội chơi cầu', style: AppText.headlineLg(color: Colors.white).copyWith(fontSize: 22, height: 1.2)),
              const SizedBox(height: 6),
              Text('Thiếu người? Mở trận từ sân đã đặt. Rảnh tay? Tìm trận vãng lai hợp trình độ.', style: AppText.body(color: const Color(0xFFCFF5D6))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FloatingShuttle extends StatefulWidget {
  const _FloatingShuttle();

  @override
  State<_FloatingShuttle> createState() => _FloatingShuttleState();
}

class _FloatingShuttleState extends State<_FloatingShuttle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)), child: Transform.rotate(angle: (_c.value - 0.5) * 0.3, child: child)),
        child: const Text('🏸', style: TextStyle(fontSize: 34)),
      );
}
