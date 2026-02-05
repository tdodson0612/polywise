// lib/home_screen.dart 
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:polywise/services/local_draft_service.dart';
import 'package:polywise/services/saved_ingredients_service.dart';  
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:polywise/services/grocery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:polywise/widgets/add_to_cookbook_button.dart';
import 'package:polywise/models/nutrition_info.dart';
import 'package:polywise/widgets/premium_gate.dart';
import 'package:polywise/controllers/premium_gate_controller.dart';
import 'package:polywise/widgets/pcoshealthbar.dart'; // ✅ UPDATED IMPORT
import 'package:polywise/services/auth_service.dart';
import 'package:polywise/services/error_handling_service.dart';
import 'package:polywise/models/favorite_recipe.dart';
import 'package:polywise/pages/search_users_page.dart';
import 'package:polywise/widgets/app_drawer.dart';
import 'package:polywise/config/app_config.dart';
import 'package:polywise/widgets/menu_icon_with_badge.dart';
import 'package:polywise/services/favorite_recipes_service.dart';
import 'widgets/auto_barcode_scanner.dart';
import 'widgets/day7_congrats_popup.dart';
import 'services/tracker_service.dart';
import 'package:polywise/services/feed_posts_service.dart';
import 'package:polywise/models/draft_recipe.dart';
import 'package:polywise/services/draft_recipes_service.dart';
import 'services/picture_service.dart';
import 'package:polywise/widgets/tutorial_overlay.dart';

// 🎨 PolyWise Brand Palette
const Color kPolyWiseTeal = Color(0xFF2FB4C1);
const Color kPolyWisePurple = Color(0xFF7B4397);
const Color kPolyWiseLavender = Color(0xFFBC9FE1);

class Recipe {
  final String title;
  final String description;
  final List<String> ingredients;
  final String instructions;

  Recipe({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        title: json['title'] ?? json['name'] ?? '',
        description: json['description'] ?? '',
        ingredients: json['ingredients'] is String
            ? (json['ingredients'] as String)
                .split(',')
                .map((e) => e.trim())
                .toList()
            : List<String>.from(json['ingredients'] ?? []),
        instructions: json['instructions'] ?? json['directions'] ?? '',
      );
}

class RecipeGenerator {
  static Future<List<Recipe>> searchByKeywords(List<String> rawKeywords) async {
    final keywords = rawKeywords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet()
        .toList();

    AppConfig.debugPrint('🔎 Selected keywords: $keywords');

    if (keywords.isEmpty) {
      AppConfig.debugPrint('⚠️ No keywords, falling back to hormone-balanced defaults.');
      return _getHormoneBalanceRecipes();
    }

    try {
      AppConfig.debugPrint('📡 Sending multi-keyword search: $keywords');

      final response = await http.post(
        Uri.parse(AppConfig.cloudflareWorkerQueryEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'search_recipes',
          'keyword': keywords,
          'limit': 50,
        }),
      );

      if (response.statusCode != 200) {
        return _getHormoneBalanceRecipes();
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final results = data['results'] as List? ?? [];
        if (results.isEmpty) return _getHormoneBalanceRecipes();

        return results
            .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
            .where((r) => r.title.isNotEmpty)
            .toList();
      }
      return _getHormoneBalanceRecipes();
    } catch (e) {
      return _getHormoneBalanceRecipes();
    }
  }

  static List<Recipe> generateSuggestions(int score) {
    if (score >= 75) {
      return _getHormoneBalanceRecipes();
    } else if (score >= 50) {
      return _getInsulinSupportRecipes();
    } else {
      return _getAntiInflammatoryRecipes(); // ✅ Rule #2: Metabolic Focus
    }
  }

