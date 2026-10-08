import 'package:flutter/material.dart';
import 'package:town_pass/gen/assets.gen.dart';
// 使用作業系統字體，避免打包授權未明字體。
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CityNewsWidget extends StatelessWidget {
  const CityNewsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _Button(
              icon: Assets.svg.iconPoster.svg(),
              text: '市政新聞',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: _Button(
              icon: Assets.svg.icon1999.svg(),
              text: '1999',
              onTap: () {
                launchUrlString('tel://1999');
              },
            ),
          )
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final Widget icon;
  final String text;
  final GestureTapCallback? onTap;

  const _Button({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap?.call,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: TPColors.grayscale50),
            borderRadius: BorderRadius.circular(6),
          ),
          shadows: const [
            BoxShadow(
              color: TPColors.grayscale100,
              blurRadius: 8,
              offset: Offset(0, 1),
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            TPText(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TPColors.grayscale800,
                fontSize: 16,
                fontFamily: null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
