import 'dart:convert';

enum NativeEventType { telemetry, battery, connection, discovery, unknown }

class NativeEvent {
  const NativeEvent({
    required this.type,
    required this.timestamp,
    this.deviceId,
    this.data = const <String, dynamic>{},
  });

  final NativeEventType type;
  final DateTime timestamp;
  final String? deviceId;
  final Map<String, dynamic> data;

  static NativeEvent? fromDynamic(dynamic raw) {
    final normalized = _normalize(raw);
    if (normalized == null) return null;
    final type = _parseType(normalized['type'] as String?);
    final timestampMs = (normalized['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final deviceId = normalized['deviceId']?.toString();
    final payload = (normalized['data'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value)) ??
        const <String, dynamic>{};

    return NativeEvent(
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      deviceId: deviceId,
      data: payload,
    );
  }

  static NativeEventType _parseType(String? raw) {
    switch (raw) {
      case 'telemetry':
        return NativeEventType.telemetry;
      case 'battery':
        return NativeEventType.battery;
      case 'connection':
        return NativeEventType.connection;
      case 'discovered':
      case 'device':
        return NativeEventType.discovery;
      default:
        return NativeEventType.unknown;
    }
  }

  static Map<String, dynamic>? _normalize(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map((key, val) => MapEntry(key.toString(), val));
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
