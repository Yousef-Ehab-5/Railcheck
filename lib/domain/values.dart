// These strings are the database contract: never persist enum indexes.
const components = [
  'Doors',
  'Lighting',
  'Seating',
  'Air conditioning',
  'Passenger displays',
  'Other',
];
const priorities = ['low', 'medium', 'high'];
const statuses = ['open', 'in_progress', 'resolved'];
String label(String value) => switch (value) {
  'open' => 'Open',
  'in_progress' => 'In progress',
  'resolved' => 'Resolved',
  'low' => 'Low',
  'medium' => 'Medium',
  'high' => 'High',
  _ => 'Unknown ($value)',
};
String localTime(int? timestamp) {
  if (timestamp == null) return 'Not recorded';
  final d = DateTime.fromMillisecondsSinceEpoch(
    timestamp,
    isUtc: true,
  ).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
