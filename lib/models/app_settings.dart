import 'dart:convert';

class AppSettings {
  final double playInterval;
  final bool serverEnabled;
  final int serverPort;

  AppSettings({
    this.playInterval = 2.0,
    this.serverEnabled = true,
    this.serverPort = 8080,
  });

  Map<String, dynamic> toJson() {
    return {
      'playInterval': playInterval,
      'serverEnabled': serverEnabled,
      'serverPort': serverPort,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      playInterval: json['playInterval']?.toDouble() ?? 2.0,
      serverEnabled: json['serverEnabled'] ?? true,
      serverPort: json['serverPort'] ?? 8080,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory AppSettings.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      return AppSettings();
    }
  }

  AppSettings copyWith({
    double? playInterval,
    bool? serverEnabled,
    int? serverPort,
  }) {
    return AppSettings(
      playInterval: playInterval ?? this.playInterval,
      serverEnabled: serverEnabled ?? this.serverEnabled,
      serverPort: serverPort ?? this.serverPort,
    );
  }
}
