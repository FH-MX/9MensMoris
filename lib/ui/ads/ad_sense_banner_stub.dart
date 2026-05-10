import 'package:flutter/widgets.dart';

class AdSenseBanner extends StatelessWidget {
  final double height;

  const AdSenseBanner({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
