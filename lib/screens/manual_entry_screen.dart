import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'ingredients_screen.dart';
import '../models/models.dart';

// Maps a food className to one of the filter categories
String _getCategory(String className) {
  final n = className.toLowerCase();
  if (['couscous', 'chourba', 'bourek', 'koftafinal', 'harira',
       'rechta', 'mhajeb', 'dolma', 'chorba_frik', 'berkoukes',
       'mechoui', 'merguez'].any(n.contains)) { return 'Algerian'; }
  if (['cake', 'baklava', 'cheesecake', 'ice_cream', 'donut',
       'cookie', 'brownie', 'muffin', 'chocolate',
       'waffle', 'pancake'].any(n.contains)) { return 'Dessert'; }
  if (['salad', 'caesar', 'vegetable', 'broccoli',
       'spinach', 'fruit'].any(n.contains)) { return 'Healthy'; }
  if (['egg', 'omelette', 'yogurt', 'granola',
       'toast', 'breakfast'].any(n.contains)) { return 'Breakfast'; }
  return 'Main';
}

const _kCategories = ['All', 'Algerian', 'Main', 'Dessert', 'Healthy', 'Breakfast'];

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});
  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _searchCtrl    = TextEditingController();
  List<FoodEntry>      _results     = [];
  bool                 _isSearching = false;
  bool                 _hasSearched = false;
  String               _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
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

  List<FoodEntry> get _filteredResults {
    if (_selectedCategory == 'All') return _results;
    return _results
        .where((f) => _getCategory(f.className) == _selectedCategory)
        .toList();
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
    final colors   = Theme.of(context).extension<AppColors>()!;
    final filtered = _filteredResults;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Entry',
          style: GoogleFonts.plusJakartaSans(
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
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

          // ── Category filter chips ───────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: _kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _kCategories[i];
                return _CategoryChip(
                  label: cat,
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 10),

          // ── Results count ───────────────────
          if (_hasSearched && !_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'meal' : 'meals'}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: colors.textSecondary,
                      fontWeight: FontWeight.w500)),
                  if (_selectedCategory != 'All') ...[
                    const SizedBox(width: 6),
                    Text('· $_selectedCategory',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),

          // ── Results list ────────────────────
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2.5))
                : filtered.isEmpty && _hasSearched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: colors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('No meals found',
                              style: GoogleFonts.dmSans(
                                fontSize: 16, color: colors.textSecondary)),
                            const SizedBox(height: 6),
                            Text('Try a different search or category',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, color: colors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final food = filtered[i];
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

// ── Animated category chip ────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : colors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? AppTheme.softShadow : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
          child: Text(label),
        ),
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

  String get _emoji {
    final n = food.className.toLowerCase();
    if (['couscous', 'chourba', 'bourek', 'koftafinal', 'harira',
         'rechta', 'mhajeb', 'dolma', 'chorba_frik', 'berkoukes',
         'mechoui', 'merguez'].any(n.contains)) return '🇩🇿';
    if (['cake', 'baklava', 'cheesecake', 'ice_cream', 'pancake',
         'waffle', 'donut', 'cookie', 'brownie', 'muffin',
         'chocolate'].any(n.contains)) return '🍰';
    if (['salad', 'vegetable', 'spinach', 'broccoli'].any(n.contains)) return '🥗';
    if (['pizza'].any(n.contains)) return '🍕';
    if (['burger', 'hamburger', 'hot_dog', 'sandwich'].any(n.contains)) return '🍔';
    if (['pasta', 'lasagna', 'spaghetti', 'ramen', 'noodle'].any(n.contains)) return '🍝';
    if (['rice', 'fried_rice', 'paella', 'risotto'].any(n.contains)) return '🍚';
    if (['chicken', 'steak', 'beef', 'lamb', 'kofta', 'kebab'].any(n.contains)) return '🥩';
    if (['salmon', 'fish', 'shrimp', 'seafood'].any(n.contains)) { return '🐟'; }
    if (['soup', 'chili', 'stew'].any(n.contains)) { return '🍜'; }
    if (['egg', 'omelette'].any(n.contains)) { return '🍳'; }
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
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(_emoji,
                    style: const TextStyle(fontSize: 24))),
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
                    '${food.ingredients.length} ingredients',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  food.totalCalories.toStringAsFixed(0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: colors.textPrimary)),
                Text('kcal',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: colors.textSecondary)),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
