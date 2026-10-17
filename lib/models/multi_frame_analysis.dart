import 'frame_protocol.dart';
import 'receive_framer.dart';
import 'serial_entry.dart';

/// One recognized display unit. A missing template means bytes could not be
/// attributed to any enabled protocol definition.
class RecognizedFrame {
  const RecognizedFrame({
    required this.data,
    this.template,
    this.parsed,
  });

  final FramedReceiveData data;
  final FrameTemplate? template;
  final ParsedFrame? parsed;
}

class _Candidate {
  const _Candidate(this.template, this.rule, this.header);
  final FrameTemplate template;
  final LengthFieldFramingConfig rule;
  final List<int> header;
}

/// Recognizes several length-delimited templates on one UART byte stream.
/// Complete valid candidates win; an incomplete candidate keeps the bytes
/// buffered so a shorter invalid lookalike cannot consume a longer frame.
class MultiTemplateFramer {
  MultiTemplateFramer(List<FrameTemplate> templates) {
    configure(templates);
  }

  final List<int> _pending = [];
  DateTime? _timestamp;
  late List<_Candidate> _candidates;
  static const maximumPendingBytes = 64 * 1024;

  void configure(List<FrameTemplate> templates) {
    _candidates = [
      for (final template in templates)
        _Candidate(
          template,
          template.receiveFramingConfig().lengthField,
          parseHexBytes(template.receiveFramingConfig().lengthField.headerHex),
        ),
    ];
    reset();
  }

  void reset() {
    _pending.clear();
    _timestamp = null;
  }

  List<RecognizedFrame> addHex(String hex, DateTime timestamp) =>
      add(parseHexBytes(hex), timestamp);

  List<RecognizedFrame> add(List<int> bytes, DateTime timestamp) {
    if (bytes.isEmpty) return const [];
    if (_pending.isEmpty) _timestamp = timestamp;
    _pending.addAll(bytes);
    final output = <RecognizedFrame>[];
    while (_pending.isNotEmpty) {
      if (_pending.length > maximumPendingBytes) {
        output.add(_take(_pending.length - maximumPendingBytes,
            FramedReceiveKind.incomplete, '缓冲超过 64 KiB'));
        continue;
      }
      final at = _firstHeaderIndex();
      if (at < 0) {
        final keep = _longestHeaderSuffix();
        if (_pending.length > keep) {
          output.add(_take(
              _pending.length - keep, FramedReceiveKind.orphan, '未匹配任何已启用模板'));
        }
        break;
      }
      if (at > 0) {
        output.add(_take(at, FramedReceiveKind.orphan, '模板帧头前的字节'));
        continue;
      }
      final matching = _candidates
          .where((candidate) => _startsWith(_pending, candidate.header))
          .toList();
      if (matching.isEmpty) break; // Partial header.
      RecognizedFrame? valid;
      RecognizedFrame? invalid;
      var incomplete = false;
      for (final candidate in matching) {
        final rule = candidate.rule;
        final needed = rule.lengthOffset + rule.lengthBytes;
        if (_pending.length < needed) {
          incomplete = true;
          continue;
        }
        final declared = _readUnsigned(
            _pending, rule.lengthOffset, rule.lengthBytes, rule.littleEndian);
        final total = declared + rule.lengthAdjustment;
        if (total < needed || total > rule.maximumFrameBytes) continue;
        if (_pending.length < total) {
          incomplete = true;
          continue;
        }
        final frameBytes = _pending.sublist(0, total);
        final frame = FramedReceiveData(frameBytes, _timestamp ?? timestamp);
        final parsed =
            ProtocolFrameParser(candidate.template).parseHex(frame.hex);
        final found = RecognizedFrame(
            data: frame, template: candidate.template, parsed: parsed);
        if (parsed.valid) {
          valid = found;
          break;
        }
        invalid ??= found;
      }
      if (valid != null) {
        output.add(_take(valid.data.bytes.length, FramedReceiveKind.frame, null,
            valid.template, valid.parsed));
      } else if (incomplete) {
        break;
      } else if (invalid != null) {
        output.add(_take(invalid.data.bytes.length, FramedReceiveKind.frame,
            invalid.parsed?.error, invalid.template, invalid.parsed));
      } else {
        output.add(_take(1, FramedReceiveKind.orphan, '模板长度字段无效'));
      }
    }
    return output;
  }

