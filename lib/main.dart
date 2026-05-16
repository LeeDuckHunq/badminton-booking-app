import 'package:application/api/phieu_dat_san_api.dart';
import 'package:application/api/qr_api.dart';
import 'package:application/api/san_api.dart';
import 'package:application/ui/screen/login_screen.dart';
import 'package:flutter/material.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
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