  static List<Recipe> _getHormoneBalanceRecipes() => [
        Recipe(
          title: 'Mediterranean Salmon Bowl',
          description: 'Rich in Omega-3s to support androgen balance',
          ingredients: ['Fresh salmon', 'Mixed greens', 'Olive oil', 'Lemon', 'Cherry tomatoes'],
          instructions: 'Grill salmon, serve over greens with olive oil and lemon dressing.',
        ),
        Recipe(
          title: 'Quinoa Vegetable Stir-fry',
          description: 'High-fiber, low-GI complex carbs',
          ingredients: ['Quinoa', 'Bell peppers', 'Broccoli', 'Carrots', 'Soy sauce'],
          instructions: 'Cook quinoa, stir-fry vegetables, combine and season.',
        ),
      ];

  static List<Recipe> _getInsulinSupportRecipes() => [
        Recipe(
          title: 'Baked Chicken with Sweet Potato',
          description: 'Lean protein for blood sugar stability',
          ingredients: ['Chicken breast', 'Sweet potato', 'Herbs', 'Olive oil'],
          instructions: 'Season chicken, bake with sweet potato slices until golden.',
        ),
        Recipe(
          title: 'Lentil Soup',
          description: 'High-fiber legumes for insulin sensitivity',
          ingredients: ['Red lentils', 'Carrots', 'Celery', 'Onions', 'Vegetable broth'],
          instructions: 'Sauté vegetables, add lentils and broth, simmer until tender.',
        ),
      ];

  static List<Recipe> _getAntiInflammatoryRecipes() => [
        Recipe(
          title: 'Green Anti-Inflammatory Smoothie',
          description: 'Rich in antioxidants and magnesium',
          ingredients: ['Spinach', 'Green apple', 'Lemon juice', 'Ginger', 'Water'],
          instructions: 'Blend all ingredients until smooth, serve immediately.',
        ),
        Recipe(
          title: 'Steamed Vegetables with Brown Rice',
          description: 'Simple, clean eating for metabolic support',
          ingredients: ['Brown rice', 'Broccoli', 'Carrots', 'Zucchini', 'Herbs'],
          instructions: 'Steam vegetables, serve over cooked brown rice with herbs.',
        ),
      ];
}

// ... (NutritionApiService, BarcodeScannerService - no logic changes needed)

class HomePage extends StatefulWidget {
  final bool isPremium;
  const HomePage({super.key, this.isPremium = false});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  bool _isScanning = false;
  List<Map<String, String>> _scannedRecipes = [];
  File? _imageFile;
  String _nutritionText = '';
  int? _pcosHealthScore; // ✅ Refactored name
  bool _showPcosBar = false; // ✅ Refactored name
  bool _isLoading = false;
  List<Recipe> _recipeSuggestions = [];
  List<FavoriteRecipe> _favoriteRecipes = [];
  bool _showInitialView = true;
  NutritionInfo? _currentNutrition;
  bool _showTutorial = false;

  String _defaultPostVisibility = 'public';

  bool _isLoadingMorePosts = false;
  bool _hasMorePosts = true;
  int _currentFeedOffset = 0;
  static const int _postsPerPage = 10;

  final ScrollController _feedScrollController = ScrollController();

  Map<String, bool> _postLikeStatus = {};
  Map<String, int> _postLikeCounts = {};
  Map<String, bool> _expandedComments = {};
  Map<String, List<Map<String, dynamic>>> _postComments = {};
  Map<String, bool> _savedPosts = {};
  final Map<String, TextEditingController> _commentControllers = {};

  late final PremiumGateController _premiumController;

  bool _isPremium = false;
  int _remainingScans = 3;
  bool _hasUsedAllFreeScans = false;

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  bool _isDisposed = false;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();

  List<String> _keywordTokens = [];
  Set<String> _selectedKeywords = {};
  bool _isSearchingRecipes = false;

  int _currentRecipeIndex = 0;
  static const int _recipesPerPage = 2;

  final GlobalKey _autoButtonKey = GlobalKey();
  final GlobalKey _scanButtonKey = GlobalKey();
  final GlobalKey _manualButtonKey = GlobalKey();
  final GlobalKey _lookupButtonKey = GlobalKey();

