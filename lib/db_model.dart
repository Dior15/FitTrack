import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DBModel {
  static final DBModel db = DBModel();
  bool _dbInitialized = false;
  late Database database;

  DBModel();

  /// Initialize the database before using it
  Future<void> initDatabase() async {
    if (!_dbInitialized) {
      String dbPath = await getDatabasesPath();
      String path = p.join(dbPath, 'fitTrackData.db');
      database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE users(uid INTEGER PRIMARY KEY AUTOINCREMENT)');
          await db.execute(
            'CREATE TABLE foodData(fid INTEGER PRIMARY KEY AUTOINCREMENT, name STRING, calories INTEGER,protein INTEGER, fat INTEGER, carbohydrates INTEGER)');
          await db.execute(
            'CREATE TABLE foodRecords(frid INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, fid INTEGER, date STRING, servings INTEGER, FOREIGN KEY (uid) REFERENCES users(uid), FOREIGN KEY (fid) REFERENCES foodData(fid))');
          await db.execute(
            'CREATE TABLE exerciseData(eid INTEGER PRIMARY KEY AUTOINCREMENT, name STRING, muscle STRING, sets INTEGER, reps INTEGER, weight INTEGER)');
          await db.execute(
            'CREATE TABLE exerciseRecords(erid INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, eid INTEGER, date STRING, time STRING, FOREIGN KEY (uid) REFERENCES users(uid), FOREIGN KEY (eid) REFERENCES exerciseData(eid))');
        }
      );
      _dbInitialized = true;
    }
  }

  /// food should be a map containing all the attributes {String name, int calories, int protein, int fat, int carbohydrates}
  Future<void> insertFoodData(Map<String, dynamic> food) async {
    await database.insert(
      'foodData',
      {
        'name': food['name'],
        'calories': food['calories'],
        'protein': food['protein'],
        'fat': food['fat'],
        'carbohydrates': food['carbohydrates']
      }
    );
  }

  /// Receive a list of maps corresponding to every row in the foodData table
  Future<List<Map<String, dynamic>>> getAllFoodData() async {
    return await database.query('foodData');
  }

  /// Receive a map for the food item specified by the given fid
  Future<Map<String, dynamic>?> getFoodDataById(int fid) async {
    final r = await database.query(
      'foodData',
      where:'fid = ?',
      whereArgs:[fid]
    );
    if (r.isNotEmpty) {
      return(r.first);
    } else {
      return(null);
    }
  }

  /// Delete foodData specified by give fid
  Future<void> deleteFoodDataById(int fid) async {
    await database.delete(
      'foodData',
      where:'fid = ?',
      whereArgs:[fid]
    );
  }

  /// foodRecord should be a map containing all the attributes {int uid, int fid, String date, int servings}
  Future<void> insertFoodRecord(Map<String, dynamic> foodRecord) async {
    await database.insert(
      'foodRecords',
      {
        'uid':foodRecord['uid'],
        'fid':foodRecord['fid'],
        'date':foodRecord['date'],
        'servings':foodRecord['servings']
      }
    );
  }

  /// Receive a list of maps corresponding to every row in the foodRecords table
  Future<List<Map<String, dynamic>>> getAllFoodRecords() async {
    return await database.query('foodRecords');
  }

  /// Receive a map for the foodRecord item specified by the given frid
  Future<Map<String, dynamic>?> getFoodRecordById(int frid) async {
    final r = await database.query(
      'foodRecords',
      where:'frid = ?',
      whereArgs:[frid]
    );
    if (r.isNotEmpty) {
      return(r.first);
    } else {
      return(null);
    }
  }

  /// Receive a list of foodRecord maps belonging to the user whose uid is input
  Future<List<Map<String, dynamic>>> getFoodRecordsByUid(int uid) async {
    return await database.query(
      'foodRecords',
      where:'uid = ?',
      whereArgs:[uid]
    );
  }

  /// Delete foodRecord specified by give frid
  Future<void> deleteFoodRecordById(int frid) async {
    await database.delete(
        'foodRecords',
        where:'frid = ?',
        whereArgs:[frid]
    );
  }

  /// exercise should be a map containing all the attributes {String name, String muscle, int sets, int reps, int weight}
  Future<void> insertExerciseData(Map<String, dynamic> exercise) async {
    await database.insert(
      'exerciseData',
      {
        'name': exercise['name'],
        'muscle': exercise['muscle'],
        'sets': exercise['sets'],
        'reps': exercise['reps'],
        'weight': exercise['weight']
      }
    );
  }

  /// Receive a list of maps corresponding to every row in the exerciseData table
  Future<List<Map<String, dynamic>>> getAllExerciseData() async {
    return await database.query('exerciseData');
  }

  /// Receive a map for the exercise item specified by the given eid
  Future<Map<String, dynamic>?> getExerciseDataById(int eid) async {
    final r = await database.query(
        'exerciseData',
        where:'eid = ?',
        whereArgs:[eid]
    );
    if (r.isNotEmpty) {
      return(r.first);
    } else {
      return(null);
    }
  }

  /// Delete exerciseData specified by give eid
  Future<void> deleteExerciseDataById(int eid) async {
    await database.delete(
        'exerciseData',
        where:'eid = ?',
        whereArgs:[eid]
    );
  }

  /// exerciseRecord should be a map containing all the attributes {int uid, int eid, String date, String time}
  Future<void> insertExerciseRecord(Map<String, dynamic> exerciseRecord) async {
    await database.insert(
        'exerciseRecords',
        {
          'uid':exerciseRecord['uid'],
          'eid':exerciseRecord['eid'],
          'date':exerciseRecord['date'],
          'time':exerciseRecord['time']
        }
    );
  }

  /// Receive a list of maps corresponding to every row in the exerciseRecords table
  Future<List<Map<String, dynamic>>> getAllExerciseRecords() async {
    return await database.query('exerciseRecords');
  }

  /// Receive a map for the exerciseRecord item specified by the given erid
  Future<Map<String, dynamic>?> getExerciseRecordById(int erid) async {
    final r = await database.query(
        'exerciseRecords',
        where:'erid = ?',
        whereArgs:[erid]
    );
    if (r.isNotEmpty) {
      return(r.first);
    } else {
      return(null);
    }
  }

  /// Receive a list of exerciseRecord maps belonging to the user whose uid is input
  Future<List<Map<String, dynamic>>> getExerciseRecordsByUid(int uid) async {
    return await database.query(
      'exerciseRecords',
      where:'uid = ?',
      whereArgs:[uid]
    );
  }

  /// Delete exerciseRecord specified by give erid
  Future<void> deleteExerciseRecordById(int erid) async {
    await database.delete(
        'exerciseRecords',
        where:'erid = ?',
        whereArgs:[erid]
    );
  }


  // ===== FOR TESTING =====
  /// DELETES ALL DATA IN THE DATABASE
  Future<void> clearDB() async {
    await deleteDatabase(p.join(await getDatabasesPath(), 'fitTrackData.db'));
  }

  /// Create mock data in all tables for testing ~ run only once to populate, then remove
  Future<void> insertMockData() async {
    insertFoodData({'name':'Burrito', 'calories':900, 'protein':50, 'fat':5, 'carbohydrates':10});
    insertFoodData({'name':'Taco', 'calories':500, 'protein':30, 'fat':5, 'carbohydrates':5});
    insertFoodData({'name':'French Fries', 'calories':400, 'protein':0, 'fat':10, 'carbohydrates':40});

    insertFoodRecord({'uid':1, 'fid':1, 'date':'2025/11/07', 'servings':1});
    insertFoodRecord({'uid':1, 'fid':2, 'date':'2025/11/08', 'servings':1});
    insertFoodRecord({'uid':2, 'fid':3, 'date':'2025/11/09', 'servings':1});

    insertExerciseData({'name':'Curls', 'muscle':'Bicep', 'sets':3, 'reps':12, 'weight':20});
    insertExerciseData({'name':'Weighted Squats', 'muscle':'Leg', 'sets':3, 'reps':12, 'weight':30});
    insertExerciseData({'name':'Lateral Raise', 'muscle':'deltoid', 'sets':3, 'reps':12, 'weight':15});

    insertExerciseRecord({'uid':1, 'eid':1, 'date':'2025/11/07', 'time':'1:00'});
    insertExerciseRecord({'uid':2, 'eid':2, 'date':'2025/11/08', 'time':'2:00'});
    insertExerciseRecord({'uid':2, 'eid':3, 'date':'2025/11/09', 'time':'2:30'});
  }
}