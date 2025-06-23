import 'package:flutter/widgets.dart';

/// Abstrakter Basistyp für alle Medien.
/// Jedes konkrete Medium liefert sein eigenes Widget.
abstract class MediaType {
  const MediaType();

  Widget build(BuildContext context);
}