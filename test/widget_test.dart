import 'package:flutter_test/flutter_test.dart';
import 'package:trainvio/core/formatters.dart';

void main() {
  test('clock time wraps past midnight and reports the journey day', () {
    expect(clockTime(615), '10:15');
    expect(clockTime(1500), '01:00');
    expect(journeyDay(615), 1);
    expect(journeyDay(1500), 2);
  });

  test('delay is described in plain words', () {
    expect(delayLabel(0), 'On time');
    expect(delayLabel(18), '18 min late');
    expect(delayLabel(60), '1 h late');
    expect(delayLabel(95), '1 h 35 min late');
  });

  test('journey length is described in hours and minutes', () {
    expect(durationLabel(45), '45 min');
    expect(durationLabel(120), '2 h');
    expect(durationLabel(135), '2 h 15 min');
  });
}
