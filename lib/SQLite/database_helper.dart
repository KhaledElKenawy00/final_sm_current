import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../JSON/users.dart';

class DatabaseHelper {
  final databaseName = "auth.db";

  // SQL for creating the users table
  final String userTable = '''
   CREATE TABLE users (
     usrId INTEGER PRIMARY KEY AUTOINCREMENT,
     fullName TEXT,
     email TEXT,
     usrName TEXT UNIQUE,
     usrPassword TEXT
   )
  ''';

  // Initialize DB with FFI
  Future<Database> initDB() async {
    // Ensure the FFI implementation is initialized only once
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final databasePath = await databaseFactory.getDatabasesPath();
    final path = join(databasePath, databaseName);

    return databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(userTable);
          },
        ));
  }

  // Authentication
  Future<bool> authenticate(Users usr) async {
    final db = await initDB();
    final result = await db.rawQuery(
      "SELECT * FROM users WHERE usrName = ? AND usrPassword = ?",
      [usr.usrName, usr.password],
    );
    return result.isNotEmpty;
  }

  // Sign up
  Future<int> createUser(Users usr) async {
    final db = await initDB();
    return await db.insert("users", usr.toMap());
  }

  // Get current user details
  Future<Users?> getUser(String usrName) async {
    final db = await initDB();
    final res =
        await db.query("users", where: "usrName = ?", whereArgs: [usrName]);
    return res.isNotEmpty ? Users.fromMap(res.first) : null;
  }
}
