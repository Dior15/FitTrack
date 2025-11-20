// lib/log.dart
import 'package:flutter/material.dart';
import 'db_model.dart';

/// LogList shows all user-entered meals and workouts
class LogList extends StatefulWidget {
  /// Optional user filter; pass null to show all users' records (useful for testing).
  final int? uid;
  const LogList({super.key, this.uid});

  @override
  State<LogList> createState() => LogListState();
}

class LogListState extends State<LogList> {
  late Future<List<_UnifiedEntry>> _future;
  final DBModel _db = DBModel.db;

  @override
  void initState() {
    super.initState();
    _future = _loadFeed();
  }

  // Allow other widgets (e.g., after save) to force a requery.
  Future<void> reload() => _refresh();

  // Pull-to-refresh support
  Future<void> _refresh() async {
    final next = _loadFeed();
    setState(() => _future = next);
    await next;
  }

  // Fetch records + reference data, then join and sort by timestamp descending.
  Future<List<_UnifiedEntry>> _loadFeed() async {
    await DBModel.db.initDatabase();
    // Fetch records (user-entered rows only).
    final foodRecs = widget.uid == null
        ? await _db.getAllFoodRecords()
        : await _db.getFoodRecordsByUid(widget.uid!); // frid, uid, fid, date, servings
    final exRecs = widget.uid == null
        ? await _db.getAllExerciseRecords()
        : await _db.getExerciseRecordsByUid(widget.uid!); // erid, uid, eid, date, time

    // Fetch reference tables to resolve names/macros and lift details.
    final foods = await _db.getAllFoodData(); // fid, name, calories, protein, fat, carbohydrates
    final exercises = await _db.getAllExerciseData(); // eid, name, muscle, sets, reps, weight

    // Build quick lookup maps for joins.
    final foodById = {for (final f in foods) (f['fid'] as int): f};
    final exById = {for (final e in exercises) (e['eid'] as int): e};

    // Merge into a unified list with a shared timestamp.
    final out = <_UnifiedEntry>[];

    for (final r in foodRecs) {
      final date = _parseDate(r['date'] as String); // meals have date only
      out.add(_UnifiedEntry.meal(
        at: date,
        record: r,
        data: foodById[r['fid'] as int],
      ));
    }

    for (final r in exRecs) {
      final date = _parseDate(r['date'] as String);
      final timeStr = (r['time'] as String?) ?? '00:00';
      final at = _combine(date, timeStr); // workouts have date + time
      out.add(_UnifiedEntry.workout(
        at: at,
        record: r,
        data: exById[r['eid'] as int],
      ));
    }

    // Most-recent first.
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_UnifiedEntry>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator()); // loading state
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}')); // simple error surface
        }
        final items = snap.data ?? const <_UnifiedEntry>[];
        if (items.isEmpty) return const Center(child: Text('No entries yet'));

        // RefreshIndicator enables pull-to-refresh to reload from DB
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(), // pull even at top/short lists
            itemCount: items.length,
            itemBuilder: (context, i) => _LogTile(entry: items[i]),
          ),
        );
      },
    );
  }
}

/// Entry types for the unified feed.
enum _EntryType { meal, workout }

/// Plain model for a feed row, with a timestamp for sorting and rendering.
class _UnifiedEntry {
  final DateTime at;
  final _EntryType type;
  final Map<String, Object?> record; // foodRecords/exerciseRecords row
  final Map<String, Object?>? data;   // joined foodData/exerciseData row

  _UnifiedEntry._(this.at, this.type, this.record, this.data);
  factory _UnifiedEntry.meal({
    required DateTime at,
    required Map<String, Object?> record,
    required Map<String, Object?>? data,
  }) => _UnifiedEntry._(at, _EntryType.meal, record, data);
  factory _UnifiedEntry.workout({
    required DateTime at,
    required Map<String, Object?> record,
    required Map<String, Object?>? data,
  }) => _UnifiedEntry._(at, _EntryType.workout, record, data);
}

/// Renders one row with icon, name, quick stats, and timestamp. [ListTile + ListView]
class _LogTile extends StatelessWidget {
  final _UnifiedEntry entry;
  const _LogTile({required this.entry});

  // Helper method to create a food stat for the food ExpansionTile
  Widget _expandedLog (String val) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(children: [
        Text(val),
      ],),

    );

  }

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatShortDate(entry.at);
    final time = TimeOfDay.fromDateTime(entry.at).format(context);

    if (entry.type == _EntryType.meal) {
      final d = entry.data ?? const {};
      final name = (d['name'] as String?) ?? 'Meal';
      final servings = entry.record['servings'] ?? 1;
      final cal = d['calories'];
      final p = d['protein'];
      final c = d['carbohydrates'];
      final f = d['fat'];

      final stats = [
        if (cal != null) 'Cal: $cal',
        if (p != null) 'Protein: $p g',
        if (c != null) 'Carbs: $c g',
        if (f != null) 'Fat: $f g',
        'Serv: $servings',
      ].join(' • ');

      // Expandable logs
      return ExpansionTile(

        // Basic info
        leading: const CircleAvatar(child: Icon(Icons.restaurant_menu_rounded)),
        title: Text(name),
        subtitle: Text('$stats • $date'),

        //Expanded content
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // children: leftColumn.map((e) => _buildItem(e.key, e.value)).toList(),
                    children: [
                      _expandedLog("Calories: $cal cals"),
                      _expandedLog("Protein: $p grams"),
                      _expandedLog("Carbs: $c grams"),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // children: rightColumn.map((e) => _buildItem(e.key, e.value)).toList(),
                    children: [
                      _expandedLog("Fat: $f grams"),
                      _expandedLog("Servings: $servings"),
                      _expandedLog("Date: $date"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

      );

    } else {
      final d = entry.data ?? const {};
      final name = (d['name'] as String?) ?? 'Workout';
      final sets = d['sets'];
      final reps = d['reps'];
      final weight = d['weight'];
      final muscle = d['muscle'];

      final stats = [
        if (muscle != null) '$muscle',
        if (sets != null && reps != null) '${sets}x$reps',
        if (weight != null) '@ $weight kg',
      ].join(' • ');

      return ExpansionTile(

        // Basic info
        leading: const CircleAvatar(child: Icon(Icons.fitness_center_rounded)),
        title: Text(name),
        subtitle: Text('$stats • $date'),

        //Expanded content
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _expandedLog("Muscle: $muscle"),
                      _expandedLog("Sets: $sets"),
                      _expandedLog("Date: $date")
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _expandedLog("Weight: $weight kg"),
                      _expandedLog("Reps: $reps"),
                      _expandedLog("Time: $time"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

      );

    }
  }
}

/// Utility: parse 'YYYY/MM/DD' into DateTime (DB stores date as string).
DateTime _parseDate(String raw) {
  // Normalize common DB formats to an ISO-like string for DateTime.parse.
  final isoish = raw.replaceAll('/', '-');
  final dt = DateTime.tryParse(isoish);
  return dt ?? DateTime.now();
}

/// Utility: combine a date with an 'H:mm' time string (e.g., '14:05').
DateTime _combine(DateTime date, String time) {
  final parts = time.split(':');
  final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, h, m);
}