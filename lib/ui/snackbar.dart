import 'package:flutter/material.dart';

final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

bool showSnackBar(String message, {int duration = 800, BuildContext? context}) {
  try {
    // we need a state to show a snackbar
    // either from the provided context
    // or from the global key which must be placed in the scaffold of the app
    ScaffoldMessengerState? state = context != null
        ? ScaffoldMessenger.of(context)
        : scaffoldKey.currentContext != null
            ? ScaffoldMessenger.of(scaffoldKey.currentContext!)
            : scaffoldKey.currentState;

    state?.showSnackBar(SnackBar(
      duration: Duration(milliseconds: duration),
      content: Text(message),
      behavior: SnackBarBehavior.fixed,
    ));
    return true;
  } catch (e) {
    return false;
  }
}
