// lib/models/pcos_type_nutrition_profile.dart
// PCOS-type specific nutrition guidelines and scoring

class PCOSTypeNutritionProfile {
  // ========================================
  // PCOS TYPE CONSTANTS
  // ========================================
  static const String INSULIN_RESISTANT = 'Insulin-Resistant PCOS';
  static const String INFLAMMATORY = 'Inflammatory PCOS';
  static const String POST_PILL = 'Post-Pill PCOS';
  static const String ADRENAL = 'Adrenal PCOS';
  static const String OTHER = 'Other (default scoring)';

  static List<String> getAllPCOSTypes() {
    return [
      INSULIN_RESISTANT,
      INFLAMMATORY,
      POST_PILL,
      ADRENAL,
      OTHER,
    ];
  }

  /// Calculate PCOS-aware score (0-100)
  /// Higher score = better for PCOS management
  static int calculatePCOSScore({
    required String pcosType,
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    double? protein,
    double? fiber,
    double? saturatedFat,
    double? monounsaturatedFat,
    double? polyunsaturatedFat,
    double? transFat,
    double? carbs,
  }) {
    // Default fallback scoring
    if (pcosType == OTHER || pcosType.isEmpty) {
      return _calculateDefaultScore(
        fat: fat,
        sodium: sodium,
        sugar: sugar,
        calories: calories,
        protein: protein,
        fiber: fiber,
      );
    }

    // PCOS-type specific scoring
    switch (pcosType) {
      case INSULIN_RESISTANT:
        return _calculateInsulinResistantScore(
          fat: fat,
          sodium: sodium,
          sugar: sugar,
          calories: calories,
          protein: protein,
          fiber: fiber,
          saturatedFat: saturatedFat,
          transFat: transFat,
          carbs: carbs,
        );
      
      case INFLAMMATORY:
        return _calculateInflammatoryScore(
          fat: fat,
          sodium: sodium,
          sugar: sugar,
          calories: calories,
          protein: protein,
          fiber: fiber,
          saturatedFat: saturatedFat,
          monounsaturatedFat: monounsaturatedFat,
          polyunsaturatedFat: polyunsaturatedFat,
          transFat: transFat,
          carbs: carbs,
        );
      
      case POST_PILL:
        return _calculatePostPillScore(
          fat: fat,
          sodium: sodium,
          sugar: sugar,
          calories: calories,
          protein: protein,
          fiber: fiber,
          monounsaturatedFat: monounsaturatedFat,
          polyunsaturatedFat: polyunsaturatedFat,
        );
      
      case ADRENAL:
        return _calculateAdrenalScore(
          fat: fat,
          sodium: sodium,
          sugar: sugar,
          calories: calories,
          protein: protein,
          fiber: fiber,
          carbs: carbs,
        );
      
      default:
        return _calculateDefaultScore(
          fat: fat,
          sodium: sodium,
          sugar: sugar,
          calories: calories,
          protein: protein,
          fiber: fiber,
        );
    }
  }

  // ========================================
  // DEFAULT SCORING (Balanced PCOS approach)
  // ========================================
  static int _calculateDefaultScore({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    double? protein,
    double? fiber,
  }) {
    // General PCOS-friendly scoring
    // Penalize: sugar, excess calories
    // Reward: protein, fiber
    
    final sugarScore = 1 - (sugar / 15.0).clamp(0.0, 1.0); // Stricter than default
    final sodiumScore = 1 - (sodium / 500.0).clamp(0.0, 1.0);
    final calScore = 1 - (calories / 400.0).clamp(0.0, 1.0);
    
    // Protein bonus (PCOS benefits from adequate protein)
    final proteinScore = protein != null && protein >= 15.0 
        ? (protein / 25.0).clamp(0.0, 1.0)
        : 0.5;
    
    // Fiber bonus
    final fiberBonus = fiber != null && fiber >= 5.0 ? 0.05 : 0.0;

    final finalScore = (sugarScore * 0.30) +
        (proteinScore * 0.25) +
        (sodiumScore * 0.20) +
        (calScore * 0.20) +
        ((1 - (fat / 20.0).clamp(0.0, 1.0)) * 0.05) +
        fiberBonus;

    return (finalScore * 100).round().clamp(0, 100);
  }

