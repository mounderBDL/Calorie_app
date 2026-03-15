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
    'baby_back_ribs':    'Baby Back Ribs',
    'beef_carpaccio':    'Beef Carpaccio',
    'beef_tartare':      'Beef Tartare',
    'beet_salad':        'Beet Salad',
    'bibimbap':          'Bibimbap',
    'bourek':            'Bourek 🇩🇿',
    'bread_pudding':     'Bread Pudding',
    'breakfast_burrito': 'Breakfast Burrito',
    'bruschetta':        'Bruschetta',
    'burger':            'Burger',
    'caesar_salad':      'Caesar Salad',
    'chourba':           'Chourba 🇩🇿',
    'chocolate_cake':    'Chocolate Cake',
    'club_sandwich':     'Club Sandwich',
    'couscous':          'Couscous 🇩🇿',
    'donuts':            'Donuts',
    'dumplings':         'Dumplings',
    'edamame':           'Edamame',
    'eggs_benedict':     'Eggs Benedict',
    'french_fries':      'French Fries',
    'fried_rice':        'Fried Rice',
    'grilled_salmon':    'Grilled Salmon',
    'hamburger':         'Hamburger',
    'hot_dog':           'Hot Dog',
    'kofta':             'Kofta 🇩🇿',
    'lasagna':           'Lasagna',
    'miso_soup':         'Miso Soup',
    'pasta':             'Pasta',
    'pizza':             'Pizza',
    'red_sauce_pasta':   'Pasta Rossa',
    'rice':              'Rice',
    'sandwich':          'Sandwich',
    'white_sauce_pasta': 'Pasta Bianca',
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
