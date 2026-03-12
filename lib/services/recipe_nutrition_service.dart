// lib/services/recipe_nutrition_service.dart
// Calculates comprehensive nutrition for recipes - PCOS VERSION
// iOS 14 Compatible | Production Ready

import 'package:polywise/models/nutrition_info.dart';
import 'package:polywise/PolyHealthBar.dart';

class RecipeNutrition {
  final double calories;
  final double fat;
  final double saturatedFat;
  final double monounsaturatedFat;
  final double transFat;
  final double sugar;
  final double sodium;
  final double potassium;
  final double protein;
  final double carbohydrates;
  final double fiber;
  final double iron;
  final double cholesterol;
  final double cobalt;
  final int polyScore;

  RecipeNutrition({
    required this.calories,
    required this.fat,
    this.saturatedFat = 0.0,
    this.monounsaturatedFat = 0.0,
    this.transFat = 0.0,
    required this.sugar,
    required this.sodium,
    this.potassium = 0.0,
    required this.protein,
    required this.carbohydrates,
    this.fiber = 0.0,
    this.iron = 0.0,
    this.cholesterol = 0.0,
    this.cobalt = 0.0,
    required this.polyScore,
  });

  /// Calculate macronutrient percentages
  Map<String, double> get macroPercentages {
    final proteinCals = protein * 4;
    final carbsCals = carbohydrates * 4;
    final fatCals = fat * 9;
    final totalMacroCals = proteinCals + carbsCals + fatCals;

    if (totalMacroCals == 0) {
      return {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    }

    return {
      'protein': (proteinCals / totalMacroCals) * 100,
      'carbs': (carbsCals / totalMacroCals) * 100,
      'fat': (fatCals / totalMacroCals) * 100,
    };
  }

  /// Net carbohydrates (Total Carbs - Fiber)
  double get netCarbs {
    return (carbohydrates - fiber).clamp(0, double.infinity);
  }

  /// Convert to NutritionInfo for display widgets
  NutritionInfo toNutritionInfo({String productName = 'Recipe Total'}) {
    return NutritionInfo(
      productName: productName,
      calories: calories,
      fat: fat,
      saturatedFat: saturatedFat,
      monounsaturatedFat: monounsaturatedFat,
      transFat: transFat,
      sodium: sodium,
      potassium: potassium,
      sugar: sugar,
      protein: protein,
      carbs: carbohydrates,
      fiber: fiber,
      iron: iron,
      cholesterol: cholesterol,
      cobalt: cobalt,
    );
  }
}

class RecipeNutritionService {
  /// Combine multiple ingredients into one nutrition summary
  static RecipeNutrition calculateTotals(List<NutritionInfo> items) {
    double totalCalories = 0;
    double totalFat = 0;
    double totalSaturatedFat = 0;
    double totalMonounsaturatedFat = 0;
    double totalTransFat = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalPotassium = 0;
    double totalProtein = 0;
    double totalCarbohydrates = 0;
    double totalFiber = 0;
    double totalIron = 0;
    double totalCholesterol = 0;
    double totalCobalt = 0;

    for (final item in items) {
      totalCalories += item.calories;
      totalFat += item.fat;
      totalSaturatedFat += item.saturatedFat ?? 0.0;
      totalMonounsaturatedFat += item.monounsaturatedFat ?? 0.0;
      totalTransFat += item.transFat ?? 0.0;
      totalSugar += item.sugar;
      totalSodium += item.sodium;
      totalPotassium += item.potassium ?? 0.0;
      totalProtein += item.protein;
      totalCarbohydrates += item.carbs;
      totalFiber += item.fiber ?? 0.0;
      totalIron += item.iron ?? 0.0;
      totalCholesterol += item.cholesterol ?? 0.0;
      totalCobalt += item.cobalt ?? 0.0;
    }

    // Compute recipe poly score
    final int polyScore = PCOSHealthCalculator.calculate(
      fat: totalFat,
      sodium: totalSodium,
      sugar: totalSugar,
      calories: totalCalories,
      protein: totalProtein,
      fiber: totalFiber,
      saturatedFat: totalSaturatedFat,
    );

    return RecipeNutrition(
      calories: totalCalories,
      fat: totalFat,
      saturatedFat: totalSaturatedFat,
      monounsaturatedFat: totalMonounsaturatedFat,
      transFat: totalTransFat,
      sugar: totalSugar,
      sodium: totalSodium,
      potassium: totalPotassium,
      protein: totalProtein,
      carbohydrates: totalCarbohydrates,
      fiber: totalFiber,
      iron: totalIron,
      cholesterol: totalCholesterol,
      cobalt: totalCobalt,
      polyScore: polyScore,
    );
  }

