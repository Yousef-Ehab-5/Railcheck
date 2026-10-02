import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'repositories/report_repository.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RailCheckApp());
}

class RailCheckApp extends StatelessWidget {
  const RailCheckApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RailCheck',
    debugShowCheckedModeBanner: false,
    theme: railTheme(),
    home: const _Bootstrap(),
  );
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  ReportRepository? _repository;
  String? _error;
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      final db = await DatabaseService.instance.database;
      if (mounted) setState(() => _repository = ReportRepository(db.reportDao));
    } catch (e, s) {
      debugPrint('Database open failed: $e\n$s');
      if (mounted) {
        setState(
          () => _error =
              'Could not open local storage. Retry without deleting your data. On Web, allow browser storage and use the supplied Web launcher.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_repository != null) return DashboardScreen(repository: _repository!);
    return Scaffold(
      appBar: AppBar(title: const Text('RailCheck')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _open, child: const Text('Retry')),
                  ],
                ),
        ),
      ),
    );
  }
}
