import 'package:flutter/material.dart';

/// Whether the active app locale uses right-to-left layout.
bool calcIsRtl(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl;

/// Numbers, keypad, and memory labels stay LTR (Windows/iOS calculator convention).
Widget calcNumbersLtr({required Widget child}) => Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
