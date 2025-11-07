// lib/fittrack.dart
import 'package:flutter/material.dart';
import 'page.dart';
import 'taskbar.dart';
import 'card.dart';
import 'db_model.dart';

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

  @override
  void initState() {
    super.initState();
  }

  // Add taskbar pages here
  final List<FitTrackPage> _pages = const [
    FitTrackPage(
      title: 'Home',
      icon: Icons.home_rounded,
      content: SingleChildScrollView(
        child: Column(
          children: [
            FitCard(
              title: 'Nutrition',
              icon: Icons.insights_rounded,
              content: Placeholder(fallbackHeight: 120),
            ),
            FitCard(
              title: 'Food',
              icon: Icons.restaurant_menu_rounded,
              content: Placeholder(fallbackHeight: 80),
              sideBySide: FitCard(
                title: 'Exercise',
                icon: Icons.fitness_center_rounded,
                content: Placeholder(fallbackHeight: 80),
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
    FitTrackPage(
      title: 'Food',
      icon: Icons.restaurant_menu_rounded,
      content: Center(child: Text('Food Log')),
    ),
    FitTrackPage(
      title: 'Train',
      icon: Icons.fitness_center_rounded,
      content: Center(child: Text('Workouts')),
    ),
    FitTrackPage(
      title: 'Log',
      icon: Icons.book,
      content: Center(child: Text('More / Profile')),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _pages[_index];

    return Scaffold(
      appBar: AppBar(title: Text(current.title)),
      body: IndexedStack(
        index: _index,
        children: _pages.map((p) => _PageContainer(child: p.content)).toList(),
      ),
      bottomNavigationBar: AppTaskbar(
        pages: _pages,
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