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
          CREATE TABLE foods (
            class_name TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            category TEXT NOT NULL
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

  // ── Search ingredients by name ────────────────
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

  // ── Search foods by name ──────────────────────
  Future<List<FoodEntry>> searchFoods(String query) async {
    final db = await database;
    final rows = await db.query(
      'foods',
      where: query.isEmpty
          ? null
          : 'LOWER(display_name) LIKE ? OR LOWER(class_name) LIKE ?',
      whereArgs: query.isEmpty
          ? null
          : ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%'],
      orderBy: 'display_name ASC',
    );

    final List<FoodEntry> result = [];
    for (final row in rows) {
      final className  = row['class_name'] as String;
      final ingredients = await getIngredientsForFood(className);
      result.add(FoodEntry(
        className:   className,
        displayName: row['display_name'] as String,
        ingredients: ingredients,
      ));
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

  List<Ingredient> _fallbackIngredients(String className) => [
    Ingredient(
      name: className.replaceAll('_', ' '),
      calories: 200, protein: 8, carbs: 25, fat: 6,
      grams: 200,
    ),
  ];

  // ══════════════════════════════════════════════
  //  SEED DATA
  // ══════════════════════════════════════════════
  Future<void> _seedData(Database db) async {

    // ── Master ingredients ────────────────────
    final ingredients = [
      // Grains & starches
      {'name': 'Couscous (cooked)',      'calories': 112.0, 'protein': 3.8,  'carbs': 23.2, 'fat': 0.2},
      {'name': 'Rice (white, cooked)',   'calories': 130.0, 'protein': 2.7,  'carbs': 28.2, 'fat': 0.3},
      {'name': 'Rice (basmati, cooked)', 'calories': 121.0, 'protein': 3.5,  'carbs': 25.2, 'fat': 0.4},
      {'name': 'Pasta (cooked)',         'calories': 158.0, 'protein': 5.8,  'carbs': 30.9, 'fat': 0.9},
      {'name': 'Bread (white)',          'calories': 265.0, 'protein': 9.0,  'carbs': 49.0, 'fat': 3.2},
      {'name': 'Bread roll',             'calories': 280.0, 'protein': 9.5,  'carbs': 51.0, 'fat': 4.0},
      {'name': 'Brik pastry',            'calories': 380.0, 'protein': 8.0,  'carbs': 55.0, 'fat': 15.0},
      {'name': 'Tortilla (flour)',       'calories': 312.0, 'protein': 8.0,  'carbs': 51.0, 'fat': 7.0},
      {'name': 'Pancake batter',         'calories': 227.0, 'protein': 6.4,  'carbs': 32.0, 'fat': 8.0},
      {'name': 'Ramen noodles (cooked)', 'calories': 138.0, 'protein': 4.5,  'carbs': 25.7, 'fat': 2.1},
      {'name': 'Garlic bread',           'calories': 350.0, 'protein': 8.0,  'carbs': 44.0, 'fat': 16.0},
      {'name': 'Phyllo dough',           'calories': 320.0, 'protein': 8.0,  'carbs': 59.0, 'fat': 5.0},
      {'name': 'Semolina (cooked)',      'calories': 65.0,  'protein': 2.2,  'carbs': 13.5, 'fat': 0.2},
      {'name': 'Vermicelli (cooked)',    'calories': 148.0, 'protein': 5.1,  'carbs': 29.4, 'fat': 0.6},
      {'name': 'Crepe batter',           'calories': 135.0, 'protein': 5.0,  'carbs': 18.0, 'fat': 4.5},
      {'name': 'Oats (cooked)',          'calories': 71.0,  'protein': 2.5,  'carbs': 12.0, 'fat': 1.5},
      // Proteins
      {'name': 'Beef (ground, cooked)',  'calories': 215.0, 'protein': 26.1, 'carbs': 0.0,  'fat': 11.8},
      {'name': 'Beef (steak, grilled)',  'calories': 271.0, 'protein': 26.4, 'carbs': 0.0,  'fat': 17.5},
      {'name': 'Lamb (cooked)',          'calories': 258.0, 'protein': 25.6, 'carbs': 0.0,  'fat': 16.5},
      {'name': 'Chicken (grilled)',      'calories': 165.0, 'protein': 31.0, 'carbs': 0.0,  'fat': 3.6},
      {'name': 'Chicken (cooked)',       'calories': 165.0, 'protein': 31.0, 'carbs': 0.0,  'fat': 3.6},
      {'name': 'Chicken (curry pieces)', 'calories': 175.0, 'protein': 22.0, 'carbs': 3.0,  'fat': 8.0},
      {'name': 'Salmon (grilled)',       'calories': 208.0, 'protein': 20.4, 'carbs': 0.0,  'fat': 13.4},
      {'name': 'Mussels (cooked)',       'calories': 172.0, 'protein': 23.8, 'carbs': 7.4,  'fat': 4.5},
      {'name': 'Shrimp (cooked)',        'calories': 99.0,  'protein': 20.9, 'carbs': 0.0,  'fat': 1.1},
      {'name': 'Fish (battered, fried)', 'calories': 265.0, 'protein': 16.0, 'carbs': 18.0, 'fat': 14.0},
      {'name': 'Egg',                    'calories': 155.0, 'protein': 13.0, 'carbs': 1.1,  'fat': 11.0},
      {'name': 'Tuna (canned)',          'calories': 116.0, 'protein': 25.5, 'carbs': 0.0,  'fat': 0.8},
      {'name': 'Hot dog sausage',        'calories': 290.0, 'protein': 10.8, 'carbs': 2.6,  'fat': 26.0},
      {'name': 'Burger patty (beef)',    'calories': 235.0, 'protein': 20.0, 'carbs': 0.0,  'fat': 17.0},
      {'name': 'Chickpeas (cooked)',     'calories': 164.0, 'protein': 8.9,  'carbs': 27.4, 'fat': 2.6},
      {'name': 'Falafel',                'calories': 333.0, 'protein': 13.3, 'carbs': 31.8, 'fat': 17.8},
      {'name': 'Merguez sausage',        'calories': 310.0, 'protein': 16.0, 'carbs': 1.0,  'fat': 27.0},
      {'name': 'Lamb shoulder (roasted)','calories': 240.0, 'protein': 24.0, 'carbs': 0.0,  'fat': 15.5},
      {'name': 'Chicken (roasted)',      'calories': 190.0, 'protein': 28.0, 'carbs': 0.0,  'fat': 8.5},
      {'name': 'Lentils (cooked)',       'calories': 116.0, 'protein': 9.0,  'carbs': 20.1, 'fat': 0.4},
      {'name': 'White beans (cooked)',   'calories': 139.0, 'protein': 9.7,  'carbs': 25.1, 'fat': 0.5},
      // Dairy & cheese
      {'name': 'Mozzarella',             'calories': 280.0, 'protein': 28.0, 'carbs': 3.1,  'fat': 17.0},
      {'name': 'Parmesan',               'calories': 431.0, 'protein': 38.0, 'carbs': 4.1,  'fat': 29.0},
      {'name': 'Cheddar cheese',         'calories': 402.0, 'protein': 25.0, 'carbs': 1.3,  'fat': 33.0},
      {'name': 'Butter',                 'calories': 717.0, 'protein': 0.9,  'carbs': 0.1,  'fat': 81.0},
      {'name': 'Cream (heavy)',          'calories': 340.0, 'protein': 2.8,  'carbs': 2.8,  'fat': 36.0},
      {'name': 'Milk (whole)',           'calories': 61.0,  'protein': 3.2,  'carbs': 4.8,  'fat': 3.3},
      {'name': 'Ice cream (vanilla)',    'calories': 207.0, 'protein': 3.5,  'carbs': 23.6, 'fat': 11.0},
      {'name': 'Feta cheese',            'calories': 264.0, 'protein': 14.2, 'carbs': 4.1,  'fat': 21.3},
      {'name': 'Yogurt (plain)',         'calories': 61.0,  'protein': 3.5,  'carbs': 4.7,  'fat': 3.3},
      {'name': 'Yogurt (Greek)',         'calories': 97.0,  'protein': 9.0,  'carbs': 3.6,  'fat': 5.0},
      {'name': 'Cream cheese',           'calories': 342.0, 'protein': 6.2,  'carbs': 4.1,  'fat': 34.0},
      {'name': 'Cheesecake filling',     'calories': 321.0, 'protein': 5.5,  'carbs': 25.5, 'fat': 22.5},
      {'name': 'Graham cracker crust',   'calories': 490.0, 'protein': 5.0,  'carbs': 65.0, 'fat': 24.0},
      // Vegetables
      {'name': 'Tomato',                 'calories': 18.0,  'protein': 0.9,  'carbs': 3.9,  'fat': 0.2},
      {'name': 'Tomato sauce',           'calories': 29.0,  'protein': 1.4,  'carbs': 6.1,  'fat': 0.2},
      {'name': 'Tomato marinara sauce',  'calories': 50.0,  'protein': 2.0,  'carbs': 8.0,  'fat': 1.5},
      {'name': 'Onion',                  'calories': 40.0,  'protein': 1.1,  'carbs': 9.3,  'fat': 0.1},
      {'name': 'Garlic',                 'calories': 149.0, 'protein': 6.4,  'carbs': 33.1, 'fat': 0.5},
      {'name': 'Carrot',                 'calories': 41.0,  'protein': 0.9,  'carbs': 9.6,  'fat': 0.2},
      {'name': 'Zucchini',               'calories': 17.0,  'protein': 1.2,  'carbs': 3.1,  'fat': 0.3},
      {'name': 'Turnip',                 'calories': 28.0,  'protein': 0.9,  'carbs': 6.4,  'fat': 0.1},
      {'name': 'Potato (fried)',         'calories': 312.0, 'protein': 3.4,  'carbs': 41.4, 'fat': 15.0},
      {'name': 'Potato (boiled)',        'calories': 87.0,  'protein': 1.9,  'carbs': 20.1, 'fat': 0.1},
      {'name': 'Lettuce',                'calories': 15.0,  'protein': 1.4,  'carbs': 2.9,  'fat': 0.2},
      {'name': 'Bell pepper',            'calories': 31.0,  'protein': 1.0,  'carbs': 6.0,  'fat': 0.3},
      {'name': 'Mushroom',               'calories': 22.0,  'protein': 3.1,  'carbs': 3.3,  'fat': 0.3},
      {'name': 'Corn',                   'calories': 86.0,  'protein': 3.2,  'carbs': 19.0, 'fat': 1.2},
      {'name': 'Peas (cooked)',          'calories': 84.0,  'protein': 5.4,  'carbs': 15.6, 'fat': 0.2},
      {'name': 'Spinach',                'calories': 23.0,  'protein': 2.9,  'carbs': 3.6,  'fat': 0.4},
      {'name': 'Cucumber',               'calories': 15.0,  'protein': 0.7,  'carbs': 3.6,  'fat': 0.1},
      {'name': 'Olives',                 'calories': 145.0, 'protein': 1.0,  'carbs': 3.8,  'fat': 15.3},
      {'name': 'Lemon juice',            'calories': 22.0,  'protein': 0.4,  'carbs': 6.9,  'fat': 0.2},
      {'name': 'Eggplant',               'calories': 25.0,  'protein': 1.0,  'carbs': 5.9,  'fat': 0.2},
      {'name': 'Grape leaves',           'calories': 90.0,  'protein': 5.0,  'carbs': 17.0, 'fat': 0.7},
      {'name': 'Green beans',            'calories': 31.0,  'protein': 1.8,  'carbs': 7.1,  'fat': 0.2},
      {'name': 'Celery',                 'calories': 16.0,  'protein': 0.7,  'carbs': 3.0,  'fat': 0.2},
      {'name': 'Broccoli',               'calories': 34.0,  'protein': 2.8,  'carbs': 6.6,  'fat': 0.4},
      // Fruits
      {'name': 'Banana',                 'calories': 89.0,  'protein': 1.1,  'carbs': 22.8, 'fat': 0.3},
      {'name': 'Apple',                  'calories': 52.0,  'protein': 0.3,  'carbs': 13.8, 'fat': 0.2},
      {'name': 'Orange',                 'calories': 47.0,  'protein': 0.9,  'carbs': 11.8, 'fat': 0.1},
      {'name': 'Strawberry',             'calories': 32.0,  'protein': 0.7,  'carbs': 7.7,  'fat': 0.3},
      {'name': 'Dates',                  'calories': 282.0, 'protein': 2.5,  'carbs': 75.0, 'fat': 0.4},
      // Sauces & condiments
      {'name': 'Cream sauce (bechamel)', 'calories': 120.0, 'protein': 3.5,  'carbs': 8.0,  'fat': 8.5},
      {'name': 'Curry sauce',            'calories': 110.0, 'protein': 3.0,  'carbs': 9.0,  'fat': 7.0},
      {'name': 'Caesar dressing',        'calories': 360.0, 'protein': 4.0,  'carbs': 7.0,  'fat': 36.0},
      {'name': 'Tahini',                 'calories': 595.0, 'protein': 17.0, 'carbs': 21.2, 'fat': 53.8},
      {'name': 'Hummus',                 'calories': 177.0, 'protein': 7.9,  'carbs': 14.3, 'fat': 10.6},
      {'name': 'Honey',                  'calories': 304.0, 'protein': 0.3,  'carbs': 82.4, 'fat': 0.0},
      {'name': 'Syrup (maple)',          'calories': 260.0, 'protein': 0.0,  'carbs': 67.0, 'fat': 0.1},
      {'name': 'Ketchup',                'calories': 101.0, 'protein': 1.7,  'carbs': 25.0, 'fat': 0.1},
      {'name': 'Mustard',                'calories': 66.0,  'protein': 4.0,  'carbs': 6.0,  'fat': 3.7},
      {'name': 'Soy sauce',              'calories': 53.0,  'protein': 8.1,  'carbs': 4.9,  'fat': 0.6},
      {'name': 'Miso paste',             'calories': 199.0, 'protein': 12.0, 'carbs': 26.5, 'fat': 6.0},
      {'name': 'Harissa paste',          'calories': 95.0,  'protein': 3.0,  'carbs': 10.0, 'fat': 5.0},
      {'name': 'Chermoula sauce',        'calories': 80.0,  'protein': 1.5,  'carbs': 4.0,  'fat': 6.5},
      // Oils & fats
      {'name': 'Olive oil',              'calories': 884.0, 'protein': 0.0,  'carbs': 0.0,  'fat': 100.0},
      {'name': 'Vegetable oil',          'calories': 884.0, 'protein': 0.0,  'carbs': 0.0,  'fat': 100.0},
      // Nuts & seeds
      {'name': 'Walnuts',                'calories': 654.0, 'protein': 15.2, 'carbs': 13.7, 'fat': 65.2},
      {'name': 'Pistachios',             'calories': 562.0, 'protein': 20.2, 'carbs': 27.2, 'fat': 45.3},
      {'name': 'Almonds',                'calories': 579.0, 'protein': 21.2, 'carbs': 21.6, 'fat': 49.9},
      // Sweets & baking
      {'name': 'Sugar',                  'calories': 387.0, 'protein': 0.0,  'carbs': 99.8, 'fat': 0.0},
      {'name': 'Flour (all-purpose)',    'calories': 364.0, 'protein': 10.3, 'carbs': 76.3, 'fat': 1.0},
      {'name': 'Chocolate (dark)',       'calories': 546.0, 'protein': 4.9,  'carbs': 60.0, 'fat': 31.3},
      {'name': 'Cocoa powder',           'calories': 228.0, 'protein': 19.6, 'carbs': 57.9, 'fat': 13.7},
      {'name': 'Baklava syrup',          'calories': 280.0, 'protein': 0.2,  'carbs': 72.0, 'fat': 0.1},
      // Herbs & spices
      {'name': 'Ras el Hanout',          'calories': 30.0,  'protein': 1.5,  'carbs': 5.0,  'fat': 0.5},
      {'name': 'Parsley',                'calories': 36.0,  'protein': 3.0,  'carbs': 6.3,  'fat': 0.8},
      {'name': 'Cilantro',               'calories': 23.0,  'protein': 2.1,  'carbs': 3.7,  'fat': 0.5},
      {'name': 'Cumin (ground)',         'calories': 375.0, 'protein': 17.8, 'carbs': 44.2, 'fat': 22.3},
      {'name': 'Paprika',                'calories': 282.0, 'protein': 14.1, 'carbs': 53.9, 'fat': 12.9},
      {'name': 'Chili powder',           'calories': 282.0, 'protein': 12.5, 'carbs': 49.7, 'fat': 14.3},
      {'name': 'Ginger (fresh)',         'calories': 80.0,  'protein': 1.8,  'carbs': 17.8, 'fat': 0.8},
      {'name': 'Cinnamon',               'calories': 247.0, 'protein': 4.0,  'carbs': 80.6, 'fat': 1.2},
      {'name': 'Oregano (dried)',        'calories': 265.0, 'protein': 9.0,  'carbs': 68.9, 'fat': 4.3},
      // Broth
      {'name': 'Broth (chicken)',        'calories': 15.0,  'protein': 1.5,  'carbs': 1.4,  'fat': 0.5},
      {'name': 'Dashi broth',            'calories': 10.0,  'protein': 1.0,  'carbs': 1.0,  'fat': 0.2},
    ];

    final b1 = db.batch();
    for (final ing in ingredients) {
      b1.insert('ingredients', ing,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await b1.commit(noResult: true);

    // ── Foods catalog ─────────────────────────
    final foods = [
      // Model classes
      {'class_name': 'Bourek',             'display_name': 'Bourek 🇩🇿',          'category': 'algerian'},
      {'class_name': 'KoftaFinal',         'display_name': 'Kofta 🇩🇿',           'category': 'algerian'},
      {'class_name': 'chourba',            'display_name': 'Chourba 🇩🇿',          'category': 'algerian'},
      {'class_name': 'couscous',           'display_name': 'Couscous 🇩🇿',         'category': 'algerian'},
      {'class_name': 'baklava',            'display_name': 'Baklava',              'category': 'dessert'},
      {'class_name': 'caesar_salad',       'display_name': 'Caesar Salad',         'category': 'salad'},
      {'class_name': 'cheesecake',         'display_name': 'Cheesecake',           'category': 'dessert'},
      {'class_name': 'chicken_curry',      'display_name': 'Chicken Curry',        'category': 'main'},
      {'class_name': 'chicken_quesadilla', 'display_name': 'Chicken Quesadilla',   'category': 'main'},
      {'class_name': 'chocolate_cake',     'display_name': 'Chocolate Cake',       'category': 'dessert'},
      {'class_name': 'falafel',            'display_name': 'Falafel',              'category': 'main'},
      {'class_name': 'fish_and_chips',     'display_name': 'Fish & Chips',         'category': 'main'},
      {'class_name': 'french_fries',       'display_name': 'French Fries',         'category': 'side'},
      {'class_name': 'fried_rice',         'display_name': 'Fried Rice',           'category': 'main'},
      {'class_name': 'garlic_bread',       'display_name': 'Garlic Bread',         'category': 'side'},
      {'class_name': 'greek_salad',        'display_name': 'Greek Salad',          'category': 'salad'},
      {'class_name': 'grilled_salmon',     'display_name': 'Grilled Salmon',       'category': 'main'},
      {'class_name': 'hamburger',          'display_name': 'Hamburger',            'category': 'main'},
      {'class_name': 'hot_dog',            'display_name': 'Hot Dog',              'category': 'main'},
      {'class_name': 'hummus',             'display_name': 'Hummus',               'category': 'side'},
      {'class_name': 'ice_cream',          'display_name': 'Ice Cream',            'category': 'dessert'},
      {'class_name': 'lasagna',            'display_name': 'Lasagna',              'category': 'main'},
      {'class_name': 'mussels',            'display_name': 'Mussels',              'category': 'main'},
      {'class_name': 'omelette',           'display_name': 'Omelette',             'category': 'breakfast'},
      {'class_name': 'paella',             'display_name': 'Paella',               'category': 'main'},
      {'class_name': 'pancakes',           'display_name': 'Pancakes',             'category': 'breakfast'},
      {'class_name': 'pizza',              'display_name': 'Pizza',                'category': 'main'},
      {'class_name': 'ramen',              'display_name': 'Ramen',                'category': 'main'},
      {'class_name': 'red_sauce_pasta',    'display_name': 'Red Sauce Pasta',      'category': 'main'},
      {'class_name': 'rice_dishes',        'display_name': 'Rice Dishes',          'category': 'main'},
      {'class_name': 'steak',              'display_name': 'Steak',                'category': 'main'},
      {'class_name': 'tacos',              'display_name': 'Tacos',                'category': 'main'},
      {'class_name': 'white_sauce_pasta',  'display_name': 'White Sauce Pasta',    'category': 'main'},
      // Extra Algerian dishes
      {'class_name': 'harira',             'display_name': 'Harira 🇩🇿',           'category': 'algerian'},
      {'class_name': 'rechta',             'display_name': 'Rechta 🇩🇿',           'category': 'algerian'},
      {'class_name': 'mhajeb',             'display_name': 'Mhajeb 🇩🇿',           'category': 'algerian'},
      {'class_name': 'dolma',              'display_name': 'Dolma 🇩🇿',            'category': 'algerian'},
      {'class_name': 'mechoui',            'display_name': 'Mechoui 🇩🇿',          'category': 'algerian'},
      {'class_name': 'merguez_sandwich',   'display_name': 'Merguez Sandwich 🇩🇿', 'category': 'algerian'},
      {'class_name': 'berkoukes',          'display_name': 'Berkoukes 🇩🇿',        'category': 'algerian'},
      {'class_name': 'shorba_frik',        'display_name': 'Chorba Frik 🇩🇿',      'category': 'algerian'},
      // Everyday foods
      {'class_name': 'boiled_eggs',        'display_name': 'Boiled Eggs',          'category': 'breakfast'},
      {'class_name': 'fried_eggs',         'display_name': 'Fried Eggs',           'category': 'breakfast'},
      {'class_name': 'avocado_toast',      'display_name': 'Avocado Toast',        'category': 'breakfast'},
      {'class_name': 'yogurt_bowl',        'display_name': 'Yogurt Bowl',          'category': 'breakfast'},
      {'class_name': 'oatmeal',            'display_name': 'Oatmeal',              'category': 'breakfast'},
      {'class_name': 'fruit_salad',        'display_name': 'Fruit Salad',          'category': 'healthy'},
      {'class_name': 'green_salad',        'display_name': 'Green Salad',          'category': 'healthy'},
      {'class_name': 'grilled_chicken',    'display_name': 'Grilled Chicken',      'category': 'healthy'},
      {'class_name': 'lentil_soup',        'display_name': 'Lentil Soup',          'category': 'healthy'},
      {'class_name': 'vegetable_soup',     'display_name': 'Vegetable Soup',       'category': 'healthy'},
      {'class_name': 'tuna_salad',         'display_name': 'Tuna Salad',           'category': 'healthy'},
      {'class_name': 'banana',             'display_name': 'Banana',               'category': 'fruit'},
      {'class_name': 'apple',              'display_name': 'Apple',                'category': 'fruit'},
      {'class_name': 'dates_bowl',         'display_name': 'Dates',                'category': 'fruit'},
    ];

    final b2 = db.batch();
    for (final f in foods) {
      b2.insert('foods', f, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await b2.commit(noResult: true);

    // ── Food → ingredient mappings ─────────────
    final foodIngredients = [
      // ── ALGERIAN ──
      {'food': 'couscous',          'ingredient': 'Couscous (cooked)',      'grams': 200.0},
      {'food': 'couscous',          'ingredient': 'Lamb (cooked)',          'grams': 120.0},
      {'food': 'couscous',          'ingredient': 'Chickpeas (cooked)',     'grams': 60.0},
      {'food': 'couscous',          'ingredient': 'Carrot',                 'grams': 50.0},
      {'food': 'couscous',          'ingredient': 'Zucchini',               'grams': 50.0},
      {'food': 'couscous',          'ingredient': 'Turnip',                 'grams': 30.0},
      {'food': 'couscous',          'ingredient': 'Onion',                  'grams': 30.0},
      {'food': 'couscous',          'ingredient': 'Ras el Hanout',          'grams': 5.0},
      {'food': 'couscous',          'ingredient': 'Olive oil',              'grams': 10.0},

      {'food': 'Bourek',            'ingredient': 'Brik pastry',            'grams': 60.0},
      {'food': 'Bourek',            'ingredient': 'Beef (ground, cooked)',  'grams': 80.0},
      {'food': 'Bourek',            'ingredient': 'Egg',                    'grams': 50.0},
      {'food': 'Bourek',            'ingredient': 'Onion',                  'grams': 20.0},
      {'food': 'Bourek',            'ingredient': 'Parsley',                'grams': 5.0},
      {'food': 'Bourek',            'ingredient': 'Vegetable oil',          'grams': 15.0},

      {'food': 'chourba',           'ingredient': 'Lamb (cooked)',          'grams': 80.0},
      {'food': 'chourba',           'ingredient': 'Chickpeas (cooked)',     'grams': 50.0},
      {'food': 'chourba',           'ingredient': 'Tomato',                 'grams': 80.0},
      {'food': 'chourba',           'ingredient': 'Onion',                  'grams': 40.0},
      {'food': 'chourba',           'ingredient': 'Carrot',                 'grams': 40.0},
      {'food': 'chourba',           'ingredient': 'Pasta (cooked)',         'grams': 40.0},
      {'food': 'chourba',           'ingredient': 'Ras el Hanout',          'grams': 5.0},
      {'food': 'chourba',           'ingredient': 'Olive oil',              'grams': 8.0},

      {'food': 'KoftaFinal',        'ingredient': 'Chicken (cooked)',       'grams': 150.0},
      {'food': 'KoftaFinal',        'ingredient': 'Onion',                  'grams': 25.0},
      {'food': 'KoftaFinal',        'ingredient': 'Parsley',                'grams': 8.0},
      {'food': 'KoftaFinal',        'ingredient': 'Ras el Hanout',          'grams': 5.0},
      {'food': 'KoftaFinal',        'ingredient': 'Cumin (ground)',         'grams': 3.0},
      {'food': 'KoftaFinal',        'ingredient': 'Olives',                 'grams': 50.0},

      {'food': 'harira',            'ingredient': 'Lamb (cooked)',          'grams': 80.0},
      {'food': 'harira',            'ingredient': 'Lentils (cooked)',       'grams': 60.0},
      {'food': 'harira',            'ingredient': 'Chickpeas (cooked)',     'grams': 50.0},
      {'food': 'harira',            'ingredient': 'Tomato',                 'grams': 80.0},
      {'food': 'harira',            'ingredient': 'Celery',                 'grams': 30.0},
      {'food': 'harira',            'ingredient': 'Onion',                  'grams': 30.0},
      {'food': 'harira',            'ingredient': 'Vermicelli (cooked)',    'grams': 30.0},
      {'food': 'harira',            'ingredient': 'Parsley',                'grams': 8.0},
      {'food': 'harira',            'ingredient': 'Cilantro',               'grams': 8.0},

      {'food': 'rechta',            'ingredient': 'Vermicelli (cooked)',    'grams': 150.0},
      {'food': 'rechta',            'ingredient': 'Chicken (roasted)',      'grams': 120.0},
      {'food': 'rechta',            'ingredient': 'Turnip',                 'grams': 60.0},
      {'food': 'rechta',            'ingredient': 'Carrot',                 'grams': 40.0},
      {'food': 'rechta',            'ingredient': 'Onion',                  'grams': 30.0},
      {'food': 'rechta',            'ingredient': 'Broth (chicken)',        'grams': 50.0},
      {'food': 'rechta',            'ingredient': 'Ras el Hanout',          'grams': 5.0},

      {'food': 'mhajeb',            'ingredient': 'Semolina (cooked)',      'grams': 120.0},
      {'food': 'mhajeb',            'ingredient': 'Onion',                  'grams': 60.0},
      {'food': 'mhajeb',            'ingredient': 'Tomato',                 'grams': 60.0},
      {'food': 'mhajeb',            'ingredient': 'Bell pepper',            'grams': 40.0},
      {'food': 'mhajeb',            'ingredient': 'Vegetable oil',          'grams': 15.0},

      {'food': 'dolma',             'ingredient': 'Grape leaves',           'grams': 80.0},
      {'food': 'dolma',             'ingredient': 'Rice (white, cooked)',   'grams': 80.0},
      {'food': 'dolma',             'ingredient': 'Beef (ground, cooked)',  'grams': 80.0},
      {'food': 'dolma',             'ingredient': 'Onion',                  'grams': 25.0},
      {'food': 'dolma',             'ingredient': 'Tomato sauce',           'grams': 50.0},
      {'food': 'dolma',             'ingredient': 'Ras el Hanout',          'grams': 5.0},

      {'food': 'mechoui',           'ingredient': 'Lamb shoulder (roasted)','grams': 200.0},
      {'food': 'mechoui',           'ingredient': 'Olive oil',              'grams': 15.0},
      {'food': 'mechoui',           'ingredient': 'Cumin (ground)',         'grams': 5.0},
      {'food': 'mechoui',           'ingredient': 'Paprika',                'grams': 5.0},
      {'food': 'mechoui',           'ingredient': 'Garlic',                 'grams': 10.0},

      {'food': 'merguez_sandwich',  'ingredient': 'Bread roll',             'grams': 80.0},
      {'food': 'merguez_sandwich',  'ingredient': 'Merguez sausage',        'grams': 100.0},
      {'food': 'merguez_sandwich',  'ingredient': 'Tomato',                 'grams': 30.0},
      {'food': 'merguez_sandwich',  'ingredient': 'Onion',                  'grams': 20.0},
      {'food': 'merguez_sandwich',  'ingredient': 'Harissa paste',          'grams': 10.0},

      {'food': 'berkoukes',         'ingredient': 'Semolina (cooked)',      'grams': 120.0},
      {'food': 'berkoukes',         'ingredient': 'Lamb (cooked)',          'grams': 100.0},
      {'food': 'berkoukes',         'ingredient': 'Turnip',                 'grams': 50.0},
      {'food': 'berkoukes',         'ingredient': 'Carrot',                 'grams': 40.0},
      {'food': 'berkoukes',         'ingredient': 'Chickpeas (cooked)',     'grams': 40.0},
      {'food': 'berkoukes',         'ingredient': 'Ras el Hanout',          'grams': 5.0},

      {'food': 'shorba_frik',       'ingredient': 'Lamb (cooked)',          'grams': 80.0},
      {'food': 'shorba_frik',       'ingredient': 'Semolina (cooked)',      'grams': 60.0},
      {'food': 'shorba_frik',       'ingredient': 'Chickpeas (cooked)',     'grams': 40.0},
      {'food': 'shorba_frik',       'ingredient': 'Tomato',                 'grams': 60.0},
      {'food': 'shorba_frik',       'ingredient': 'Onion',                  'grams': 30.0},
      {'food': 'shorba_frik',       'ingredient': 'Ras el Hanout',          'grams': 5.0},
      {'food': 'shorba_frik',       'ingredient': 'Cilantro',               'grams': 8.0},

      // ── MODEL CLASSES ──
      {'food': 'baklava',           'ingredient': 'Phyllo dough',           'grams': 30.0},
      {'food': 'baklava',           'ingredient': 'Walnuts',                'grams': 25.0},
      {'food': 'baklava',           'ingredient': 'Pistachios',             'grams': 10.0},
      {'food': 'baklava',           'ingredient': 'Butter',                 'grams': 15.0},
      {'food': 'baklava',           'ingredient': 'Baklava syrup',          'grams': 20.0},

      {'food': 'caesar_salad',      'ingredient': 'Lettuce',                'grams': 120.0},
      {'food': 'caesar_salad',      'ingredient': 'Parmesan',               'grams': 20.0},
      {'food': 'caesar_salad',      'ingredient': 'Caesar dressing',        'grams': 40.0},
      {'food': 'caesar_salad',      'ingredient': 'Bread (white)',          'grams': 20.0},
      {'food': 'caesar_salad',      'ingredient': 'Chicken (grilled)',      'grams': 80.0},

      {'food': 'cheesecake',        'ingredient': 'Cheesecake filling',     'grams': 90.0},
      {'food': 'cheesecake',        'ingredient': 'Graham cracker crust',   'grams': 30.0},
      {'food': 'cheesecake',        'ingredient': 'Sugar',                  'grams': 15.0},

      {'food': 'chicken_curry',     'ingredient': 'Chicken (curry pieces)', 'grams': 150.0},
      {'food': 'chicken_curry',     'ingredient': 'Curry sauce',            'grams': 100.0},
      {'food': 'chicken_curry',     'ingredient': 'Rice (white, cooked)',   'grams': 150.0},
      {'food': 'chicken_curry',     'ingredient': 'Onion',                  'grams': 40.0},

      {'food': 'chicken_quesadilla','ingredient': 'Tortilla (flour)',       'grams': 80.0},
      {'food': 'chicken_quesadilla','ingredient': 'Chicken (grilled)',      'grams': 80.0},
      {'food': 'chicken_quesadilla','ingredient': 'Cheddar cheese',         'grams': 40.0},
      {'food': 'chicken_quesadilla','ingredient': 'Bell pepper',            'grams': 20.0},

      {'food': 'chocolate_cake',    'ingredient': 'Flour (all-purpose)',    'grams': 40.0},
      {'food': 'chocolate_cake',    'ingredient': 'Sugar',                  'grams': 35.0},
      {'food': 'chocolate_cake',    'ingredient': 'Cocoa powder',           'grams': 15.0},
      {'food': 'chocolate_cake',    'ingredient': 'Egg',                    'grams': 25.0},
      {'food': 'chocolate_cake',    'ingredient': 'Butter',                 'grams': 20.0},

      {'food': 'falafel',           'ingredient': 'Falafel',                'grams': 120.0},
      {'food': 'falafel',           'ingredient': 'Tahini',                 'grams': 20.0},
      {'food': 'falafel',           'ingredient': 'Tomato',                 'grams': 30.0},

      {'food': 'fish_and_chips',    'ingredient': 'Fish (battered, fried)', 'grams': 180.0},
      {'food': 'fish_and_chips',    'ingredient': 'Potato (fried)',         'grams': 150.0},

      {'food': 'french_fries',      'ingredient': 'Potato (fried)',         'grams': 150.0},
      {'food': 'french_fries',      'ingredient': 'Ketchup',                'grams': 20.0},

      {'food': 'fried_rice',        'ingredient': 'Rice (white, cooked)',   'grams': 200.0},
      {'food': 'fried_rice',        'ingredient': 'Egg',                    'grams': 50.0},
      {'food': 'fried_rice',        'ingredient': 'Peas (cooked)',          'grams': 30.0},
      {'food': 'fried_rice',        'ingredient': 'Soy sauce',              'grams': 10.0},
      {'food': 'fried_rice',        'ingredient': 'Vegetable oil',          'grams': 10.0},

      {'food': 'garlic_bread',      'ingredient': 'Garlic bread',           'grams': 80.0},

      {'food': 'greek_salad',       'ingredient': 'Tomato',                 'grams': 80.0},
      {'food': 'greek_salad',       'ingredient': 'Cucumber',               'grams': 60.0},
      {'food': 'greek_salad',       'ingredient': 'Feta cheese',            'grams': 50.0},
      {'food': 'greek_salad',       'ingredient': 'Olives',                 'grams': 30.0},
      {'food': 'greek_salad',       'ingredient': 'Olive oil',              'grams': 15.0},

      {'food': 'grilled_salmon',    'ingredient': 'Salmon (grilled)',       'grams': 180.0},
      {'food': 'grilled_salmon',    'ingredient': 'Lemon juice',            'grams': 10.0},
      {'food': 'grilled_salmon',    'ingredient': 'Olive oil',              'grams': 10.0},

      {'food': 'hamburger',         'ingredient': 'Bread roll',             'grams': 80.0},
      {'food': 'hamburger',         'ingredient': 'Burger patty (beef)',    'grams': 100.0},
      {'food': 'hamburger',         'ingredient': 'Lettuce',                'grams': 15.0},
      {'food': 'hamburger',         'ingredient': 'Tomato',                 'grams': 20.0},
      {'food': 'hamburger',         'ingredient': 'Cheddar cheese',         'grams': 20.0},
      {'food': 'hamburger',         'ingredient': 'Ketchup',                'grams': 15.0},

      {'food': 'hot_dog',           'ingredient': 'Bread roll',             'grams': 60.0},
      {'food': 'hot_dog',           'ingredient': 'Hot dog sausage',        'grams': 70.0},
      {'food': 'hot_dog',           'ingredient': 'Ketchup',                'grams': 15.0},
      {'food': 'hot_dog',           'ingredient': 'Mustard',                'grams': 5.0},

      {'food': 'hummus',            'ingredient': 'Hummus',                 'grams': 80.0},
      {'food': 'hummus',            'ingredient': 'Olive oil',              'grams': 10.0},
      {'food': 'hummus',            'ingredient': 'Bread (white)',          'grams': 40.0},

      {'food': 'ice_cream',         'ingredient': 'Ice cream (vanilla)',    'grams': 100.0},

      {'food': 'lasagna',           'ingredient': 'Pasta (cooked)',         'grams': 80.0},
      {'food': 'lasagna',           'ingredient': 'Beef (ground, cooked)',  'grams': 100.0},
      {'food': 'lasagna',           'ingredient': 'Tomato marinara sauce',  'grams': 80.0},
      {'food': 'lasagna',           'ingredient': 'Cream sauce (bechamel)', 'grams': 60.0},
      {'food': 'lasagna',           'ingredient': 'Mozzarella',             'grams': 40.0},

      {'food': 'mussels',           'ingredient': 'Mussels (cooked)',       'grams': 200.0},
      {'food': 'mussels',           'ingredient': 'Butter',                 'grams': 20.0},
      {'food': 'mussels',           'ingredient': 'Garlic',                 'grams': 10.0},

      {'food': 'omelette',          'ingredient': 'Egg',                    'grams': 150.0},
      {'food': 'omelette',          'ingredient': 'Butter',                 'grams': 10.0},
      {'food': 'omelette',          'ingredient': 'Cheddar cheese',         'grams': 20.0},

      {'food': 'paella',            'ingredient': 'Rice (basmati, cooked)', 'grams': 150.0},
      {'food': 'paella',            'ingredient': 'Shrimp (cooked)',        'grams': 80.0},
      {'food': 'paella',            'ingredient': 'Mussels (cooked)',       'grams': 60.0},
      {'food': 'paella',            'ingredient': 'Bell pepper',            'grams': 40.0},
      {'food': 'paella',            'ingredient': 'Olive oil',              'grams': 15.0},

      {'food': 'pancakes',          'ingredient': 'Pancake batter',         'grams': 100.0},
      {'food': 'pancakes',          'ingredient': 'Butter',                 'grams': 10.0},
      {'food': 'pancakes',          'ingredient': 'Syrup (maple)',          'grams': 30.0},

      {'food': 'pizza',             'ingredient': 'Bread (white)',          'grams': 60.0},
      {'food': 'pizza',             'ingredient': 'Tomato marinara sauce',  'grams': 30.0},
      {'food': 'pizza',             'ingredient': 'Mozzarella',             'grams': 40.0},

      {'food': 'ramen',             'ingredient': 'Ramen noodles (cooked)', 'grams': 150.0},
      {'food': 'ramen',             'ingredient': 'Broth (chicken)',        'grams': 150.0},
      {'food': 'ramen',             'ingredient': 'Egg',                    'grams': 50.0},
      {'food': 'ramen',             'ingredient': 'Miso paste',             'grams': 15.0},

      {'food': 'red_sauce_pasta',   'ingredient': 'Pasta (cooked)',         'grams': 180.0},
      {'food': 'red_sauce_pasta',   'ingredient': 'Tomato marinara sauce',  'grams': 100.0},
      {'food': 'red_sauce_pasta',   'ingredient': 'Parmesan',               'grams': 20.0},

      {'food': 'rice_dishes',       'ingredient': 'Rice (white, cooked)',   'grams': 200.0},
      {'food': 'rice_dishes',       'ingredient': 'Olive oil',              'grams': 10.0},

      {'food': 'steak',             'ingredient': 'Beef (steak, grilled)',  'grams': 200.0},
      {'food': 'steak',             'ingredient': 'Butter',                 'grams': 15.0},
      {'food': 'steak',             'ingredient': 'Garlic',                 'grams': 5.0},

      {'food': 'tacos',             'ingredient': 'Tortilla (flour)',       'grams': 60.0},
      {'food': 'tacos',             'ingredient': 'Beef (ground, cooked)',  'grams': 80.0},
      {'food': 'tacos',             'ingredient': 'Lettuce',                'grams': 15.0},
      {'food': 'tacos',             'ingredient': 'Cheddar cheese',         'grams': 20.0},

      {'food': 'white_sauce_pasta', 'ingredient': 'Pasta (cooked)',         'grams': 180.0},
      {'food': 'white_sauce_pasta', 'ingredient': 'Cream sauce (bechamel)', 'grams': 100.0},
      {'food': 'white_sauce_pasta', 'ingredient': 'Parmesan',               'grams': 20.0},

      // ── EVERYDAY FOODS ──
      {'food': 'boiled_eggs',       'ingredient': 'Egg',                    'grams': 150.0},

      {'food': 'fried_eggs',        'ingredient': 'Egg',                    'grams': 150.0},
      {'food': 'fried_eggs',        'ingredient': 'Butter',                 'grams': 10.0},

      {'food': 'avocado_toast',     'ingredient': 'Bread (white)',          'grams': 80.0},
      {'food': 'avocado_toast',     'ingredient': 'Lemon juice',            'grams': 5.0},

      {'food': 'yogurt_bowl',       'ingredient': 'Yogurt (Greek)',         'grams': 150.0},
      {'food': 'yogurt_bowl',       'ingredient': 'Honey',                  'grams': 15.0},
      {'food': 'yogurt_bowl',       'ingredient': 'Strawberry',             'grams': 50.0},

      {'food': 'oatmeal',           'ingredient': 'Oats (cooked)',          'grams': 150.0},
      {'food': 'oatmeal',           'ingredient': 'Milk (whole)',           'grams': 100.0},
      {'food': 'oatmeal',           'ingredient': 'Honey',                  'grams': 10.0},
      {'food': 'oatmeal',           'ingredient': 'Banana',                 'grams': 60.0},

      {'food': 'fruit_salad',       'ingredient': 'Apple',                  'grams': 80.0},
      {'food': 'fruit_salad',       'ingredient': 'Banana',                 'grams': 60.0},
      {'food': 'fruit_salad',       'ingredient': 'Orange',                 'grams': 80.0},
      {'food': 'fruit_salad',       'ingredient': 'Strawberry',             'grams': 50.0},

      {'food': 'green_salad',       'ingredient': 'Lettuce',                'grams': 100.0},
      {'food': 'green_salad',       'ingredient': 'Cucumber',               'grams': 50.0},
      {'food': 'green_salad',       'ingredient': 'Tomato',                 'grams': 50.0},
      {'food': 'green_salad',       'ingredient': 'Olive oil',              'grams': 10.0},
      {'food': 'green_salad',       'ingredient': 'Lemon juice',            'grams': 8.0},

      {'food': 'grilled_chicken',   'ingredient': 'Chicken (grilled)',      'grams': 200.0},
      {'food': 'grilled_chicken',   'ingredient': 'Olive oil',              'grams': 10.0},
      {'food': 'grilled_chicken',   'ingredient': 'Garlic',                 'grams': 5.0},

      {'food': 'lentil_soup',       'ingredient': 'Lentils (cooked)',       'grams': 150.0},
      {'food': 'lentil_soup',       'ingredient': 'Onion',                  'grams': 40.0},
      {'food': 'lentil_soup',       'ingredient': 'Tomato',                 'grams': 60.0},
      {'food': 'lentil_soup',       'ingredient': 'Cumin (ground)',         'grams': 3.0},
      {'food': 'lentil_soup',       'ingredient': 'Olive oil',              'grams': 10.0},

      {'food': 'vegetable_soup',    'ingredient': 'Carrot',                 'grams': 60.0},
      {'food': 'vegetable_soup',    'ingredient': 'Potato (boiled)',        'grams': 80.0},
      {'food': 'vegetable_soup',    'ingredient': 'Zucchini',               'grams': 50.0},
      {'food': 'vegetable_soup',    'ingredient': 'Onion',                  'grams': 30.0},
      {'food': 'vegetable_soup',    'ingredient': 'Tomato',                 'grams': 50.0},

      {'food': 'tuna_salad',        'ingredient': 'Tuna (canned)',          'grams': 120.0},
      {'food': 'tuna_salad',        'ingredient': 'Lettuce',                'grams': 60.0},
      {'food': 'tuna_salad',        'ingredient': 'Tomato',                 'grams': 50.0},
      {'food': 'tuna_salad',        'ingredient': 'Olive oil',              'grams': 10.0},
      {'food': 'tuna_salad',        'ingredient': 'Lemon juice',            'grams': 8.0},

      {'food': 'banana',            'ingredient': 'Banana',                 'grams': 120.0},
      {'food': 'apple',             'ingredient': 'Apple',                  'grams': 150.0},
      {'food': 'dates_bowl',        'ingredient': 'Dates',                  'grams': 100.0},
    ];

    final b3 = db.batch();
    for (final fi in foodIngredients) {
      b3.insert('food_ingredients', {
        'food_class_name':  fi['food'],
        'ingredient_name':  fi['ingredient'],
        'default_grams':    fi['grams'],
      });
    }
    await b3.commit(noResult: true);
  }
}