  // ========================================
  // INSULIN-RESISTANT PCOS SCORING
  // Focus: Low glycemic load, high fiber, adequate protein
  // ========================================
  static int _calculateInsulinResistantScore({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    double? protein,
    double? fiber,
    double? saturatedFat,
    double? transFat,
    double? carbs,
  }) {
    // CRITICAL: Sugar and net carbs (glycemic load proxy)
    final sugarScore = 1 - (sugar / 10.0).clamp(0.0, 1.0); // Very strict
    
    // Net carbs penalty (if available)
    double netCarbsScore = 0.8; // Neutral default
    if (carbs != null && fiber != null) {
      final netCarbs = (carbs - fiber).clamp(0.0, carbs);
      netCarbsScore = 1 - (netCarbs / 20.0).clamp(0.0, 1.0);
    }
    
    // Trans fat is toxic for insulin resistance
    final transFatPenalty = transFat != null && transFat > 0.5 
        ? -0.15 
        : 0.0;
    
    // Protein is crucial (aim for ≥20g per meal)
    final proteinScore = protein != null
        ? (protein / 25.0).clamp(0.0, 1.0)
        : 0.4; // Penalize if unknown
    
    // Fiber is highly beneficial
    final fiberBonus = fiber != null && fiber >= 5.0 
        ? 0.10 
        : (fiber != null && fiber >= 3.0 ? 0.05 : 0.0);
    
    // Moderate saturated fat
    final satFatScore = saturatedFat != null
        ? 1 - (saturatedFat / 8.0).clamp(0.0, 1.0)
        : 1 - (fat * 0.35 / 8.0).clamp(0.0, 1.0);
    
    final finalScore = (sugarScore * 0.35) +
        (netCarbsScore * 0.20) +
        (proteinScore * 0.20) +
        (fiberBonus * 1.0) + // Weighted as bonus
        (satFatScore * 0.15) +
        ((1 - (calories / 400.0).clamp(0.0, 1.0)) * 0.10) +
        transFatPenalty;

    return (finalScore * 100).round().clamp(0, 100);
  }

  // ========================================
  // INFLAMMATORY PCOS SCORING
  // Focus: Anti-inflammatory fats, low refined carbs, high fiber
  // ========================================
  static int _calculateInflammatoryScore({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    double? protein,
    double? fiber,
    double? saturatedFat,
    double? monounsaturatedFat,
    double? polyunsaturatedFat,
    double? transFat,
    double? carbs,
  }) {
    // Trans fat is the worst for inflammation
    final transFatPenalty = transFat != null && transFat > 0.5 
        ? -0.20 
        : 0.0;
    
    // Refined carbs drive inflammation
    final sugarScore = 1 - (sugar / 12.0).clamp(0.0, 1.0);
    
    double refinedCarbScore = 0.7;
    if (carbs != null && fiber != null) {
      final netCarbs = (carbs - fiber).clamp(0.0, carbs);
      refinedCarbScore = 1 - (netCarbs / 25.0).clamp(0.0, 1.0);
    }
    
    // Reward healthy fats (mono/poly)
    double healthyFatBonus = 0.0;
    if (monounsaturatedFat != null && monounsaturatedFat >= 5.0) {
      healthyFatBonus += 0.05;
    }
    if (polyunsaturatedFat != null && polyunsaturatedFat >= 3.0) {
      healthyFatBonus += 0.05;
    }
    
    // Fiber is anti-inflammatory
    final fiberBonus = fiber != null && fiber >= 5.0 
        ? 0.10 
        : (fiber != null && fiber >= 3.0 ? 0.05 : 0.0);
    
    // Protein for satiety
    final proteinScore = protein != null && protein >= 15.0 
        ? 0.8 
        : 0.5;
    
    // Sodium can worsen inflammation
    final sodiumScore = 1 - (sodium / 400.0).clamp(0.0, 1.0);

    final finalScore = (sugarScore * 0.25) +
        (refinedCarbScore * 0.20) +
        (sodiumScore * 0.15) +
        (proteinScore * 0.15) +
        ((1 - (saturatedFat ?? fat * 0.35) / 10.0).clamp(0.0, 1.0) * 0.15) +
        ((1 - (calories / 400.0).clamp(0.0, 1.0)) * 0.10) +
        fiberBonus +
        healthyFatBonus +
        transFatPenalty;

    return (finalScore * 100).round().clamp(0, 100);
  }

