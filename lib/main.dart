import 'package:application/api/api_client.dart';
import 'package:application/security/AuthManager.dart';
import 'package:application/ui/screen/home_screen.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Token hết hạn / tài khoản bị khoá → đăng xuất và quay về màn hình đăng nhập.
  ApiClient.onUnauthorized = () async {
    await AuthManager.logout();
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    final context = appNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.')),
      );
    }
  };

  bool loggedIn = await AuthManager.isLoggedIn();

  runApp(
    MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      home: loggedIn ? HomeScreen() : LoginScreen(),
    ),
  );
}
