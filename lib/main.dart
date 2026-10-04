import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await AppStore.instance.initialize();

  runApp(const FitnessTrackerApp());
}

// ============================================================
// APP STORAGE
// ============================================================

class AppStore {
  AppStore._();

  static final AppStore instance = AppStore._();

  late Box<dynamic> _box;

  List<WeightPlan> weightPlans = [];
  List<WorkoutDay> workoutDays = [];
  DietGoals dietGoals = DietGoals.defaults();
  List<DietLogEntry> dietLogs = [];
  List<FoodDefinition> customFoods = [];

  Future<void> initialize() async {
    _box = await Hive.openBox('fitness_tracker_data');

    final savedWeightPlans = _box.get('weightPlans');
    final savedWorkoutDays = _box.get('workoutDays');
    final savedDietGoals = _box.get('dietGoals');
    final savedDietLogs = _box.get('dietLogs');
    final savedCustomFoods = _box.get('customFoods');

    if (savedWeightPlans is List) {
      weightPlans = savedWeightPlans
          .map(
            (item) => WeightPlan.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (savedWorkoutDays is List) {
      workoutDays = savedWorkoutDays
          .map(
            (item) => WorkoutDay.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (savedDietGoals is Map) {
      dietGoals = DietGoals.fromJson(
        Map<String, dynamic>.from(savedDietGoals),
      );
    }

    if (savedDietLogs is List) {
      dietLogs = savedDietLogs
          .map(
            (item) => DietLogEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (savedCustomFoods is List) {
      customFoods = savedCustomFoods
          .map(
            (item) => FoodDefinition.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (weightPlans.isEmpty && !_box.containsKey('weightPlans')) {
      weightPlans = [
        WeightPlan(
          name: 'Cutting',
          entries: [
            WeightEntry(
              lb: 190,
              kg: 86.18,
              dateTime: DateTime(2026, 9, 1, 7, 55),
              note: 'Starting weight',
            ),
            WeightEntry(
              lb: 185,
              kg: 83.91,
              dateTime: DateTime(2026, 9, 15, 8, 20),
              note: 'Morning weigh-in',
            ),
            WeightEntry(
              lb: 182.4,
              kg: 82.74,
              dateTime: DateTime(2026, 9, 25, 9, 32),
              note: 'Feeling good',
            ),
          ],
        ),
      ];
    }

    if (workoutDays.isEmpty && !_box.containsKey('workoutDays')) {
      workoutDays = [
        WorkoutDay(
          name: 'Push',
          exercises: [
            WorkoutExercise(
              name: 'Incline Bench',
              sessions: [],
            ),
          ],
        ),
        WorkoutDay(
          name: 'Pull',
          exercises: [],
        ),
        WorkoutDay(
          name: 'Legs',
          exercises: [],
        ),
      ];
    }

    await save();
  }

  Future<void> save() async {
    await _box.put(
      'weightPlans',
      weightPlans.map((e) => e.toJson()).toList(),
    );

    await _box.put(
      'workoutDays',
      workoutDays.map((e) => e.toJson()).toList(),
    );

    await _box.put(
      'dietGoals',
      dietGoals.toJson(),
    );

    await _box.put(
      'dietLogs',
      dietLogs.map((e) => e.toJson()).toList(),
    );

    await _box.put(
      'customFoods',
      customFoods.map((e) => e.toJson()).toList(),
    );
  }
}

// ============================================================
// APP
// ============================================================

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF080B0F),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171B20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF0A84FF),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// WEIGHT MODELS
// ============================================================

class WeightEntry {
  WeightEntry({
    required this.lb,
    required this.kg,
    required this.dateTime,
    required this.note,
  });

  double lb;
  double kg;
  DateTime dateTime;
  String note;

  Map<String, dynamic> toJson() {
    return {
      'lb': lb,
      'kg': kg,
      'dateTime': dateTime.toIso8601String(),
      'note': note,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      lb: (json['lb'] as num).toDouble(),
      kg: (json['kg'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      note: json['note'] as String? ?? '',
    );
  }
}

class WeightPlan {
  WeightPlan({
    required this.name,
    required this.entries,
  });

  String name;
  List<WeightEntry> entries;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }

  factory WeightPlan.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List? ?? [];

    return WeightPlan(
      name: json['name'] as String? ?? 'Weight Plan',
      entries: rawEntries
          .map(
            (e) => WeightEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================
// WORKOUT MODELS
// ============================================================

class ExerciseSetRecord {
  ExerciseSetRecord({
    required this.weightLb,
    required this.weightKg,
    this.reps = 0,
    this.durationSeconds = 0,
    this.trackingMode = 'reps',
    this.inputUnit = 'lb',
  });

  double weightLb;
  double weightKg;
  int reps;
  int durationSeconds;
  String trackingMode;
  String inputUnit;

  Map<String, dynamic> toJson() {
    return {
      'weightLb': weightLb,
      'weightKg': weightKg,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'trackingMode': trackingMode,
      'inputUnit': inputUnit,
    };
  }

  factory ExerciseSetRecord.fromJson(Map<String, dynamic> json) {
    final duration = (json['durationSeconds'] as num?)?.toInt() ?? 0;
    final mode = json['trackingMode'] as String? ??
        (duration > 0 ? 'time' : 'reps');

    return ExerciseSetRecord(
      weightLb: (json['weightLb'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      durationSeconds: duration,
      trackingMode: mode,
      inputUnit: json['inputUnit'] as String? ?? 'lb',
    );
  }
}

class ExerciseSession {
  ExerciseSession({
    required this.dateTime,
    required this.sets,
    required this.note,
  });

  DateTime dateTime;
  List<ExerciseSetRecord> sets;
  String note;

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'sets': sets.map((e) => e.toJson()).toList(),
      'note': note,
    };
  }

  factory ExerciseSession.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'] as List? ?? [];

    return ExerciseSession(
      dateTime: DateTime.parse(json['dateTime'] as String),
      sets: rawSets
          .map(
            (e) => ExerciseSetRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      note: json['note'] as String? ?? '',
    );
  }
}

class WorkoutExercise {
  WorkoutExercise({
    required this.name,
    required this.sessions,
  });

  String name;
  List<ExerciseSession> sessions;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'] as List? ?? [];

    return WorkoutExercise(
      name: json['name'] as String? ?? 'Exercise',
      sessions: rawSessions
          .map(
            (e) => ExerciseSession.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class WorkoutDay {
  WorkoutDay({
    required this.name,
    required this.exercises,
  });

  String name;
  List<WorkoutExercise> exercises;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List? ?? [];

    return WorkoutDay(
      name: json['name'] as String? ?? 'Workout',
      exercises: rawExercises
          .map(
            (e) => WorkoutExercise.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}


// ============================================================
// DIET MODELS + FOOD SEARCH
// ============================================================

class DietGoals {
  DietGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double calories;
  double protein;
  double carbs;
  double fat;

  factory DietGoals.defaults() {
    return DietGoals(
      calories: 2400,
      protein: 180,
      carbs: 250,
      fat: 70,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory DietGoals.fromJson(Map<String, dynamic> json) {
    return DietGoals(
      calories: (json['calories'] as num?)?.toDouble() ?? 2400,
      protein: (json['protein'] as num?)?.toDouble() ?? 180,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 250,
      fat: (json['fat'] as num?)?.toDouble() ?? 70,
    );
  }
}

class FoodDefinition {
  FoodDefinition({
    required this.name,
    required this.brand,
    required this.servingLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
    this.barcode = '',
    this.gramsPerServing,
  });

  String name;
  String brand;
  String servingLabel;
  double calories;
  double protein;
  double carbs;
  double fat;
  String source;
  String barcode;

  // Optional weight represented by one nutrition serving. For Open Food
  // Facts entries this is 100 g. Custom foods can also define this value.
  // It lets the diary convert grams or a counted quantity into nutrition.
  double? gramsPerServing;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'servingLabel': servingLabel,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'source': source,
      'barcode': barcode,
      'gramsPerServing': gramsPerServing,
    };
  }

  factory FoodDefinition.fromJson(Map<String, dynamic> json) {
    final servingLabel =
        json['servingLabel'] as String? ?? '1 serving';
    final savedGrams =
        (json['gramsPerServing'] as num?)?.toDouble();

    return FoodDefinition(
      name: json['name'] as String? ?? 'Food',
      brand: json['brand'] as String? ?? '',
      servingLabel: servingLabel,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'Custom',
      barcode: json['barcode'] as String? ?? '',
      gramsPerServing:
          savedGrams ?? gramsFromServingLabel(servingLabel),
    );
  }

  FoodDefinition copy() {
    return FoodDefinition.fromJson(toJson());
  }
}

class DietLogEntry {
  DietLogEntry({
    required this.id,
    required this.food,
    required this.meal,
    required this.dateTime,
    required this.servings,
    this.quantity,
    this.quantityUnit,
    this.gramsPerUnit,
  });

  String id;
  FoodDefinition food;
  String meal;
  DateTime dateTime;

  // Nutrition is always calculated with this multiplier so old saved entries
  // remain compatible. Quantity fields are optional display/conversion data.
  double servings;
  double? quantity;
  String? quantityUnit;
  double? gramsPerUnit;

  double get calories => food.calories * servings;
  double get protein => food.protein * servings;
  double get carbs => food.carbs * servings;
  double get fat => food.fat * servings;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food': food.toJson(),
      'meal': meal,
      'dateTime': dateTime.toIso8601String(),
      'servings': servings,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'gramsPerUnit': gramsPerUnit,
    };
  }

  factory DietLogEntry.fromJson(Map<String, dynamic> json) {
    return DietLogEntry(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      food: FoodDefinition.fromJson(
        Map<String, dynamic>.from(
          (json['food'] as Map?) ?? <String, dynamic>{},
        ),
      ),
      meal: json['meal'] as String? ?? 'Snacks',
      dateTime: DateTime.tryParse(
            json['dateTime'] as String? ?? '',
          ) ??
          DateTime.now(),
      servings: (json['servings'] as num?)?.toDouble() ?? 1,
      quantity: (json['quantity'] as num?)?.toDouble(),
      quantityUnit: json['quantityUnit'] as String?,
      gramsPerUnit: (json['gramsPerUnit'] as num?)?.toDouble(),
    );
  }
}

class OpenFoodFactsService {
  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Future<List<FoodDefinition>> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.length < 2) {
      return [];
    }

    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/cgi/search.pl',
      {
        'search_terms': trimmed,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '25',
        'fields': 'code,product_name,brands,nutriments',
      },
    );

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    // Browsers do not allow apps to set the User-Agent header manually.
    // Native iOS/Android builds can identify the app as requested by OFF.
    if (!kIsWeb) {
      headers['User-Agent'] =
          'FitnessTracker/1.0 (com.legin.fitnesstracker)';
    }

    final response = await http
        .get(
          uri,
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Food search failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Unexpected food database response.');
    }

    final rawProducts = decoded['products'];

    if (rawProducts is! List) {
      return [];
    }

    final results = <FoodDefinition>[];
    final seen = <String>{};

    for (final raw in rawProducts) {
      if (raw is! Map) continue;

      final product = Map<String, dynamic>.from(raw);
      final name =
          (product['product_name']?.toString() ?? '').trim();

      if (name.isEmpty) continue;

      final nutrimentsRaw = product['nutriments'];
      if (nutrimentsRaw is! Map) continue;

      final nutriments =
          Map<String, dynamic>.from(nutrimentsRaw);

      double? calories =
          _number(nutriments['energy-kcal_100g']);

      if (calories == null) {
        final energyKj =
            _number(nutriments['energy-kj_100g']) ??
                _number(nutriments['energy_100g']);

        if (energyKj != null) {
          calories = energyKj / 4.184;
        }
      }

      final protein =
          _number(nutriments['proteins_100g']) ?? 0;
      final carbs =
          _number(nutriments['carbohydrates_100g']) ?? 0;
      final fat =
          _number(nutriments['fat_100g']) ?? 0;

      calories ??= 0;

      if (calories <= 0 &&
          protein <= 0 &&
          carbs <= 0 &&
          fat <= 0) {
        continue;
      }

      final brand =
          (product['brands']?.toString() ?? '').trim();
      final barcode =
          (product['code']?.toString() ?? '').trim();

      final key =
          '${name.toLowerCase()}|${brand.toLowerCase()}|$barcode';

      if (!seen.add(key)) continue;

      results.add(
        FoodDefinition(
          name: name,
          brand: brand,
          servingLabel: '100 g',
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          source: 'Open Food Facts',
          barcode: barcode,
          gramsPerServing: 100,
        ),
      );
    }

    return results;
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      WeightPlansPage(),
      WorkoutDaysPage(),
      DietPage(),
      SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF11151A),
        indicatorColor: const Color(0xFF0A84FF),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Weight',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Diet',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WEIGHT PLANS
// ============================================================

class WeightPlansPage extends StatefulWidget {
  const WeightPlansPage({super.key});

  @override
  State<WeightPlansPage> createState() => _WeightPlansPageState();
}

class _WeightPlansPageState extends State<WeightPlansPage> {
  List<WeightPlan> get plans => AppStore.instance.weightPlans;

  Future<void> addPlan() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171B20),
          title: const Text('New Weight Plan'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Plan name',
              hintText: 'Cutting, Bulking, Maintenance...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      setState(() {
        plans.add(
          WeightPlan(
            name: result,
            entries: [],
          ),
        );
      });

      await AppStore.instance.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Weight Tracker',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: addPlan,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Plans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: plans.isEmpty
                  ? const Center(
                      child: Text(
                        'No plans yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: plans.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final plan = plans[index];

                        final sorted =
                            List<WeightEntry>.from(plan.entries)
                              ..sort(
                                (a, b) =>
                                    b.dateTime.compareTo(a.dateTime),
                              );

                        final latest =
                            sorted.isEmpty ? null : sorted.first;

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WeightPlanDetailPage(plan: plan),
                              ),
                            );

                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171B20),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A84FF)
                                        .withOpacity(0.18),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.monitor_weight,
                                    color: Color(0xFF0A84FF),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        latest == null
                                            ? 'No entries yet'
                                            : '${latest.lb.toStringAsFixed(1)} lb  •  ${latest.kg.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      if (latest != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Latest: ${formatDateTimeOneLine(latest.dateTime)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WEIGHT PLAN DETAIL + GRAPH
// ============================================================

class WeightPlanDetailPage extends StatefulWidget {
  const WeightPlanDetailPage({
    super.key,
    required this.plan,
  });

  final WeightPlan plan;

  @override
  State<WeightPlanDetailPage> createState() =>
      _WeightPlanDetailPageState();
}

class _WeightPlanDetailPageState extends State<WeightPlanDetailPage> {
  String displayUnit = 'lb';

  double weightForEntry(WeightEntry entry) {
    return displayUnit == 'lb' ? entry.lb : entry.kg;
  }

  Future<void> addWeight() async {
    final entry = await showModalBottomSheet<WeightEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11151A),
      builder: (_) => const AddWeightSheet(),
    );

    if (entry != null) {
      setState(() {
        widget.plan.entries.add(entry);
      });

      await AppStore.instance.save();
    }
  }

  Future<void> deleteEntry(WeightEntry entry) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete weight entry?',
      message:
          'This will permanently delete this weigh-in and cannot be undone.',
    );

    if (!confirmed) return;

    setState(() {
      widget.plan.entries.remove(entry);
    });

    await AppStore.instance.save();
  }

  @override
  Widget build(BuildContext context) {
    final entries = List<WeightEntry>.from(widget.plan.entries)
      ..sort(
        (a, b) => b.dateTime.compareTo(a.dateTime),
      );

    final chronological = List<WeightEntry>.from(widget.plan.entries)
      ..sort(
        (a, b) => a.dateTime.compareTo(b.dateTime),
      );

    WeightEntry? latest;
    WeightEntry? starting;

    if (entries.isNotEmpty) {
      latest = entries.first;
      starting = entries.last;
    }

    final latestWeight =
        latest == null ? null : weightForEntry(latest);

    final startingWeight =
        starting == null ? null : weightForEntry(starting);

    final change = latestWeight != null && startingWeight != null
        ? latestWeight - startingWeight
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addWeight,
        icon: const Icon(Icons.add),
        label: const Text('Add Weight'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'lb',
                    label: Text('lb'),
                  ),
                  ButtonSegment(
                    value: 'kg',
                    label: Text('kg'),
                  ),
                ],
                selected: {displayUnit},
                onSelectionChanged: (selection) {
                  setState(() {
                    displayUnit = selection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Latest',
                  value: latestWeight == null
                      ? '—'
                      : '${latestWeight.toStringAsFixed(1)} $displayUnit',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Starting',
                  value: startingWeight == null
                      ? '—'
                      : '${startingWeight.toStringAsFixed(1)} $displayUnit',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Change',
                  value: latestWeight == null
                      ? '—'
                      : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} $displayUnit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF171B20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weight Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chronological.length < 2
                      ? 'Add at least 2 entries to see a trend.'
                      : '${chronological.length} recorded weigh-ins',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: chronological.isEmpty
                      ? const Center(
                          child: Text(
                            'No weight data yet.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: WeightProgressChartPainter(
                            entries: chronological,
                            unit: displayUnit,
                          ),
                        ),
                ),
                if (chronological.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formatShortDate(chronological.first.dateTime),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (chronological.length > 1)
                        Text(
                          formatShortDate(chronological.last.dateTime),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'No weight entries yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ...entries.map(
            (entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171B20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weightForEntry(entry).toStringAsFixed(1)} $displayUnit',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            displayUnit == 'lb'
                                ? '${entry.kg.toStringAsFixed(1)} kg'
                                : '${entry.lb.toStringAsFixed(1)} lb',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          if (entry.note.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              entry.note,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatDateTime(entry.dateTime),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            deleteEntry(entry);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ============================================================
// WEIGHT PROGRESS GRAPH
// ============================================================

class WeightProgressChartPainter extends CustomPainter {
  WeightProgressChartPainter({
    required this.entries,
    required this.unit,
  });

  final List<WeightEntry> entries;
  final String unit;

  double weight(WeightEntry entry) {
    return unit == 'lb' ? entry.lb : entry.kg;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final values = entries.map(weight).toList();

    double min = values.reduce(
      (a, b) => a < b ? a : b,
    );

    double max = values.reduce(
      (a, b) => a > b ? a : b,
    );

    double range = max - min;

    if (range == 0) {
      range = unit == 'lb' ? 10 : 5;
      min -= range / 2;
      max += range / 2;
    } else {
      final paddingAmount = range * 0.15;
      min -= paddingAmount;
      max += paddingAmount;
    }

    const leftPadding = 14.0;
    const rightPadding = 14.0;
    const topPadding = 16.0;
    const bottomPadding = 16.0;

    final chartWidth =
        size.width - leftPadding - rightPadding;
    final chartHeight =
        size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..style = PaintingStyle.fill;

    final pointOutlinePaint = Paint()
      ..color = const Color(0xFF171B20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + chartHeight / 4 * i;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    final path = Path();

    for (int i = 0; i < entries.length; i++) {
      final value = values[i];

      final x = entries.length == 1
          ? size.width / 2
          : leftPadding +
              (i / (entries.length - 1)) * chartWidth;

      final normalized =
          (value - min) / (max - min);

      final y = topPadding +
          chartHeight -
          normalized * chartHeight;

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    if (entries.length > 1) {
      canvas.drawPath(path, linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(
        point,
        6,
        pointOutlinePaint,
      );
      canvas.drawCircle(
        point,
        4,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant WeightProgressChartPainter oldDelegate,
  ) {
    return true;
  }
}

// ============================================================
// ADD WEIGHT
// ============================================================

class AddWeightSheet extends StatefulWidget {
  const AddWeightSheet({super.key});

  @override
  State<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends State<AddWeightSheet> {
  final weightController = TextEditingController();
  final noteController = TextEditingController();

  String unit = 'lb';
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    weightController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> chooseDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void save() {
    final value = double.tryParse(weightController.text);

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid weight.'),
        ),
      );
      return;
    }

    late double lb;
    late double kg;

    if (unit == 'lb') {
      lb = value;
      kg = value / 2.20462;
    } else {
      kg = value;
      lb = value * 2.20462;
    }

    Navigator.pop(
      context,
      WeightEntry(
        lb: lb,
        kg: kg,
        dateTime: selectedDate,
        note: noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Weight',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('lb'),
                  selected: unit == 'lb',
                  onSelected: (_) {
                    setState(() {
                      unit = 'lb';
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('kg'),
                  selected: unit == 'kg',
                  onSelected: (_) {
                    setState(() {
                      unit = 'kg';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListTile(
              tileColor: const Color(0xFF171B20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date & Time'),
              subtitle: Text(
                formatDateTimeOneLine(selectedDate),
              ),
              trailing: const Icon(Icons.edit),
              onTap: chooseDateTime,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Morning weigh-in...',
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: save,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Save Weight'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WORKOUT DAYS
// ============================================================

class WorkoutDaysPage extends StatefulWidget {
  const WorkoutDaysPage({super.key});

  @override
  State<WorkoutDaysPage> createState() => _WorkoutDaysPageState();
}

class _WorkoutDaysPageState extends State<WorkoutDaysPage> {
  List<WorkoutDay> get days => AppStore.instance.workoutDays;

  Future<void> addWorkoutDay() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171B20),
          title: const Text('New Workout Day'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Day name',
              hintText: 'Chest, Back, Arms, Push...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      setState(() {
        days.add(
          WorkoutDay(
            name: result,
            exercises: [],
          ),
        );
      });

      await AppStore.instance.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Workouts',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: addWorkoutDay,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a workout day',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: days.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final day = days[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutDayPage(day: day),
                        ),
                      );

                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171B20),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A84FF)
                                  .withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.exercises.length} exercises',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WORKOUT DAY
// ============================================================

class WorkoutDayPage extends StatefulWidget {
  const WorkoutDayPage({
    super.key,
    required this.day,
  });

  final WorkoutDay day;

  @override
  State<WorkoutDayPage> createState() =>
      _WorkoutDayPageState();
}

class _WorkoutDayPageState extends State<WorkoutDayPage> {
  Future<void> addExercise() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171B20),
          title: const Text('Add Exercise'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Exercise name',
              hintText: 'Incline Bench',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.isEmpty) {
      return;
    }

    final duplicate = widget.day.exercises.any(
      (exercise) =>
          exercise.name.toLowerCase() ==
          result.toLowerCase(),
    );

    if (duplicate) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That exercise is already in this workout.',
          ),
        ),
      );

      return;
    }

    setState(() {
      widget.day.exercises.add(
        WorkoutExercise(
          name: result,
          sessions: [],
        ),
      );
    });

    await AppStore.instance.save();
  }

  double? heaviestSet(WorkoutExercise exercise) {
    final allSets = exercise.sessions
        .expand((session) => session.sets)
        .toList();

    if (allSets.isEmpty) return null;

    return allSets
        .map((set) => set.weightLb)
        .reduce((a, b) => a > b ? a : b);
  }

  DateTime? lastPerformed(WorkoutExercise exercise) {
    if (exercise.sessions.isEmpty) return null;

    final sessions =
        List<ExerciseSession>.from(exercise.sessions)
          ..sort(
            (a, b) => b.dateTime.compareTo(a.dateTime),
          );

    return sessions.first.dateTime;
  }

  Future<void> deleteExercise(
    WorkoutExercise exercise,
  ) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete exercise?',
      message:
          'This will delete ${exercise.name} and all of its workout history.',
    );

    if (!confirmed) return;

    setState(() {
      widget.day.exercises.remove(exercise);
    });

    await AppStore.instance.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.day.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
      body: widget.day.exercises.isEmpty
          ? const Center(
              child: Text(
                'No exercises yet.\nTap Add Exercise.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: widget.day.exercises.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exercise =
                    widget.day.exercises[index];

                final last = lastPerformed(exercise);
                final best = heaviestSet(exercise);

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExerciseDetailPage(
                          exercise: exercise,
                        ),
                      ),
                    );

                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171B20),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF)
                                .withOpacity(0.18),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Color(0xFF0A84FF),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (last == null)
                                const Text(
                                  'Not logged yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                Text(
                                  'Last: ${formatShortDate(last)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              if (best != null)
                                Text(
                                  'Heaviest: ${best.toStringAsFixed(1)} lb',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.chevron_right,
                            ),
                            IconButton(
                              onPressed: () {
                                deleteExercise(exercise);
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// EXERCISE DETAIL
// ============================================================

class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  final WorkoutExercise exercise;

  @override
  State<ExerciseDetailPage> createState() =>
      _ExerciseDetailPageState();
}

class _ExerciseDetailPageState
    extends State<ExerciseDetailPage> {
  String displayUnit = 'lb';

  double weightForSet(ExerciseSetRecord set) {
    return displayUnit == 'lb'
        ? set.weightLb
        : set.weightKg;
  }

  String sessionTrackingMode(ExerciseSession session) {
    if (session.sets.isEmpty) return 'reps';
    return session.sets.first.trackingMode;
  }

  double sessionTopWeight(ExerciseSession session) {
    if (session.sets.isEmpty) return 0;

    return session.sets
        .map(weightForSet)
        .reduce((a, b) => a > b ? a : b);
  }

  int sessionLongestHold(ExerciseSession session) {
    if (session.sets.isEmpty) return 0;

    return session.sets
        .map((set) => set.durationSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  double? heaviestWeight(List<ExerciseSession> sessions) {
    final sets = sessions
        .expand((session) => session.sets)
        .where((set) => set.trackingMode == 'reps')
        .toList();

    if (sets.isEmpty) return null;

    return sets
        .map(weightForSet)
        .reduce((a, b) => a > b ? a : b);
  }

  int? longestHold(List<ExerciseSession> sessions) {
    final sets = sessions
        .expand((session) => session.sets)
        .where((set) => set.trackingMode == 'time')
        .toList();

    if (sets.isEmpty) return null;

    return sets
        .map((set) => set.durationSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  Future<void> logWorkout() async {
    final sorted =
        List<ExerciseSession>.from(widget.exercise.sessions)
          ..sort(
            (a, b) => b.dateTime.compareTo(a.dateTime),
          );

    final initialMode = sorted.isEmpty
        ? 'reps'
        : sessionTrackingMode(sorted.first);

    final session =
        await Navigator.push<ExerciseSession>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExerciseSessionPage(
          exerciseName: widget.exercise.name,
          initialTrackingMode: initialMode,
        ),
      ),
    );

    if (session != null) {
      setState(() {
        widget.exercise.sessions.add(session);
      });

      await AppStore.instance.save();
    }
  }

  Future<void> editSession(
    ExerciseSession session,
  ) async {
    final updated =
        await Navigator.push<ExerciseSession>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExerciseSessionPage(
          exerciseName: widget.exercise.name,
          existingSession: session,
          initialTrackingMode:
              sessionTrackingMode(session),
        ),
      ),
    );

    if (updated == null) return;

    final index =
        widget.exercise.sessions.indexOf(session);

    if (index == -1) return;

    setState(() {
      widget.exercise.sessions[index] = updated;
    });

    await AppStore.instance.save();
  }

  Future<void> deleteSession(
    ExerciseSession session,
  ) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete workout entry?',
      message:
          'This will permanently delete this workout and all of its sets.',
    );

    if (!confirmed) return;

    setState(() {
      widget.exercise.sessions.remove(session);
    });

    await AppStore.instance.save();
  }

  @override
  Widget build(BuildContext context) {
    final sessions =
        List<ExerciseSession>.from(
          widget.exercise.sessions,
        )
          ..sort(
            (a, b) =>
                b.dateTime.compareTo(a.dateTime),
          );

    final progressMode = sessions.isEmpty
        ? 'reps'
        : sessionTrackingMode(sessions.first);

    final metricSessions =
        List<ExerciseSession>.from(
          widget.exercise.sessions.where(
            (session) =>
                sessionTrackingMode(session) == progressMode,
          ),
        )
          ..sort(
            (a, b) =>
                a.dateTime.compareTo(b.dateTime),
          );

    final bestWeight =
        heaviestWeight(metricSessions);
    final bestHold =
        longestHold(metricSessions);

    double? latestWeight;
    int? latestHold;

    if (sessions.isNotEmpty) {
      final latest = sessions.first;

      if (progressMode == 'time') {
        latestHold = sessionLongestHold(latest);
      } else {
        latestWeight = sessionTopWeight(latest);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: logWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Log Workout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'lb',
                    label: Text('lb'),
                  ),
                  ButtonSegment(
                    value: 'kg',
                    label: Text('kg'),
                  ),
                ],
                selected: {displayUnit},
                onSelectionChanged: (selection) {
                  setState(() {
                    displayUnit = selection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ProgressStatCard(
                  title: progressMode == 'time'
                      ? 'Latest Hold'
                      : 'Latest',
                  value: progressMode == 'time'
                      ? (latestHold == null
                          ? '—'
                          : formatDurationSeconds(latestHold))
                      : (latestWeight == null
                          ? '—'
                          : '${latestWeight.toStringAsFixed(1)} $displayUnit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProgressStatCard(
                  title: progressMode == 'time'
                      ? 'Longest'
                      : 'Heaviest',
                  value: progressMode == 'time'
                      ? (bestHold == null
                          ? '—'
                          : formatDurationSeconds(bestHold))
                      : (bestWeight == null
                          ? '—'
                          : '${bestWeight.toStringAsFixed(1)} $displayUnit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProgressStatCard(
                  title: 'Sessions',
                  value:
                      '${widget.exercise.sessions.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF171B20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  progressMode == 'time'
                      ? 'Longest Hold Over Time'
                      : 'Heaviest Set Over Time',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: metricSessions.isEmpty
                      ? const Center(
                          child: Text(
                            'Log workouts to see progress.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter:
                              ExerciseSessionChartPainter(
                            sessions: metricSessions,
                            unit: displayUnit,
                            metricMode: progressMode,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Workout History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'No workouts logged yet.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ...sessions.map(
            (session) {
              return Container(
                margin:
                    const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF171B20),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDateTimeOneLine(
                              session.dateTime,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit workout',
                          onPressed: () {
                            editSession(session);
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF0A84FF),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete workout',
                          onPressed: () {
                            deleteSession(session);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...List.generate(
                      session.sets.length,
                      (index) {
                        final set =
                            session.sets[index];

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'Set ${index + 1}',
                                  style:
                                      const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${weightForSet(set).toStringAsFixed(1)} $displayUnit',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (set.trackingMode == 'time')
                                Text(
                                  formatDurationSeconds(
                                    set.durationSeconds,
                                  ),
                                )
                              else
                                Text(
                                  '${set.reps} reps',
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (session.note.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        session.note,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ============================================================
// ADD / EDIT EXERCISE SESSION
// ============================================================

class AddExerciseSessionPage extends StatefulWidget {
  const AddExerciseSessionPage({
    super.key,
    required this.exerciseName,
    this.existingSession,
    this.initialTrackingMode = 'reps',
  });

  final String exerciseName;
  final ExerciseSession? existingSession;
  final String initialTrackingMode;

  @override
  State<AddExerciseSessionPage> createState() =>
      _AddExerciseSessionPageState();
}

class _SetInput {
  _SetInput({
    String weight = '',
    String value = '',
  })  : weightController =
            TextEditingController(text: weight),
        valueController =
            TextEditingController(text: value);

  final TextEditingController weightController;
  final TextEditingController valueController;

  Timer? timer;
  bool timerRunning = false;
  int elapsedSeconds = 0;

  void stopTimer() {
    timer?.cancel();
    timer = null;
    timerRunning = false;
  }

  void dispose() {
    stopTimer();
    weightController.dispose();
    valueController.dispose();
  }
}

class _AddExerciseSessionPageState
    extends State<AddExerciseSessionPage> {
  late String unit;
  late String trackingMode;
  late DateTime selectedDate;
  late TextEditingController noteController;
  late List<_SetInput> sets;

  bool get isEditing => widget.existingSession != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingSession;

    selectedDate =
        existing?.dateTime ?? DateTime.now();

    noteController = TextEditingController(
      text: existing?.note ?? '',
    );

    if (existing != null &&
        existing.sets.isNotEmpty) {
      trackingMode =
          existing.sets.first.trackingMode;
      unit = existing.sets.first.inputUnit;

      sets = existing.sets.map(
        (set) {
          final displayWeight = unit == 'kg'
              ? set.weightKg
              : set.weightLb;

          final value = trackingMode == 'time'
              ? set.durationSeconds.toString()
              : set.reps.toString();

          final input = _SetInput(
            weight:
                displayWeight.toStringAsFixed(1),
            value: value,
          );

          if (trackingMode == 'time') {
            input.elapsedSeconds =
                set.durationSeconds;
          }

          return input;
        },
      ).toList();
    } else {
      trackingMode =
          widget.initialTrackingMode;
      unit = 'lb';
      sets = [
        _SetInput(),
      ];
    }
  }

  @override
  void dispose() {
    noteController.dispose();

    for (final set in sets) {
      set.dispose();
    }

    super.dispose();
  }

  void stopAllTimers() {
    for (final set in sets) {
      set.stopTimer();
    }
  }

  void changeTrackingMode(String mode) {
    if (trackingMode == mode) return;

    stopAllTimers();

    setState(() {
      trackingMode = mode;

      for (final set in sets) {
        set.valueController.clear();
        set.elapsedSeconds = 0;
      }
    });
  }

  void addSet() {
    String previousWeight = '';
    String previousValue = '';

    if (sets.isNotEmpty) {
      previousWeight =
          sets.last.weightController.text;
      previousValue =
          sets.last.valueController.text;
    }

    setState(() {
      final input = _SetInput(
        weight: previousWeight,
        value: previousValue,
      );

      if (trackingMode == 'time') {
        input.elapsedSeconds =
            int.tryParse(previousValue) ?? 0;
      }

      sets.add(input);
    });
  }

  void removeSet(int index) {
    if (sets.length <= 1) return;

    final removed = sets.removeAt(index);
    removed.dispose();

    setState(() {});
  }

  void toggleTimer(int index) {
    final input = sets[index];

    if (input.timerRunning) {
      input.stopTimer();
      setState(() {});
      return;
    }

    input.elapsedSeconds =
        int.tryParse(
          input.valueController.text,
        ) ??
        0;

    input.timerRunning = true;

    input.timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          input.elapsedSeconds++;
          input.valueController.text =
              input.elapsedSeconds.toString();
        });
      },
    );

    setState(() {});
  }

  void resetTimer(int index) {
    final input = sets[index];

    input.stopTimer();

    setState(() {
      input.elapsedSeconds = 0;
      input.valueController.text = '0';
    });
  }

  Future<void> chooseDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(selectedDate),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void saveWorkout() {
    stopAllTimers();

    final completedSets =
        <ExerciseSetRecord>[];

    for (final input in sets) {
      final weight = double.tryParse(
        input.weightController.text,
      );

      final trackedValue = int.tryParse(
        input.valueController.text,
      );

      if (weight == null ||
          weight < 0 ||
          trackedValue == null ||
          trackedValue <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              trackingMode == 'time'
                  ? 'Enter a valid weight and time for every set.'
                  : 'Enter a valid weight and reps for every set.',
            ),
          ),
        );

        return;
      }

      late double weightLb;
      late double weightKg;

      if (unit == 'lb') {
        weightLb = weight;
        weightKg = weight / 2.20462;
      } else {
        weightKg = weight;
        weightLb = weight * 2.20462;
      }

      completedSets.add(
        ExerciseSetRecord(
          weightLb: weightLb,
          weightKg: weightKg,
          reps: trackingMode == 'reps'
              ? trackedValue
              : 0,
          durationSeconds:
              trackingMode == 'time'
                  ? trackedValue
                  : 0,
          trackingMode: trackingMode,
          inputUnit: unit,
        ),
      );
    }

    Navigator.pop(
      context,
      ExerciseSession(
        dateTime: selectedDate,
        sets: completedSets,
        note: noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit ${widget.exerciseName}'
              : widget.exerciseName,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isEditing
                ? 'Edit Workout'
                : 'Log Workout',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.exerciseName,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 22),
          ListTile(
            tileColor: const Color(0xFF171B20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading:
                const Icon(Icons.calendar_today),
            title: const Text('Date & Time'),
            subtitle: Text(
              formatDateTimeOneLine(selectedDate),
            ),
            trailing: const Icon(Icons.edit),
            onTap: chooseDateTime,
          ),
          const SizedBox(height: 20),
          const Text(
            'Track Sets By',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'reps',
                icon: Icon(Icons.repeat),
                label: Text('Reps'),
              ),
              ButtonSegment(
                value: 'time',
                icon: Icon(Icons.timer_outlined),
                label: Text('Time'),
              ),
            ],
            selected: {trackingMode},
            onSelectionChanged: (selection) {
              changeTrackingMode(
                selection.first,
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Weight Unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'lb',
                label: Text('lb'),
              ),
              ButtonSegment(
                value: 'kg',
                label: Text('kg'),
              ),
            ],
            selected: {unit},
            onSelectionChanged: (selection) {
              setState(() {
                unit = selection.first;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sets',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${sets.length} total',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            sets.length,
            (index) {
              final set = sets[index];

              return Container(
                margin:
                    const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF171B20),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Set ${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        if (sets.length > 1)
                          IconButton(
                            tooltip: 'Remove set',
                            onPressed: () {
                              removeSet(index);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller:
                                set.weightController,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Weight ($unit)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller:
                                set.valueController,
                            keyboardType:
                                TextInputType.number,
                            decoration:
                                InputDecoration(
                              labelText:
                                  trackingMode ==
                                          'time'
                                      ? 'Seconds'
                                      : 'Reps',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (trackingMode == 'time') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: const Color(
                                  0xFF11151A,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Text(
                                formatStopwatch(
                                  set.elapsedSeconds,
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () {
                              toggleTimer(index);
                            },
                            icon: Icon(
                              set.timerRunning
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              set.timerRunning
                                  ? 'Stop'
                                  : 'Start',
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Reset timer',
                            onPressed: () {
                              resetTimer(index);
                            },
                            icon: const Icon(
                              Icons.restart_alt,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: addSet,
            icon: const Icon(Icons.add),
            label: const Text('Add Set'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Workout Note',
              hintText:
                  'Felt strong, PR, slow reps...',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saveWorkout,
            icon: Icon(
              isEditing
                  ? Icons.check
                  : Icons.save,
            ),
            label: Padding(
              padding:
                  const EdgeInsets.all(14),
              child: Text(
                isEditing
                    ? 'Save Changes'
                    : 'Save Workout',
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================
// EXERCISE PROGRESS GRAPH
// ============================================================

class ExerciseSessionChartPainter
    extends CustomPainter {
  ExerciseSessionChartPainter({
    required this.sessions,
    required this.unit,
    required this.metricMode,
  });

  final List<ExerciseSession> sessions;
  final String unit;
  final String metricMode;

  double weight(ExerciseSetRecord set) {
    return unit == 'lb'
        ? set.weightLb
        : set.weightKg;
  }

  double sessionValue(ExerciseSession session) {
    if (session.sets.isEmpty) {
      return 0;
    }

    if (metricMode == 'time') {
      return session.sets
          .map(
            (set) =>
                set.durationSeconds.toDouble(),
          )
          .reduce((a, b) => a > b ? a : b);
    }

    return session.sets
        .map(weight)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;

    final values =
        sessions.map(sessionValue).toList();

    double min = values.reduce(
      (a, b) => a < b ? a : b,
    );

    double max = values.reduce(
      (a, b) => a > b ? a : b,
    );

    if (min == max) {
      final extra = metricMode == 'time'
          ? 10.0
          : 5.0;

      min -= extra;
      max += extra;
    }

    const padding = 20.0;

    final chartWidth =
        size.width - padding * 2;

    final chartHeight =
        size.height - padding * 2;

    final gridPaint = Paint()
      ..color =
          Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 4; i++) {
      final y =
          padding + chartHeight / 4 * i;

      canvas.drawLine(
        Offset(padding, y),
        Offset(
          size.width - padding,
          y,
        ),
        gridPaint,
      );
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0;
        i < sessions.length;
        i++) {
      final value = values[i];

      final x = sessions.length == 1
          ? size.width / 2
          : padding +
              i /
                  (sessions.length - 1) *
                  chartWidth;

      final normalized =
          (value - min) / (max - min);

      final y = padding +
          chartHeight -
          normalized * chartHeight;

      final point = Offset(x, y);

      points.add(point);

      if (i == 0) {
        path.moveTo(
          point.dx,
          point.dy,
        );
      } else {
        path.lineTo(
          point.dx,
          point.dy,
        );
      }
    }

    if (sessions.length > 1) {
      canvas.drawPath(
        path,
        linePaint,
      );
    }

    for (final point in points) {
      canvas.drawCircle(
        point,
        5,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant ExerciseSessionChartPainter
        oldDelegate,
  ) {
    return true;
  }
}


// ============================================================
// DIET
// ============================================================

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  static const meals = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  List<DietLogEntry> get dayEntries {
    final entries = AppStore.instance.dietLogs
        .where(
          (entry) => sameCalendarDay(
            entry.dateTime,
            selectedDate,
          ),
        )
        .toList()
      ..sort(
        (a, b) => a.dateTime.compareTo(b.dateTime),
      );

    return entries;
  }

  Future<void> addFood(String meal) async {
    final entry = await Navigator.push<DietLogEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodPickerPage(
          meal: meal,
          selectedDate: selectedDate,
        ),
      ),
    );

    if (entry == null) return;

    setState(() {
      AppStore.instance.dietLogs.add(entry);
    });

    await AppStore.instance.save();
  }

  Future<void> editFood(DietLogEntry entry) async {
    final updated = await Navigator.push<DietLogEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodAmountPage(
          food: entry.food,
          initialMeal: entry.meal,
          selectedDate: entry.dateTime,
          existingEntry: entry,
        ),
      ),
    );

    if (updated == null) return;

    final index = AppStore.instance.dietLogs.indexWhere(
      (item) => item.id == entry.id,
    );

    if (index == -1) return;

    setState(() {
      AppStore.instance.dietLogs[index] = updated;
    });

    await AppStore.instance.save();
  }

  Future<void> deleteFood(DietLogEntry entry) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete food entry?',
      message:
          'This will permanently remove ${entry.food.name} from this day.',
    );

    if (!confirmed) return;

    setState(() {
      AppStore.instance.dietLogs.removeWhere(
        (item) => item.id == entry.id,
      );
    });

    await AppStore.instance.save();
  }

  Future<void> editGoals() async {
    final current = AppStore.instance.dietGoals;

    final caloriesController = TextEditingController(
      text: current.calories.toStringAsFixed(0),
    );
    final proteinController = TextEditingController(
      text: current.protein.toStringAsFixed(0),
    );
    final carbsController = TextEditingController(
      text: current.carbs.toStringAsFixed(0),
    );
    final fatController = TextEditingController(
      text: current.fat.toStringAsFixed(0),
    );

    final result = await showDialog<DietGoals>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171B20),
          title: const Text('Daily Diet Goals'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: caloriesController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    suffixText: 'kcal',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: proteinController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Protein',
                    suffixText: 'g',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: carbsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Carbs',
                    suffixText: 'g',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fat',
                    suffixText: 'g',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final calories =
                    double.tryParse(caloriesController.text);
                final protein =
                    double.tryParse(proteinController.text);
                final carbs =
                    double.tryParse(carbsController.text);
                final fat =
                    double.tryParse(fatController.text);

                if (calories == null ||
                    calories <= 0 ||
                    protein == null ||
                    protein < 0 ||
                    carbs == null ||
                    carbs < 0 ||
                    fat == null ||
                    fat < 0) {
                  return;
                }

                Navigator.pop(
                  context,
                  DietGoals(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();

    if (result == null) return;

    setState(() {
      AppStore.instance.dietGoals = result;
    });

    await AppStore.instance.save();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
      );
    });
  }

  void moveDay(int amount) {
    setState(() {
      selectedDate = selectedDate.add(
        Duration(days: amount),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final goals = AppStore.instance.dietGoals;
    final entries = dayEntries;

    final calories = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.calories,
    );
    final protein = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.protein,
    );
    final carbs = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.carbs,
    );
    final fat = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.fat,
    );

    final remaining = goals.calories - calories;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          90,
        ),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Diet',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Daily goals',
                onPressed: editGoals,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF171B20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: () => moveDay(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                    ),
                    label: Text(
                      dietDateLabel(selectedDate),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: () => moveDay(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF171B20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calories',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${calories.toStringAsFixed(0)} / ${goals.calories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      remaining >= 0
                          ? '${remaining.toStringAsFixed(0)} left'
                          : '${(-remaining).toStringAsFixed(0)} over',
                      style: TextStyle(
                        color: remaining >= 0
                            ? Colors.white70
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progressValue(
                    calories,
                    goals.calories,
                  ),
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor:
                      Colors.white.withOpacity(0.08),
                ),
                const SizedBox(height: 18),
                MacroProgressRow(
                  name: 'Protein',
                  current: protein,
                  target: goals.protein,
                  suffix: 'g',
                ),
                const SizedBox(height: 12),
                MacroProgressRow(
                  name: 'Carbs',
                  current: carbs,
                  target: goals.carbs,
                  suffix: 'g',
                ),
                const SizedBox(height: 12),
                MacroProgressRow(
                  name: 'Fat',
                  current: fat,
                  target: goals.fat,
                  suffix: 'g',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...meals.map(
            (meal) {
              final mealEntries = entries
                  .where(
                    (entry) => entry.meal == meal,
                  )
                  .toList();

              final mealCalories =
                  mealEntries.fold<double>(
                0,
                (sum, entry) =>
                    sum + entry.calories,
              );

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF171B20),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          14,
                          10,
                          8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                meal,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${mealCalories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Add food',
                              onPressed: () {
                                addFood(meal);
                              },
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color:
                                    Color(0xFF0A84FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mealEntries.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          child: Align(
                            alignment:
                                Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                addFood(meal);
                              },
                              icon:
                                  const Icon(Icons.add),
                              label:
                                  const Text('Add Food'),
                            ),
                          ),
                        )
                      else
                        ...mealEntries.map(
                          (entry) {
                            return Column(
                              children: [
                                const Divider(
                                  height: 1,
                                ),
                                ListTile(
                                  onTap: () {
                                    editFood(entry);
                                  },
                                  title: Text(
                                    entry.food.name,
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis,
                                  ),
                                  subtitle: Text(
                                    foodEntrySubtitle(
                                      entry,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow
                                        .ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${entry.calories.toStringAsFixed(0)} kcal',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      PopupMenuButton<
                                          String>(
                                        onSelected:
                                            (value) {
                                          if (value ==
                                              'edit') {
                                            editFood(
                                                entry);
                                          } else if (value ==
                                              'delete') {
                                            deleteFood(
                                                entry);
                                          }
                                        },
                                        itemBuilder:
                                            (context) => const [
                                          PopupMenuItem(
                                            value:
                                                'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons
                                                    .edit_outlined),
                                                SizedBox(
                                                    width:
                                                        10),
                                                Text(
                                                    'Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value:
                                                'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .delete_outline,
                                                  color: Colors
                                                      .redAccent,
                                                ),
                                                SizedBox(
                                                    width:
                                                        10),
                                                Text(
                                                  'Delete',
                                                  style:
                                                      TextStyle(
                                                    color: Colors
                                                        .redAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Food search powered by Open Food Facts',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIET - FOOD PICKER
// ============================================================

class FoodPickerPage extends StatefulWidget {
  const FoodPickerPage({
    super.key,
    required this.meal,
    required this.selectedDate,
  });

  final String meal;
  final DateTime selectedDate;

  @override
  State<FoodPickerPage> createState() =>
      _FoodPickerPageState();
}

class _FoodPickerPageState
    extends State<FoodPickerPage> {
  final searchController = TextEditingController();

  bool searching = false;
  String searchMessage = '';
  List<FoodDefinition> searchResults = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<FoodDefinition> recentFoods() {
    final logs =
        List<DietLogEntry>.from(
          AppStore.instance.dietLogs,
        )
          ..sort(
            (a, b) =>
                b.dateTime.compareTo(a.dateTime),
          );

    final result = <FoodDefinition>[];
    final seen = <String>{};

    for (final log in logs) {
      final food = log.food;
      final key =
          '${food.name.toLowerCase()}|${food.brand.toLowerCase()}|${food.servingLabel.toLowerCase()}';

      if (!seen.add(key)) continue;

      result.add(food.copy());

      if (result.length >= 30) break;
    }

    return result;
  }

  Future<void> search() async {
    final query = searchController.text.trim();

    if (query.length < 2) {
      setState(() {
        searchResults = [];
        searchMessage =
            'Type at least 2 characters.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      searching = true;
      searchMessage = '';
      searchResults = [];
    });

    try {
      final results =
          await OpenFoodFactsService.search(query);

      if (!mounted) return;

      setState(() {
        searchResults = results;
        searchMessage = results.isEmpty
            ? 'No foods found. Try another search or add a custom food.'
            : '';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        searchMessage =
            'Could not search the food database. Check your internet connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          searching = false;
        });
      }
    }
  }

  Future<void> selectFood(
    FoodDefinition food,
  ) async {
    final entry =
        await Navigator.push<DietLogEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodAmountPage(
          food: food,
          initialMeal: widget.meal,
          selectedDate: widget.selectedDate,
        ),
      ),
    );

    if (entry == null || !mounted) return;

    Navigator.pop(context, entry);
  }

  Future<void> createCustomFood() async {
    final food =
        await Navigator.push<FoodDefinition>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CreateCustomFoodPage(),
      ),
    );

    if (food == null) return;

    AppStore.instance.customFoods.add(food);
    await AppStore.instance.save();

    if (!mounted) return;

    setState(() {});

    await selectFood(food);
  }

  Future<void> deleteCustomFood(
    FoodDefinition food,
  ) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete custom food?',
      message:
          'This removes ${food.name} from your custom foods. Existing diary entries will stay saved.',
    );

    if (!confirmed) return;

    setState(() {
      AppStore.instance.customFoods.remove(food);
    });

    await AppStore.instance.save();
  }

  Widget foodTile(FoodDefinition food) {
    return ListTile(
      onTap: () => selectFood(food),
      title: Text(
        food.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (food.brand.isNotEmpty) food.brand,
          '${food.calories.toStringAsFixed(0)} kcal • P ${food.protein.toStringAsFixed(1)}g • C ${food.carbs.toStringAsFixed(1)}g • F ${food.fat.toStringAsFixed(1)}g',
          'per ${food.servingLabel}',
        ].join('\n'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(
        Icons.chevron_right,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recent = recentFoods();
    final custom =
        AppStore.instance.customFoods;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add to ${widget.meal}'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.search),
                text: 'Search',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Recent',
              ),
              Tab(
                icon: Icon(Icons.bookmark_outline),
                text: 'Custom',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              searchController,
                          autofocus: true,
                          textInputAction:
                              TextInputAction.search,
                          onSubmitted: (_) =>
                              search(),
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Search foods',
                            hintText:
                                'Greek yogurt, chicken breast...',
                            prefixIcon:
                                Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed:
                            searching ? null : search,
                        child: searching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                ),
                if (searchMessage.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      12,
                    ),
                    child: Text(
                      searchMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              30,
                            ),
                            child: Text(
                              searching
                                  ? 'Searching...'
                                  : 'Search the Open Food Facts database, or use the Custom tab to add your own food.',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                              searchResults.length,
                          separatorBuilder:
                              (_, __) =>
                                  const Divider(
                            height: 1,
                          ),
                          itemBuilder:
                              (context, index) {
                            return foodTile(
                              searchResults[index],
                            );
                          },
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Nutrition data is community-maintained. Check the product label when accuracy matters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            recent.isEmpty
                ? const Center(
                    child: Text(
                      'Foods you log will appear here.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: recent.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder:
                        (context, index) {
                      return foodTile(
                        recent[index],
                      );
                    },
                  ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          createCustomFood,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Create Custom Food',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: custom.isEmpty
                      ? const Center(
                          child: Text(
                            'No custom foods yet.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                              custom.length,
                          separatorBuilder:
                              (_, __) =>
                                  const Divider(
                            height: 1,
                          ),
                          itemBuilder:
                              (context, index) {
                            final food =
                                custom[index];

                            return ListTile(
                              onTap: () {
                                selectFood(food);
                              },
                              title: Text(
                                food.name,
                              ),
                              subtitle: Text(
                                '${food.calories.toStringAsFixed(0)} kcal • ${food.servingLabel}',
                              ),
                              trailing: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons
                                        .chevron_right,
                                  ),
                                  IconButton(
                                    tooltip:
                                        'Delete custom food',
                                    onPressed: () {
                                      deleteCustomFood(
                                        food,
                                      );
                                    },
                                    icon:
                                        const Icon(
                                      Icons
                                          .delete_outline,
                                      color: Colors
                                          .redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DIET - FOOD AMOUNT / EDIT ENTRY
// ============================================================

class FoodAmountPage extends StatefulWidget {
  const FoodAmountPage({
    super.key,
    required this.food,
    required this.initialMeal,
    required this.selectedDate,
    this.existingEntry,
  });

  final FoodDefinition food;
  final String initialMeal;
  final DateTime selectedDate;
  final DietLogEntry? existingEntry;

  @override
  State<FoodAmountPage> createState() =>
      _FoodAmountPageState();
}

class _FoodAmountPageState extends State<FoodAmountPage> {
  late TextEditingController amountController;
  late TextEditingController gramsPerUnitController;
  late String meal;
  late DateTime dateTime;
  late String amountMode;
  late String quantityUnit;

  static const quantityUnits = <String>[
    'item',
    'egg',
    'slice',
    'piece',
    'bar',
    'scoop',
    'bottle',
    'can',
    'packet',
    'cup',
    'tbsp',
    'tsp',
    'oz',
    'mL',
  ];

  bool get isEditing => widget.existingEntry != null;
  bool get canUseWeightConversion =>
      widget.food.gramsPerServing != null &&
      widget.food.gramsPerServing! > 0;

  @override
  void initState() {
    super.initState();

    meal = widget.existingEntry?.meal ?? widget.initialMeal;

    final existing = widget.existingEntry;

    if (existing?.quantity != null &&
        existing?.quantityUnit != null) {
      if (existing!.quantityUnit == 'g') {
        amountMode = 'Grams';
        quantityUnit = 'item';
      } else {
        amountMode = 'Quantity';
        quantityUnit = existing.quantityUnit!;
      }

      amountController = TextEditingController(
        text: trimDouble(existing.quantity!),
      );

      gramsPerUnitController = TextEditingController(
        text: existing.gramsPerUnit == null
            ? suggestedGramsPerUnit(widget.food).toStringAsFixed(0)
            : trimDouble(existing.gramsPerUnit!),
      );
    } else {
      // Keep older saved entries in their original Servings mode. New
      // countable foods such as eggs can open in Quantity mode automatically.
      final suggestion = existing == null
          ? suggestedQuantityUnit(widget.food)
          : null;

      amountMode = suggestion == null ? 'Servings' : 'Quantity';
      quantityUnit = suggestion ?? 'item';

      amountController = TextEditingController(
        text: existing == null ? '1' : trimDouble(existing.servings),
      );

      gramsPerUnitController = TextEditingController(
        text: suggestion == null
            ? ''
            : trimDouble(suggestedGramsPerUnit(widget.food)),
      );
    }

    if (widget.existingEntry != null) {
      dateTime = widget.existingEntry!.dateTime;
    } else {
      final now = DateTime.now();
      dateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        now.hour,
        now.minute,
      );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    gramsPerUnitController.dispose();
    super.dispose();
  }

  double get amount =>
      double.tryParse(amountController.text.trim()) ?? 0;

  double get gramsPerUnit =>
      double.tryParse(gramsPerUnitController.text.trim()) ?? 0;

  double get nutritionMultiplier {
    if (amountMode == 'Servings') {
      return amount;
    }

    final baseGrams = widget.food.gramsPerServing;
    if (baseGrams == null || baseGrams <= 0) return 0;

    if (amountMode == 'Grams') {
      return amount / baseGrams;
    }

    return (amount * gramsPerUnit) / baseGrams;
  }

  double get totalGrams {
    if (amountMode == 'Grams') return amount;
    if (amountMode == 'Quantity') return amount * gramsPerUnit;

    final base = widget.food.gramsPerServing;
    return base == null ? 0 : amount * base;
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() {
      dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        dateTime.hour,
        dateTime.minute,
      );
    });
  }

  void setAmount(double value) {
    setState(() {
      amountController.text = trimDouble(value);
    });
  }

  void setMode(String mode) {
    if (mode != 'Servings' && !canUseWeightConversion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This food needs a serving weight before Quantity or Grams can be used. Create a custom food and add a serving weight.',
          ),
        ),
      );
      return;
    }

    setState(() {
      amountMode = mode;

      if (mode == 'Quantity' && gramsPerUnit <= 0) {
        final suggested = suggestedGramsPerUnit(widget.food);
        if (suggested > 0) {
          gramsPerUnitController.text = trimDouble(suggested);
        }
      }
    });
  }

  void save() {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amountMode == 'Quantity'
                ? 'Enter a quantity greater than 0.'
                : amountMode == 'Grams'
                    ? 'Enter grams greater than 0.'
                    : 'Enter a serving amount greater than 0.',
          ),
        ),
      );
      return;
    }

    if (amountMode == 'Quantity' && gramsPerUnit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the weight of one item in grams so nutrition can be calculated accurately.',
          ),
        ),
      );
      return;
    }

    final multiplier = nutritionMultiplier;
    if (multiplier <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to calculate nutrition for this amount.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      DietLogEntry(
        id: widget.existingEntry?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        food: widget.food.copy(),
        meal: meal,
        dateTime: dateTime,
        servings: multiplier,
        quantity: amountMode == 'Servings' ? null : amount,
        quantityUnit: amountMode == 'Servings'
            ? null
            : amountMode == 'Grams'
                ? 'g'
                : quantityUnit,
        gramsPerUnit: amountMode == 'Quantity'
            ? gramsPerUnit
            : amountMode == 'Grams'
                ? 1
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = nutritionMultiplier;
    final calories = widget.food.calories * multiplier;
    final protein = widget.food.protein * multiplier;
    final carbs = widget.food.carbs * multiplier;
    final fat = widget.food.fat * multiplier;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Food' : 'Add Food'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.food.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.food.brand.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.food.brand,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171B20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NutritionNumber(
                        label: 'Protein',
                        value: '${protein.toStringAsFixed(1)} g',
                      ),
                    ),
                    Expanded(
                      child: NutritionNumber(
                        label: 'Carbs',
                        value: '${carbs.toStringAsFixed(1)} g',
                      ),
                    ),
                    Expanded(
                      child: NutritionNumber(
                        label: 'Fat',
                        value: '${fat.toStringAsFixed(1)} g',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How do you want to enter it?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Servings',
                label: Text('Servings'),
                icon: Icon(Icons.restaurant),
              ),
              ButtonSegment(
                value: 'Quantity',
                label: Text('Quantity'),
                icon: Icon(Icons.numbers),
              ),
              ButtonSegment(
                value: 'Grams',
                label: Text('Grams'),
                icon: Icon(Icons.scale_outlined),
              ),
            ],
            selected: {amountMode},
            onSelectionChanged: (selection) {
              setMode(selection.first);
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: amountMode == 'Quantity'
                  ? 'Quantity'
                  : amountMode == 'Grams'
                      ? 'Weight'
                      : 'Servings',
              suffixText: amountMode == 'Grams' ? 'g' : null,
              helperText: amountMode == 'Servings'
                  ? '1 serving = ${widget.food.servingLabel}'
                  : null,
            ),
          ),
          if (amountMode == 'Quantity') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: quantityUnits.contains(quantityUnit)
                  ? quantityUnit
                  : 'item',
              decoration: const InputDecoration(
                labelText: 'Unit',
              ),
              items: quantityUnits
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(quantityUnitName(unit, 2)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  quantityUnit = value;

                  final suggested = suggestedGramsForUnit(
                    widget.food,
                    value,
                  );
                  if (suggested > 0) {
                    gramsPerUnitController.text = trimDouble(suggested);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gramsPerUnitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Weight of 1 $quantityUnit',
                suffixText: 'g',
                helperText:
                    'Editable because item sizes vary by brand and food.',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in amountMode == 'Quantity'
                  ? [1.0, 2.0, 3.0, 4.0]
                  : amountMode == 'Grams'
                      ? [50.0, 100.0, 150.0, 200.0]
                      : [0.5, 1.0, 1.5, 2.0])
                ChoiceChip(
                  label: Text(
                    amountMode == 'Grams'
                        ? '${trimDouble(value)} g'
                        : trimDouble(value),
                  ),
                  selected: (amount - value).abs() < 0.0001,
                  onSelected: (_) => setAmount(value),
                ),
            ],
          ),
          if (amountMode != 'Servings' && totalGrams > 0) ...[
            const SizedBox(height: 14),
            Text(
              amountMode == 'Quantity'
                  ? '${trimDouble(amount)} ${quantityUnitName(quantityUnit, amount)} ≈ ${trimDouble(totalGrams)} g total'
                  : '${trimDouble(totalGrams)} g total',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: meal,
            decoration: const InputDecoration(labelText: 'Meal'),
            items: const [
              DropdownMenuItem(
                value: 'Breakfast',
                child: Text('Breakfast'),
              ),
              DropdownMenuItem(
                value: 'Lunch',
                child: Text('Lunch'),
              ),
              DropdownMenuItem(
                value: 'Dinner',
                child: Text('Dinner'),
              ),
              DropdownMenuItem(
                value: 'Snacks',
                child: Text('Snacks'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => meal = value);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xFF171B20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(formatShortDate(dateTime)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: chooseDate,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: save,
            icon: Icon(isEditing ? Icons.check : Icons.add),
            label: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                isEditing ? 'Save Changes' : 'Add to Diary',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.food.source == 'Open Food Facts'
                ? 'Source: Open Food Facts • database nutrition is based on ${widget.food.servingLabel}. Quantity conversions use the item weight shown above.'
                : 'Custom food • nutrition is based on ${widget.food.servingLabel}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIET - CREATE CUSTOM FOOD
// ============================================================

class CreateCustomFoodPage extends StatefulWidget {
  const CreateCustomFoodPage({super.key});

  @override
  State<CreateCustomFoodPage> createState() =>
      _CreateCustomFoodPageState();
}

class _CreateCustomFoodPageState extends State<CreateCustomFoodPage> {
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final servingController = TextEditingController(text: '1 serving');
  final servingWeightController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    servingController.dispose();
    servingWeightController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }

  void save() {
    final name = nameController.text.trim();
    final serving = servingController.text.trim();
    final servingWeightText = servingWeightController.text.trim();
    final servingWeight = servingWeightText.isEmpty
        ? null
        : double.tryParse(servingWeightText);
    final calories = double.tryParse(caloriesController.text);
    final protein = double.tryParse(proteinController.text);
    final carbs = double.tryParse(carbsController.text);
    final fat = double.tryParse(fatController.text);

    if (name.isEmpty ||
        serving.isEmpty ||
        calories == null ||
        calories < 0 ||
        protein == null ||
        protein < 0 ||
        carbs == null ||
        carbs < 0 ||
        fat == null ||
        fat < 0 ||
        (servingWeightText.isNotEmpty &&
            (servingWeight == null || servingWeight <= 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fill in all nutrition fields with valid values. Serving weight can be left blank.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      FoodDefinition(
        name: name,
        brand: brandController.text.trim(),
        servingLabel: serving,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        source: 'Custom',
        gramsPerServing: servingWeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Food')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Food name',
              hintText: 'Protein Shake',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: brandController,
            decoration: const InputDecoration(
              labelText: 'Brand (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: servingController,
            decoration: const InputDecoration(
              labelText: 'Serving',
              hintText: '1 scoop, 1 slice, 250 mL, 1 bar...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: servingWeightController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Serving weight (optional)',
              suffixText: 'g',
              helperText:
                  'Add this if you want Quantity/Grams logging for this custom food.',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nutrition per serving',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: caloriesController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Calories',
              suffixText: 'kcal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: proteinController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Protein',
              suffixText: 'g',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: carbsController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Carbs',
              suffixText: 'g',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: fatController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Fat',
              suffixText: 'g',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Save Custom Food'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIET WIDGETS
// ============================================================

class MacroProgressRow extends StatelessWidget {
  const MacroProgressRow({
    super.key,
    required this.name,
    required this.current,
    required this.target,
    required this.suffix,
  });

  final String name;
  final double current;
  final double target;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value:
                progressValue(current, target),
            minHeight: 7,
            borderRadius:
                BorderRadius.circular(20),
            backgroundColor:
                Colors.white.withOpacity(0.08),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $suffix',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class NutritionNumber extends StatelessWidget {
  const NutritionNumber({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}


// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171B20),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.dark_mode),
                    title:
                        Text('Appearance'),
                    subtitle:
                        Text('Dark Mode'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.monitor_weight,
                    ),
                    title: Text(
                      'Default Weight Unit',
                    ),
                    subtitle: Text('lb'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading:
                        Icon(Icons.storage),
                    title:
                        Text('Storage'),
                    subtitle: Text(
                      'Permanent local device storage',
                    ),
                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CARDS
// ============================================================

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171B20),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressStatCard
    extends StatelessWidget {
  const ProgressStatCard({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF171B20),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


double progressValue(
  double current,
  double target,
) {
  if (target <= 0) return 0;

  return (current / target)
      .clamp(0.0, 1.0)
      .toDouble();
}

bool sameCalendarDay(
  DateTime a,
  DateTime b,
) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

String dietDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );
  final selected = DateTime(
    date.year,
    date.month,
    date.day,
  );

  if (selected == today) {
    return 'Today • ${formatShortDate(date)}';
  }

  if (selected ==
      today.subtract(
        const Duration(days: 1),
      )) {
    return 'Yesterday • ${formatShortDate(date)}';
  }

  if (selected ==
      today.add(
        const Duration(days: 1),
      )) {
    return 'Tomorrow • ${formatShortDate(date)}';
  }

  return formatShortDate(date);
}

String trimDouble(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2).replaceFirst(
        RegExp(r'0+$'),
        '',
      );
}

double? gramsFromServingLabel(String label) {
  final match = RegExp(
    r'([0-9]+(?:\.[0-9]+)?)\s*g\b',
    caseSensitive: false,
  ).firstMatch(label);

  if (match == null) return null;
  return double.tryParse(match.group(1) ?? '');
}

String foodEntrySubtitle(DietLogEntry entry) {
  String amountText;

  if (entry.quantity != null && entry.quantityUnit != null) {
    final unit = quantityUnitName(entry.quantityUnit!, entry.quantity!);
    amountText = '${trimDouble(entry.quantity!)} $unit';

    if (entry.quantityUnit != 'g' &&
        entry.gramsPerUnit != null &&
        entry.gramsPerUnit! > 0) {
      final grams = entry.quantity! * entry.gramsPerUnit!;
      amountText += ' • ${trimDouble(grams)} g';
    }
  } else {
    amountText =
        '${trimDouble(entry.servings)} × ${entry.food.servingLabel}';
  }

  final macroText =
      'P ${entry.protein.toStringAsFixed(1)}g • C ${entry.carbs.toStringAsFixed(1)}g • F ${entry.fat.toStringAsFixed(1)}g';

  if (entry.food.brand.isEmpty) {
    return '$amountText\n$macroText';
  }

  return '${entry.food.brand} • $amountText\n$macroText';
}

String quantityUnitName(String unit, double quantity) {
  final plural = quantity.abs() != 1;

  switch (unit) {
    case 'item':
      return plural ? 'items' : 'item';
    case 'egg':
      return plural ? 'eggs' : 'egg';
    case 'slice':
      return plural ? 'slices' : 'slice';
    case 'piece':
      return plural ? 'pieces' : 'piece';
    case 'bar':
      return plural ? 'bars' : 'bar';
    case 'scoop':
      return plural ? 'scoops' : 'scoop';
    case 'bottle':
      return plural ? 'bottles' : 'bottle';
    case 'can':
      return plural ? 'cans' : 'can';
    case 'packet':
      return plural ? 'packets' : 'packet';
    case 'cup':
      return plural ? 'cups' : 'cup';
    case 'tbsp':
      return 'tbsp';
    case 'tsp':
      return 'tsp';
    case 'oz':
      return 'oz';
    case 'mL':
      return 'mL';
    case 'g':
      return 'g';
    default:
      return unit;
  }
}

String? suggestedQuantityUnit(FoodDefinition food) {
  if (food.gramsPerServing == null || food.gramsPerServing! <= 0) {
    return null;
  }

  final name = food.name.toLowerCase();
  final serving = food.servingLabel.toLowerCase();

  if (RegExp(r'\beggs?\b').hasMatch(name) ||
      RegExp(r'\beggs?\b').hasMatch(serving)) {
    return 'egg';
  }
  if (serving.contains('slice')) return 'slice';
  if (serving.contains('piece')) return 'piece';
  if (serving.contains('bar')) return 'bar';
  if (serving.contains('scoop')) return 'scoop';
  if (serving.contains('bottle')) return 'bottle';
  if (RegExp(r'\bcan\b').hasMatch(serving)) return 'can';
  if (serving.contains('packet')) return 'packet';
  if (name.contains('banana')) return 'item';
  if (RegExp(r'\bapple\b').hasMatch(name)) return 'item';
  if (RegExp(r'\borange\b').hasMatch(name)) return 'item';

  return null;
}

double suggestedGramsPerUnit(FoodDefinition food) {
  final unit = suggestedQuantityUnit(food) ?? 'item';
  return suggestedGramsForUnit(food, unit);
}

double suggestedGramsForUnit(FoodDefinition food, String unit) {
  final name = food.name.toLowerCase();

  final serving = food.servingLabel.toLowerCase();
  final baseGrams = food.gramsPerServing;

  if (baseGrams != null && baseGrams > 0) {
    final matchesServingUnit =
        (unit == 'egg' && RegExp(r'\beggs?\b').hasMatch(serving)) ||
        (unit == 'slice' && serving.contains('slice')) ||
        (unit == 'piece' && serving.contains('piece')) ||
        (unit == 'bar' && serving.contains('bar')) ||
        (unit == 'scoop' && serving.contains('scoop')) ||
        (unit == 'bottle' && serving.contains('bottle')) ||
        (unit == 'can' && RegExp(r'\bcan\b').hasMatch(serving)) ||
        (unit == 'packet' && serving.contains('packet'));

    if (matchesServingUnit) return baseGrams;
  }

  if (unit == 'egg') return 50;
  if (unit == 'oz') return 28.3495;

  // These volume conversions are only starting points. The amount stays
  // editable because food density and product size can vary.
  if (unit == 'tbsp') return 15;
  if (unit == 'tsp') return 5;
  if (unit == 'mL') return 1;
  if (unit == 'cup') return 240;

  if (unit == 'item') {
    if (name.contains('banana')) return 118;
    if (RegExp(r'\bapple\b').hasMatch(name)) return 182;
    if (RegExp(r'\borange\b').hasMatch(name)) return 131;
  }

  return 0;
}

// ============================================================
// CONFIRMATION / TIMER HELPERS
// ============================================================

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF171B20),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

String formatDurationSeconds(int totalSeconds) {
  if (totalSeconds < 60) {
    return '${totalSeconds}s';
  }

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (seconds == 0) {
    return '${minutes}m';
  }

  return '${minutes}m ${seconds}s';
}

String formatStopwatch(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

// ============================================================
// DATE HELPERS
// ============================================================

String formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatDateTime(DateTime date) {
  int hour = date.hour;

  final amPm =
      hour >= 12 ? 'PM' : 'AM';

  if (hour == 0) {
    hour = 12;
  } else if (hour > 12) {
    hour -= 12;
  }

  final minute = date.minute
      .toString()
      .padLeft(2, '0');

  return '${formatShortDate(date)}\n$hour:$minute $amPm';
}

String formatDateTimeOneLine(
  DateTime date,
) {
  return formatDateTime(date)
      .replaceAll('\n', ' • ');
}
