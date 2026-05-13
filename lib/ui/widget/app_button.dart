import 'package:application/ui/theme/app_color.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {

  final String btnText;
  final bool isLoading;
  final VoidCallback onTap;

  const AppButton({
    super.key,
    required this.btnText,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColor.kDeepGreen,
            AppColor.kCourtGreen,
            AppColor.kGreenLight
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),

          onTap: isLoading ? null : onTap,

          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColor.kLineWhite,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              btnText,
              style: const TextStyle(
                color: AppColor.kLineWhite,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}