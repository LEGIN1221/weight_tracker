import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

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

  Future<void> initialize() async {
    _box = await Hive.openBox('fitness_tracker_data');

    final savedWeightPlans = _box.get('weightPlans');
    final savedWorkoutDays = _box.get('workoutDays');

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
    required this.reps,
  });

  double weightLb;
  double weightKg;
  int reps;

  Map<String, dynamic> toJson() {
    return {
      'weightLb': weightLb,
      'weightKg': weightKg,
      'reps': reps,
    };
  }

  factory ExerciseSetRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseSetRecord(
      weightLb: (json['weightLb'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
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

  double sessionTopWeight(ExerciseSession session) {
    if (session.sets.isEmpty) {
      return 0;
    }

    return session.sets
        .map(weightForSet)
        .reduce((a, b) => a > b ? a : b);
  }

  double? heaviestWeight() {
    final sets = widget.exercise.sessions
        .expand((session) => session.sets)
        .toList();

    if (sets.isEmpty) return null;

    return sets
        .map(weightForSet)
        .reduce((a, b) => a > b ? a : b);
  }

  Future<void> logWorkout() async {
    final session =
        await Navigator.push<ExerciseSession>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExerciseSessionPage(
          exerciseName: widget.exercise.name,
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

  Future<void> deleteSession(
    ExerciseSession session,
  ) async {
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

    final chronological =
        List<ExerciseSession>.from(
          widget.exercise.sessions,
        )
          ..sort(
            (a, b) =>
                a.dateTime.compareTo(b.dateTime),
          );

    final heaviest = heaviestWeight();

    double? latestWeight;

    if (sessions.isNotEmpty) {
      latestWeight =
          sessionTopWeight(sessions.first);
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
                  title: 'Latest',
                  value: latestWeight == null
                      ? '—'
                      : '${latestWeight.toStringAsFixed(1)} $displayUnit',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProgressStatCard(
                  title: 'Heaviest',
                  value: heaviest == null
                      ? '—'
                      : '${heaviest.toStringAsFixed(1)} $displayUnit',
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
                const Text(
                  'Heaviest Set Over Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: chronological.isEmpty
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
                            sessions: chronological,
                            unit: displayUnit,
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
// ADD EXERCISE SESSION
// ============================================================

class AddExerciseSessionPage extends StatefulWidget {
  const AddExerciseSessionPage({
    super.key,
    required this.exerciseName,
  });

  final String exerciseName;

  @override
  State<AddExerciseSessionPage> createState() =>
      _AddExerciseSessionPageState();
}

class _SetInput {
  _SetInput({
    String weight = '',
    String reps = '',
  })  : weightController =
            TextEditingController(text: weight),
        repsController =
            TextEditingController(text: reps);

  final TextEditingController weightController;
  final TextEditingController repsController;

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class _AddExerciseSessionPageState
    extends State<AddExerciseSessionPage> {
  String unit = 'lb';

  DateTime selectedDate = DateTime.now();

  final noteController = TextEditingController();

  final List<_SetInput> sets = [
    _SetInput(),
  ];

  @override
  void dispose() {
    noteController.dispose();

    for (final set in sets) {
      set.dispose();
    }

    super.dispose();
  }

  void addSet() {
    String previousWeight = '';
    String previousReps = '';

    if (sets.isNotEmpty) {
      previousWeight =
          sets.last.weightController.text;

      previousReps =
          sets.last.repsController.text;
    }

    setState(() {
      sets.add(
        _SetInput(
          weight: previousWeight,
          reps: previousReps,
        ),
      );
    });
  }

  void removeSet(int index) {
    if (sets.length <= 1) return;

    final removed = sets.removeAt(index);

    removed.dispose();

    setState(() {});
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
    final completedSets =
        <ExerciseSetRecord>[];

    for (final input in sets) {
      final weight = double.tryParse(
        input.weightController.text,
      );

      final reps = int.tryParse(
        input.repsController.text,
      );

      if (weight == null ||
          weight < 0 ||
          reps == null ||
          reps <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid weight and reps for every set.',
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
          reps: reps,
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
        title: Text(widget.exerciseName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Log Workout',
            style: TextStyle(
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
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
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
                            set.repsController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText: 'Reps',
                        ),
                      ),
                    ),
                    if (sets.length > 1)
                      IconButton(
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
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Save Workout',
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
  });

  final List<ExerciseSession> sessions;
  final String unit;

  double weight(ExerciseSetRecord set) {
    return unit == 'lb'
        ? set.weightLb
        : set.weightKg;
  }

  double sessionMax(ExerciseSession session) {
    if (session.sets.isEmpty) {
      return 0;
    }

    return session.sets
        .map(weight)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;

    final values =
        sessions.map(sessionMax).toList();

    double min = values.reduce(
      (a, b) => a < b ? a : b,
    );

    double max = values.reduce(
      (a, b) => a > b ? a : b,
    );

    if (min == max) {
      min -= 5;
      max += 5;
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
