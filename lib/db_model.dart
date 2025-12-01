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
            'CREATE TABLE users(uid INTEGER PRIMARY KEY AUTOINCREMENT, dailyCalorieLimit DOUBLE, dailyProteinLimit DOUBLE, dailyFatLimit DOUBLE, dailyCarbsLimit DOUBLE)');
          await db.execute(
            'CREATE TABLE foodData(fid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, calories INTEGER,protein INTEGER, fat INTEGER, carbohydrates INTEGER)');
          await db.execute(
            'CREATE TABLE foodRecords(frid INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, fid INTEGER, date DATE, time TEXT, servings INTEGER, FOREIGN KEY (uid) REFERENCES users(uid), FOREIGN KEY (fid) REFERENCES foodData(fid))');
          await db.execute(
            'CREATE TABLE exerciseData(eid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, muscle TEXT, sets INTEGER, reps INTEGER, weight INTEGER)');
          await db.execute(
            'CREATE TABLE exerciseRecords(erid INTEGER PRIMARY KEY AUTOINCREMENT, uid INTEGER, eid INTEGER, date DATE, time TEXT, FOREIGN KEY (uid) REFERENCES users(uid), FOREIGN KEY (eid) REFERENCES exerciseData(eid))');
        }
      );
      _dbInitialized = true;
      await initWorkoutData();
    }
  }

  /// Insert a dictionary that contains info about a NEW user, no uid
  Future<void> insertUser(Map<String, dynamic> user) async {
    await database.insert(
      'users',
      {
        'dailyCalorieLimit':user['dailyCalorieLimit'],
        'dailyProteinLimit':user['dailyProteinLimit'],
        'dailyFatLimit':user['dailyFatLimit'],
        'dailyCarbsLimit':user['dailyCarbsLimit']
      }
    );
  }

  /// Input dictionary of EXISTING user with UPDATED values
  Future<void> updateUser(Map<String,dynamic> user) async {
    await database.update(
      'users',
      {
        'uid':user['uid'],
        'dailyCalorieLimit':user['dailyCalorieLimit'],
        'dailyProteinLimit':user['dailyProteinLimit'],
        'dailyFatLimit':user['dailyFatLimit'],
        'dailyCarbsLimit':user['dailyCarbsLimit']
      },
      where:'uid = ?',
      whereArgs:[user['uid']]
    );
  }

  /// Input EXISTING uid, receive map of corresponding table row
  Future<Map<String,dynamic>?> getUserDataById(int uid) async {
    List<Map<String,dynamic>> r = await database.query(
      'users',
      where:'uid = ?',
      whereArgs:[uid]
    );
    if (r.isNotEmpty) {
      return(r.first);
    } else {
      return(null);
    }
  }

  /// food should be a map containing all the attributes {String name, int calories, int protein, int fat, int carbohydrates}
  Future<int> insertFoodData(Map<String, dynamic> food) async {
    return await database.insert(
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

  /// Update food data, just pass the updated food data dictionary to the method, make sure the fid is a part of this dictionary
  Future<void> updateFoodData(Map<String, dynamic> food) async {
    await database.update(
        'foodData',
        {
          'fid':food['fid'],
          'name': food['name'],
          'calories': food['calories'],
          'protein': food['protein'],
          'fat': food['fat'],
          'carbohydrates': food['carbohydrates']
        },
      where:'fid = ?',
      whereArgs:[food['fid']]
    );
  }

  /// foodRecord should be a map containing all the attributes {int uid, int fid, String date, int servings}
  Future<int> insertFoodRecord(Map<String, dynamic> foodRecord) async {
    // CHANGED: centralize conversion from DateTime/String to DB strings
    final dt = _ensureDateTime(foodRecord['date']);
    final dynamic rawTime = foodRecord['time'];

    // If caller supplies a separate time, respect it; otherwise use dt's time.
    late final DateTime timeSource;
    if (rawTime is DateTime) {
      timeSource = rawTime;
    } else if (rawTime is String) {
      timeSource = _ensureDateTime(rawTime);
    } else {
      timeSource = dt;
    }

    return await database.insert(
      'foodRecords',
      {
        'uid':foodRecord['uid'],
        'fid':foodRecord['fid'],
        'date': _dateToDb(dt),
        'time': _timeToDb(timeSource),
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

  /// Update food record, just pass the updated food record dictionary to the method, make sure the frid is a part of this dictionary
  Future<void> updateFoodRecord(Map<String, dynamic> foodRecord) async {
    await database.update(
        'foodRecords',
        {
          'frid':foodRecord['frid'],
          'uid':foodRecord['uid'],
          'fid':foodRecord['fid'],
          'date':foodRecord['date'],
          'servings':foodRecord['servings']
        },
        where:'frid = ?',
        whereArgs:[foodRecord['frid']]
    );
  }

  Future<List<double>> getDayFoodRecordByUid(int uid, dynamic date) async {
    List<Map<String, dynamic>> records;
    final dateStr = _dateToDb(date);
    // First get relevant records
    if (uid != -1) {
      records = await database.query(
        'foodRecords',
        columns:['uid','fid','date'],
        where:'date = ? AND uid = ?',
        whereArgs:[dateStr, uid]
      );
    } else {
      records = await database.query(
        'foodRecords',
        columns:['fid','date'],
        where:'date = ?',
        whereArgs:[dateStr]
      );
    }

    double todaysCalories = 0;
    double todaysProtein = 0;
    double todaysFat = 0;
    double todaysCarbs = 0;
    for (Map<String,dynamic> record in records) {
      final data = await getFoodDataById(record['fid']);
      todaysCalories += data?['calories'];
      todaysProtein += data?['protein'];
      todaysFat += data?['fat'];
      todaysCarbs += data?['carbohydrates'];
    }

    return([todaysCalories,todaysProtein,todaysFat,todaysCarbs]);
  }

  /// exercise should be a map containing all the attributes {String name, String muscle, int sets, int reps, int weight}
  Future<int> insertExerciseData(Map<String, dynamic> exercise) async {
    return await database.insert(
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

  /// Update exercise data, just pass the updated exercise data dictionary to the method, make sure the eid is a part of this dictionary
  Future<void> updateExerciseData(Map<String, dynamic> exercise) async {
    await database.update(
      'exerciseData',
      {
        'eid':exercise['eid'],
        'name': exercise['name'],
        'muscle': exercise['muscle'],
        'sets': exercise['sets'],
        'reps': exercise['reps'],
        'weight': exercise['weight']
      },
      where:"eid = ?",
      whereArgs:[exercise['eid']]
    );
  }

  /// exerciseRecord should be a map containing all the attributes {int uid, int eid, String date, String time}
  Future<int> insertExerciseRecord(Map<String, dynamic> exerciseRecord) async {
    // CHANGED: only require a single DateTime, derive both date+time
    final dt = _ensureDateTime(exerciseRecord['date']);

    return await database.insert(
        'exerciseRecords',
        {
          'uid':exerciseRecord['uid'],
          'eid':exerciseRecord['eid'],
          'date':_dateToDb(dt),
          'time':_timeToDb(dt),
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

  /// Update exercise record, just pass the updated exercise record dictionary to the method, make sure the erid is a part of this dictionary
  Future<void> updateExerciseRecord(Map<String, dynamic> exerciseRecord) async {
    await database.update(
      'exerciseRecords',
      {
        'erid':exerciseRecord['erid'],
        'uid':exerciseRecord['uid'],
        'eid':exerciseRecord['eid'],
        'date':exerciseRecord['date'],
        'time':exerciseRecord['time']
      },
      where:'erid = ?',
      whereArgs:[exerciseRecord['erid']]
    );
  }

  String _dateToDb(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';

  String _timeToDb(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  DateTime _ensureDateTime(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      final isoish = v.replaceAll('/', '-');
      return DateTime.tryParse(isoish) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Populates the workout table if empty
  Future<void> initWorkoutData() async {
    List exercises = await getAllExerciseData();
    if (exercises.isEmpty) {
      insertExerciseData({'name':'Push Ups', 'muscle':'Chest', 'sets':2, 'reps':20, 'weight':0});
      insertExerciseData({'name':'Box Dips', 'muscle':'Chest', 'sets':3, 'reps':10, 'weight':0});
      insertExerciseData({'name':'Dumbbell Front Raise', 'muscle':'Shoulders', 'sets':4, 'reps':10, 'weight':10});
      insertExerciseData({'name':'Machine Overhand Overhead Press', 'muscle':'Arms', 'sets':5, 'reps':8, 'weight':20});
      insertExerciseData({'name':'Kettlebell Shrug', 'muscle':'Shoulders', 'sets':3, 'reps':10, 'weight':10});
      insertExerciseData({'name':'Band Curl', 'muscle':'Arms', 'sets':4, 'reps':15, 'weight':2});
      insertExerciseData({'name':'Dumbbell Wrist Curl', 'muscle':'Arms', 'sets':8, 'reps':5, 'weight':10});
      insertExerciseData({'name':'Elbow Side Plank', 'muscle':'Core', 'sets':6, 'reps':5, 'weight':0});
      insertExerciseData({'name':'Crunches', 'muscle':'Core', 'sets':3, 'reps':20, 'weight':0});
      insertExerciseData({'name':'Forward Lunge', 'muscle':'Legs', 'sets':4, 'reps':10, 'weight':0});
    }
  }


  // ===== FOR TESTING =====
  /// DELETES ALL DATA IN THE DATABASE
  Future<void> clearDB() async {
    await deleteDatabase(p.join(await getDatabasesPath(), 'fitTrackData.db'));
  }

  /// Create mock data in all tables for testing ~ run only once to populate, then remove
  Future<void> insertMockData() async {
    insertFoodData({'name':'Burrito', 'calories':900, 'protein':50, 'fat':5, 'carbohydrates':10});
    insertFoodData({'name':'Taco', 'calories':550, 'protein':30, 'fat':5, 'carbohydrates':5});
    insertFoodData({'name':'French Fries', 'calories':450, 'protein':0, 'fat':10, 'carbohydrates':40});

    insertFoodRecord({'uid':1, 'fid':1, 'date':DateTime(2025, 11, 9, 12, 0), 'servings':1});
    final now = DateTime.now();
    insertFoodRecord({'uid':1, 'fid':2, 'date':DateTime(now.year, now.month, now.day, 8, 30), 'servings':1});
    insertFoodRecord({'uid':1, 'fid':3, 'date':DateTime(now.year, now.month, now.day, 19, 0), 'servings':1});

    insertExerciseData({'name':'Curls', 'muscle':'Bicep', 'sets':3, 'reps':12, 'weight':20});
    insertExerciseData({'name':'Weighted Squats', 'muscle':'Leg', 'sets':3, 'reps':12, 'weight':30});
    insertExerciseData({'name':'Lateral Raise', 'muscle':'Deltoid', 'sets':3, 'reps':12, 'weight':15});

    insertExerciseRecord({'uid':1, 'eid':1, 'date':DateTime(2025, 11, 7, 13, 0)});
    insertExerciseRecord({'uid':1, 'eid':2, 'date':DateTime(2025, 11, 8, 14, 0)});
    insertExerciseRecord({'uid':1, 'eid':3, 'date':DateTime(2025, 11, 9, 14, 30)});
  }
}