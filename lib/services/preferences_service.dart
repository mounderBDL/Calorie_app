import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const _keyCalorieGoal = 'daily_calorie_goal';
  static const _keyCarbGoal    = 'daily_carb_goal';
  static const _keyProteinGoal = 'daily_protein_goal';
  static const _keyFatGoal     = 'daily_fat_goal';

  int _dailyCalorieGoal = 2000;
  int _dailyCarbGoal    = 250;
  int _dailyProteinGoal = 125;
  int _dailyFatGoal     = 56;

  int get dailyCalorieGoal => _dailyCalorieGoal;
  int get dailyCarbGoal    => _dailyCarbGoal;
  int get dailyProteinGoal => _dailyProteinGoal;
  int get dailyFatGoal     => _dailyFatGoal;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyCalorieGoal = prefs.getInt(_keyCalorieGoal) ?? 2000;
    _dailyCarbGoal    = prefs.getInt(_keyCarbGoal)    ?? 250;
    _dailyProteinGoal = prefs.getInt(_keyProteinGoal) ?? 125;
    _dailyFatGoal     = prefs.getInt(_keyFatGoal)     ?? 56;
    notifyListeners();
  }

  Future<void> setDailyCalorieGoal(int goal) async {
    _dailyCalorieGoal = goal.clamp(500, 10000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCalorieGoal, _dailyCalorieGoal);
    notifyListeners();
  }

  Future<void> setDailyCarbGoal(int grams) async {
    _dailyCarbGoal = grams.clamp(10, 1000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCarbGoal, _dailyCarbGoal);
    notifyListeners();
  }

  Future<void> setDailyProteinGoal(int grams) async {
    _dailyProteinGoal = grams.clamp(10, 500);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyProteinGoal, _dailyProteinGoal);
    notifyListeners();
  }

  Future<void> setDailyFatGoal(int grams) async {
    _dailyFatGoal = grams.clamp(5, 500);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFatGoal, _dailyFatGoal);
    notifyListeners();
  }
}
