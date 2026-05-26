import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const _keyCalorieGoal = 'daily_calorie_goal';
  static const _keyCarbGoal    = 'daily_carb_goal';
  static const _keyProteinGoal = 'daily_protein_goal';
  static const _keyFatGoal     = 'daily_fat_goal';

  // Stored inside the same logs subcollection that Firestore rules already cover
  static const _prefsDocId = '_preferences';

  final _firestore = FirebaseFirestore.instance;

  int _dailyCalorieGoal = 2000;
  int _dailyCarbGoal    = 250;
  int _dailyProteinGoal = 125;
  int _dailyFatGoal     = 56;

  int get dailyCalorieGoal => _dailyCalorieGoal;
  int get dailyCarbGoal    => _dailyCarbGoal;
  int get dailyProteinGoal => _dailyProteinGoal;
  int get dailyFatGoal     => _dailyFatGoal;

  // ── Load from local SharedPreferences (fast, called at startup) ──
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyCalorieGoal = prefs.getInt(_keyCalorieGoal) ?? 2000;
    _dailyCarbGoal    = prefs.getInt(_keyCarbGoal)    ?? 250;
    _dailyProteinGoal = prefs.getInt(_keyProteinGoal) ?? 125;
    _dailyFatGoal     = prefs.getInt(_keyFatGoal)     ?? 56;
    notifyListeners();
  }

  // ── Sync from Firestore after login (restores goals on new device) ──
  Future<void> syncFromCloud(String userId) async {
    try {
      final doc = await _firestore
          .collection('meal_logs')
          .doc(userId)
          .collection('logs')
          .doc(_prefsDocId)
          .get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data[_keyCalorieGoal] != null) {
        _dailyCalorieGoal = (data[_keyCalorieGoal] as num).toInt();
        await prefs.setInt(_keyCalorieGoal, _dailyCalorieGoal);
      }
      if (data[_keyCarbGoal] != null) {
        _dailyCarbGoal = (data[_keyCarbGoal] as num).toInt();
        await prefs.setInt(_keyCarbGoal, _dailyCarbGoal);
      }
      if (data[_keyProteinGoal] != null) {
        _dailyProteinGoal = (data[_keyProteinGoal] as num).toInt();
        await prefs.setInt(_keyProteinGoal, _dailyProteinGoal);
      }
      if (data[_keyFatGoal] != null) {
        _dailyFatGoal = (data[_keyFatGoal] as num).toInt();
        await prefs.setInt(_keyFatGoal, _dailyFatGoal);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('PreferencesService.syncFromCloud error: $e');
    }
  }

  // ── Write goals to Firestore ──
  Future<void> _pushToCloud() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore
          .collection('meal_logs')
          .doc(userId)
          .collection('logs')
          .doc(_prefsDocId)
          .set({
            _keyCalorieGoal: _dailyCalorieGoal,
            _keyCarbGoal:    _dailyCarbGoal,
            _keyProteinGoal: _dailyProteinGoal,
            _keyFatGoal:     _dailyFatGoal,
          });
    } catch (e) {
      debugPrint('PreferencesService.pushToCloud error: $e');
    }
  }

  Future<void> setDailyCalorieGoal(int goal) async {
    _dailyCalorieGoal = goal.clamp(500, 10000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCalorieGoal, _dailyCalorieGoal);
    notifyListeners();
    await _pushToCloud();
  }

  Future<void> setDailyCarbGoal(int grams) async {
    _dailyCarbGoal = grams.clamp(10, 1000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCarbGoal, _dailyCarbGoal);
    notifyListeners();
    await _pushToCloud();
  }

  Future<void> setDailyProteinGoal(int grams) async {
    _dailyProteinGoal = grams.clamp(10, 500);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyProteinGoal, _dailyProteinGoal);
    notifyListeners();
    await _pushToCloud();
  }

  Future<void> setDailyFatGoal(int grams) async {
    _dailyFatGoal = grams.clamp(5, 500);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFatGoal, _dailyFatGoal);
    notifyListeners();
    await _pushToCloud();
  }
}
