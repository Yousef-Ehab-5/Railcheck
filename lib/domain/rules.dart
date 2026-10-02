import '../database/report.dart';
import 'values.dart';

class RuleViolation implements Exception {
  final String message;
  const RuleViolation(this.message);
  @override
  String toString() => message;
}

class Draft {
  String train;
  int carriage;
  String component;
  String description;
  String priority;
  String status;
  String notes;
  double? latitude;
  double? longitude;
  int? capturedAt;
  Draft({
    this.train = '',
    this.carriage = 1,
    this.component = 'Doors',
    this.description = '',
    this.priority = 'medium',
    this.status = 'open',
    this.notes = '',
    this.latitude,
    this.longitude,
    this.capturedAt,
  });
  factory Draft.fromReport(Report r) => Draft(
    train: r.train,
    carriage: r.carriage,
    component: r.component,
    description: r.description,
    priority: r.priority,
    status: r.status,
    notes: r.resolutionNotes ?? '',
    latitude: r.latitude,
    longitude: r.longitude,
    capturedAt: r.locationCapturedAt,
  );
  Draft copy() => Draft(
    train: train,
    carriage: carriage,
    component: component,
    description: description,
    priority: priority,
    status: status,
    notes: notes,
    latitude: latitude,
    longitude: longitude,
    capturedAt: capturedAt,
  );
  void clearLocation() {
    latitude = null;
    longitude = null;
    capturedAt = null;
  }

  String get fingerprint => [
    train,
    carriage,
    component,
    description,
    priority,
    status,
    notes,
    latitude,
    longitude,
    capturedAt,
  ].join('');
}

class Rules {
  static String? trainError(String? s) {
    final n = (s ?? '').trim().length;
    return n < 1 || n > 30
        ? 'Enter a train identifier of 1–30 characters.'
        : null;
  }

  static String? descriptionError(String? s) {
    final n = (s ?? '').trim().length;
    return n < 10 || n > 1000
        ? 'Use 10–1,000 characters after trimming.'
        : null;
  }

  static void validateLocation(double? lat, double? lon, int? time) {
    final count = [lat, lon, time].where((x) => x != null).length;
    if (count != 0 && count != 3) {
      throw const RuleViolation(
        'Location coordinates and capture time must be supplied together.',
      );
    }
    if (lat != null &&
        (!lat.isFinite ||
            lat < -90 ||
            lat > 90 ||
            !lon!.isFinite ||
            lon < -180 ||
            lon > 180 ||
            time! < 0)) {
      throw const RuleViolation(
        'Invalid location coordinates or capture time.',
      );
    }
  }

  static bool known(Report r) =>
      statuses.contains(r.status) &&
      priorities.contains(r.priority) &&
      components.contains(r.component);
  static Report prepare(Draft d, Report? previous, int now) {
    final textError = trainError(d.train) ?? descriptionError(d.description);
    if (textError != null) throw RuleViolation(textError);
    if (d.carriage < 1 ||
        d.carriage > 6 ||
        !components.contains(d.component) ||
        !priorities.contains(d.priority) ||
        !statuses.contains(d.status)) {
      throw const RuleViolation(
        'Choose a valid carriage, component, priority and status.',
      );
    }
    if (previous != null && !known(previous)) {
      throw const RuleViolation(
        'This report contains an unsupported stored value. Editing is disabled to preserve it.',
      );
    }
    final old = previous?.status;
    if (old == null && d.status != 'open') {
      throw const RuleViolation('New reports must start as Open.');
    }
    if (old != null &&
        old != d.status &&
        !(old == 'open' && d.status == 'in_progress' ||
            old == 'in_progress' && d.status == 'resolved' ||
            old == 'resolved' && d.status == 'open')) {
      throw const RuleViolation(
        'Follow Open → In progress → Resolved → Reopen.',
      );
    }
    validateLocation(d.latitude, d.longitude, d.capturedAt);
    if (d.status == 'resolved' && descriptionError(d.notes) != null) {
      throw const RuleViolation(
        'Resolution notes require 10–1,000 trimmed characters.',
      );
    }
    return Report(
      id: previous?.id,
      train: d.train.trim(),
      carriage: d.carriage,
      component: d.component,
      description: d.description.trim(),
      priority: d.priority,
      status: d.status,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      latitude: d.latitude,
      longitude: d.longitude,
      locationCapturedAt: d.capturedAt,
      resolutionNotes: d.status == 'resolved' ? d.notes.trim() : null,
      resolvedAt: d.status == 'resolved' ? previous?.resolvedAt ?? now : null,
    );
  }
}
