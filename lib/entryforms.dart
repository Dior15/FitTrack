import 'package:flutter/material.dart';
import 'db_model.dart';

/// Meal and Workout Classes
class MealEntry {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int servings;
  final DateTime date;

  const MealEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servings,
    required this.date,
  });

  // Map<String, dynamic> toMap() => {
  //   'name': name,
  //   'calories': calories,
  //   'protein': protein,
  //   'carbs': carbs,
  //   'fat': fat,
  //   'servings': servings,
  //   'date': date.toIso8601String(),
  // };
}

class WorkoutEntry {
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double weight;
  final DateTime dateTime;

  const WorkoutEntry({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.dateTime,
  });

  // Map<String, dynamic> toMap() => {
  //   'name': name,
  //   'muscleGroup': muscleGroup,
  //   'sets': sets,
  //   'reps': reps,
  //   'weight': weight,
  //   'dateTime': dateTime.toIso8601String(),
  // };
}

/// Format as 'YYYY/MM/DD' to match db.
String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// Format as 'HH:mm' 24h for exerciseRecords.time
String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Shows the Add Meal dialog, then inserts into:
/// 1) foodData (name + macros), 2) foodRecords (link to data + uid/date/servings).
/// Returns the new foodRecords.frid, or null if cancelled.
Future<int?> addMealViaDialog(BuildContext context, {required int uid, MealEntry? initial}) async {
  final meal = await showMealEntryDialog(context, initial: initial);
  if (meal == null) return null;

  final db = DBModel.db;
  return await db.insertFoodRecord({
    'uid': uid,
    'fid': await db.insertFoodData({
      'name': meal.name,
      'calories': meal.calories,
      'protein': meal.protein,
      'fat': meal.fat,
      'carbohydrates': meal.carbs,
    }),
    'date': _fmtDate(meal.date),
    'servings': meal.servings,
  });
}

/// Shows the Add Workout dialog, then inserts into:
/// 1) exerciseData (exercise details), 2) exerciseRecords (link + uid/date/time).
/// Returns the new exerciseRecords.erid, or null if cancelled.
Future<int?> addWorkoutViaDialog(BuildContext context, {required int uid}) async {
  final workout = await showWorkoutEntryDialog(context); // existing dialog [web:64]
  if (workout == null) return null;

  final db = DBModel.db;

  return await db.insertExerciseRecord({
    'uid': uid,
    'eid': await db.insertExerciseData({
      'name': workout.name,
      'muscle': workout.muscleGroup,
      'sets': workout.sets,
      'reps': workout.reps,
      'weight': workout.weight,
    }),
    'date': _fmtDate(workout.dateTime),
    'time': _fmtTime(TimeOfDay.fromDateTime(workout.dateTime))
  });
}

/// Dialog forms for meals and workouts that return their respective classes
Future<MealEntry?> showMealEntryDialog(
    BuildContext context, {
      MealEntry? initial,
    }) {
  // Controllers hold temporary field values while the dialog is open.
  final name = TextEditingController(text: initial?.name ?? '');
  final calories =
  TextEditingController(text: initial?.calories.toString() ?? '');
  final protein =
  TextEditingController(text: initial?.protein.toString() ?? '');
  final carbs =
  TextEditingController(text: initial?.carbs.toString() ?? '');
  final fat =
  TextEditingController(text: initial?.fat.toString() ?? '');
  final servings =
  TextEditingController(text: initial?.servings.toString() ?? '1');
  DateTime date = initial?.date ?? DateTime.now();

  return showDialog<MealEntry>(
    context: context,
    builder: (_) => _FormDialog<MealEntry>(
      title: 'Add Meal',
      fields: (theme) => [
        _TextField(label: 'Name', controller: name),
        _NumberField(label: 'Calories', controller: calories),
        _NumberField(label: 'Protein (g)', controller: protein),
        _NumberField(label: 'Carbs (g)', controller: carbs),
        _NumberField(label: 'Fat (g)', controller: fat),
        _NumberField(
          label: 'Servings',
          controller: servings,
          validateNum: (n) => n <= 0 ? 'Must be > 0' : null,
        ),
        _DatePickerField(
          label: 'Date',
          initial: date,
          onChanged: (d) => date = d,
        ),
      ],
      collectResult: () => MealEntry(
        name: name.text.trim(),
        calories: int.parse(calories.text),
        protein: int.parse(protein.text),
        carbs: int.parse(carbs.text),
        fat: int.parse(fat.text),
        servings: int.parse(servings.text),
        date: date,
      ),
    ),
  );
}

