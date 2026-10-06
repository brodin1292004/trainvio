// Timetable times are stored as minutes after 00:00 on the day the train
// starts. 1500 therefore means 01:00 on day 2.

String _two(int n) => n.toString().padLeft(2, '0');

/// 24-hour clock time, e.g. 615 -> "10:15".
String clockTime(int minutes) {
  final int m = minutes % 1440;
  return '${_two(m ~/ 60)}:${_two(m % 60)}';
}

/// Journey day, starting at 1.
int journeyDay(int minutes) => minutes ~/ 1440 + 1;

String delayLabel(int delayMinutes) {
  if (delayMinutes <= 0) return 'On time';
  if (delayMinutes < 60) return '$delayMinutes min late';
  final int h = delayMinutes ~/ 60;
  final int m = delayMinutes % 60;
  return m == 0 ? '$h h late' : '$h h $m min late';
}

String durationLabel(int minutes) {
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "6 Oct".
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// e.g. "14:05".
String timeOfDay(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
