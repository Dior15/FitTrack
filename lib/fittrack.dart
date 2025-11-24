// lib/fittrack.dart
import 'package:flutter/material.dart' hide Notification;
import 'page.dart';
import 'taskbar.dart';
import 'card.dart';
import 'db_model.dart';
import 'entryforms.dart';
import 'notification.dart';
import 'log.dart';
import 'graphing.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prepare engine before async init [web:244][web:223]
  DBModel db = DBModel.db;
  // await db.clearDB();
  await db.initDatabase();
  // await db.insertMockData();
  runApp(const FitTrackApp());
  // ===== DBMODEL METHOD TESTS =====
  // print(await db.getAllFoodData());
  // print(await db.getAllFoodRecords());
  // print(await db.getAllExerciseData());
  // print(await db.getAllExerciseRecords());

  // print(await db.getFoodDataById(1));
  // print(await db.getFoodRecordById(1));
  // print(await db.getExerciseDataById(1));
  // print(await db.getExerciseRecordById(1));

  // print(await db.getFoodRecordsByUid(1));
  // print(await db.getFoodRecordsByUid(2));
  // print(await db.getExerciseRecordsByUid(1));
  // print(await db.getExerciseRecordsByUid(2));

  // await db.deleteFoodDataById(1);
  // await db.deleteFoodRecordById(1);
  // await db.deleteExerciseDataById(1);
  // await db.deleteExerciseRecordById(1);

  // await db.updateFoodData({'fid':1, 'name':'Burrito', 'calories':800, 'protein':50, 'fat':5, 'carbohydrates':10});
  // await db.updateExerciseData({'eid':1, 'name':'Curls', 'muscle':'Bicep', 'sets':3, 'reps':12, 'weight':50});

  // Notification Stuff
  // NOTE: as commented in notification class, this block is arbitrary, won't show properly in this version
  tz.initializeTimeZones();
  final notif = Notification();
  await notif.init();

  final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
  notif.sendNotificationMealtime("Test", "mealtime", "payload", testTime);

  List<tz.TZDateTime> mealTimes = [];
  // mealTimes.add(tz.TZDateTime(toronto, year))
  mealTimes.add(tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, 10, 0, 0));
  mealTimes.add(tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, 14, 0, 0));
  mealTimes.add(tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 0, 0));

  for (tz.TZDateTime mealTime in mealTimes) {
    notif.sendNotificationMealtime("Mealtime!", "Don't forget to log your meal stats in FitTrack!", "payload", mealTime);
  }

  // NOTE: as commented in notification class, placeholder function
  notif.sendNotificationDelayed();

}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const FitTrackShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FitTrackShell extends StatefulWidget {
  const FitTrackShell({super.key});

  @override
  State<FitTrackShell> createState() => _FitTrackShellState();
}

class _FitTrackShellState extends State<FitTrackShell> {
  int _index = 0;
  final logKey = GlobalKey<LogListState>();

  @override
  void initState() {
    super.initState();
  }

  // Add taskbar pages here
  List<FitTrackPage> _buildPages(BuildContext context) => [
    FitTrackPage(
        title: 'Home',
        icon: Icons.home_rounded,
        content: SingleChildScrollView(
          child: Column(
            children: [
              FitCard(
                  title: 'Nutrition',
                  icon: Icons.insights_rounded,
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min, //shrink to fit
                        children: [
                          DayGraph(dimensions: Size(60,60)),
                          const SizedBox(height:4),
                          const Text("Weekly")
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min, //shrink to fit
                        children: [
                          DayGraph(dimensions: Size(60,60)),
                          const SizedBox(height:4),
                          const Text("Daily")
                        ],
                      ),
                    ],
                  )
              ),
              FitCard(
                title: 'Food',
                icon: Icons.restaurant_menu_rounded,
                content: ElevatedButton(
                  onPressed: () async {
                    final frid = await addMealViaDialog(context, uid: 1); // supply current user id
                    if (frid != null) {
                      // trigger any local refresh/state update if needed
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal saved')));
                      logKey.currentState?.reload();
                    }
                  },
                  child: const Text('Add Meal'),
                ),
                sideBySide: FitCard(
                  title: 'Exercise',
                  icon: Icons.fitness_center_rounded,
                  content: ElevatedButton(
                    onPressed: () async {
                      final erid = await addWorkoutViaDialog(context, uid: 1);
                      if (erid != null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout saved')));
                        logKey.currentState?.reload();
                      }
                    },
                    child: const Text('Add Workout'),
                  ),
                ),
              ),
              FitCard(
                title: 'Steps',
                icon: Icons.directions_walk_rounded,
                content: StepGraph(height: 60),
              ),
            ],
          ),
        )
    ),
    const FitTrackPage(
      title: 'Food',
      icon: Icons.restaurant_menu_rounded,
      content: Center(child: Text('Food Log')),
    ),
    const FitTrackPage(
      title: 'Train',
      icon: Icons.fitness_center_rounded,
      content: Center(child: Text('Workouts')),
    ),
    FitTrackPage(
      title: 'Log',
      icon: Icons.book,
      content: LogList(key: logKey),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);

    return Scaffold(
      appBar: AppBar(title: Text(pages[_index].title)),
      body: IndexedStack(
        index: _index,
        children: _buildPages(context).map((p) => _PageContainer(child: p.content)).toList(),
      ),
      bottomNavigationBar: AppTaskbar(
        pages: _buildPages(context),
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _PageContainer extends StatelessWidget {
  final Widget child;
  const _PageContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: child));
  }
}