  List<RecognizedFrame> flush() => _pending.isEmpty
      ? const []
      : [_take(_pending.length, FramedReceiveKind.incomplete, '接收流尚未组成完整模板帧')];

  RecognizedFrame _take(int count, FramedReceiveKind kind, String? note,
      [FrameTemplate? template, ParsedFrame? parsed]) {
    final bytes = List<int>.unmodifiable(_pending.sublist(0, count));
    _pending.removeRange(0, count);
    final at = _timestamp ?? DateTime.now().toUtc();
    if (_pending.isEmpty) _timestamp = null;
    return RecognizedFrame(
        data: FramedReceiveData(bytes, at, kind: kind, note: note),
        template: template,
        parsed: parsed);
  }

  int _firstHeaderIndex() {
    for (var index = 0; index < _pending.length; index++) {
      for (final candidate in _candidates) {
        if (_matchesAt(index, candidate.header)) return index;
      }
    }
    return -1;
  }

  int _longestHeaderSuffix() {
    for (var length = _pending.length; length > 0; length--) {
      final suffix = _pending.sublist(_pending.length - length);
      if (_candidates.any((candidate) =>
          suffix.length < candidate.header.length &&
          _startsWith(candidate.header, suffix))) {
        return length;
      }
    }
    return 0;
  }

  bool _matchesAt(int offset, List<int> header) =>
      offset + header.length <= _pending.length &&
      _startsWith(_pending.sublist(offset), header);

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[index] != prefix[index]) return false;
    }
    return true;
  }

  static int _readUnsigned(
      List<int> bytes, int offset, int width, bool littleEndian) {
    var value = 0;
    for (var index = 0; index < width; index++) {
      final shift = littleEndian ? index : width - index - 1;
      value |= bytes[offset + index] << (shift * 8);
    }
    return value;
  }
}

enum TransactionStatus { pending, completed, timedOut }

class ProtocolTransaction {
  ProtocolTransaction({
    required this.request,
    required this.requestTemplate,
    required this.requestKey,
  });

  final SerialEntry request;
  final FrameTemplate requestTemplate;
  final String? requestKey;
  SerialEntry? response;
  FrameTemplate? responseTemplate;
  TransactionStatus status = TransactionStatus.pending;

  Duration? get latency => response?.timestamp.difference(request.timestamp);
}

/// TX requests are paired with the first matching RX response. When both
/// templates identify a correlation field, its parsed bytes disambiguate
/// concurrent requests; otherwise the matching request queue is FIFO.
class RequestResponseTracker {
  RequestResponseTracker({this.timeout = const Duration(seconds: 2)});

  Duration timeout;
  final List<ProtocolTransaction> transactions = [];

  void reset() => transactions.clear();

  void observe(SerialEntry entry, FrameTemplate template, ParsedFrame parsed) {
    if (!parsed.valid) return;
    expire(entry.timestamp);
    if (entry.direction == SerialDirection.tx &&
        template.role == FrameRole.request) {
      transactions.add(ProtocolTransaction(
        request: entry,
        requestTemplate: template,
        requestKey: _key(template, parsed),
      ));
      if (transactions.length > 500) transactions.removeAt(0);
    } else if (entry.direction == SerialDirection.rx &&
        template.role == FrameRole.response) {
      final responseKey = _key(template, parsed);
      for (final transaction in transactions) {
        if (transaction.status != TransactionStatus.pending ||
            template.responseToTemplateId != transaction.requestTemplate.id) {
          continue;
        }
        if (responseKey != null && transaction.requestKey != responseKey) {
          continue;
        }
        transaction
          ..response = entry
          ..responseTemplate = template
          ..status = TransactionStatus.completed;
        break;
      }
    }
  }

  void expire(DateTime now) {
    for (final transaction in transactions) {
      if (transaction.status == TransactionStatus.pending &&
          now.difference(transaction.request.timestamp) >= timeout) {
        transaction.status = TransactionStatus.timedOut;
      }
    }
  }

  String? _key(FrameTemplate template, ParsedFrame parsed) {
    final id = template.correlationFieldId;
    if (id == null || id.isEmpty) return null;
    for (final field in parsed.fields) {
      if (field.field.id == id) {
        return field.bytes
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase();
      }
    }
    return null;
  }
}
