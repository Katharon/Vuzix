import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanner extends StatelessWidget {
  const QRScanner({
    super.key,
    required this.onScan,
    this.height = 250,
  });

  final ValueChanged<String> onScan;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null) onScan(code);
        },
      ),
    );
  }
}