Future<WorkoutEntry?> showWorkoutEntryDialog(BuildContext context) {
  final name = TextEditingController();
  final sets = TextEditingController(text: '3');
  final reps = TextEditingController(text: '10');
  final weight = TextEditingController(text: '0');
  final muscle = ValueNotifier<String>('Chest'); // Simple dropdown source
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();

  return showDialog<WorkoutEntry>(
    context: context,
    builder: (_) => _FormDialog<WorkoutEntry>(
      title: 'Add Workout',
      fields: (theme) => [
        _TextField(label: 'Exercise', controller: name),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ValueListenableBuilder<String>(
            valueListenable: muscle,
            builder: (context, value, _) => DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(
                labelText: 'Muscle Group',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                'Chest',
                'Back',
                'Legs',
                'Shoulders',
                'Arms',
                'Core',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => muscle.value = v ?? muscle.value,
            ),
          ),
        ),
        _NumberField(
          label: 'Sets',
          controller: sets,
          validateNum: (n) => n <= 0 ? 'Must be > 0' : null,
        ),
        _NumberField(
          label: 'Reps',
          controller: reps,
          validateNum: (n) => n <= 0 ? 'Must be > 0' : null,
        ),
        _NumberField(label: 'Weight (kg)', controller: weight),
        _DatePickerField(
          label: 'Date',
          initial: date,
          onChanged: (d) => date = d,
        ),
        _TimePickerField(
          label: 'Time',
          initial: time,
          onChanged: (t) => time = t,
        ),
      ],
      collectResult: () {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        return WorkoutEntry(
          name: name.text.trim(),
          muscleGroup: muscle.value,
          sets: int.parse(sets.text),
          reps: int.parse(reps.text),
          weight: double.parse(weight.text),
          dateTime: dt,
        );
      },
    ),
  );
}

// Forms base for configuration
class _FormDialog<T> extends StatefulWidget {
  final String title;
  // The field builder receives ThemeData for consistent styling when needed.
  final List<Widget> Function(ThemeData theme) fields;
  // How to build the final result after validation passes.
  final T Function() collectResult;

  const _FormDialog({
    required this.title,
    required this.fields,
    required this.collectResult,
  });

  @override
  State<_FormDialog<T>> createState() => _FormDialogState<T>();
}

class _FormDialogState<T> extends State<_FormDialog<T>> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text(widget.title), // visible title region
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Widen the dialog — AlertDialog sizes to content width.
      content: SizedBox(
        width: screenW * 0.90,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // nicer UX
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.fields(theme),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          // onPressed: () => Navigator.of(context).pop(null),
          onPressed: () {

            Navigator.of(context).pop(null);
            final cancelSnackbar = SnackBar(content: Text('Entry cancelled'));
            ScaffoldMessenger.of(context).showSnackBar(cancelSnackbar);
            
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Validate all inputs; if OK, return the typed result T.
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(widget.collectResult());
            }

            final submittedSnackbar = SnackBar(content: Text('Successfully submitted!'));
            ScaffoldMessenger.of(context).showSnackBar(submittedSnackbar);

          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// FIELD HELPERS
class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _TextField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: validator ??
                (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(num value)? validateNum;

  const _NumberField({
    required this.label,
    required this.controller,
    this.validateNum,
  });

  @override
  Widget build(BuildContext context) {
    return _TextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final num? parsed = num.tryParse(v);
        if (parsed == null) return 'Enter a number';
        return validateNum?.call(parsed);
      },
    );
  }
}

/// Date picker field that mirrors a dense text field visually and opens the
/// Material date picker on tap, returning the chosen DateTime via callback. [web:70]
class _DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? initial;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.label,
    required this.onChanged,
    this.initial,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  DateTime? value;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date'
        : MaterialLocalizations.of(context).formatShortDate(value!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) {
            setState(() => value = picked);
            widget.onChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

/// Time picker field that matches text field styling and opens the system
/// time picker, providing the selected TimeOfDay via callback. [web:74]
class _TimePickerField extends StatefulWidget {
  final String label;
  final TimeOfDay? initial;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerField({
    required this.label,
    required this.onChanged,
    this.initial,
  });

  @override
  State<_TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<_TimePickerField> {
  TimeOfDay? value;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null ? 'Select time' : value!.format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: value ?? TimeOfDay.now(),
          );
          if (picked != null) {
            setState(() => value = picked);
            widget.onChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}