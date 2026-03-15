// ── Prediction result from TFLite ────────────
class PredictionResult {
  final String className;
  final String displayName;
  final double confidence;
  final List<TopPrediction> topPredictions;

  const PredictionResult({
    required this.className,
    required this.displayName,
    required this.confidence,
    required this.topPredictions,
  });
}

class TopPrediction {
  final String className;
  final String displayName;
  final double confidence;
  const TopPrediction({
    required this.className,
    required this.displayName,
    required this.confidence,
  });
}

// ── Ingredient with nutritional values ───────
class Ingredient {
  final int? id;
  final String name;
  final double calories;    // per 100g
  final double protein;     // per 100g
  final double carbs;       // per 100g
  final double fat;         // per 100g
  double grams;             // user-adjusted portion

  Ingredient({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.grams,
  });

  // Scaled values based on current portion
  double get scaledCalories => calories * grams / 100;
  double get scaledProtein  => protein  * grams / 100;
  double get scaledCarbs    => carbs    * grams / 100;
  double get scaledFat      => fat      * grams / 100;

  Ingredient copyWith({double? grams}) => Ingredient(
    id:       id,
    name:     name,
    calories: calories,
    protein:  protein,
    carbs:    carbs,
    fat:      fat,
    grams:    grams ?? this.grams,
  );

  Map<String, dynamic> toMap() => {
    'name':     name,
    'calories': calories,
    'protein':  protein,
    'carbs':    carbs,
    'fat':      fat,
  };
}

// ── Food class with default ingredient list ───
class FoodEntry {
  final String className;
  final String displayName;
  final List<Ingredient> ingredients;

  const FoodEntry({
    required this.className,
    required this.displayName,
    required this.ingredients,
  });

  // Total nutrition summary
  double get totalCalories => ingredients.fold(0, (s, i) => s + i.scaledCalories);
  double get totalProtein  => ingredients.fold(0, (s, i) => s + i.scaledProtein);
  double get totalCarbs    => ingredients.fold(0, (s, i) => s + i.scaledCarbs);
  double get totalFat      => ingredients.fold(0, (s, i) => s + i.scaledFat);
}

// ── Meal log entry ────────────────────────────
class MealLog {
  final int? id;
  final String foodClassName;
  final String foodDisplayName;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime loggedAt;

  const MealLog({
    this.id,
    required this.foodClassName,
    required this.foodDisplayName,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() => {
    'food_class_name':   foodClassName,
    'food_display_name': foodDisplayName,
    'total_calories':    totalCalories,
    'total_protein':     totalProtein,
    'total_carbs':       totalCarbs,
    'total_fat':         totalFat,
    'logged_at':         loggedAt.toIso8601String(),
  };
}
