import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/models.dart';

class InferenceService {
  static const int   inputSize  = 224;
  static const int   topK       = 3;

  Interpreter?    _interpreter;
  List<String>    _labels = [];
  bool            get isReady => _interpreter != null && _labels.isNotEmpty;

  // ── Friendly display names ────────────────
  static const Map<String, String> _displayNames = {
    'Bourek':              'Bourek 🇩🇿',
    'KoftaFinal':          'Tadjine Zitoune 🇩🇿',        // ← fixes the display name
    'baklava':             'Baklava',
    'caesar_salad':        'Caesar Salad',
    'cheesecake':          'Cheesecake',
    'chicken_curry':       'Chicken Curry',
    'chicken_quesadilla':  'Chicken Quesadilla',
    'chocolate_cake':      'Chocolate Cake',
    'chourba':             'Chourba 🇩🇿',
    'couscous':            'Couscous 🇩🇿',
    'falafel':             'Falafel',
    'fish_and_chips':      'Fish & Chips',
    'french_fries':        'French Fries',
    'fried_rice':          'Fried Rice',
    'garlic_bread':        'Garlic Bread',
    'greek_salad':         'Greek Salad',
    'grilled_salmon':      'Grilled Salmon',
    'hamburger':           'Hamburger',
    'hot_dog':             'Hot Dog',
    'hummus':              'Hummus',
    'ice_cream':           'Ice Cream',
    'lasagna':             'Lasagna',
    'mussels':             'Mussels',
    'omelette':            'Omelette',
    'paella':              'Paella',
    'pancakes':            'Pancakes',
    'pizza':               'Pizza',
    'ramen':               'Ramen',
    'red_sauce_pasta':     'Red Sauce Pasta',
    'rice_dishes':         'Rice Dishes',
    'steak':               'Steak',
    'tacos':               'Tacos',
    'white_sauce_pasta':   'White Sauce Pasta',
  };

  static const Map<String, String> servingNotes = {
    // Algerian
    'Bourek':             '2 pieces (~200g)',
    'KoftaFinal':         '3 skewers (~200g)',
    'chourba':            '1 medium bowl (~350g)',
    'couscous':           '1 medium plate (~450g)',

    // Salads
    'caesar_salad':       '1 serving (~250g)',
    'greek_salad':        '1 serving (~250g)',

    // Meat & poultry
    'hamburger':          '1 burger (~200g)',
    'hot_dog':            '1 hot dog (~150g)',
    'steak':              '1 fillet (~200g)',
    'tacos':              '2 tacos (~160g)',
    'chicken_curry':      '1 serving with rice (~350g)',
    'chicken_quesadilla': '1 quesadilla (~200g)',

    // Seafood
    'grilled_salmon':     '1 fillet (~200g)',
    'mussels':            '1 serving (~300g)',
    'fish_and_chips':     '1 serving (~350g)',
    'paella':             '1 serving (~350g)',

    // Pasta & rice
    'lasagna':            '1 slice (~300g)',
    'red_sauce_pasta':    '1 plate (~300g)',
    'white_sauce_pasta':  '1 plate (~300g)',
    'fried_rice':         '1 plate (~300g)',
    'rice_dishes':        '1 medium bowl (~250g)',
    'ramen':              '1 bowl (~400g)',

    // Breakfast
    'pancakes':           '2 pancakes (~150g)',
    'omelette':           '1 omelette (~150g)',

    // Fast food & sides
    'pizza':              '1 slice (~120g)',
    'french_fries':       '1 medium serving (~150g)',
    'garlic_bread':       '2 slices (~80g)',
    'hummus':             '1 serving with bread (~120g)',
    'falafel':            '4 pieces (~120g)',

    // Desserts
    'cheesecake':         '1 slice (~120g)',
    'chocolate_cake':     '1 slice (~120g)',
    'ice_cream':          '1 scoop (~100g)',
    'baklava':            '2 pieces (~80g)',
  };

  String displayName(String className) =>
      _displayNames[className] ?? _formatClassName(className);

  String _formatClassName(String name) => name
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  // ── Initialise model ──────────────────────
  Future<void> init() async {
    await _loadLabels();
    await _loadModel();
  }

  Future<void> _loadLabels() async {
    final raw = await rootBundle.loadString('assets/model/model_labels.txt');
    _labels = raw.trim().split('\n').map((l) => l.trim()).toList();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
  }

  // ── Run inference ─────────────────────────
  Future<PredictionResult?> predict(File imageFile) async {
    if (!isReady) {
      return const PredictionResult(
        className: 'model_not_ready',
        displayName: 'Model not loaded yet',
        confidence: 0.0,
        topPredictions: [],
        );
    }

    // Preprocess
    final input = await _preprocessImage(imageFile);

    // Run model
    final output = [List.filled(_labels.length, 0.0)];
    _interpreter!.run(input, output);
    final probabilities = List<double>.from(output[0]);

    // Get top-K predictions
    final indexed = List.generate(probabilities.length,
        (i) => MapEntry(i, probabilities[i]))
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = indexed.take(topK).toList();
    final bestIdx  = top[0].key;
    final bestConf = top[0].value;
    final bestClass = _labels[bestIdx];

    return PredictionResult(
      className:    bestClass,
      displayName:  displayName(bestClass),
      confidence:   bestConf,
      topPredictions: top.map((e) => TopPrediction(
        className:   _labels[e.key],
        displayName: displayName(_labels[e.key]),
        confidence:  e.value,
      )).toList(),
    );
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File file) async {
    final bytes  = await file.readAsBytes();
    var image    = img.decodeImage(bytes)!;
    image        = img.copyResize(image, width: inputSize, height: inputSize);

    // Build [1, 300, 300, 3] float32 input in [0, 255]
    return List.generate(1, (_) =>
      List.generate(inputSize, (y) =>
        List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        })
      )
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}
