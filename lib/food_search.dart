// lib/food_search.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'entryforms.dart';

/// Simple product model built from Open Food Facts search results.
class OffProduct {
  final String name;
  final String? brand;
  final String? servingSize;          // e.g. "30 g" or "1 bar (40 g)"
  final double? caloriesPerServing;
  final double? proteinPerServing;
  final double? carbsPerServing;
  final double? fatPerServing;

  OffProduct({
    required this.name,
    this.brand,
    this.servingSize,
    this.caloriesPerServing,
    this.proteinPerServing,
    this.carbsPerServing,
    this.fatPerServing,
  });

  bool get hasAnyMacros =>
      caloriesPerServing != null ||
      proteinPerServing != null ||
      carbsPerServing != null ||
      fatPerServing != null;

  factory OffProduct.fromJson(Map<String, dynamic> json) {
    final nutriments = (json['nutriments'] as Map?) ?? {};
    double? _num(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

    return OffProduct(
      name: (json['product_name'] ?? '').toString(),
      brand: (json['brands'] ?? '').toString().isEmpty ? null : (json['brands'] as String),
      servingSize: (json['serving_size'] as String?)?.trim(),
      caloriesPerServing: _num(nutriments['energy-kcal_serving'] ?? nutriments['energy_serving']),
      proteinPerServing: _num(nutriments['proteins_serving']),
      carbsPerServing: _num(nutriments['carbohydrates_serving']),
      fatPerServing: _num(nutriments['fat_serving']),
    );
  }
}

/// Search + result list for the Food tab.
class FoodSearchPage extends StatefulWidget {
  final int uid; // current user id for DB inserts
  final VoidCallback? onEntryAdded;

  const FoodSearchPage({super.key, required this.uid, this.onEntryAdded});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final _queryController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<OffProduct> _results = [];

  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // v1 search API with full-text search.
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/cgi/search.pl',
        {
          'search_terms': q,        // query
          'search_simple': '1',     // simple full-text search
          'action': 'process',
          'json': '1',              // ask for JSON
          'page_size': '20',
          'fields': 'product_name,brands,nutriments',
        },
      );

      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final products = (data['products'] as List? ?? [])
          .map((p) => OffProduct.fromJson(p as Map<String, dynamic>))
          .where((p) => p.name.isNotEmpty && p.hasAnyMacros)
          .toList();

      setState(() {
        _results = products;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  Future<void> _onProductTap(OffProduct p) async {
    // Build a prefilled MealEntry based on per-100g macros.
    final meal = MealEntry(
      name: p.name,
      calories: (p.caloriesPerServing ?? 0).round(),
      protein: (p.proteinPerServing ?? 0).round(),
      carbs: (p.carbsPerServing ?? 0).round(),
      fat: (p.fatPerServing ?? 0).round(),
      servings: 1,
      date: DateTime.now(),
    );

    // Open your existing dialog with fields prefilled, then save to DB.
    final frid = await addMealViaDialog(
      context,
      uid: widget.uid,
      initial: meal,
    );
    if (frid != null && mounted) {
      widget.onEntryAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${meal.name}" to log')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _queryController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search foods',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _search(),
        ),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: _results.isEmpty && !_loading
              ? const Center(child: Text('Search for a food to see results'))
              : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final p = _results[index];
              final subtitleParts = <String>[];
              if (p.caloriesPerServing != null) {
                final label = p.servingSize ?? 'serving';
                subtitleParts.add('${p.caloriesPerServing!.round()} Cal / $label');
              }
              if (p.proteinPerServing != null) {
                subtitleParts.add('P ${p.proteinPerServing!.round()} g');
              }
              if (p.carbsPerServing != null) {
                subtitleParts.add('C ${p.carbsPerServing!.round()} g');
              }
              if (p.fatPerServing != null) {
                subtitleParts.add('F ${p.fatPerServing!.round()} g');
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  onTap: () => _onProductTap(p),
                  title: Text(p.name),
                  subtitle: Text(subtitleParts.join(' • ')),
                  trailing: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
