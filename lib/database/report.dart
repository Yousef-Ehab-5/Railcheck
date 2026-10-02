import 'package:floor/floor.dart';

@Entity(tableName: 'reports')
class Report {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String train;
  final int carriage;
  final String component;
  final String description;
  final String priority;
  final String status;
  final int createdAt;
  final int updatedAt;
  final double? latitude;
  final double? longitude;
  final int? locationCapturedAt;
  final String? resolutionNotes;
  final int? resolvedAt;
  const Report({
    this.id,
    required this.train,
    required this.carriage,
    required this.component,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.locationCapturedAt,
    this.resolutionNotes,
    this.resolvedAt,
  });
}
