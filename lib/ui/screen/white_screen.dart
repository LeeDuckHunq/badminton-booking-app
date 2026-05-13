import 'package:flutter/material.dart';

class WhiteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: const Text("TEST SCREEN..."),
                )
              ],
            ),
          )
      ),
    );
  }
}