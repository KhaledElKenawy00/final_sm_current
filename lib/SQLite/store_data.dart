import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  Database? _db;
  bool _isInitializing = false;

  Future<void> initDB() async {
    if (_db != null) return;
    if (_isInitializing) {
      while (_db == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    final dbPath = await getDatabasesPath();

    _db = await openDatabase(
      join(dbPath, 'stm32_data.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE readings_stm1 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            json_data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE readings_stm2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            json_data TEXT
          )
        ''');
      },
    );

    _isInitializing = false;
  }

  Future<void> insertReadingSTM1(Map<String, dynamic> jsonMap) async {
    if (_db == null) await initDB();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await _db!.insert('readings_stm1', {
      'timestamp': now,
      'json_data': json.encode(jsonMap),
    });
  }

  Future<void> insertReadingSTM2(Map<String, dynamic> jsonMap) async {
    if (_db == null) await initDB();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await _db!.insert('readings_stm2', {
      'timestamp': now,
      'json_data': json.encode(jsonMap),
    });
  }

  /// ✅ يستخدم في FullDataPage حسب الجهاز المحدد
  Future<List<Map<String, dynamic>>> getReadingsByPage({
    required int page,
    required int pageSize,
    required String device, // 'STM1' or 'STM2'
  }) async {
    if (_db == null) await initDB();

    final offset = page * pageSize;
    final tableName = device == 'STM1' ? 'readings_stm1' : 'readings_stm2';

    final result = await _db!.query(
      tableName,
      orderBy: 'id DESC',
      limit: pageSize,
      offset: offset,
    );

    return result;
  }

  Future<void> clearAllReadingsSTM1() async {
    if (_db == null) await initDB();
    await _db!.delete('readings_stm1');
  }

  Future<void> clearAllReadingsSTM2() async {
    if (_db == null) await initDB();
    await _db!.delete('readings_stm2');
  }

  /// ✅ تصدير البيانات الخاصة بجهاز معين فقط
  Future<String> exportToCSV(String device) async {
    if (_db == null) await initDB();

    final tableName = device == 'STM1' ? 'readings_stm1' : 'readings_stm2';
    final List<Map<String, dynamic>> data =
        await _db!.query(tableName, orderBy: 'id DESC');

    List<List<String>> csvData = [
      ['date_time', 'device', 'key', 'value'],
    ];

    for (var row in data) {
      final rawJson = row['json_data'] ?? '{}';
      final timestampRaw = row['timestamp'] ?? '';

      String formattedDateTime = timestampRaw;
      try {
        final dt = DateTime.parse(timestampRaw);
        formattedDateTime =
            'Date: ${dt.toLocal().toString().split(' ').first} - Time: ${dt.toLocal().toString().split(' ').last}';
      } catch (_) {}

      try {
        final Map<String, dynamic> decoded = json.decode(rawJson);
        for (var entry in decoded.entries) {
          csvData.add(
              [formattedDateTime, device, entry.key, entry.value.toString()]);
        }
      } catch (e) {
        csvData.add([formattedDateTime, device, 'invalid_json', rawJson]);
      }
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/${device}_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }
}
