import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DBModel {
  static final DBModel db = DBModel();
  bool _dbInitialized = false;
  late Database database;

  DBModel() {
    print('Created DBModel instance');
  }

  initDatabase() async {
    if (!_dbInitialized) {
      String dbPath = await getDatabasesPath();
      String path = p.join(dbPath, 'fitTrackData.db');
      database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE users(uid INTEGER PRIMARY KEY)');
          await db.execute(
            'CREATE TABLE foodData(fid INTEGER PRIMARY KEY, name STRING, calories INTEGER,protein INTEGER, fat INTEGER, carbohydrates INTEGER)');
          await db.execute(
            'CREATE TABLE foodRecords(frid INTEGER PRIMARY KEY, uid INTEGER, fid INTEGER, date STRING, servings INTEGER, FOREIGN KEY (uid) REFERENCES users(uid), FOREIGN KEY (fid) REFERENCES foodData(fid))');
          await db.execute(
            'CREATE TABLE exerciseData(eid INTEGER PRIMARY KEY, name STRING, muscle STRING, sets INTEGER, reps INTEGER, weight INTEGER)');
          await db.execute(
            'CREATE TABLE exerciseRecords(erid INTEGER PRIMARY KEY, uid INTEGER, eid INTEGER, date STRING, time STRING, FOREIGN KEY (uid) REFERENCES users(uid), FOREIGN KEY (eid) REFERENCES exerciseData(eid))');
        }
      );
      print("Database initialized");
      _dbInitialized = true;
    }
  }
}