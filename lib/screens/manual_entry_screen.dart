import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'ingredients_screen.dart';
import '../models/models.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});
  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _searchCtrl   = TextEditingController();
  List<FoodEntry>     _results = [];
  bool                _isSearching = false;
  bool                _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Load all meals on open
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    final db      = context.read<DatabaseService>();
    final results = await db.searchFoods(query.trim());
    if (mounted) {
      setState(() {
        _results     = results;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _selectFood(FoodEntry food) async {
    final db          = context.read<DatabaseService>();
    final ingredients = await db.getIngredientsForFood(food.className);
    if (!mounted) return;

    final prediction = PredictionResult(
      className:      food.className,
      displayName:    food.displayName,
      confidence:     1.0,
      topPredictions: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientsScreen(
          prediction:  prediction,
          ingredients: ingredients,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Entry',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [

          // ── Search bar ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _search,
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for a meal...',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: colors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.primary, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            size: 18, color: colors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── Results count ───────────────────
          if (_hasSearched && !_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    _searchCtrl.text.isEmpty
                        ? '${_results.length} meals available'
                        : '${_results.length} results',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: colors.textSecondary,
                      fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          // ── Results list ────────────────────
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2.5))
                : _results.isEmpty && _hasSearched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: colors.textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text('No meals found',
                              style: GoogleFonts.dmSans(
                                fontSize: 16, color: colors.textSecondary)),
                            const SizedBox(height: 6),
                            Text('Try a different search term',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, color: colors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final food = _results[i];
                          return _FoodCard(
                            food: food,
                            colors: colors,
                            onTap: () => _selectFood(food),
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 30 * i),
                            duration: 300.ms,
                          ).slideX(begin: 0.04);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Food result card ──────────────────────────
class _FoodCard extends StatelessWidget {
  final FoodEntry   food;
  final AppColors   colors;
  final VoidCallback onTap;
  const _FoodCard({
    required this.food,
    required this.colors,
    required this.onTap,
  });

  // Emoji per food group
  String get _emoji {
    final n = food.className.toLowerCase();
    if (['couscous','chourba','bourek','koftafinal','harira',
         'rechta','mhajeb','dolma','chorba_frik','berkoukes',
         'mechoui','merguez'].any(n.contains)) return '🇩🇿';
    if (['cake','baklava','cheesecake','ice_cream','pancake',
         'waffle','donut','cookie','brownie','muffin',
         'chocolate'].any(n.contains)) return '🍰';
    if (['salad','vegetable','spinach','broccoli'].any(n.contains)) return '🥗';
    if (['pizza'].any(n.contains)) return '🍕';
    if (['burger','hamburger','hot_dog','sandwich'].any(n.contains)) return '🍔';
    if (['pasta','lasagna','spaghetti','ramen','noodle'].any(n.contains)) return '🍝';
    if (['rice','fried_rice','paella','risotto'].any(n.contains)) return '🍚';
    if (['chicken','steak','beef','lamb','kofta','kebab',
         'merguez','mechoui'].any(n.contains)) return '🥩';
    if (['salmon','fish','shrimp','mussel','seafood'].any(n.contains)) return '🐟';
    if (['soup','chili','stew','chourba','harira'].any(n.contains)) return '🍜';
    if (['egg','omelette','omelette'].any(n.contains)) return '🍳';
    if (['fruit','apple','banana','orange','mango'].any(n.contains)) return '🍎';
    if (['yogurt','milk','cheese'].any(n.contains)) return '🥛';
    if (['juice','smoothie','drink'].any(n.contains)) return '🥤';
    return '🍽';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(_emoji,
                    style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.displayName,
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    '${food.ingredients.length} default ingredients',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${food.totalCalories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.primary,
                  fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
