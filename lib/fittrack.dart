// lib/fittrack.dart
import 'package:flutter/material.dart';
import 'page.dart';
import 'taskbar.dart';
import 'card.dart';
import 'db_model.dart';
import 'entryforms.dart';

void main() {
  runApp(const FitTrackApp());
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
    DBModel db = DBModel.db;
    db.initDatabase();
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