import 'package:flutter_test/flutter_test.dart';
import 'package:janus/models/frame_protocol.dart';
import 'package:janus/models/multi_frame_analysis.dart';
import 'package:janus/models/serial_entry.dart';

FrameTemplate _template(String id, String opcode, FrameRole role,
        {String? responseTo}) =>
    FrameTemplate(
      id: id,
      name: id,
      role: role,
      responseToTemplateId: responseTo,
      correlationFieldId: 'payload',
      fields: [
        const ProtocolField(
          id: 'header',
          kind: ProtocolFieldKind.header,
          name: 'header',
          byteLength: 2,
          valueHex: 'AA 55',
        ),
        const ProtocolField(
          id: 'length',
          kind: ProtocolFieldKind.length,
          name: 'length',
        ),
        ProtocolField(
          id: 'opcode',
          kind: ProtocolFieldKind.integer,
          name: 'opcode',
          valueHex: opcode,
          matchValue: true,
        ),
        const ProtocolField(
          id: 'payload',
          kind: ProtocolFieldKind.payload,
          name: 'payload',
        ),
        const ProtocolField(
          id: 'sum',
          kind: ProtocolFieldKind.checksum,
          name: 'sum',
        ),
        const ProtocolField(
          id: 'trailer',
          kind: ProtocolFieldKind.trailer,
          name: 'trailer',
          valueHex: '0D',
        ),
      ],
    );

void main() {
  final request = _template('query', '10', FrameRole.request);
  final response =
      _template('reply', '20', FrameRole.response, responseTo: 'query');

  test('recognizes two templates with the same header across UART reads', () {
    final framer = MultiTemplateFramer([request, response]);
    final at = DateTime.utc(2026, 9, 25);
    final query = request.compose({'payload': '33'}).hex;
    final reply = response.compose({'payload': '33'}).hex;
    expect(framer.addHex('AA', at), isEmpty);
    expect(framer.addHex(query.substring(2, 9), at), isEmpty);
    final first = framer.addHex(query.substring(9), at);
    expect(first, hasLength(1));
    expect(first.single.template?.id, 'query');
    expect(first.single.parsed?.valid, isTrue);
    final second = framer.addHex(reply, at);
    expect(second.single.template?.id, 'reply');
    expect(second.single.parsed?.valid, isTrue);
  });

  test('pairs a response by template and field, and reports timeout', () {
    final tracker = RequestResponseTracker(timeout: const Duration(seconds: 2));
    final at = DateTime.utc(2026, 9, 25);
    final tx = SerialEntry(
        direction: SerialDirection.tx,
        timestamp: at,
        hex: request.compose({'payload': '33'}).hex,
        label: 'TX');
    final rx = SerialEntry(
        direction: SerialDirection.rx,
        timestamp: at.add(const Duration(milliseconds: 120)),
        hex: response.compose({'payload': '33'}).hex,
        label: 'RX');
    tracker.observe(tx, request, ProtocolFrameParser(request).parseHex(tx.hex));
    tracker.observe(
        rx, response, ProtocolFrameParser(response).parseHex(rx.hex));
    expect(tracker.transactions.single.status, TransactionStatus.completed);
    expect(tracker.transactions.single.latency?.inMilliseconds, 120);

    final later = SerialEntry(
        direction: SerialDirection.tx,
        timestamp: at.add(const Duration(seconds: 3)),
        hex: tx.hex,
        label: 'TX');
    tracker.observe(
        later, request, ProtocolFrameParser(request).parseHex(later.hex));
    tracker.expire(at.add(const Duration(seconds: 6)));
    expect(tracker.transactions.last.status, TransactionStatus.timedOut);
  });

  test('does not pair a response with a different correlation value', () {
    final tracker = RequestResponseTracker();
    final at = DateTime.utc(2026, 9, 25);
    final tx = SerialEntry(
        direction: SerialDirection.tx,
        timestamp: at,
        hex: request.compose({'payload': '33'}).hex,
        label: 'TX');
    final wrong = SerialEntry(
        direction: SerialDirection.rx,
        timestamp: at.add(const Duration(milliseconds: 10)),
        hex: response.compose({'payload': '44'}).hex,
        label: 'RX');
    tracker.observe(tx, request, ProtocolFrameParser(request).parseHex(tx.hex));
    tracker.observe(
        wrong, response, ProtocolFrameParser(response).parseHex(wrong.hex));
    expect(tracker.transactions.single.status, TransactionStatus.pending);
  });

  test('integer defaults are only fixed when explicitly marked', () {
    final flexible = _template('flex', '10', FrameRole.other).copyWith(fields: [
      for (final field in request.fields)
        field.id == 'opcode' ? field.copyWith(matchValue: false) : field,
    ]);
    final bytes = flexible.compose({'opcode': '32', 'payload': '01'}).hex;
    expect(ProtocolFrameParser(flexible).parseHex(bytes).valid, isTrue);
    expect(ProtocolFrameParser(request).parseHex(bytes).valid, isFalse);
  });
}
