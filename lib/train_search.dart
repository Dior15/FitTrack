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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _queryController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search exercises',
            prefixIcon: const Icon(Icons.search_outlined),
            border: const OutlineInputBorder()
          ),
          onSubmitted: (_) => _search(),
        ),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Error: $_error', style: const TextStyle(color: Colors.red))
          ),
        Expanded(
          child: _results.isEmpty && !_loading
              ? const Center(child: Text('Search for an exercise to see results'))
              : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final ex = _results[index];
              final subtitleParts = <String>[];
              if (ex["muscle"] != null) {
                subtitleParts.add(ex["muscle"]);
              }
              if (ex["sets"] != null) {
                subtitleParts.add("${ex["sets"]} sets");
              }
              if (ex["reps"] != null) {
                subtitleParts.add("${ex["reps"]} reps");
              }
              if (ex["weight"] != null) {
                subtitleParts.add("${ex["weight"]} kg");
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  onTap: () => _onExerciseTap(ex),
                  title: Text(ex['name']),
                  subtitle: Text(subtitleParts.join(' - ')),
                  trailing: const Icon(Icons.add_circle)
                )
              );
            }
          )
        )
      ]
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