// lib/user_manager.dart

/// Global state manager for PolyWise user status.
/// Handles premium access and advertisement visibility logic.
class UserManager {
  static bool _hasPurchased = false;
  static bool _isMonetized = false;

  /// Returns true if the app is set to show ads and the user has not purchased premium.
  static bool get showAds => _isMonetized && !_hasPurchased;

  /// Updates the premium purchase status.
  static void setPurchased(bool value) {
    _hasPurchased = value;
  }

  /// Toggles whether the app should consider showing ads (controlled by Remote Config or AppConfig).
  static void setMonetized(bool value) {
    _isMonetized = value;
  }

  static bool get isMonetized => _isMonetized;
  static bool get hasPurchased => _hasPurchased;
}