  /// Calculate nutrition for a single serving
  static RecipeNutrition calculatePerServing(
    List<NutritionInfo> items,
    int servings,
  ) {
    if (servings <= 0) {
      throw ArgumentError('Servings must be greater than 0');
    }

    final totals = calculateTotals(items);

    return RecipeNutrition(
      calories: totals.calories / servings,
      fat: totals.fat / servings,
      saturatedFat: totals.saturatedFat / servings,
      monounsaturatedFat: totals.monounsaturatedFat / servings,
      transFat: totals.transFat / servings,
      sugar: totals.sugar / servings,
      sodium: totals.sodium / servings,
      potassium: totals.potassium / servings,
      protein: totals.protein / servings,
      carbohydrates: totals.carbohydrates / servings,
      fiber: totals.fiber / servings,
      iron: totals.iron / servings,
      cholesterol: totals.cholesterol / servings,
      cobalt: totals.cobalt / servings,
      polyScore: totals.polyScore, // poly score doesn't change per serving
    );
  }

  /// Get a summary string of macronutrients
  static String getMacroSummary(RecipeNutrition nutrition) {
    final macros = nutrition.macroPercentages;
    return 'Protein: ${macros['protein']!.toStringAsFixed(1)}% | '
        'Carbs: ${macros['carbs']!.toStringAsFixed(1)}% | '
        'Fat: ${macros['fat']!.toStringAsFixed(1)}%';
  }

  /// Check if recipe is high protein (>30% of calories from protein)
  static bool isHighProtein(RecipeNutrition nutrition) {
    final macros = nutrition.macroPercentages;
    return macros['protein']! >= 30.0;
  }

  /// Check if recipe is low carb (<30% of calories from carbs)
  static bool isLowCarb(RecipeNutrition nutrition) {
    final macros = nutrition.macroPercentages;
    return macros['carbs']! < 30.0;
  }

  /// Check if recipe is low fat (<30% of calories from fat)
  static bool isLowFat(RecipeNutrition nutrition) {
    final macros = nutrition.macroPercentages;
    return macros['fat']! < 30.0;
  }

  /// Check if recipe is low sugar (<10g) — critical for insulin resistance
  static bool isLowSugar(RecipeNutrition nutrition) {
    return nutrition.sugar < 10.0;
  }

  /// Check if recipe is keto-friendly (<10% carbs, >70% fat)
  static bool isKeto(RecipeNutrition nutrition) {
    final macros = nutrition.macroPercentages;
    return macros['carbs']! < 10.0 && macros['fat']! > 70.0;
  }

  /// Check if recipe is heart-healthy
  static bool isHeartHealthy(RecipeNutrition nutrition) {
    return nutrition.saturatedFat < 2.0 &&
        nutrition.transFat == 0.0 &&
        nutrition.cholesterol < 20.0 &&
        nutrition.sodium < 140.0;
  }

  /// Check if recipe is PCOS-friendly
  static bool isPCOSFriendly(RecipeNutrition nutrition) {
    return isHighProtein(nutrition) &&
        isLowSugar(nutrition) &&
        nutrition.fat < 20.0 &&
        nutrition.sodium < 400.0;
  }

  /// Get dietary label for recipe based on macros
  static String getDietaryLabel(RecipeNutrition nutrition) {
    final labels = <String>[];

    if (isHighProtein(nutrition)) labels.add('High Protein');
    if (isLowCarb(nutrition)) labels.add('Low Carb');
    if (isLowFat(nutrition)) labels.add('Low Fat');
    if (isLowSugar(nutrition)) labels.add('Low Sugar');
    if (isKeto(nutrition)) labels.add('Keto');
    if (isPCOSFriendly(nutrition)) labels.add('PCOS Friendly');

    return labels.isEmpty ? 'Balanced' : labels.join(', ');
  }

