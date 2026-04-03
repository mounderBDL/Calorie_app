import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'nutrition_screen.dart';

class IngredientsScreen extends StatefulWidget {
  final PredictionResult prediction;
  final List<Ingredient> ingredients;

  const IngredientsScreen({
    super.key,
    required this.prediction,
    required this.ingredients,
  });

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  late List<Ingredient> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.ingredients);
  }

  double get _totalCalories =>
      _ingredients.fold(0, (s, i) => s + i.scaledCalories);
  double get _totalProtein =>
      _ingredients.fold(0, (s, i) => s + i.scaledProtein);
  double get _totalCarbs =>
      _ingredients.fold(0, (s, i) => s + i.scaledCarbs);
  double get _totalFat =>
      _ingredients.fold(0, (s, i) => s + i.scaledFat);

  void _updateGrams(int index, double newGrams) {
    setState(() {
      _ingredients[index] = _ingredients[index].copyWith(grams: newGrams);
    });
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
  }

  void _addIngredient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddIngredientSheet(
        onAdd: (ingredient) => setState(() => _ingredients.add(ingredient)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prediction.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Live calorie summary ──────────────
          _CalorieBanner(calories: _totalCalories)
              .animate().fadeIn(duration: 400.ms),

          // ── Ingredients list ──────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              itemCount: _ingredients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ing = _ingredients[index];
                return _IngredientCard(
                  ingredient: ing,
                  onGramsChanged: (g) => _updateGrams(index, g),
                  onRemove: () => _removeIngredient(index),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 60 * index),
                  duration: 350.ms,
                ).slideX(begin: 0.05);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        totalCalories: _totalCalories,
        onAddIngredient: _addIngredient,
        onViewNutrition: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NutritionScreen(
              prediction: widget.prediction,
              ingredients: _ingredients,
              totalCalories: _totalCalories,
              totalProtein:  _totalProtein,
              totalCarbs:    _totalCarbs,
              totalFat:      _totalFat,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live calorie banner ───────────────────────
class _CalorieBanner extends StatelessWidget {
  final double calories;
  const _CalorieBanner({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accentWarm],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Calories',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                )),
              Text('${calories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
            ],
          ),
          const Spacer(),
          Text('Tap to adjust\nportions below',
            textAlign: TextAlign.right,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            )),
        ],
      ),
    );
  }
}

