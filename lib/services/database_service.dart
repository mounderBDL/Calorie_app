import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'foodlens.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            calories REAL NOT NULL,
            protein REAL NOT NULL,
            carbs REAL NOT NULL,
            fat REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE food_ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_class_name TEXT NOT NULL,
            ingredient_name TEXT NOT NULL,
            default_grams REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE meal_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            food_class_name TEXT NOT NULL,
            food_display_name TEXT NOT NULL,
            total_calories REAL NOT NULL,
            total_protein REAL NOT NULL,
            total_carbs REAL NOT NULL,
            total_fat REAL NOT NULL,
            logged_at TEXT NOT NULL
          )
        ''');
        await _seedData(db);
      },
    );
  }

  // ── Get default ingredients for a food class ──
  Future<List<Ingredient>> getIngredientsForFood(String className) async {
    final db = await database;
    final foodIngRows = await db.query(
      'food_ingredients',
      where: 'food_class_name = ?',
      whereArgs: [className],
    );
    if (foodIngRows.isEmpty) return _fallbackIngredients(className);

    final List<Ingredient> result = [];
    for (final row in foodIngRows) {
      final ingName    = row['ingredient_name'] as String;
      final defaultGrams = row['default_grams'] as double;
      final ingRows    = await db.query(
        'ingredients',
        where: 'name = ?',
        whereArgs: [ingName],
      );
      if (ingRows.isNotEmpty) {
        final ing = ingRows.first;
        result.add(Ingredient(
          id:       ing['id'] as int,
          name:     ing['name'] as String,
          calories: ing['calories'] as double,
          protein:  ing['protein'] as double,
          carbs:    ing['carbs'] as double,
          fat:      ing['fat'] as double,
          grams:    defaultGrams,
        ));
      }
    }
    return result;
  }

  // ── Log a meal ────────────────────────────────
  Future<void> logMeal(MealLog log, {required String userId}) async {
    final db = await database;
    await db.insert('meal_logs', {
      ...log.toMap(),
      'user_id': userId,
    });
  }

  // ── Get meal history ──────────────────────────
  Future<List<MealLog>> getMealHistory({
    required String userId,
    int limit = 20,
  }) async {
    final db   = await database;
    final rows = await db.query(
      'meal_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC',
      limit: limit,
    );
    return rows.map((r) => MealLog(
      id:               r['id'] as int,
      foodClassName:    r['food_class_name'] as String,
      foodDisplayName:  r['food_display_name'] as String,
      totalCalories:    r['total_calories'] as double,
      totalProtein:     r['total_protein'] as double,
      totalCarbs:       r['total_carbs'] as double,
      totalFat:         r['total_fat'] as double,
      loggedAt:         DateTime.parse(r['logged_at'] as String),
    )).toList();
  }


  // ── Fallback for unknown classes ──────────────
  List<Ingredient> _fallbackIngredients(String className) => [
    Ingredient(
      name: className.replaceAll('_', ' '),
      calories: 200, protein: 8, carbs: 30, fat: 6,
      grams: 200,
    ),
  ];

  // ══════════════════════════════════════════════
  //  SEED DATA — ingredients & food compositions
  // ══════════════════════════════════════════════
  Future<void> _seedData(Database db) async {
    // ── Master ingredients table ──────────────
    final ingredients = [
      // Grains & staples
      {'name': 'Couscous (dry)',     'calories': 376.0, 'protein': 12.8, 'carbs': 77.4, 'fat': 0.6},
      {'name': 'Rice (white, dry)',  'calories': 365.0, 'protein': 7.1,  'carbs': 79.3, 'fat': 0.7},
      {'name': 'Pasta (dry)',        'calories': 371.0, 'protein': 13.0, 'carbs': 74.7, 'fat': 1.5},
      {'name': 'Bread',              'calories': 265.0, 'protein': 9.0,  'carbs': 49.0, 'fat': 3.2},
      {'name': 'Brik Pastry',        'calories': 380.0, 'protein': 8.0,  'carbs': 55.0, 'fat': 15.0},
      // Proteins
      {'name': 'Chicken (cooked)',   'calories': 165.0, 'protein': 31.0, 'carbs': 0.0,  'fat': 3.6},
      {'name': 'Lamb (cooked)',      'calories': 258.0, 'protein': 25.6, 'carbs': 0.0,  'fat': 16.5},
      {'name': 'Ground Beef',        'calories': 215.0, 'protein': 26.1, 'carbs': 0.0,  'fat': 11.8},
      {'name': 'Beef (cooked)',      'calories': 250.0, 'protein': 26.0, 'carbs': 0.0,  'fat': 15.0},
      {'name': 'Egg',                'calories': 155.0, 'protein': 13.0, 'carbs': 1.1,  'fat': 11.0},
      {'name': 'Tuna',               'calories': 116.0, 'protein': 25.5, 'carbs': 0.0,  'fat': 0.8},
      {'name': 'Salmon (cooked)',    'calories': 208.0, 'protein': 20.4, 'carbs': 0.0,  'fat': 13.4},
      // Vegetables
      {'name': 'Onion',              'calories': 40.0,  'protein': 1.1,  'carbs': 9.3,  'fat': 0.1},
      {'name': 'Tomato',             'calories': 18.0,  'protein': 0.9,  'carbs': 3.9,  'fat': 0.2},
      {'name': 'Carrot',             'calories': 41.0,  'protein': 0.9,  'carbs': 9.6,  'fat': 0.2},
      {'name': 'Chickpeas (cooked)', 'calories': 164.0, 'protein': 8.9,  'carbs': 27.4, 'fat': 2.6},
      {'name': 'Zucchini',           'calories': 17.0,  'protein': 1.2,  'carbs': 3.1,  'fat': 0.3},
      {'name': 'Turnip',             'calories': 28.0,  'protein': 0.9,  'carbs': 6.4,  'fat': 0.1},
      {'name': 'Potato',             'calories': 77.0,  'protein': 2.0,  'carbs': 17.5, 'fat': 0.1},
      {'name': 'Lettuce',            'calories': 15.0,  'protein': 1.4,  'carbs': 2.9,  'fat': 0.2},
      // Dairy & sauces
      {'name': 'Tomato Sauce',       'calories': 29.0,  'protein': 1.4,  'carbs': 6.1,  'fat': 0.2},
      {'name': 'Cream Sauce',        'calories': 195.0, 'protein': 3.5,  'carbs': 8.0,  'fat': 17.0},
      {'name': 'Mozzarella',         'calories': 280.0, 'protein': 28.0, 'carbs': 3.1,  'fat': 17.0},
      {'name': 'Parmesan',           'calories': 431.0, 'protein': 38.0, 'carbs': 4.1,  'fat': 29.0},
      {'name': 'Butter',             'calories': 717.0, 'protein': 0.9,  'carbs': 0.1,  'fat': 81.0},
      // Oils & fats
      {'name': 'Olive Oil',          'calories': 884.0, 'protein': 0.0,  'carbs': 0.0,  'fat': 100.0},
      {'name': 'Vegetable Oil',      'calories': 884.0, 'protein': 0.0,  'carbs': 0.0,  'fat': 100.0},
      // Herbs & spices (minimal calories, added for completeness)
      {'name': 'Ras el Hanout',      'calories': 30.0,  'protein': 1.5,  'carbs': 5.0,  'fat': 0.5},
      {'name': 'Parsley',            'calories': 36.0,  'protein': 3.0,  'carbs': 6.3,  'fat': 0.8},
    ];

    final batch = db.batch();
    for (final ing in ingredients) {
      batch.insert('ingredients', ing);
    }
    await batch.commit(noResult: true);

    // ── Food → ingredient mappings ────────────
    final foodIngredients = [
      // Algerian classes
      {'food': 'couscous',  'ingredient': 'Couscous (dry)',     'grams': 120.0},
      {'food': 'couscous',  'ingredient': 'Lamb (cooked)',      'grams': 150.0},
      {'food': 'couscous',  'ingredient': 'Chickpeas (cooked)', 'grams': 80.0},
      {'food': 'couscous',  'ingredient': 'Carrot',             'grams': 60.0},
      {'food': 'couscous',  'ingredient': 'Zucchini',           'grams': 60.0},
      {'food': 'couscous',  'ingredient': 'Turnip',             'grams': 40.0},
      {'food': 'couscous',  'ingredient': 'Onion',              'grams': 30.0},
      {'food': 'couscous',  'ingredient': 'Ras el Hanout',      'grams': 5.0},

      {'food': 'bourek',    'ingredient': 'Brik Pastry',        'grams': 60.0},
      {'food': 'bourek',    'ingredient': 'Ground Beef',        'grams': 80.0},
      {'food': 'bourek',    'ingredient': 'Egg',                'grams': 50.0},
      {'food': 'bourek',    'ingredient': 'Onion',              'grams': 20.0},
      {'food': 'bourek',    'ingredient': 'Parsley',            'grams': 5.0},
      {'food': 'bourek',    'ingredient': 'Vegetable Oil',      'grams': 15.0},

      {'food': 'chourba',   'ingredient': 'Lamb (cooked)',      'grams': 100.0},
      {'food': 'chourba',   'ingredient': 'Chickpeas (cooked)', 'grams': 60.0},
      {'food': 'chourba',   'ingredient': 'Tomato',             'grams': 80.0},
      {'food': 'chourba',   'ingredient': 'Onion',              'grams': 40.0},
      {'food': 'chourba',   'ingredient': 'Carrot',             'grams': 40.0},
      {'food': 'chourba',   'ingredient': 'Pasta (dry)',        'grams': 30.0},
      {'food': 'chourba',   'ingredient': 'Ras el Hanout',      'grams': 5.0},

      {'food': 'kofta',     'ingredient': 'Ground Beef',        'grams': 150.0},
      {'food': 'kofta',     'ingredient': 'Onion',              'grams': 30.0},
      {'food': 'kofta',     'ingredient': 'Parsley',            'grams': 10.0},
      {'food': 'kofta',     'ingredient': 'Ras el Hanout',      'grams': 5.0},
      {'food': 'kofta',     'ingredient': 'Olive Oil',          'grams': 10.0},

      // Extra classes
      {'food': 'red_sauce_pasta',   'ingredient': 'Pasta (dry)',    'grams': 80.0},
      {'food': 'red_sauce_pasta',   'ingredient': 'Tomato Sauce',   'grams': 120.0},
      {'food': 'red_sauce_pasta',   'ingredient': 'Parmesan',       'grams': 20.0},
      {'food': 'red_sauce_pasta',   'ingredient': 'Olive Oil',      'grams': 10.0},

      {'food': 'white_sauce_pasta', 'ingredient': 'Pasta (dry)',    'grams': 80.0},
      {'food': 'white_sauce_pasta', 'ingredient': 'Cream Sauce',    'grams': 100.0},
      {'food': 'white_sauce_pasta', 'ingredient': 'Parmesan',       'grams': 20.0},
      {'food': 'white_sauce_pasta', 'ingredient': 'Butter',         'grams': 10.0},

      {'food': 'rice',  'ingredient': 'Rice (white, dry)', 'grams': 80.0},
      {'food': 'rice',  'ingredient': 'Olive Oil',         'grams': 10.0},
      {'food': 'rice',  'ingredient': 'Onion',             'grams': 20.0},

      // Food-101 samples
      {'food': 'pizza',     'ingredient': 'Bread',          'grams': 120.0},
      {'food': 'pizza',     'ingredient': 'Tomato Sauce',   'grams': 60.0},
      {'food': 'pizza',     'ingredient': 'Mozzarella',     'grams': 80.0},
      {'food': 'pizza',     'ingredient': 'Olive Oil',      'grams': 10.0},

      {'food': 'burger',    'ingredient': 'Bread',          'grams': 80.0},
      {'food': 'burger',    'ingredient': 'Ground Beef',    'grams': 120.0},
      {'food': 'burger',    'ingredient': 'Lettuce',        'grams': 20.0},
      {'food': 'burger',    'ingredient': 'Tomato',         'grams': 30.0},

      {'food': 'grilled_salmon', 'ingredient': 'Salmon (cooked)', 'grams': 180.0},
      {'food': 'grilled_salmon', 'ingredient': 'Olive Oil',       'grams': 10.0},
      {'food': 'grilled_salmon', 'ingredient': 'Parsley',         'grams': 5.0},
    ];

    final batch2 = db.batch();
    for (final fi in foodIngredients) {
      batch2.insert('food_ingredients', {
        'food_class_name':  fi['food'],
        'ingredient_name':  fi['ingredient'],
        'default_grams':    fi['grams'],
      });
    }
    await batch2.commit(noResult: true);
  }
}
