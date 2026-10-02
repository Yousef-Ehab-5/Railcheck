import 'package:floor/floor.dart';
import 'report.dart';

@dao
abstract class ReportDao {
  @Query('SELECT * FROM reports ORDER BY updatedAt DESC, id DESC')
  Stream<List<Report>> watchAll();
  @Query('SELECT * FROM reports WHERE id = :id')
  Future<Report?> findById(int id);
  @insert
  Future<int> insertReport(Report report);
  @update
  Future<int> updateReport(Report report);
  @delete
  Future<int> deleteReport(Report report);
  @Query('DELETE FROM reports')
  Future<void> deleteAll();
}
