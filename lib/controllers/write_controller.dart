import 'package:flutter/foundation.dart';
import '../domain/rules.dart';

// A small ChangeNotifier owns the submit guard and user-facing errors.
class WriteController extends ChangeNotifier {
  bool busy = false;
  String? error;
  bool _disposed = false;
  Future<bool> run(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e, stack) {
      error = e is RuleViolation
          ? e.message
          : 'Could not save changes. Your input is preserved. Try again.';
      debugPrint('RailCheck write failure: $e\n$stack');
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
