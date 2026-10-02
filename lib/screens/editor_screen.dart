import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Badge;
import '../controllers/write_controller.dart';
import '../database/report.dart';
import '../domain/rules.dart';
import '../domain/values.dart';
import '../repositories/report_repository.dart';
import '../services/location_service.dart';
import '../widgets/common.dart';

// One reusable editor, reached as Add (screen 2) or Details/Edit (screen 3).
class EditorScreen extends StatefulWidget {
  final ReportStore repository;
  final int? reportId;
  const EditorScreen({super.key, required this.repository, this.reportId});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _form = GlobalKey<FormState>();
  final _train = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _writer = WriteController();
  final _location = LocationService();
  Draft _draft = Draft();
  Report? _original;
  String _baseline = '';
  String? _loadError;
  LocationFailure? _locationError;
  String? _locationFeedback;
  bool _loading = false, _missing = false, _allowPop = false;
  bool _wantLocation = false, _locating = false, _leaving = false;
  bool _initialWantLocation = false;
  int _locationGeneration = 0;
  bool get _editing => widget.reportId != null;
  bool get _dirty =>
      _baseline != _draft.fingerprint || _wantLocation != _initialWantLocation;
  bool get _supported => _original == null || Rules.known(_original!);
  @override
  void initState() {
    super.initState();
    _baseline = _draft.fingerprint;
    _writer.addListener(_refresh);
    _train.addListener(_textChanged);
    _description.addListener(_textChanged);
    _notes.addListener(_textChanged);
    if (_editing) _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _textChanged() {
    _draft.train = _train.text;
    _draft.description = _description.text;
    _draft.notes = _notes.text;
    _refresh();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final r = await widget.repository.find(widget.reportId!);
      if (!mounted) return;
      if (r == null) {
        setState(() => _missing = true);
        return;
      }
      _original = r;
      // Controller listeners synchronize only after all three values are assigned.
      _train.removeListener(_textChanged);
      _description.removeListener(_textChanged);
      _notes.removeListener(_textChanged);
      _draft = Draft.fromReport(r);
      _train.text = r.train;
      _description.text = r.description;
      _notes.text = r.resolutionNotes ?? '';
      _train.addListener(_textChanged);
      _description.addListener(_textChanged);
      _notes.addListener(_textChanged);
      _wantLocation = r.latitude != null;
      _initialWantLocation = _wantLocation;
      _baseline = _draft.fingerprint;
    } catch (_) {
      if (mounted) {
        setState(
          () => _loadError = 'Could not load this report. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exit() async {
    ++_locationGeneration;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _leave() async {
    if (_writer.busy || _leaving) return;
    _leaving = true;
    try {
      if (!_dirty ||
          await confirm(
            context,
            'Discard unsaved changes?',
            'Your unsaved edits and any pending location request will be discarded.',
            action: 'Discard',
          )) {
        if (mounted) await _exit();
      }
    } finally {
      _leaving = false;
    }
  }

  void _clearLocation() {
    ++_locationGeneration;
    setState(() {
      _wantLocation = false;
      _locating = false;
      _locationError = null;
      _locationFeedback = null;
      _draft.clearLocation();
    });
  }

  Future<void> _capture() async {
    final request = ++_locationGeneration;
    setState(() {
      _wantLocation = true;
      _locating = true;
      _locationError = null;
      _locationFeedback = null;
    });
    try {
      final p = await _location.capture();
      if (!mounted || request != _locationGeneration || !_wantLocation) return;
      setState(() {
        _draft.latitude = p.latitude;
        _draft.longitude = p.longitude;
        _draft.capturedAt = p.timestamp;
        _locationFeedback =
            'Location captured • estimated accuracy ±${p.accuracy.toStringAsFixed(0)} m. Approximate positions are accepted.';
      });
    } on LocationFailure catch (e) {
      if (mounted && request == _locationGeneration) {
        setState(() => _locationError = e);
      }
    } finally {
      if (mounted && request == _locationGeneration) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _settings(bool app) async {
    final opened = await _location.openSettings(app: app);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'After changing settings, return here and tap Retry.'
              : 'Open your device or browser site settings manually, then tap Retry.',
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_writer.busy ||
        _locating ||
        !_supported ||
        !_form.currentState!.validate()) {
      return;
    }
    if (_wantLocation && (_draft.latitude == null || _locationError != null)) {
      return;
    }
    final snapshot = _draft.copy();
    final ok = await _writer.run(
      () => widget.repository.save(snapshot, _original),
    );
    if (ok && mounted) await _exit();
  }

  Future<void> _delete() async {
    if (_writer.busy || _original == null) return;
    final yes = await confirm(
      context,
      'Delete this report?',
      'This permanently deletes report #${_original!.id}. Unsaved edits will also be discarded.',
      action: 'Delete',
    );
    if (!yes || !mounted) return;
    final ok = await _writer.run(() => widget.repository.delete(_original!));
    if (ok && mounted) await _exit();
  }

  Future<void> _transition() async {
    final old = _original!.status;
    if (old == 'resolved') {
      final yes = await confirm(
        context,
        'Reopen report?',
        'Saving this change returns the report to Open and clears its current resolution notes and resolution time. No audit history is kept.',
        action: 'Reopen',
      );
      if (!yes || !mounted) return;
    }
    setState(() {
      _draft.status = switch (old) {
        'open' => 'in_progress',
        'in_progress' => 'resolved',
        _ => 'open',
      };
      if (old == 'resolved') _notes.clear();
    });
  }

  @override
  void dispose() {
    ++_locationGeneration;
    _writer.removeListener(_refresh);
    _writer.dispose();
    _train.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Report details / edit' : 'Report a defect'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _writer.busy ? null : _leave,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _body(),
          ),
        ),
      ),
    ),
  );
  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_missing) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('This report no longer exists. Return to the dashboard.'),
      );
    }
    if (_loadError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Notice(_loadError!),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (!_supported) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Notice(
            'Unsupported stored value. This report is read-only to avoid silently changing data.',
          ),
          Text('Train ${_original!.train} • Carriage ${_original!.carriage}'),
          Text('Component: ${_original!.component}'),
          Text(_original!.description),
          Badge(_original!.status),
          Badge(_original!.priority),
          Text('Created: ${localTime(_original!.createdAt)}'),
          Text('Updated: ${localTime(_original!.updatedAt)}'),
          Text(
            'Location: ${_original!.latitude}, ${_original!.longitude} • ${localTime(_original!.locationCapturedAt)}',
          ),
          Text('Resolved: ${localTime(_original!.resolvedAt)}'),
          Text(_original!.resolutionNotes ?? ''),
          if (_writer.error != null) Notice(_writer.error!),
          TextButton(
            onPressed: _writer.busy ? null : _delete,
            child: const Text('Delete report'),
          ),
        ],
      );
    }
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'TRAINING SIMULATOR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF805600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _editing ? 'Inspection #${_original!.id}' : 'Log an inspection',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (_original != null) ...[
            const SizedBox(height: 8),
            Text('Created ${localTime(_original!.createdAt)}'),
            Text('Last saved ${localTime(_original!.updatedAt)}'),
            if (_original!.resolvedAt != null)
              Text('Resolved ${localTime(_original!.resolvedAt)}'),
          ],
          const SizedBox(height: 20),
          AbsorbPointer(
            absorbing: _writer.busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _train,
                  validator: Rules.trainError,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Train identifier',
                    hintText: 'e.g. Train 205 or RC-A12',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                CarriageSelector(
                  value: _draft.carriage,
                  onChanged: (v) => setState(() => _draft.carriage = v),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _draft.component,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Component'),
                  items: components
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _draft.component = v!),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _description,
                  validator: Rules.descriptionError,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Defect description',
                    alignLabelWithHint: true,
                    hintText: 'Describe the defect and where you found it.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _draft.priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: priorities
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v, child: Text(label(v))),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _draft.priority = v!),
                ),
                const SizedBox(height: 20),
                const Text(
                  'LOCATION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    _editing
                        ? 'Attach location to this report'
                        : 'Attach my current location',
                  ),
                  subtitle: const Text('Optional • Foreground capture only'),
                  value: _wantLocation,
                  onChanged: (v) {
                    if (v == true) {
                      _capture();
                    } else {
                      _clearLocation();
                    }
                  },
                ),
                if (_locating) ...[
                  const LinearProgressIndicator(),
                  const Text(
                    'Getting your location… You can uncheck to cancel.',
                  ),
                ],
                if (_draft.latitude != null) ...[
                  SelectableText(
                    '${_draft.latitude!.toStringAsFixed(6)}, ${_draft.longitude!.toStringAsFixed(6)}',
                  ),
                  Text('Captured ${localTime(_draft.capturedAt)}'),
                  if (_editing)
                    const Text(
                      'Replace captures your current position, not the original defect location.',
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _locating ? null : _capture,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Replace with current location'),
                      ),
                      TextButton(
                        onPressed: _clearLocation,
                        child: const Text('Remove location'),
                      ),
                    ],
                  ),
                ],
                if (_locationFeedback != null) Text(_locationFeedback!),
                if (_locationError != null) ...[
                  Notice(_locationError!.message),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _capture,
                        child: const Text('Retry location'),
                      ),
                      TextButton(
                        onPressed: _clearLocation,
                        child: const Text('Continue without location'),
                      ),
                      if (_draft.latitude != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _locationError = null),
                          child: const Text('Keep existing location'),
                        ),
                      if (!kIsWeb && _locationError!.appSettings)
                        TextButton(
                          onPressed: () => _settings(true),
                          child: const Text('App settings'),
                        ),
                      if (!kIsWeb && _locationError!.locationSettings)
                        TextButton(
                          onPressed: () => _settings(false),
                          child: const Text('Location settings'),
                        ),
                    ],
                  ),
                  if (kIsWeb)
                    const Text(
                      'Use the browser site settings to manage location permission.',
                    ),
                ],
                const Divider(height: 32),
                const Text(
                  'WORKFLOW',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Badge(_draft.status),
                ),
                if (_original == null)
                  const Text('New reports start as Open.')
                else if (_draft.status != _original!.status) ...[
                  const Text(
                    'Status change is pending. Tap Save changes to apply it.',
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _draft.status = _original!.status;
                      _notes.text = _original!.resolutionNotes ?? '';
                    }),
                    child: const Text('Undo status change'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: _transition,
                    child: Text(switch (_original!.status) {
                      'open' => 'Start work → In progress',
                      'in_progress' => 'Resolve report',
                      _ => 'Reopen report',
                    }),
                  ),
                if (_draft.status == 'resolved')
                  TextFormField(
                    controller: _notes,
                    validator: Rules.descriptionError,
                    minLines: 3,
                    maxLines: 8,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Resolution notes',
                      hintText: 'Explain how the defect was resolved.',
                    ),
                  ),
              ],
            ),
          ),
          if (_writer.error != null) Notice(_writer.error!),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed:
                _writer.busy ||
                    _locating ||
                    (_wantLocation &&
                        (_draft.latitude == null || _locationError != null))
                ? null
                : _save,
            icon: _writer.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _writer.busy
                  ? 'Saving…'
                  : _editing
                  ? 'Save changes'
                  : 'Save report',
            ),
          ),
          if (_editing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _writer.busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete report'),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