// ── Ingredient card ───────────────────────────
class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final ValueChanged<double> onGramsChanged;
  final VoidCallback onRemove;

  const _IngredientCard({
    required this.ingredient,
    required this.onGramsChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ctrl   = TextEditingController(
        text: ingredient.grams.toStringAsFixed(0));

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(ingredient.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  )),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded,
                    color: colors.textSecondary, size: 22),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Grams input
              Expanded(
                child: Row(
                  children: [
                    Text('Portion: ',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: colors.textSecondary,
                      )),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppTheme.primary.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          final grams = double.tryParse(v) ?? 0;
                          if (grams > 0) onGramsChanged(grams);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text('g',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: colors.textSecondary,
                        )),
                    ),
                  ],
                ),
              ),
              // Calories for this ingredient
              Text(
                '${ingredient.scaledCalories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────
class _BottomBar extends StatelessWidget {
  final double totalCalories;
  final VoidCallback onAddIngredient;
  final VoidCallback onViewNutrition;

  const _BottomBar({
    required this.totalCalories,
    required this.onAddIngredient,
    required this.onViewNutrition,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
          18, 14, 18, MediaQuery.of(context).padding.bottom + 14),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onAddIngredient,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onViewNutrition,
              icon: const Icon(Icons.bar_chart_rounded, size: 20),
              label: const Text('View Nutrition'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add ingredient bottom sheet ───────────────
class _AddIngredientSheet extends StatefulWidget {
  final ValueChanged<Ingredient> onAdd;
  const _AddIngredientSheet({required this.onAdd});

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final _searchCtrl = TextEditingController();
  final _gramsCtrl  = TextEditingController(text: '100');

  // Manual entry controllers
  final _nameCtrl   = TextEditingController();
  final _calCtrl    = TextEditingController();
  final _protCtrl   = TextEditingController();
  final _carbCtrl   = TextEditingController();
  final _fatCtrl    = TextEditingController();

  List<Ingredient> _searchResults = [];
  Ingredient? _selected;
  bool _showManual = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);

    final db      = context.read<DatabaseService>();
    final results = await db.searchIngredients(query.trim());

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching   = false;
      });
    }
  }

  void _selectIngredient(Ingredient ing) {
    setState(() {
      _selected      = ing;
      _searchResults = [];
      _searchCtrl.text = ing.name;
    });
  }

  void _confirmAdd() {
    if (_selected != null) {
      final grams = double.tryParse(_gramsCtrl.text) ?? 100.0;
      widget.onAdd(_selected!.copyWith(grams: grams));
      Navigator.pop(context);
      return;
    }

    // Manual entry fallback
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.onAdd(Ingredient(
      name:     _nameCtrl.text.trim(),
      calories: double.tryParse(_calCtrl.text)  ?? 0,
      protein:  double.tryParse(_protCtrl.text) ?? 0,
      carbs:    double.tryParse(_carbCtrl.text) ?? 0,
      fat:      double.tryParse(_fatCtrl.text)  ?? 0,
      grams:    double.tryParse(_gramsCtrl.text) ?? 100,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          22, 20, 22, MediaQuery.of(context).viewInsets.bottom + 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text('Add Ingredient',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: colors.textPrimary)),

            const SizedBox(height: 6),
            Text(
              _showManual
                  ? 'Enter details manually'
                  : 'Search our database or add manually',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: colors.textSecondary)),

            const SizedBox(height: 18),

            if (!_showManual) ...[
              // ── Search mode ─────────────────
              // Search bar
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _search,
                style: GoogleFonts.dmSans(
                    fontSize: 15, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search ingredients...',
                  hintStyle: GoogleFonts.dmSans(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.primary, size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 18, color: colors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchResults = [];
                              _selected = null;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),

              // Loading indicator
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                    ),
                  ),
                ),

              // Search results
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.divider),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colors.divider),
                    itemBuilder: (_, i) {
                      final ing = _searchResults[i];
                      return ListTile(
                        dense: true,
                        title: Text(ing.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: colors.textPrimary)),
                        subtitle: Text(
                          '${ing.calories.toStringAsFixed(0)} kcal · '
                          'P ${ing.protein.toStringAsFixed(1)}g · '
                          'C ${ing.carbs.toStringAsFixed(1)}g · '
                          'F ${ing.fat.toStringAsFixed(1)}g',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: colors.textSecondary)),
                        trailing: const Icon(Icons.add_circle_rounded,
                            color: AppTheme.primary, size: 22),
                        onTap: () => _selectIngredient(ing),
                      );
                    },
                  ),
                ),
              ],

              // No results message
              if (_searchCtrl.text.isNotEmpty &&
                  !_isSearching &&
                  _searchResults.isEmpty &&
                  _selected == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 32,
                          color: colors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 8),
                      Text('No results for "${_searchCtrl.text}"',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: colors.textSecondary)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _showManual = true),
                        child: Text('Add it manually →',
                          style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

              // Selected ingredient confirmation
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected!.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: colors.textPrimary)),
                            Text(
                              '${_selected!.calories.toStringAsFixed(0)} kcal/100g',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: colors.textSecondary)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selected = null;
                          _searchCtrl.clear();
                        }),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],

              // Portion input (shown when ingredient selected)
              if (_selected != null) ...[
                const SizedBox(height: 14),
                Text('Portion size',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gramsCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '100',
                          suffixText: 'g',
                          prefixIcon: const Icon(
                              Icons.scale_rounded,
                              color: AppTheme.primary, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Manual entry toggle (only shown when no results / not searching)
              if (_selected == null &&
                  _searchResults.isEmpty &&
                  _searchCtrl.text.isEmpty)
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _showManual = true),
                    child: Text('+ Add ingredient manually',
                      style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                  ),
                ),
            ] else ...[
              // ── Manual entry mode ────────────
              GestureDetector(
                onTap: () => setState(() => _showManual = false),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text('Back to search',
                      style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl,  'Ingredient name', context, isNumber: false),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_gramsCtrl, 'Grams',       context, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_calCtrl,   'Cal/100g',    context, isNumber: true)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_protCtrl,  'Protein/100g', context, isNumber: true)),
                const SizedBox(width: 6),
                Expanded(child: _field(_carbCtrl,  'Carbs/100g',   context, isNumber: true)),
                const SizedBox(width: 6),
                Expanded(child: _field(_fatCtrl,   'Fat/100g',     context, isNumber: true)),
              ]),
            ],

            const SizedBox(height: 20),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selected != null ||
                        (_showManual && _nameCtrl.text.isNotEmpty))
                    ? _confirmAdd
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _showManual ? 'Add Ingredient' : 'Add to Meal',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      BuildContext context, {bool isNumber = false}) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.dmSans(fontSize: 14, color: colors.textPrimary),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
      ),
    );
  }
}
