// lib/PolyHealthBar.dart

import 'package:flutter/material.dart';
import 'models/pcos_type_nutrition_profile.dart';

// PolyWise Brand Palette for the UI
const Color kPolyWiseTeal = Color(0xFF2FB4C1);
const Color kPolyWisePurple = Color(0xFF7B4397);

String getFaceEmoji(int score) {
  if (score <= 25) return '😐'; // Rule #6: Avoid shaming (😠 replaced with 😐)
  if (score <= 49) return '🙂'; 
  if (score <= 74) return '😊';
  return '😄';
}

/// 🔥 Standalone calculator class for PCOS-first nutrition rules
class PCOSHealthCalculator {
  /// Main calculate method - pivoted for Insulin Resistance and Metabolic Health
  static int calculate({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    String? pcosType,
    double? protein,
    double? fiber,
    double? saturatedFat,
    double? monounsaturatedFat,
    double? polyunsaturatedFat,
    double? transFat,
    double? carbs,
  }) {
    if (pcosType == null || pcosType == 'Other (default scoring)') {
      
      // PCOS Optimization Thresholds (per serving/100g logic)
      const sugarLimit = 12.0;    // Penalize heavily over 12g
      const fiberTarget = 5.0;    // Reward heavily at 5g+
      const proteinTarget = 15.0; // Reward for hormonal satiety
      const fatMax = 20.0;
      const calMax = 400.0;

      // 1. Glycemic Control Score (Highest Priority for PCOS)
      final sugarScore = 1 - (sugar / sugarLimit).clamp(0, 1);
      
      // 2. Fiber Bonus (Essential for PCOS Insulin Sensitivity)
      final fiberScore = ( (fiber ?? 0) / fiberTarget).clamp(0, 1);

      // 3. Protein Support (Hormonal balance)
      final proteinScore = ( (protein ?? 0) / proteinTarget).clamp(0, 1);

      // 4. Caloric & Fat density (Secondary priority)
      final fatScore = 1 - (fat / fatMax).clamp(0, 1);
      final calScore = 1 - (calories / calMax).clamp(0, 1);

      // PCOS WEIGHTED SCORING ENGINE:
      // 40% Glycemic (Sugar) + 25% Fiber + 15% Protein + 10% Fat + 10% Calories
      final finalScore = (sugarScore * 0.40) +
          (fiberScore * 0.25) +
          (proteinScore * 0.15) +
          (fatScore * 0.10) +
          (calScore * 0.10);

      return (finalScore * 100).round().clamp(0, 100);
    } else {
      // Use PCOS subtype-specific calculation (Insulin Resistant, Inflammatory, etc.)
      return PCOSTypeNutritionProfile.calculatePCOSScore(
        pcosType: pcosType,
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
    }
  }
}

class PolyHealthBar extends StatelessWidget {
  final int healthScore;

  const PolyHealthBar({super.key, required this.healthScore});

  /// Legacy static function for backwards compatibility
  /// Delegates to PCOSHealthCalculator.calculate()
  static int calculateScore({
    required double fat,
    required double sodium,
    required double sugar,
    required double calories,
    String? pcosType,
    double? protein,
    double? fiber,
    double? saturatedFat,
    double? monounsaturatedFat,
    double? polyunsaturatedFat,
    double? transFat,
    double? carbs,
  }) {
    return PCOSHealthCalculator.calculate(
      fat: fat,
      sodium: sodium,
      sugar: sugar,
      calories: calories,
      pcosType: pcosType,
      protein: protein,
      fiber: fiber,
      saturatedFat: saturatedFat,
      monounsaturatedFat: monounsaturatedFat,
      polyunsaturatedFat: polyunsaturatedFat,
      transFat: transFat,
      carbs: carbs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final face = getFaceEmoji(healthScore);
    return Stack(
      clipBehavior: Clip.none, // Ensures emoji isn't cut off if it bounces
      children: [
        // Gradient Bar - Brand-aware status spectrum
        Container(
          height: 25,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Colors.redAccent, 
                Colors.orangeAccent, 
                kPolyWiseTeal,   // PolyWise Teal for good
                kPolyWisePurple  // PolyWise Purple for optimal
              ],
            ),
          ),
        ),
        // Emoji sliding over bar based on healthScore percentage
        Positioned(
          left: 16 + (MediaQuery.of(context).size.width - 32 - 28) * (healthScore / 100),
          top: -30,
          child: Text(
            face,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ],
    );
  }
}