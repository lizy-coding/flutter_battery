import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PerfLabChannel {
  PerfLabChannel._();

  static const MethodChannel _ch = MethodChannel('perflab');

  static Future<void> logMarker(String name, {int? tMs}) async {
    if (kReleaseMode) return;
    try {
      await _ch.invokeMethod('logMarker', <String, dynamic>{
        'name': name,
        if (tMs != null) 'tMs': tMs,
      });
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getStartupTimeline() async {
    if (kReleaseMode) return <String, dynamic>{};
    final res = await _ch.invokeMethod('getStartupTimeline');
    return (res as Map).cast<String, dynamic>();
  }
}