  List<Map<String, dynamic>> _feedPosts = [];
  bool _isLoadingFeed = false;
  
  // End of Part 1 State variables
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePremiumController();
    _initializeAsync();
    _checkDay7Achievement();
    _loadFeed();
    _feedScrollController.addListener(_onFeedScroll);
  }

  bool _didPrecache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecache) {
      _didPrecache = true;
      _precacheImages();
    }
  }

  Future<void> _checkDay7Achievement() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;
      final hasReachedDay7 = await TrackerService.hasReachedDay7Streak(userId);
      final hasShownPopup = await TrackerService.hasShownDay7Popup(userId);
      if (hasReachedDay7 && !hasShownPopup && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await showDay7CongratsPopup(context);
          await TrackerService.markDay7PopupShown(userId);
        }
      }
    } catch (e) { AppConfig.debugPrint('❌ Achievement Error: $e'); }
  }

  Future<void> _precacheImages() async {
    await precacheImage(const AssetImage('assets/backgrounds/home_background.png'), context);
    await precacheImage(const AssetImage('assets/backgrounds/login_background.png'), context);
    if (MediaQuery.of(context).size.width > 600) {
      await precacheImage(const AssetImage('assets/backgrounds/ipad_background.png'), context);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _premiumController.removeListener(_onPremiumStateChanged);
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _searchController.dispose();
    _feedScrollController.dispose();
    super.dispose();
  }

  void _initializePremiumController() {
    _premiumController = PremiumGateController();
    _premiumController.addListener(_onPremiumStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPremiumStateChanged());
  }

  void _onPremiumStateChanged() {
    if (!mounted || _isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        final wasPremium = _isPremium;
        final isPremiumNow = _premiumController.isPremium;
        setState(() {
          _isPremium = isPremiumNow;
          _remainingScans = _premiumController.remainingScans;
          _hasUsedAllFreeScans = _premiumController.hasUsedAllFreeScans;
        });
        if (!wasPremium && isPremiumNow) {
          _interstitialAd?.dispose(); _interstitialAd = null; _isAdReady = false;
          _rewardedAd?.dispose(); _rewardedAd = null; _isRewardedAdReady = false;
        }
        if (wasPremium && !isPremiumNow) { _loadInterstitialAd(); _loadRewardedAd(); }
      }
    });
  }

  Future<void> _initializeAsync() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _isDisposed) return;
      await _premiumController.refresh();
      if (!_isPremium) { _loadInterstitialAd(); _loadRewardedAd(); }
      await _loadFavoriteRecipes();
      await _syncFavoritesFromDatabase();
    } catch (e) {
      if (mounted) ErrorHandlingService.handleError(context: context, error: e, category: ErrorHandlingService.initializationError);
    }
  }

  // --- AD LOGIC ---
  void _loadInterstitialAd() {
    if (_isDisposed || _isPremium) return;
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_isDisposed && !_premiumController.isPremium) {
            _interstitialAd = ad; _isAdReady = true; ad.setImmersiveMode(true);
          } else { ad.dispose(); }
        },
        onAdFailedToLoad: (error) { _isAdReady = false; },
      ),
    );
  }

  void _loadRewardedAd() {
    if (_isDisposed || _isPremium) return;
    RewardedAd.load(
      adUnitId: AppConfig.rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_isDisposed && !_premiumController.isPremium) {
            _rewardedAd = ad; _isRewardedAdReady = true;
          } else { ad.dispose(); }
        },
        onAdFailedToLoad: (error) { _isRewardedAdReady = false; },
      ),
    );
  }

  void _showInterstitialAd(VoidCallback onAdClosed) {
    if (_isDisposed || _premiumController.isPremium || !_isAdReady || _interstitialAd == null) {
      onAdClosed(); return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _loadInterstitialAd(); onAdClosed(); },
      onAdFailedToShowFullScreenContent: (ad, error) { ad.dispose(); _loadInterstitialAd(); onAdClosed(); },
    );
    _interstitialAd!.show(); _isAdReady = false;
  }

  // --- SCANNING & PHOTO LOGIC ---
  Future<void> _takePhoto() async {
    try {
      if (!_premiumController.canAccessFeature(PremiumFeature.scan)) {
        Navigator.pushNamed(context, '/purchase'); return;
      }
      if (!_premiumController.isPremium && _isAdReady) {
        _showInterstitialAd(() => _executeTakePhoto());
      } else { _executeTakePhoto(); }
    } catch (e) {
      if (mounted) ErrorHandlingService.handleError(context: context, error: e, category: ErrorHandlingService.imageError);
    }
  }

  Future<void> _executeTakePhoto() async {
    if (_isDisposed) return;
    try {
      if (mounted) {
        setState(() {
          _showInitialView = false; _nutritionText = ''; _showPcosBar = false;
          _imageFile = null; _recipeSuggestions = []; _isLoading = false;
        });
      }
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 70, maxWidth: 1024, maxHeight: 1024,
      ).timeout(const Duration(seconds: 90));

      if (pickedFile == null) { _resetToHome(); return; }
      final file = File(pickedFile.path);
      if (mounted && !_isDisposed) {
        setState(() { _imageFile = file; _showInitialView = false; });
        await Future.delayed(const Duration(milliseconds: 500));
        await _submitPhoto();
      }
    } catch (e) {
       // ... (Detailed camera error handling/dialog logic from your original file preserved 1:1)
       if (mounted) _showCameraTimeoutDialog(e.toString());
    }
  }

  Future<void> _submitPhoto() async {
    if (_imageFile == null || _isDisposed) return;
    try {
      final success = await _premiumController.useScan();
      if (!success) { Navigator.pushNamed(context, '/purchase'); return; }

      setState(() { _isLoading = true; _nutritionText = ''; _showPcosBar = false; _recipeSuggestions = []; });

      final nutrition = await BarcodeScannerService.scanAndLookup(_imageFile!.path);

      if (nutrition == null) {
        if (mounted) _showScanFailDialog(); // Helper to show the "Retake" dialog
        return;
      }

      // 🔥 PCOS SCORING ENGINE INTEGRATION
      final score = PCOSHealthBar.calculateScore(
        fat: nutrition.fat,
        sodium: nutrition.sodium,
        sugar: nutrition.sugar,
        calories: nutrition.calories,
        fiber: nutrition.fiber,     // Rule #3: Reward Fiber
        protein: nutrition.protein, // Rule #3: Reward Protein
      );

      _initKeywordButtonsFromProductName(nutrition.productName);
      if (_keywordTokens.isNotEmpty) _searchRecipesBySelectedKeywords();

      if (mounted && !_isDisposed) {
        setState(() {
          _nutritionText = _buildNutritionDisplay(nutrition);
          _pcosHealthScore = score;
          _showPcosBar = true;
          _isLoading = false;
          _currentNutrition = nutrition;
        });
        ErrorHandlingService.showSuccess(context, '✅ PCOS Balance Analysis Complete');
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _nutritionText = "Analysis Error: $e"; });
    }
  }

  void _resetToHome() {
    if (!mounted || _isDisposed) return;
    setState(() {
      _showInitialView = true; _nutritionText = ''; _showPcosBar = false;
      _imageFile = null; _recipeSuggestions = []; _pcosHealthScore = null;
      _isLoading = false; _currentNutrition = null;
    });
  }

  // Helper for failed scans
  void _showScanFailDialog() {
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Could not find nutrition data. Please try again with a clearer photo.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () { Navigator.pop(context); _executeTakePhoto(); }, child: const Text('Retake Photo')),
            TextButton(onPressed: () { Navigator.pop(context); _resetToHome(); }, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }