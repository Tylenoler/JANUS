enum SerialDirection { rx, tx }

class SerialEntry {
  const SerialEntry({
    required this.direction,
    required this.timestamp,
    required this.hex,
    required this.label,
    this.templateId,
  });

  final SerialDirection direction;
  final DateTime timestamp;
  final String hex;
  final String label;
  final String? templateId;

  int get byteCount =>
      hex.split(RegExp(r'\s+')).where((byte) => byte.isNotEmpty).length;

  Map<String, dynamic> toJson() => {
        'direction': direction.name,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'hex': hex,
        'label': label,
        if (templateId != null) 'templateId': templateId,
      };

  factory SerialEntry.fromJson(Map<String, dynamic> json) => SerialEntry(
        direction: json['direction'] == SerialDirection.tx.name
            ? SerialDirection.tx
            : SerialDirection.rx,
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        hex: json['hex']?.toString() ?? '',
        label: json['label']?.toString() ?? '会话记录',
        templateId: json['templateId']?.toString(),
      );
}
