import 'package:flutter/material.dart';
import 'MediaType.dart';

class ImageMedia extends MediaType {
  final String assetPath;

  const ImageMedia({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}