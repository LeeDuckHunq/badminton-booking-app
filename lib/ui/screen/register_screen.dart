import 'package:application/api/account_api.dart';
import 'package:application/ui/account/screens/voucher_screen.dart' show PolicyScreen;
import 'package:application/ui/screen/login_screen.dart' show AuthFooterLink;
import 'package:application/ui/theme/app_color.dart';
import 'package:application/ui/theme/app_theme.dart';
import 'package:application/ui/widget/sz.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// M2 – Đăng ký. Trả về `true` qua Navigator.pop khi đăng ký thành công.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _agree = false;
  bool _loading = false;
  final Map<String, String> _errors = {};
  late final TapGestureRecognizer _policyTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyScreen()));

  @override
  void dispose() {
    for (final c in [_username, _password, _fullName, _email, _phone]) {
      c.dispose();
    }
    _policyTap.dispose();
    super.dispose();
  }

  bool _validate() {
    _errors.clear();
    final username = _username.text.trim();
    if (!RegExp(r'^[A-Za-z0-9_.-]{3,32}$').hasMatch(username)) {
      _errors['username'] = '3–32 ký tự, chữ không dấu, số, dấu . _ -';
    }
    if (_password.text.length < 6) _errors['password'] = 'Mật khẩu tối thiểu 6 ký tự';
    if (_fullName.text.trim().isEmpty) _errors['fullName'] = 'Vui lòng nhập họ và tên';
    final email = _email.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) _errors['email'] = 'Email không hợp lệ';
    if (!RegExp(r'^[0-9 +]{9,15}$').hasMatch(_phone.text.trim())) _errors['phone'] = 'Số điện thoại không hợp lệ';
    if (!_agree) _errors['agree'] = 'Bạn cần đồng ý với điều khoản để tiếp tục';
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _register() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    bool ok = false;
    try {
      ok = await AccountApi.register(_username.text.trim(), _password.text, 'ROLE_USER', _fullName.text.trim(), _email.text.trim(), _phone.text.trim());
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      showSzSnack(context, 'Tên đăng nhập đã tồn tại hoặc thông tin không hợp lệ', type: SzToast.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFFEA),
      appBar: const SzTopBar(title: 'Tạo tài khoản', backIcon: Icons.arrow_back_ios_new_rounded),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColor.mintStrong, shape: BoxShape.circle),
              child: const Icon(Icons.sports_tennis_rounded, size: 42, color: AppColor.primaryDark),
            ),
          ),
          const SizedBox(height: 14),
          Text('Tạo tài khoản', textAlign: TextAlign.center, style: AppText.display(color: AppColor.text).copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text('Gia nhập cộng đồng người chơi cầu lông SmashZone', textAlign: TextAlign.center, style: AppText.bodyLg(color: AppColor.textMuted)),
          const SizedBox(height: 20),
          SzCard(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field('Tên đăng nhập', SzTextField(controller: _username, hint: 'nguyentuananh', icon: Icons.person_outline_rounded, error: _errors['username'], textInputAction: TextInputAction.next), help: '3–32 ký tự, chữ không dấu, số, dấu . _ -', errorKey: 'username'),
              _field('Mật khẩu', SzTextField(controller: _password, hint: '••••••••', icon: Icons.lock_outline_rounded, password: true, error: _errors['password'], textInputAction: TextInputAction.next), help: 'Tối thiểu 6 ký tự', errorKey: 'password'),
              _field('Họ và tên', SzTextField(controller: _fullName, hint: 'Nguyễn Tuấn Anh', icon: Icons.badge_outlined, error: _errors['fullName'], textInputAction: TextInputAction.next)),
              _field('Email', SzTextField(controller: _email, hint: 'tenban@gmail.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, error: _errors['email'], textInputAction: TextInputAction.next)),
              _field('Số điện thoại', SzTextField(controller: _phone, hint: '0908 123 456', icon: Icons.call_outlined, keyboardType: TextInputType.phone, error: _errors['phone'], textInputAction: TextInputAction.done, onSubmitted: (_) => _register())),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false), visualDensity: VisualDensity.compact),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text.rich(TextSpan(style: AppText.body(), children: [
                      const TextSpan(text: 'Tôi đồng ý với '),
                      TextSpan(text: 'Điều khoản sử dụng & Chính sách bảo mật', style: AppText.labelLg(color: AppColor.primary), recognizer: _policyTap),
                      const TextSpan(text: ' của SmashZone'),
                    ])),
                  ),
                ),
              ]),
              if (_errors['agree'] != null) Padding(padding: const EdgeInsets.only(left: 12, top: 2), child: Text(_errors['agree']!, style: AppText.bodySm(color: AppColor.danger))),
              const SizedBox(height: 18),
              SzButton('Đăng ký tài khoản', expand: true, height: 56, kind: SzButtonKind.dark, trailingIcon: Icons.sports_score_rounded, loading: _loading, onPressed: _register),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFD7FDDB), borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: AppColor.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text('Đặt sân ngay sau khi đăng ký và nhận voucher giảm giá ở tab Khám phá.', style: AppText.body())),
            ]),
          ),
          const SizedBox(height: 12),
          AuthFooterLink(text: 'Đã có tài khoản?', action: 'Đăng nhập', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _field(String label, Widget input, {String? help, String? errorKey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(style: AppText.labelLg(), children: [TextSpan(text: label), const TextSpan(text: '  *', style: TextStyle(color: AppColor.danger))])),
        const SizedBox(height: 8),
        input,
        if (help != null && (errorKey == null || _errors[errorKey] == null)) ...[const SizedBox(height: 6), Text(help, style: AppText.bodySm())],
      ]),
    );
  }
}
