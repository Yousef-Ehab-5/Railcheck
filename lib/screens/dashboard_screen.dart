import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:shake/shake.dart';
import '../database/report.dart';
import '../domain/values.dart';
import '../repositories/report_repository.dart';
import '../widgets/common.dart';
import 'editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ReportStore repository;
  const DashboardScreen({super.key, required this.repository});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  StreamSubscription<List<Report>>? _subscription;
  ShakeDetector? _shake;
  List<Report> _reports = [];
  final _search = TextEditingController();
  String _query = '', _status = 'all', _priority = 'all';
  String? _error;
  bool _loading = true, _confirming = false, _deleting = false, _active = true;
  int _watchGeneration = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watch();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _shake = ShakeDetector.autoStart(
        onPhoneShake: (_) {
          if (_active && ModalRoute.of(context)?.isCurrent == true) {
            _deleteAll();
          }
        },
        minimumShakeCount: 2,
        shakeThresholdGravity: 2.7,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
  }

  Future<void> _watch() async {
    final generation = ++_watchGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _subscription?.cancel();
    if (!mounted || generation != _watchGeneration) return;
    _subscription = widget.repository.watchAll().listen(
      (reports) {
        if (mounted) {
          setState(() {
            _reports = reports;
            _loading = false;
            _error = null;
          });
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Report stream failed: $error\n$stack');
        if (mounted) {
          setState(() {
            _loading = false;
            _error =
                'Could not load reports. Your saved database has not been deleted.';
          });
        }
      },
    );
  }

  Future<void> _deleteAll() async {
    if (_confirming ||
        _deleting ||
        _reports.isEmpty ||
        !mounted ||
        _loading ||
        _error != null) {
      return;
    }
    _confirming = true;
    try {
      final accepted = await confirm(
        context,
        'Delete ALL reports?',
        'This permanently deletes all ${_reports.length} saved reports, including reports hidden by filters. This cannot be undone.',
        action: 'Delete all',
      );
      if (!accepted || !mounted) return;
      setState(() => _deleting = true);
      await widget.repository.deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All reports deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deletion failed. Try again.')),
        );
      }
    } finally {
      _confirming = false;
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _open([Report? report]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EditorScreen(repository: widget.repository, reportId: report?.id),
      ),
    );
  }

  @override
  void dispose() {
    ++_watchGeneration;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _shake?.stopListening();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _reports
        .where(
          (r) =>
              (_status == 'all' || r.status == _status) &&
              (_priority == 'all' || r.priority == _priority) &&
              (r.train.toLowerCase().contains(_query) ||
                  r.description.toLowerCase().contains(_query)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('RailCheck'),
        actions: [
          IconButton(
            tooltip: 'Delete all reports (also available by shaking a phone)',
            onPressed:
                _reports.isEmpty || _deleting || _loading || _error != null
                ? null
                : _deleteAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _deleting ? null : () => _open(),
        icon: const Icon(Icons.add),
        label: const Text('Report defect'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '●  INSPECTION CONTROL  ━━━━━',
                          style: TextStyle(
                            color: Color(0xFF805600),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Every carriage. Every detail.',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text(
                          'Training simulator • Fictional trains • Stored on this device',
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ALL SAVED REPORTS • Counters ignore filters',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _counter('Total', _reports.length),
                            for (final s in statuses)
                              _counter(
                                label(s),
                                _reports.where((r) => r.status == s).length,
                              ),
                          ],
                        ),
                        if (_reports.any((r) => !statuses.contains(r.status)))
                          const Notice(
                            'Some reports have unknown statuses; they are included in Total.',
                          ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            labelText: 'Search train or description',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (s) =>
                              setState(() => _query = s.trim().toLowerCase()),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 210,
                              child: DropdownButtonFormField<String>(
                                initialValue: _status,
                                decoration: const InputDecoration(
                                  labelText: 'Status filter',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All statuses'),
                                  ),
                                  for (final s in statuses)
                                    DropdownMenuItem(
                                      value: s,
                                      child: Text(label(s)),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _status = v!),
                              ),
                            ),
                            SizedBox(
                              width: 210,
                              child: DropdownButtonFormField<String>(
                                initialValue: _priority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority filter',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All priorities'),
                                  ),
                                  for (final p in priorities)
                                    DropdownMenuItem(
                                      value: p,
                                      child: Text(label(p)),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _priority = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${visible.length} reports shown • Recently updated first',
                        ),
                        if (_deleting) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Notice(_error!),
                          FilledButton(
                            onPressed: _watch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (visible.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.train_outlined, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            _reports.isEmpty
                                ? 'Your inspection log starts here.'
                                : 'No reports match these filters.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _reports.isEmpty
                                ? 'Tap Report defect to record your first inspection.'
                                : 'Try another search or choose All in the filters.',
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final r = visible[index];
                        return Card(
                          key: ValueKey(r.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _deleting ? null : () => _open(r),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Train ${r.train} • Carriage ${r.carriage}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(r.component),
                                  const SizedBox(height: 8),
                                  Text(
                                    r.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Badge(r.priority),
                                      Badge(r.status),
                                    ],
                                  ),
                                  Text('Updated ${localTime(r.updatedAt)}'),
                                  if (r.latitude != null)
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Text('Location attached'),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: visible.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _counter(String title, int n) => Container(
    constraints: const BoxConstraints(minWidth: 105),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD8DAD8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$n', style: Theme.of(context).textTheme.headlineMedium),
        Text(title),
      ],
    ),
  );
}
