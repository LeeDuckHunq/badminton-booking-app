import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:flutter/material.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await testApi();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    ),
  );
}

Future<void> testApi() async {
  try {

    final dsSan =
    await SanApi
        .getSanTheoCumSan(
        'CS001');

    print(
      'So san: ${dsSan.length}',
    );

    final dsPhieu =
    await PhieuDatSanApi
        .getPhieuDatTheoNgay(
      DateTime(
        2026,
        5,
        16,
      ),
    );

    print(
      'So phieu: ${dsPhieu.length}',
    );

  } catch (e) {

    print(
      'Loi API: $e',
    );
  }
}