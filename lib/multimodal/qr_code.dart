import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatelessWidget {
  const QRScanner(
      {super.key,
      required this.onScan,
      required this.isVisible,
      required this.rotateCamera,
      this.height = 50,
      this.width = 150});

  final ValueChanged<String> onScan;
  final double width;
  final double height;
  final bool isVisible;
  final bool rotateCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isVisible ? width : 0,
      height: isVisible ? height : 0,
      child: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null) onScan(code);
        },
      ),
    );
  }
}
