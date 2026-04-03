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
      join(dbPath, 'smartmeal.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
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

  // ── Get ingredients for a food class ──────────
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
      final ingName      = row['ingredient_name'] as String;
      final defaultGrams = row['default_grams'] as double;
      final ingRows      = await db.query(
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

  // ─────── search for ingredients ───────
  Future<List<Ingredient>> searchIngredients(String query) async {
    final db   = await database;
    final rows = await db.query(
      'ingredients',
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'name ASC',
      limit: 10,
    );
    return rows.map((r) => Ingredient(
      id:       r['id'] as int,
      name:     r['name'] as String,
      calories: r['calories'] as double,
      protein:  r['protein'] as double,
      carbs:    r['carbs'] as double,
      fat:      r['fat'] as double,
      grams:    100.0,
    )).toList();
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
    int limit = 50,
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
      calories: 200, protein: 8, carbs: 25, fat: 6,
      grams: 200,
    ),
  ];

  // ══════════════════════════════════════════════
  //  SEED DATA
  //  All nutritional values are per 100g
  //  Source: USDA FoodData Central
  // ══════════════════════════════════════════════
  Future<void> _seedData(Database db) async {

    // ── Master ingredients table ──────────────
    final ingredients = [
      // ── Grains & starches ──────────────────
      {'name': 'Couscous (dry)',        'calories': 376.0, 'protein': 12.8, 'carbs': 77.4, 'fat': 0.6},
      {'name': 'Couscous (cooked)',     'calories': 112.0, 'protein': 3.8,  'carbs': 23.2, 'fat': 0.2},
      {'name': 'Rice (white, cooked)',  'calories': 130.0, 'protein': 2.7,  'carbs': 28.2, 'fat': 0.3},
      {'name': 'Rice (basmati, cooked)','calories': 121.0, 'protein': 3.5,  'carbs': 25.2, 'fat': 0.4},
      {'name': 'Pasta (cooked)',        'calories': 158.0, 'protein': 5.8,  'carbs': 30.9, 'fat': 0.9},
      {'name': 'Pasta (dry)',           'calories': 371.0, 'protein': 13.0, 'carbs': 74.7, 'fat': 1.5},
      {'name': 'Bread (white)',         'calories': 265.0, 'protein': 9.0,  'carbs': 49.0, 'fat': 3.2},
      {'name': 'Bread roll',            'calories': 280.0, 'protein': 9.5,  'carbs': 51.0, 'fat': 4.0},
      {'name': 'Brik pastry',           'calories': 380.0, 'protein': 8.0,  'carbs': 55.0, 'fat': 15.0},
      {'name': 'Tortilla (flour)',      'calories': 312.0, 'protein': 8.0,  'carbs': 51.0, 'fat': 7.0},
      {'name': 'Tortilla chip',         'calories': 489.0, 'protein': 6.6,  'carbs': 65.8, 'fat': 23.4},
      {'name': 'Pancake batter',        'calories': 227.0, 'protein': 6.4,  'carbs': 32.0, 'fat': 8.0},
      {'name': 'Ramen noodles (cooked)','calories': 138.0, 'protein': 4.5,  'carbs': 25.7, 'fat': 2.1},
      {'name': 'Garlic bread',          'calories': 350.0, 'protein': 8.0,  'carbs': 44.0, 'fat': 16.0},
      {'name': 'Phyllo dough',          'calories': 320.0, 'protein': 8.0,  'carbs': 59.0, 'fat': 5.0},

      // ── Proteins ───────────────────────────
      {'name': 'Beef (ground, cooked)', 'calories': 215.0, 'protein': 26.1, 'carbs': 0.0,  'fat': 11.8},
      {'name': 'Beef (steak, grilled)', 'calories': 271.0, 'protein': 26.4, 'carbs': 0.0,  'fat': 17.5},
      {'name': 'Lamb (cooked)',         'calories': 258.0, 'protein': 25.6, 'carbs': 0.0,  'fat': 16.5},
      {'name': 'Chicken (grilled)',     'calories': 165.0, 'protein': 31.0, 'carbs': 0.0,  'fat': 3.6},
      {'name': 'Chicken (curry pieces)','calories': 175.0, 'protein': 22.0, 'carbs': 3.0,  'fat': 8.0},
      {'name': 'Salmon (grilled)',      'calories': 208.0, 'protein': 20.4, 'carbs': 0.0,  'fat': 13.4},
      {'name': 'Mussels (cooked)',      'calories': 172.0, 'protein': 23.8, 'carbs': 7.4,  'fat': 4.5},
      {'name': 'Shrimp (cooked)',       'calories': 99.0,  'protein': 20.9, 'carbs': 0.0,  'fat': 1.1},
      {'name': 'Fish (battered, fried)','calories': 265.0, 'protein': 16.0, 'carbs': 18.0, 'fat': 14.0},
      {'name': 'Egg',                   'calories': 155.0, 'protein': 13.0, 'carbs': 1.1,  'fat': 11.0},
      {'name': 'Egg (fried)',           'calories': 196.0, 'protein': 13.6, 'carbs': 0.4,  'fat': 15.2},
      {'name': 'Tuna (canned)',         'calories': 116.0, 'protein': 25.5, 'carbs': 0.0,  'fat': 0.8},
      {'name': 'Hot dog sausage',       'calories': 290.0, 'protein': 10.8, 'carbs': 2.6,  'fat': 26.0},
      {'name': 'Burger patty (beef)',   'calories': 235.0, 'protein': 20.0, 'carbs': 0.0,  'fat': 17.0},
      {'name': 'Chickpeas (cooked)',    'calories': 164.0, 'protein': 8.9,  'carbs': 27.4, 'fat': 2.6},
      {'name': 'Falafel',               'calories': 333.0, 'protein': 13.3, 'carbs': 31.8, 'fat': 17.8},

      // ── Dairy & cheese ─────────────────────
      {'name': 'Mozzarella',            'calories': 280.0, 'protein': 28.0, 'carbs': 3.1,  'fat': 17.0},
      {'name': 'Parmesan',              'calories': 431.0, 'protein': 38.0, 'carbs': 4.1,  'fat': 29.0},
      {'name': 'Cheddar cheese',        'calories': 402.0, 'protein': 25.0, 'carbs': 1.3,  'fat': 33.0},
      {'name': 'Cream cheese',          'calories': 342.0, 'protein': 6.2,  'carbs': 4.1,  'fat': 34.0},
      {'name': 'Butter',                'calories': 717.0, 'protein': 0.9,  'carbs': 0.1,  'fat': 81.0},
      {'name': 'Cream (heavy)',         'calories': 340.0, 'protein': 2.8,  'carbs': 2.8,  'fat': 36.0},
      {'name': 'Milk (whole)',          'calories': 61.0,  'protein': 3.2,  'carbs': 4.8,  'fat': 3.3},
      {'name': 'Ice cream (vanilla)',   'calories': 207.0, 'protein': 3.5,  'carbs': 23.6, 'fat': 11.0},
      {'name': 'Feta cheese',           'calories': 264.0, 'protein': 14.2, 'carbs': 4.1,  'fat': 21.3},

      // ── Vegetables ─────────────────────────
      {'name': 'Tomato',                'calories': 18.0,  'protein': 0.9,  'carbs': 3.9,  'fat': 0.2},
      {'name': 'Tomato sauce',          'calories': 29.0,  'protein': 1.4,  'carbs': 6.1,  'fat': 0.2},
      {'name': 'Onion',                 'calories': 40.0,  'protein': 1.1,  'carbs': 9.3,  'fat': 0.1},
      {'name': 'Garlic',                'calories': 149.0, 'protein': 6.4,  'carbs': 33.1, 'fat': 0.5},
      {'name': 'Carrot',                'calories': 41.0,  'protein': 0.9,  'carbs': 9.6,  'fat': 0.2},
      {'name': 'Zucchini',              'calories': 17.0,  'protein': 1.2,  'carbs': 3.1,  'fat': 0.3},
      {'name': 'Turnip',                'calories': 28.0,  'protein': 0.9,  'carbs': 6.4,  'fat': 0.1},
      {'name': 'Potato (fried)',        'calories': 312.0, 'protein': 3.4,  'carbs': 41.4, 'fat': 15.0},
      {'name': 'Potato (boiled)',       'calories': 87.0,  'protein': 1.9,  'carbs': 20.1, 'fat': 0.1},
      {'name': 'Lettuce',               'calories': 15.0,  'protein': 1.4,  'carbs': 2.9,  'fat': 0.2},
      {'name': 'Bell pepper',           'calories': 31.0,  'protein': 1.0,  'carbs': 6.0,  'fat': 0.3},
      {'name': 'Mushroom',              'calories': 22.0,  'protein': 3.1,  'carbs': 3.3,  'fat': 0.3},
      {'name': 'Corn',                  'calories': 86.0,  'protein': 3.2,  'carbs': 19.0, 'fat': 1.2},
      {'name': 'Peas (cooked)',         'calories': 84.0,  'protein': 5.4,  'carbs': 15.6, 'fat': 0.2},
      {'name': 'Spinach',               'calories': 23.0,  'protein': 2.9,  'carbs': 3.6,  'fat': 0.4},
      {'name': 'Cucumber',              'calories': 15.0,  'protein': 0.7,  'carbs': 3.6,  'fat': 0.1},
      {'name': 'Olives',                'calories': 145.0, 'protein': 1.0,  'carbs': 3.8,  'fat': 15.3},
      {'name': 'Lemon juice',           'calories': 22.0,  'protein': 0.4,  'carbs': 6.9,  'fat': 0.2},

      // ── Sauces & condiments ────────────────
      {'name': 'Tomato marinara sauce', 'calories': 50.0,  'protein': 2.0,  'carbs': 8.0,  'fat': 1.5},
      {'name': 'Cream sauce (bechamel)','calories': 120.0, 'protein': 3.5,  'carbs': 8.0,  'fat': 8.5},
      {'name': 'Curry sauce',           'calories': 110.0, 'protein': 3.0,  'carbs': 9.0,  'fat': 7.0},
      {'name': 'Caesar dressing',       'calories': 360.0, 'protein': 4.0,  'carbs': 7.0,  'fat': 36.0},
      {'name': 'Tahini',                'calories': 595.0, 'protein': 17.0, 'carbs': 21.2, 'fat': 53.8},
      {'name': 'Hummus',                'calories': 177.0, 'protein': 7.9,  'carbs': 14.3, 'fat': 10.6},
      {'name': 'Honey',                 'calories': 304.0, 'protein': 0.3,  'carbs': 82.4, 'fat': 0.0},
      {'name': 'Syrup (maple)',         'calories': 260.0, 'protein': 0.0,  'carbs': 67.0, 'fat': 0.1},
      {'name': 'Ketchup',               'calories': 101.0, 'protein': 1.7,  'carbs': 25.0, 'fat': 0.1},
      {'name': 'Mustard',               'calories': 66.0,  'protein': 4.0,  'carbs': 6.0,  'fat': 3.7},
      {'name': 'Soy sauce',             'calories': 53.0,  'protein': 8.1,  'carbs': 4.9,  'fat': 0.6},
      {'name': 'Miso paste',            'calories': 199.0, 'protein': 12.0, 'carbs': 26.5, 'fat': 6.0},
      {'name': 'Fish sauce',            'calories': 35.0,  'protein': 5.0,  'carbs': 3.6,  'fat': 0.0},

      // ── Oils & fats ────────────────────────
      {'name': 'Olive oil',             'calories': 884.0, 'protein': 0.0,  'carbs': 0.0,  'fat': 100.0},
      {'name': 'Vegetable oil',         'calories': 884.0, 'protein': 0.0,  'carbs': 0.0,  'fat': 100.0},

      // ── Nuts & seeds ───────────────────────
      {'name': 'Walnuts',               'calories': 654.0, 'protein': 15.2, 'carbs': 13.7, 'fat': 65.2},
      {'name': 'Pistachios',            'calories': 562.0, 'protein': 20.2, 'carbs': 27.2, 'fat': 45.3},

      // ── Sweets & baking ────────────────────
      {'name': 'Sugar',                 'calories': 387.0, 'protein': 0.0,  'carbs': 99.8, 'fat': 0.0},
      {'name': 'Flour (all-purpose)',   'calories': 364.0, 'protein': 10.3, 'carbs': 76.3, 'fat': 1.0},
      {'name': 'Chocolate (dark)',      'calories': 546.0, 'protein': 4.9,  'carbs': 60.0, 'fat': 31.3},
      {'name': 'Cocoa powder',          'calories': 228.0, 'protein': 19.6, 'carbs': 57.9, 'fat': 13.7},
      {'name': 'Cheesecake filling',    'calories': 321.0, 'protein': 5.5,  'carbs': 25.5, 'fat': 22.5},
      {'name': 'Graham cracker crust',  'calories': 490.0, 'protein': 5.0,  'carbs': 65.0, 'fat': 24.0},
      {'name': 'Baklava syrup',         'calories': 280.0, 'protein': 0.2,  'carbs': 72.0, 'fat': 0.1},

      // ── Herbs & spices (minimal cal) ───────
      {'name': 'Ras el Hanout',         'calories': 30.0,  'protein': 1.5,  'carbs': 5.0,  'fat': 0.5},
      {'name': 'Parsley',               'calories': 36.0,  'protein': 3.0,  'carbs': 6.3,  'fat': 0.8},
      {'name': 'Cilantro',              'calories': 23.0,  'protein': 2.1,  'carbs': 3.7,  'fat': 0.5},
      {'name': 'Oregano (dried)',        'calories': 265.0, 'protein': 9.0,  'carbs': 68.9, 'fat': 4.3},
      {'name': 'Cumin (ground)',         'calories': 375.0, 'protein': 17.8, 'carbs': 44.2, 'fat': 22.3},
      {'name': 'Paprika',               'calories': 282.0, 'protein': 14.1, 'carbs': 53.9, 'fat': 12.9},
      {'name': 'Chili powder',          'calories': 282.0, 'protein': 12.5, 'carbs': 49.7, 'fat': 14.3},
      {'name': 'Ginger (fresh)',         'calories': 80.0,  'protein': 1.8,  'carbs': 17.8, 'fat': 0.8},

      // ── Broth & stock ───────────────────────
      {'name': 'Broth (chicken)',       'calories': 15.0,  'protein': 1.5,  'carbs': 1.4,  'fat': 0.5},
      {'name': 'Dashi broth',           'calories': 10.0,  'protein': 1.0,  'carbs': 1.0,  'fat': 0.2},
    ];

    final batch = db.batch();
    for (final ing in ingredients) {
      batch.insert('ingredients', ing,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);

    // ── Food → ingredient mappings ────────────
    // Each entry: food class name → ingredient → default grams
    final foodIngredients = [

      // ══ ALGERIAN CLASSES ══════════════════════

      // Couscous (traditional serving ~450g)
      {'food': 'couscous',           'ingredient': 'Couscous (cooked)',     'grams': 200.0},
      {'food': 'couscous',           'ingredient': 'Lamb (cooked)',         'grams': 120.0},
      {'food': 'couscous',           'ingredient': 'Chickpeas (cooked)',    'grams': 60.0},
      {'food': 'couscous',           'ingredient': 'Carrot',                'grams': 50.0},
      {'food': 'couscous',           'ingredient': 'Zucchini',              'grams': 50.0},
      {'food': 'couscous',           'ingredient': 'Turnip',                'grams': 30.0},
      {'food': 'couscous',           'ingredient': 'Onion',                 'grams': 30.0},
      {'food': 'couscous',           'ingredient': 'Ras el Hanout',         'grams': 5.0},
      {'food': 'couscous',           'ingredient': 'Olive oil',             'grams': 10.0},

      // Bourek (2 pieces ~200g)
      {'food': 'Bourek',             'ingredient': 'Brik pastry',           'grams': 60.0},
      {'food': 'Bourek',             'ingredient': 'Beef (ground, cooked)', 'grams': 80.0},
      {'food': 'Bourek',             'ingredient': 'Egg',                   'grams': 50.0},
      {'food': 'Bourek',             'ingredient': 'Onion',                 'grams': 20.0},
      {'food': 'Bourek',             'ingredient': 'Parsley',               'grams': 5.0},
      {'food': 'Bourek',             'ingredient': 'Vegetable oil',         'grams': 15.0},

      // Chourba (1 bowl ~350g)
      {'food': 'chourba',            'ingredient': 'Lamb (cooked)',         'grams': 80.0},
      {'food': 'chourba',            'ingredient': 'Chickpeas (cooked)',    'grams': 50.0},
      {'food': 'chourba',            'ingredient': 'Tomato',                'grams': 80.0},
      {'food': 'chourba',            'ingredient': 'Onion',                 'grams': 40.0},
      {'food': 'chourba',            'ingredient': 'Carrot',                'grams': 40.0},
      {'food': 'chourba',            'ingredient': 'Pasta (cooked)',        'grams': 40.0},
      {'food': 'chourba',            'ingredient': 'Ras el Hanout',         'grams': 5.0},
      {'food': 'chourba',            'ingredient': 'Olive oil',             'grams': 8.0},

      // Kofta (3 skewers ~200g)
      {'food': 'KoftaFinal',         'ingredient': 'Beef (ground, cooked)', 'grams': 150.0},
      {'food': 'KoftaFinal',         'ingredient': 'Onion',                 'grams': 25.0},
      {'food': 'KoftaFinal',         'ingredient': 'Parsley',               'grams': 8.0},
      {'food': 'KoftaFinal',         'ingredient': 'Ras el Hanout',         'grams': 5.0},
      {'food': 'KoftaFinal',         'ingredient': 'Cumin (ground)',         'grams': 3.0},
      {'food': 'KoftaFinal',         'ingredient': 'Olive oil',             'grams': 8.0},

      // ══ FOOD-101 CLASSES ══════════════════════

      // Baklava (2 pieces ~80g)
      {'food': 'baklava',            'ingredient': 'Phyllo dough',          'grams': 30.0},
      {'food': 'baklava',            'ingredient': 'Walnuts',               'grams': 25.0},
      {'food': 'baklava',            'ingredient': 'Pistachios',            'grams': 10.0},
      {'food': 'baklava',            'ingredient': 'Butter',                'grams': 15.0},
      {'food': 'baklava',            'ingredient': 'Baklava syrup',         'grams': 20.0},
      {'food': 'baklava',            'ingredient': 'Sugar',                 'grams': 10.0},

      // Caesar salad (1 serving ~250g)
      {'food': 'caesar_salad',       'ingredient': 'Lettuce',               'grams': 120.0},
      {'food': 'caesar_salad',       'ingredient': 'Parmesan',              'grams': 20.0},
      {'food': 'caesar_salad',       'ingredient': 'Caesar dressing',       'grams': 40.0},
      {'food': 'caesar_salad',       'ingredient': 'Bread (white)',         'grams': 20.0},
      {'food': 'caesar_salad',       'ingredient': 'Chicken (grilled)',     'grams': 80.0},

      // Cheesecake (1 slice ~120g)
      {'food': 'cheesecake',         'ingredient': 'Cheesecake filling',    'grams': 90.0},
      {'food': 'cheesecake',         'ingredient': 'Graham cracker crust',  'grams': 30.0},
      {'food': 'cheesecake',         'ingredient': 'Sugar',                 'grams': 15.0},

      // Chicken curry (1 serving ~350g)
      {'food': 'chicken_curry',      'ingredient': 'Chicken (curry pieces)', 'grams': 150.0},
      {'food': 'chicken_curry',      'ingredient': 'Curry sauce',           'grams': 100.0},
      {'food': 'chicken_curry',      'ingredient': 'Rice (white, cooked)',  'grams': 150.0},
      {'food': 'chicken_curry',      'ingredient': 'Onion',                 'grams': 40.0},
      {'food': 'chicken_curry',      'ingredient': 'Tomato',                'grams': 40.0},
      {'food': 'chicken_curry',      'ingredient': 'Garlic',                'grams': 5.0},
      {'food': 'chicken_curry',      'ingredient': 'Ginger (fresh)',        'grams': 5.0},

      // Chicken quesadilla (1 serving ~200g)
      {'food': 'chicken_quesadilla', 'ingredient': 'Tortilla (flour)',      'grams': 80.0},
      {'food': 'chicken_quesadilla', 'ingredient': 'Chicken (grilled)',     'grams': 80.0},
      {'food': 'chicken_quesadilla', 'ingredient': 'Cheddar cheese',        'grams': 40.0},
      {'food': 'chicken_quesadilla', 'ingredient': 'Bell pepper',           'grams': 20.0},
      {'food': 'chicken_quesadilla', 'ingredient': 'Onion',                 'grams': 15.0},

      // Chocolate cake (1 slice ~120g)
      {'food': 'chocolate_cake',     'ingredient': 'Flour (all-purpose)',   'grams': 40.0},
      {'food': 'chocolate_cake',     'ingredient': 'Sugar',                 'grams': 35.0},
      {'food': 'chocolate_cake',     'ingredient': 'Cocoa powder',          'grams': 15.0},
      {'food': 'chocolate_cake',     'ingredient': 'Egg',                   'grams': 25.0},
      {'food': 'chocolate_cake',     'ingredient': 'Butter',                'grams': 20.0},
      {'food': 'chocolate_cake',     'ingredient': 'Milk (whole)',          'grams': 20.0},

      // Falafel (4 pieces ~120g)
      {'food': 'falafel',            'ingredient': 'Falafel',               'grams': 120.0},
      {'food': 'falafel',            'ingredient': 'Tahini',                'grams': 20.0},
      {'food': 'falafel',            'ingredient': 'Lettuce',               'grams': 20.0},
      {'food': 'falafel',            'ingredient': 'Tomato',                'grams': 30.0},

      // Fish and chips (1 serving ~350g)
      {'food': 'fish_and_chips',     'ingredient': 'Fish (battered, fried)', 'grams': 180.0},
      {'food': 'fish_and_chips',     'ingredient': 'Potato (fried)',        'grams': 150.0},
      {'food': 'fish_and_chips',     'ingredient': 'Lemon juice',           'grams': 10.0},

      // French fries (1 serving ~150g)
      {'food': 'french_fries',       'ingredient': 'Potato (fried)',        'grams': 150.0},
      {'food': 'french_fries',       'ingredient': 'Vegetable oil',         'grams': 10.0},
      {'food': 'french_fries',       'ingredient': 'Ketchup',               'grams': 20.0},

      // Fried rice (1 serving ~300g)
      {'food': 'fried_rice',         'ingredient': 'Rice (white, cooked)',  'grams': 200.0},
      {'food': 'fried_rice',         'ingredient': 'Egg',                   'grams': 50.0},
      {'food': 'fried_rice',         'ingredient': 'Peas (cooked)',         'grams': 30.0},
      {'food': 'fried_rice',         'ingredient': 'Corn',                  'grams': 20.0},
      {'food': 'fried_rice',         'ingredient': 'Soy sauce',             'grams': 10.0},
      {'food': 'fried_rice',         'ingredient': 'Vegetable oil',         'grams': 10.0},
      {'food': 'fried_rice',         'ingredient': 'Onion',                 'grams': 20.0},

      // Garlic bread (2 slices ~80g)
      {'food': 'garlic_bread',       'ingredient': 'Garlic bread',          'grams': 80.0},

      // Greek salad (1 serving ~250g)
      {'food': 'greek_salad',        'ingredient': 'Tomato',                'grams': 80.0},
      {'food': 'greek_salad',        'ingredient': 'Cucumber',              'grams': 60.0},
      {'food': 'greek_salad',        'ingredient': 'Feta cheese',           'grams': 50.0},
      {'food': 'greek_salad',        'ingredient': 'Olives',                'grams': 30.0},
      {'food': 'greek_salad',        'ingredient': 'Bell pepper',           'grams': 30.0},
      {'food': 'greek_salad',        'ingredient': 'Onion',                 'grams': 20.0},
      {'food': 'greek_salad',        'ingredient': 'Olive oil',             'grams': 15.0},
      {'food': 'greek_salad',        'ingredient': 'Lemon juice',           'grams': 10.0},

      // Grilled salmon (1 fillet ~200g)
      {'food': 'grilled_salmon',     'ingredient': 'Salmon (grilled)',      'grams': 180.0},
      {'food': 'grilled_salmon',     'ingredient': 'Lemon juice',           'grams': 10.0},
      {'food': 'grilled_salmon',     'ingredient': 'Olive oil',             'grams': 10.0},
      {'food': 'grilled_salmon',     'ingredient': 'Garlic',                'grams': 5.0},
      {'food': 'grilled_salmon',     'ingredient': 'Parsley',               'grams': 5.0},

      // Hamburger (1 burger ~200g)
      {'food': 'hamburger',          'ingredient': 'Bread roll',            'grams': 80.0},
      {'food': 'hamburger',          'ingredient': 'Burger patty (beef)',   'grams': 100.0},
      {'food': 'hamburger',          'ingredient': 'Lettuce',               'grams': 15.0},
      {'food': 'hamburger',          'ingredient': 'Tomato',                'grams': 20.0},
      {'food': 'hamburger',          'ingredient': 'Cheddar cheese',        'grams': 20.0},
      {'food': 'hamburger',          'ingredient': 'Ketchup',               'grams': 15.0},
      {'food': 'hamburger',          'ingredient': 'Mustard',               'grams': 5.0},

      // Hot dog (1 hot dog ~150g)
      {'food': 'hot_dog',            'ingredient': 'Bread roll',            'grams': 60.0},
      {'food': 'hot_dog',            'ingredient': 'Hot dog sausage',       'grams': 70.0},
      {'food': 'hot_dog',            'ingredient': 'Ketchup',               'grams': 15.0},
      {'food': 'hot_dog',            'ingredient': 'Mustard',               'grams': 5.0},

      // Hummus (1 serving ~100g with pita)
      {'food': 'hummus',             'ingredient': 'Hummus',                'grams': 80.0},
      {'food': 'hummus',             'ingredient': 'Olive oil',             'grams': 10.0},
      {'food': 'hummus',             'ingredient': 'Bread (white)',         'grams': 40.0},
      {'food': 'hummus',             'ingredient': 'Paprika',               'grams': 2.0},

      // Ice cream (1 scoop ~100g)
      {'food': 'ice_cream',          'ingredient': 'Ice cream (vanilla)',   'grams': 100.0},

      // Lasagna (1 serving ~300g)
      {'food': 'lasagna',            'ingredient': 'Pasta (cooked)',        'grams': 80.0},
      {'food': 'lasagna',            'ingredient': 'Beef (ground, cooked)', 'grams': 100.0},
      {'food': 'lasagna',            'ingredient': 'Tomato marinara sauce', 'grams': 80.0},
      {'food': 'lasagna',            'ingredient': 'Cream sauce (bechamel)','grams': 60.0},
      {'food': 'lasagna',            'ingredient': 'Mozzarella',            'grams': 40.0},
      {'food': 'lasagna',            'ingredient': 'Parmesan',              'grams': 20.0},

      // Mussels (1 serving ~300g)
      {'food': 'mussels',            'ingredient': 'Mussels (cooked)',      'grams': 200.0},
      {'food': 'mussels',            'ingredient': 'Garlic',                'grams': 10.0},
      {'food': 'mussels',            'ingredient': 'Butter',                'grams': 20.0},
      {'food': 'mussels',            'ingredient': 'Parsley',               'grams': 5.0},
      {'food': 'mussels',            'ingredient': 'Lemon juice',           'grams': 10.0},

      // Omelette (1 serving ~150g)
      {'food': 'omelette',           'ingredient': 'Egg',                   'grams': 150.0},
      {'food': 'omelette',           'ingredient': 'Butter',                'grams': 10.0},
      {'food': 'omelette',           'ingredient': 'Mushroom',              'grams': 30.0},
      {'food': 'omelette',           'ingredient': 'Bell pepper',           'grams': 20.0},
      {'food': 'omelette',           'ingredient': 'Cheddar cheese',        'grams': 20.0},

      // Paella (1 serving ~350g)
      {'food': 'paella',             'ingredient': 'Rice (basmati, cooked)','grams': 150.0},
      {'food': 'paella',             'ingredient': 'Shrimp (cooked)',       'grams': 80.0},
      {'food': 'paella',             'ingredient': 'Mussels (cooked)',      'grams': 60.0},
      {'food': 'paella',             'ingredient': 'Bell pepper',           'grams': 40.0},
      {'food': 'paella',             'ingredient': 'Tomato',                'grams': 40.0},
      {'food': 'paella',             'ingredient': 'Onion',                 'grams': 30.0},
      {'food': 'paella',             'ingredient': 'Olive oil',             'grams': 15.0},
      {'food': 'paella',             'ingredient': 'Paprika',               'grams': 3.0},

      // Pancakes (2 pancakes ~150g)
      {'food': 'pancakes',           'ingredient': 'Pancake batter',        'grams': 100.0},
      {'food': 'pancakes',           'ingredient': 'Butter',                'grams': 10.0},
      {'food': 'pancakes',           'ingredient': 'Syrup (maple)',         'grams': 30.0},

      // Pizza (1 slice ~120g)
      {'food': 'pizza',              'ingredient': 'Bread (white)',         'grams': 60.0},
      {'food': 'pizza',              'ingredient': 'Tomato marinara sauce', 'grams': 30.0},
      {'food': 'pizza',              'ingredient': 'Mozzarella',            'grams': 40.0},
      {'food': 'pizza',              'ingredient': 'Olive oil',             'grams': 5.0},
      {'food': 'pizza',              'ingredient': 'Oregano (dried)',        'grams': 2.0},

      // Ramen (1 bowl ~400g)
      {'food': 'ramen',              'ingredient': 'Ramen noodles (cooked)','grams': 150.0},
      {'food': 'ramen',              'ingredient': 'Broth (chicken)',       'grams': 150.0},
      {'food': 'ramen',              'ingredient': 'Egg',                   'grams': 50.0},
      {'food': 'ramen',              'ingredient': 'Corn',                  'grams': 20.0},
      {'food': 'ramen',              'ingredient': 'Mushroom',              'grams': 20.0},
      {'food': 'ramen',              'ingredient': 'Miso paste',            'grams': 15.0},
      {'food': 'ramen',              'ingredient': 'Soy sauce',             'grams': 10.0},

      // Red sauce pasta (1 serving ~300g)
      {'food': 'red_sauce_pasta',    'ingredient': 'Pasta (cooked)',        'grams': 180.0},
      {'food': 'red_sauce_pasta',    'ingredient': 'Tomato marinara sauce', 'grams': 100.0},
      {'food': 'red_sauce_pasta',    'ingredient': 'Parmesan',              'grams': 20.0},
      {'food': 'red_sauce_pasta',    'ingredient': 'Olive oil',             'grams': 10.0},
      {'food': 'red_sauce_pasta',    'ingredient': 'Garlic',                'grams': 5.0},

      // Rice dishes (1 serving ~250g)
      {'food': 'rice_dishes',        'ingredient': 'Rice (white, cooked)',  'grams': 200.0},
      {'food': 'rice_dishes',        'ingredient': 'Olive oil',             'grams': 10.0},
      {'food': 'rice_dishes',        'ingredient': 'Onion',                 'grams': 20.0},
      {'food': 'rice_dishes',        'ingredient': 'Broth (chicken)',       'grams': 30.0},

      // Steak (1 serving ~200g)
      {'food': 'steak',              'ingredient': 'Beef (steak, grilled)', 'grams': 200.0},
      {'food': 'steak',              'ingredient': 'Butter',                'grams': 15.0},
      {'food': 'steak',              'ingredient': 'Garlic',                'grams': 5.0},
      {'food': 'steak',              'ingredient': 'Olive oil',             'grams': 8.0},

      // Tacos (2 tacos ~160g)
      {'food': 'tacos',              'ingredient': 'Tortilla (flour)',      'grams': 60.0},
      {'food': 'tacos',              'ingredient': 'Beef (ground, cooked)', 'grams': 80.0},
      {'food': 'tacos',              'ingredient': 'Lettuce',               'grams': 15.0},
      {'food': 'tacos',              'ingredient': 'Tomato',                'grams': 20.0},
      {'food': 'tacos',              'ingredient': 'Cheddar cheese',        'grams': 20.0},
      {'food': 'tacos',              'ingredient': 'Chili powder',          'grams': 3.0},

      // White sauce pasta (1 serving ~300g)
      {'food': 'white_sauce_pasta',  'ingredient': 'Pasta (cooked)',        'grams': 180.0},
      {'food': 'white_sauce_pasta',  'ingredient': 'Cream sauce (bechamel)','grams': 100.0},
      {'food': 'white_sauce_pasta',  'ingredient': 'Parmesan',              'grams': 20.0},
      {'food': 'white_sauce_pasta',  'ingredient': 'Butter',                'grams': 10.0},
      {'food': 'white_sauce_pasta',  'ingredient': 'Garlic',                'grams': 5.0},
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
