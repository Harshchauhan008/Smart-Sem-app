import 'package:flutter/material.dart';

const String appName = 'SmartSem';

Size screenSize(BuildContext context) {
  return MediaQuery.sizeOf(context);
}

bool isMobile(BuildContext context) {
  return screenSize(context).width < 600;
}

bool isTablet(BuildContext context) {
  final width = screenSize(context).width;
  return width >= 600 && width < 1024;
}

bool isDesktop(BuildContext context) {
  return screenSize(context).width >= 1024;
}
