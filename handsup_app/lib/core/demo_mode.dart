import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DemoMode {
  static bool enabled = false;

  static Future<void> autoDetect() async {
    // Включаем демо-режим только на iOS Simulator
    if (Platform.isIOS) {
      final ios = await DeviceInfoPlugin().iosInfo;
      if (ios.isPhysicalDevice == false) {
        enabled = true;
      }
    }
  }
}