  /// Get nutrient density score (nutrients per calorie)
  static double getNutrientDensity(RecipeNutrition nutrition) {
    if (nutrition.calories == 0) return 0;

    final nutrientScore = nutrition.protein +
        nutrition.fiber +
        (nutrition.potassium / 100) +
        (nutrition.iron * 10);

    return (nutrientScore / nutrition.calories) * 100;
  }

  /// Get PCOS-specific health warnings
  static List<String> getPCOSWarnings(RecipeNutrition nutrition) {
    final warnings = <String>[];

    if (nutrition.sugar > 10.0) {
      warnings.add('⚠️ High sugar — may worsen insulin resistance');
    }
    if (nutrition.fat > 15.0) {
      warnings.add('⚠️ High fat — may affect hormone balance');
    }
    if (nutrition.saturatedFat > 5.0) {
      warnings.add('⚠️ High saturated fat — linked to inflammation');
    }
    if (nutrition.sodium > 400.0) {
      warnings.add('⚠️ High sodium — stay hydrated');
    }
    if (nutrition.protein < 15.0) {
      warnings.add('ℹ️ Low protein — consider adding a protein source');
    }

    return warnings;
  }

  /// Get health warnings (general)
  static List<String> getHealthWarnings(RecipeNutrition nutrition) {
    final warnings = <String>[];

    if (nutrition.saturatedFat > 5.0) warnings.add('High in saturated fat');
    if (nutrition.transFat > 0.0) warnings.add('Contains trans fat');
    if (nutrition.sodium > 400.0) warnings.add('High in sodium');
    if (nutrition.sugar > 15.0) warnings.add('High in sugar');
    if (nutrition.cholesterol > 75.0) warnings.add('High in cholesterol');

    return warnings;
  }

  /// Get health benefits
  static List<String> getHealthBenefits(RecipeNutrition nutrition) {
    final benefits = <String>[];

    if (nutrition.protein >= 20.0) {
      benefits.add('Excellent protein source');
    } else if (nutrition.protein >= 10.0) {
      benefits.add('Good protein source');
    }
    if (nutrition.fiber >= 5.0) {
      benefits.add('High fiber');
    } else if (nutrition.fiber >= 3.0) {
      benefits.add('Good source of fiber');
    }
    if (nutrition.iron >= 2.0) benefits.add('Good source of iron');
    if (nutrition.potassium >= 300.0) benefits.add('Good source of potassium');
    if (isLowSugar(nutrition)) benefits.add('Low sugar');
    if (isHeartHealthy(nutrition)) benefits.add('Heart-healthy');
    if (isPCOSFriendly(nutrition)) benefits.add('PCOS-friendly');

    return benefits;
  }

  /// Get PCOS-type-specific guidance
  static String getPCOSGuidance(RecipeNutrition nutrition, String pcosType) {
    switch (pcosType.toLowerCase()) {
      case 'insulin resistant':
        if (nutrition.sugar > 10) {
          return '⚠️ High sugar content may worsen insulin resistance';
        }
        if (nutrition.protein >= 20) {
          return '✅ Good protein content to support blood sugar balance';
        }
        return 'Focus on low-GI foods and pair carbs with protein';

      case 'lean pcos':
        if (nutrition.protein < 15) {
          return '⚠️ Consider adding more protein to support hormone production';
        }
        return 'Focus on anti-inflammatory whole foods';

      case 'inflammatory':
        if (nutrition.saturatedFat > 5.0) {
          return '⚠️ High saturated fat may increase inflammation';
        }
        if (nutrition.fiber >= 5.0) {
          return '✅ Good fiber content supports gut health and reduces inflammation';
        }
        return 'Prioritise omega-3s, antioxidants, and fibre-rich foods';

      case 'adrenal':
        if (nutrition.sodium > 400.0) {
          return 'ℹ️ Moderate sodium — helpful for adrenal support but watch overall intake';
        }
        if (nutrition.protein >= 20) {
          return '✅ Good protein to support adrenal function and energy';
        }
        return 'Focus on regular meals with balanced macros to support cortisol rhythm';

      case 'post-pill pcos':
        if (nutrition.iron >= 3.0) {
          return '✅ Good iron content — helpful during hormone rebalancing';
        }
        return 'Focus on nutrient-dense foods to support hormone recovery';

      default:
        return 'Consult your PCOS care team for personalised nutrition guidance';
    }
  }
}