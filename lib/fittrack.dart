// lib/fittrack.dart
import 'package:flutter/material.dart' hide Notification;
import 'page.dart';
import 'taskbar.dart';
import 'card.dart';
import 'db_model.dart';
import 'entryforms.dart';
import 'notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  runApp(const FitTrackApp());
  DBModel db = DBModel.db;
  // await db.clearDB();
  await db.initDatabase();
  // await db.insertMockData();

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
  DBModel db = DBModel.db;

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
                  content: Placeholder(fallbackHeight: 60)
              ),
              FitCard(
                title: 'Food',
                icon: Icons.restaurant_menu_rounded,
                content: ElevatedButton(
                  onPressed: () async {
                    final meal = await showMealEntryDialog(context);
                    // if (meal != null) InMemoryEntryStore.instance.addMeal(meal);
                    print(await db.getAllFoodData());
                  },
                  child: const Text('Add Meal'),
                ),
                sideBySide: FitCard(
                  title: 'Exercise',
                  icon: Icons.fitness_center_rounded,
                  content: ElevatedButton(
                    onPressed: () async {
                      final workout = await showWorkoutEntryDialog(context);
                      // if (workout != null) InMemoryEntryStore.instance.addWorkout(workout);
                    },
                    child: const Text('Add Workout'),
                  ),
                ),
              ),
              FitCard(
                title: 'Steps',
                icon: Icons.directions_walk_rounded,
                content: Placeholder(fallbackHeight: 60),
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
    const FitTrackPage(
      title: 'Log',
      icon: Icons.book,
      content: Center(child: Text('More / Profile')),
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