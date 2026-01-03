import 'package:flutter/widgets.dart';

/// Simple responsive helpers for mobile/tablet layouts.
const double kTabletBreakpoint = 600.0; // Material default guidance for tablets
const double kDesktopBreakpoint = 900.0;

bool isTabletWidth(double width) => width >= kTabletBreakpoint;

bool isDesktopWidth(double width) => width >= kDesktopBreakpoint;

int gridCountForWidth(double width) {
  if (width >= kDesktopBreakpoint) return 4;
  if (width >= kTabletBreakpoint) return 3;
  return 2;
}

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= kTabletBreakpoint;

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= kDesktopBreakpoint;
