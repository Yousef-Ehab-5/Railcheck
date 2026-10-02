import 'package:flutter/material.dart';
import '../domain/values.dart';

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String action = 'Confirm',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class Badge extends StatelessWidget {
  final String value;
  const Badge(this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    final icon = switch (value) {
      'high' => Icons.priority_high,
      'medium' => Icons.remove,
      'low' => Icons.arrow_downward,
      'resolved' => Icons.check_circle_outline,
      'in_progress' => Icons.build_outlined,
      'open' => Icons.radio_button_unchecked,
      _ => Icons.help_outline,
    };
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label(value)),
      backgroundColor: value == 'high' ? const Color(0xFFFFE1D8) : null,
      visualDensity: VisualDensity.compact,
    );
  }
}

class Notice extends StatelessWidget {
  final String message;
  const Notice(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}

class CarriageSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const CarriageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'SELECT CARRIAGE',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(6, (index) {
            final n = index + 1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Semantics(
                label: 'Carriage $n',
                selected: n == value,
                button: true,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: n == value
                        ? const Color(0xFFFFD27A)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => onChanged(n),
                  child: Column(
                    children: [
                      const Icon(Icons.train_outlined),
                      Text('$n'),
                      const Text('● ━━ ●', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        initialValue: value,
        key: ValueKey(value),
        decoration: const InputDecoration(
          labelText: 'Carriage (accessible selector)',
        ),
        items: List.generate(
          6,
          (i) =>
              DropdownMenuItem(value: i + 1, child: Text('Carriage ${i + 1}')),
        ),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ],
  );
}
