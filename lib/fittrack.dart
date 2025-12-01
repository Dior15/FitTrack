// lib/fittrack.dart
import 'package:fittrack/train_search.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'page.dart';
import 'taskbar.dart';
import 'card.dart';
import 'db_model.dart';
import 'entryforms.dart';
import 'notification.dart';
import 'log.dart';
import 'graphing.dart';
import 'food_search.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'settings_menu.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DBModel db = DBModel.db;
  // await db.clearDB();
  await db.initDatabase();
  // await db.insertMockData();

  // Generating default user with default limit values
  if (await db.getUserDataById(1) == null) {
    db.insertUser({'dailyCalorieLimit':2000, 'dailyProteinLimit':60, 'dailyFatLimit':72, 'dailyCarbsLimit':275});
  }

  runApp(const FitTrackApp());


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

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {

  //Dynamic theme stuff
  String _themeMode = "light";

  void _setTheme(String mode) {setState(() {_themeMode = mode;});}
  ThemeData _getTheme() {
    switch (_themeMode) {
      case "dark":
        return dark;
      case "matrix":
        return matrix;
      case "light":
      default:
        return light;
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      // theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      theme: _getTheme(),
      home: FitTrackShell(
        // Theme allocation
        onThemeChanged: _setTheme,
        currentThemeMode: _themeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FitTrackShell extends StatefulWidget {

  final Function(String) onThemeChanged;
  final String currentThemeMode;

  const FitTrackShell({
    super.key,
    // Theme changing
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<FitTrackShell> createState() => _FitTrackShellState();
}

class _FitTrackShellState extends State<FitTrackShell> {
  int _index = 0;
  double dailyCalories = 0;
  double dailyCalorieLimit = 2000;
  double dailyProtein = 0;
  double dailyProteinLimit = 50;
  double dailyCarbs = 0;
  double dailyCarbsLimit = 50;
  double dailyFat = 0;
  double dailyFatLimit = 50;
  final GlobalKey<LogListState> logKey = GlobalKey<LogListState>();

  @override
  void initState() {
    super.initState();
    updateDailyCalories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateDailyCalories();
  }

  Future<void> updateDailyCalories() async {
    DBModel db = DBModel.db;
    DateTime date = DateTime.now();
    List updatedDailyInfo = await db.getDayFoodRecordByUid(-1, date);
    Map<String,dynamic>? userDailyLimits = await db.getUserDataById(1); // This is just hardcoded for one user atm
    setState(() {
      dailyCalories = updatedDailyInfo[0];
      dailyProtein = updatedDailyInfo[1];
      dailyFat = updatedDailyInfo[2];
      dailyCarbs = updatedDailyInfo[3];
      if (userDailyLimits != null) {
        dailyCalorieLimit = userDailyLimits['dailyCalorieLimit'];
        dailyProteinLimit = userDailyLimits['dailyProteinLimit'];
        dailyFatLimit = userDailyLimits['dailyFatLimit'];
        dailyCarbsLimit = userDailyLimits['dailyCarbsLimit'];
      }
    });
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
                          DayGraph(dimensions: Size(200,200), dailyCalories:dailyCalories, dailyCalorieLimit:dailyCalorieLimit, unit:'cals'),
                          const SizedBox(height:10),
                          const Text("Daily", style:TextStyle(fontSize:24))
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal saved')));
                      logKey.currentState?.reload();
                    }
                    updateDailyCalories();
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
                title:'Macros',
                icon: Icons.insights_rounded,
                content: Column(

                children:[
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Column(
                      children:[
                        DayGraph(dimensions: Size(125,125), dailyCalories:dailyProtein, dailyCalorieLimit:dailyProteinLimit, unit:'g'),
                        const SizedBox(height:10),
                        const Text("Protein", style:TextStyle(fontSize:16))
                      ]
                    ),
                    SizedBox(width:50),
                    Column(
                      children:[
                        DayGraph(dimensions: Size(125,125), dailyCalories:dailyCarbs, dailyCalorieLimit:dailyCarbsLimit, unit:'g'),
                        const SizedBox(height:10),
                        const Text("Carbs", style:TextStyle(fontSize:16))
                      ]
                    ),
                  ]),
                  SizedBox(height:20),
                  Column(
                    children:[
                      DayGraph(dimensions: Size(125,125), dailyCalories:dailyFat, dailyCalorieLimit:dailyFatLimit, unit:'g'),
                      const SizedBox(height:10),
                      const Text("Carbs", style:TextStyle(fontSize:16))
                    ]
                  ),
                ])
              ),
            ],
          ),
        ),
    ),
    FitTrackPage(
      title: 'Food',
      icon: Icons.restaurant_menu_rounded,
      content:  FoodSearchPage(
        uid: 1,
        onEntryAdded: () {
          updateDailyCalories();
          logKey.currentState?.reload();
        },
      ),
    ),
    FitTrackPage(
      title: 'Train',
      icon: Icons.fitness_center_rounded,
      content: TrainingSearchPage(
          uid: 1,
        onEntryAdded: () {
            logKey.currentState?.reload();
        }
      ),
    ),
    FitTrackPage(
      title: 'Log',
      icon: Icons.book,
      content: LogList(key: logKey),
    ),
    FitTrackPage(
      title: 'Settings',
      icon: Icons.settings,
      content: SettingsMenu(
        calorieValue:dailyCalorieLimit.toString(),
        proteinValue:dailyProteinLimit.toString(),
        fatValue:dailyFatLimit.toString(),
        carbsValue:dailyCarbsLimit.toString(),
        // Theme changing
        onThemeChanged: widget.onThemeChanged,
        currentThemeMode: widget.currentThemeMode
      )
    )
  ];

  @override
  Widget build(BuildContext context) {
    List<FitTrackPage> pages = _buildPages(context);

    return Scaffold(
      appBar: AppBar(title: Text(pages[_index].title)),
      body: IndexedStack(
        index: _index,
        children: _buildPages(context).map((p) => _PageContainer(child: p.content)).toList(),
      ),
      bottomNavigationBar: AppTaskbar(
        pages: _buildPages(context),
        currentIndex: _index,
        onTap: (i) => setState(() {
          _index = i;
          updateDailyCalories();
        }),
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