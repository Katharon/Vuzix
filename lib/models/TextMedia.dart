import 'package:flutter/material.dart';
import 'MediaType.dart';

class TextMedia extends MediaType {
  final String text;

  const TextMedia({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.left,
      ),
    );
  }
}