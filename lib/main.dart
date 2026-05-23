import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/qr_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/security/AuthManager.dart';
import 'package:application/ui/screen/account_screen.dart';
import 'package:application/ui/screen/home_screen.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://amkurnemhawgartdzhwx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFta3VybmVtaGF3Z2FydGR6aHd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5Mzc0NzgsImV4cCI6MjA5NDUxMzQ3OH0.ZaDoOxVC1Hy2Id2JvDpmnFgFBdoC2wRm9IalESJuJAU',
  );

  bool loggedIn = await AuthManager.isLoggedIn();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: loggedIn
          ? HomeScreen()
          : LoginScreen(),
    ),
  );
}

Future<void> testQR() async {

  final qr = await QRApi.getQR(
    'leduchung',
  );

  if (qr != null) {

    print(
      'Receiver: ${qr.receiver}',
    );

    print(
      'QR Code: ${qr.qrCode}',
    );

  } else {

    print(
      'Khong lay duoc QR',
    );
  }
}