  // ========================================
  // POST-PILL PCOS SCORING
  // Focus: Nutrient density, hormone-balancing fats, protein
  // ========================================
  static int _calculatePostPillScore({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    double? protein,
    double? fiber,
    double? monounsaturatedFat,
    double? polyunsaturatedFat,
  }) {
    // Sugar disrupts hormonal rebalancing
    final sugarScore = 1 - (sugar / 12.0).clamp(0.0, 1.0);
    
    // Protein supports hormone production
    final proteinScore = protein != null
        ? (protein / 25.0).clamp(0.0, 1.0)
        : 0.4;
    
    // Healthy fats are crucial for hormone synthesis
    double healthyFatBonus = 0.0;
    if (monounsaturatedFat != null && monounsaturatedFat >= 5.0) {
      healthyFatBonus += 0.08;
    }
    if (polyunsaturatedFat != null && polyunsaturatedFat >= 3.0) {
      healthyFatBonus += 0.07;
    }
    
    // Fiber helps clear excess hormones
    final fiberBonus = fiber != null && fiber >= 5.0 
        ? 0.08 
        : (fiber != null && fiber >= 3.0 ? 0.04 : 0.0);
    
    // Sodium (moderate concern)
    final sodiumScore = 1 - (sodium / 500.0).clamp(0.0, 1.0);
    
    // Calories (secondary)
    final calScore = 1 - (calories / 450.0).clamp(0.0, 1.0);

    final finalScore = (sugarScore * 0.30) +
        (proteinScore * 0.25) +
        (sodiumScore * 0.15) +
        (calScore * 0.10) +
        ((1 - (fat / 20.0).clamp(0.0, 1.0)) * 0.05) +
        fiberBonus +
        healthyFatBonus;

    return (finalScore * 100).round().clamp(0, 100);
  }

  // ========================================
  // ADRENAL PCOS SCORING
  // Focus: Blood sugar stability, adequate protein, complex carbs
  // ========================================
  static int _calculateAdrenalScore({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    double? protein,
    double? fiber,
    double? carbs,
  }) {
    // Sugar spikes worsen cortisol dysregulation
    final sugarScore = 1 - (sugar / 12.0).clamp(0.0, 1.0);
    
    // Protein stabilizes blood sugar and supports adrenals
    final proteinScore = protein != null
        ? (protein / 25.0).clamp(0.0, 1.0)
        : 0.4;
    
    // Complex carbs (fiber-rich) help manage cortisol
    double complexCarbBonus = 0.0;
    if (fiber != null && fiber >= 5.0 && carbs != null && carbs >= 15.0) {
      complexCarbBonus = 0.10; // Good fiber + carbs = complex carbs
    } else if (fiber != null && fiber >= 3.0) {
      complexCarbBonus = 0.05;
    }
    
    // Moderate fat (not too low, not too high)
    final fatScore = 1 - ((fat - 12.0).abs() / 12.0).clamp(0.0, 1.0);
    
    // Sodium (moderate concern)
    final sodiumScore = 1 - (sodium / 500.0).clamp(0.0, 1.0);
    
    // Calories (avoid extremes)
    final calScore = 1 - ((calories - 350.0).abs() / 350.0).clamp(0.0, 1.0);

    final finalScore = (sugarScore * 0.30) +
        (proteinScore * 0.25) +
        (complexCarbBonus * 1.0) + // Weighted as bonus
        (fatScore * 0.15) +
        (sodiumScore * 0.15) +
        (calScore * 0.15);

    return (finalScore * 100).round().clamp(0, 100);
  }

  /// Get user-friendly description of PCOS type focus
  static String getPCOSGuidance(String pcosType) {
    switch (pcosType) {
      case INSULIN_RESISTANT:
        return 'Focus on: Low sugar, high fiber, adequate protein (≥20g), low net carbs';
      case INFLAMMATORY:
        return 'Focus on: Anti-inflammatory fats, low refined carbs, high fiber, avoid trans fats';
      case POST_PILL:
        return 'Focus on: Nutrient-dense foods, healthy fats, adequate protein, high fiber';
      case ADRENAL:
        return 'Focus on: Blood sugar stability, adequate protein, complex carbs, avoid sugar spikes';
      default:
        return 'Using balanced PCOS-friendly scoring';
    }
  }

  /// Get detailed explanation for each PCOS type (for UI education)
  static String getPCOSTypeDescription(String pcosType) {
    switch (pcosType) {
      case INSULIN_RESISTANT:
        return 'Most common PCOS type. Your body has difficulty processing carbohydrates efficiently. '
            'Focus on low-glycemic foods, high fiber, and adequate protein to manage blood sugar.';
      case INFLAMMATORY:
        return 'Your PCOS is driven by chronic inflammation. Prioritize anti-inflammatory foods, '
            'omega-3 fats, and avoid processed foods and trans fats.';
      case POST_PILL:
        return 'PCOS symptoms appeared after stopping hormonal birth control. Focus on nutrient-dense '
            'foods that support natural hormone production and balance.';
      case ADRENAL:
        return 'Driven by stress and elevated DHEA/cortisol. Manage blood sugar stability, get adequate '
            'protein, and focus on stress-reducing nutrition patterns.';
      default:
        return 'General PCOS-friendly nutrition approach balancing blood sugar, inflammation, and hormone health.';
    }
  }
}