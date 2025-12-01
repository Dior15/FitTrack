import 'package:flutter/material.dart';
import 'db_model.dart';
import 'entryforms.dart';

/// Search page that pulls workouts from the database, not the API.
/// Otherwise largely follows the conventions used in FoodSearchPage.
class TrainingSearchPage extends StatefulWidget {
  final int uid; // Current user for DB access/modify
  final VoidCallback? onEntryAdded;

  const TrainingSearchPage({super.key, required this.uid, this.onEntryAdded});

  @override
  State<TrainingSearchPage> createState() => _TrainingSearchPageState();
}

class _TrainingSearchPageState extends State<TrainingSearchPage> {
  final _queryController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  DBModel db = DBModel.db;

  // Load exercises that the user has actually logged,
  // by joining exerciseRecords with exerciseData on eid.
  Future<List<Map<String, dynamic>>> _loadLoggedExercises() async {
    final records = await db.getExerciseRecordsByUid(widget.uid);
    final data = await db.getAllExerciseData();

    final Map<int, Map<String, dynamic>> byId = {};
    for (final e in data) {
      final id = e['eid'] as int?;
      if (id != null) byId[id] = e;
    }

    final List<Map<String, dynamic>> out = [];
    for (final r in records) {
      final eid = r['eid'] as int?;
      final d = eid == null ? null : byId[eid];
      if (d != null) out.add(d);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search_outlined),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: _results.isEmpty && !_loading
              // When there are no search results, show logged workouts instead.
                  ? FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadLoggedExercises(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final recs = snap.data ?? [];
                  if (recs.isEmpty) {
                    return const Center(child: Text('No logged workouts yet'));
                  }

                  // Use the SAME tile format as the normal search results.
                  return ListView.builder(
                    itemCount: recs.length,
                    itemBuilder: (context, index) {
                      final ex = recs[index];
                      final subtitleParts = <String>[];

                      if (ex['muscle'] != null) {
                        subtitleParts.add(ex['muscle']);
                      }
                      if (ex['sets'] != null) {
                        subtitleParts.add('${ex["sets"]} sets');
                      }
                      if (ex['reps'] != null) {
                        subtitleParts.add('${ex["reps"]} reps');
                      }
                      if (ex['weight'] != null) {
                        subtitleParts.add('${ex["weight"]} kg');
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () => _onExerciseTap(ex),
                          title: Text(ex['name']),
                          subtitle: Text(subtitleParts.join(' - ')),
                          trailing: const Icon(Icons.add_circle),
                        ),
                      );
                    },
                  );
                },
              )
              : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final ex = _results[index];
                  final subtitleParts = <String>[];

                  if (ex['muscle'] != null) {
                    subtitleParts.add(ex['muscle']);
                  }
                  if (ex['sets'] != null) {
                    subtitleParts.add('${ex["sets"]} sets');
                  }
                  if (ex['reps'] != null) {
                    subtitleParts.add('${ex["reps"]} reps');
                  }
                  if (ex['weight'] != null) {
                    subtitleParts.add('${ex["weight"]} kg');
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      onTap: () => _onExerciseTap(ex),
                      title: Text(ex['name']),
                      subtitle: Text(subtitleParts.join(' - ')),
                      trailing: const Icon(Icons.add_circle),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // FAB to manually add a workout
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () async {
              final erid = await addWorkoutViaDialog(context, uid: widget.uid);
              if (erid != null && mounted) {
                widget.onEntryAdded?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout saved')),
                );
              }
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }


  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> data = await db.getAllExerciseData();
      _results = [];

      if (q.toLowerCase() == "all") {
        _results = data;
      } else {
        for (int i=0; i<data.length; i++) {

          if (data[i]["name"].toLowerCase().contains(q) || data[i]["muscle"].toLowerCase().contains(q)) {
            _results.add(data[i]);
          }
        }
      }

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onExerciseTap(Map<String, dynamic> ex) async {
    // Building a prefilled WorkoutEntry
    final exercise = WorkoutEntry(
        name: ex["name"] ?? "",
        muscleGroup: ex["muscle"] ?? "Chest",
        sets: ex["sets"] ?? 0,
        reps: ex["reps"] ?? 0,
        weight: ex["weight"].toDouble() ?? 0.0,
        dateTime: DateTime.now()
    );

    final erid = await addWorkoutViaDialog(
        context,
        uid: widget.uid,
        initial: exercise,
    );

    if (erid != null && mounted) {
      widget.onEntryAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${exercise.name}" to log'))
      );
    }
  }
}