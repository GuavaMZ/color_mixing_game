import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';

class LabItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final Color placeholderColor;
  final List<Color> gradientColors;
  final IconData? icon;

  const LabItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.placeholderColor,
    this.gradientColors = const [],
    this.icon,
  });
}

class LabUpgradeHub extends StatefulWidget {
  final ColorMixerGame game;

  const LabUpgradeHub({super.key, required this.game});

  @override
  State<LabUpgradeHub> createState() => _LabUpgradeHubState();
}

class _LabUpgradeHubState extends State<LabUpgradeHub>
    with TickerProviderStateMixin {
  String _selectedCategory = 'surface';
  List<String> _unlockedItems = [];
  Map<String, String> _equippedConfig = {};
  bool _isLoading = true;
  String? _hoveredItemId;
  bool _isSidebarCollapsed = false;

  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _sidebarController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _sidebarAnimation;

  // Catalog with enhanced descriptions
  final List<LabItem> _catalog = [
    // Surfaces
    LabItem(
      id: 'surface_steel',
      name: 'Basic Steel',
      description: 'Standard industrial-grade stainless steel surface',
      price: 0,
      category: 'surface',
      placeholderColor: Colors.grey,
      gradientColors: [Colors.grey.shade800, Colors.grey.shade900],
      icon: Icons.grid_4x4,
    ),
    LabItem(
      id: 'surface_marble',
      name: 'Polished Marble',
      description: 'Luxurious white marble with gold veining',
      price: 400, // Adjusted from 500
      category: 'surface',
      placeholderColor: Colors.white,
      gradientColors: [
        Colors.white,
        const Color(0xFFF0F0F0),
        const Color(0xFFFFD700),
      ],
      icon: Icons.diamond,
    ),
    LabItem(
      id: 'surface_titanium',
      name: 'Titanium Alloy',
      description: 'High-tech aerospace-grade titanium with brushed finish',
      price: 800,
      category: 'surface',
      placeholderColor: const Color(0xFFB0B0B0),
      gradientColors: [const Color(0xFF9E9E9E), const Color(0xFF757575)],
      icon: Icons.layers,
    ),
    LabItem(
      id: 'surface_cyber',
      name: 'Cyber-Grid Hex',
      description: 'Advanced hexagonal cyber-grid with reactive lighting',
      price: 1200, // Adjusted from 1500
      category: 'surface',
      placeholderColor: Colors.cyan,
      gradientColors: [const Color(0xFF00FFCC), const Color(0xFF0077FF)],
      icon: Icons.hexagon,
    ),
    LabItem(
      id: 'surface_crystal',
      name: 'Crystal Matrix',
      description: 'Crystalline surface with prismatic light refraction',
      price: 2000,
      category: 'surface',
      placeholderColor: const Color(0xFFE1F5FE),
      gradientColors: [
        const Color(0xFFE1F5FE),
        const Color(0xFF81D4FA),
        const Color(0xFF4FC3F7),
      ],
      icon: Icons.auto_awesome,
    ),

    // Lighting
    LabItem(
      id: 'light_basic',
      name: 'Standard Fluorescent',
      description: 'Basic overhead fluorescent lighting',
      price: 0,
      category: 'lighting',
      placeholderColor: Colors.yellow,
      icon: Icons.wb_incandescent_outlined,
    ),
    LabItem(
      id: 'light_warm',
      name: 'Warm Amber',
      description: 'Cozy warm amber lighting for a relaxed atmosphere',
      price: 500, // Adjusted from 600
      category: 'lighting',
      placeholderColor: Colors.orange,
      gradientColors: [Colors.orange, Colors.amber],
      icon: Icons.wb_sunny,
    ),
    LabItem(
      id: 'light_neon_blue',
      name: 'Neon Blue & Purple',
      description: 'Dramatic neon lighting with color-shifting effects',
      price: 700, // Adjusted from 800
      category: 'lighting',
      placeholderColor: Colors.purpleAccent,
      gradientColors: [
        Colors.purpleAccent,
        Colors.blueAccent,
        Colors.cyanAccent,
      ],
      icon: Icons.lightbulb,
    ),
    LabItem(
      id: 'light_rgb',
      name: 'RGB Dynamic',
      description: 'Programmable RGB lighting that adapts to your experiments',
      price: 1500,
      category: 'lighting',
      placeholderColor: const Color(0xFFFF00FF),
      gradientColors: [Colors.red, Colors.green, Colors.blue],
      icon: Icons.color_lens,
    ),
    LabItem(
      id: 'light_bio',
      name: 'Bioluminescent',
      description: 'Organic bioluminescent lighting with natural glow',
      price: 2500,
      category: 'lighting',
      placeholderColor: const Color(0xFF00FF88),
      gradientColors: [const Color(0xFF00FF88), const Color(0xFF00CCAA)],
      icon: Icons.eco,
    ),

    // Backgrounds
    LabItem(
      id: 'bg_default',
      name: 'Standard Lab',
      description: 'Clean, professional laboratory environment',
      price: 0,
      category: 'background',
      placeholderColor: Colors.blueGrey,
      icon: Icons.science,
    ),
    LabItem(
      id: 'bg_nature',
      name: 'Botanical Garden',
      description: 'Serene greenhouse laboratory surrounded by nature',
      price: 1000, // Adjusted from 1200
      category: 'background',
      placeholderColor: Colors.green,
      gradientColors: [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
      icon: Icons.park,
    ),
    LabItem(
      id: 'bg_cyber',
      name: 'Cyberpunk City',
      description: 'Neon-lit urban skyline with holographic billboards',
      price: 1200,
      category: 'background',
      placeholderColor: const Color(0xFFFF00FF),
      gradientColors: [
        const Color(0xFF1A1A2E),
        const Color(0xFFFF00FF),
        const Color(0xFF00FFFF),
      ],
      icon: Icons.location_city,
    ),
    LabItem(
      id: 'bg_futuristic',
      name: 'High-Tech Facility',
      description: 'Cutting-edge research facility with holographic displays',
      price: 1800, // Adjusted from 2000
      category: 'background',
      placeholderColor: Colors.black,
      gradientColors: [
        Colors.black,
        const Color(0xFF1A237E),
        const Color(0xFF00BCD4),
      ],
      icon: Icons.computer,
    ),
    LabItem(
      id: 'bg_underwater',
      name: 'Deep Sea Research',
      description: 'Underwater laboratory with bioluminescent marine life',
      price: 2500,
      category: 'background',
      placeholderColor: const Color(0xFF006064),
      gradientColors: [
        const Color(0xFF006064),
        const Color(0xFF00838F),
        const Color(0xFF0097A7),
      ],
      icon: Icons.water,
    ),

    // Stands
    LabItem(
      id: 'stand_basic',
      name: 'Standard Stand',
      description: 'Basic metal laboratory stand',
      price: 0,
      category: 'stand',
      placeholderColor: Colors.grey,
      icon: Icons.table_chart,
    ),
    LabItem(
      id: 'stand_chrome',
      name: 'Chrome Finish',
      description: 'Polished chrome stand with modern aesthetic',
      price: 300,
      category: 'stand',
      placeholderColor: const Color(0xFFE0E0E0),
      gradientColors: [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
      icon: Icons.brightness_7,
    ),
    LabItem(
      id: 'stand_wood',
      name: 'Wooden Artisan',
      description: 'Handcrafted wooden stand with natural grain',
      price: 500,
      category: 'stand',
      placeholderColor: const Color(0xFF8D6E63),
      gradientColors: [const Color(0xFF8D6E63), const Color(0xFF6D4C41)],
      icon: Icons.deck,
    ),
    LabItem(
      id: 'stand_holo',
      name: 'Holographic',
      description: 'Floating holographic projection stand',
      price: 1000,
      category: 'stand',
      placeholderColor: const Color(0xFF00E5FF),
      gradientColors: [const Color(0xFF00E5FF), const Color(0xFF00B8D4)],
      icon: Icons.blur_on,
    ),
    LabItem(
      id: 'stand_levitate',
      name: 'Anti-Gravity',
      description: 'Magnetic levitation stand with zero contact',
      price: 2000,
      category: 'stand',
      placeholderColor: const Color(0xFFAA00FF),
      gradientColors: [const Color(0xFFAA00FF), const Color(0xFF6200EA)],
      icon: Icons.flight_takeoff,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _sidebarAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _sidebarController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _unlockedItems = await SaveManager.loadUnlockedLabItems();
    _equippedConfig = await SaveManager.loadLabConfig();
    setState(() {
      _isLoading = false;
    });
    _fadeController.forward();
  }

  Future<void> _purchaseItem(LabItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildPurchaseDialog(item),
    );

    if (confirmed != true) return;

    if (widget.game.totalCoins.value >= item.price) {
      int newBalance = widget.game.totalCoins.value - item.price;
      widget.game.totalCoins.value = newBalance;
      await SaveManager.saveTotalCoins(newBalance);

      _unlockedItems.add(item.id);
      await SaveManager.saveUnlockedLabItems(_unlockedItems);
      AudioManager().playUnlockSound();

      if (_equippedConfig[item.category] == null ||
          !_unlockedItems.contains(_equippedConfig[item.category])) {
        await _equipItem(item);
      }

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ${item.name} unlocked!'),
            backgroundColor: AppTheme.neonCyan,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      AudioManager().playError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough coins! Need ${item.price - widget.game.totalCoins.value} more.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _equipItem(LabItem item) async {
    _equippedConfig[item.category] = item.id;
    await SaveManager.saveLabConfig(_equippedConfig);
    AudioManager().playButton();
    setState(() {});
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fadeController.reset();
    _fadeController.forward();
    AudioManager().playButton();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
    if (_isSidebarCollapsed) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: AppTheme.neonCyan,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Lab Upgrades...',
                style: TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                        Color.lerp(
                          const Color(0xFF000000),
                          const Color(0xFF1A237E),
                          _glowAnimation.value * 0.3,
                        )!,
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: GridPainter(opacity: _glowAnimation.value),
                  ),
                );
              },
            ),
          ),

          // Main UI
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isMobile, isTablet),

                Expanded(
                  child: isMobile
                      ? _buildMobileLayout()
                      : Row(
                          children: [
                            _buildSidebar(isMobile, isTablet),
                            Expanded(child: _buildGrid(isMobile, isTablet)),
                          ],
                        ),
                ),

                _buildFooter(context, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Category Selector (Horizontal Scroll)
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildMobileTab('Surface', 'surface', Icons.table_restaurant),
              _buildMobileTab('Lighting', 'lighting', Icons.lightbulb_outline),
              _buildMobileTab('Background', 'background', Icons.wallpaper),
              _buildMobileTab('Stand', 'stand', Icons.science),
            ],
          ),
        ),

        // Grid
        Expanded(child: _buildGrid(true, false)),
      ],
    );
  }

  Widget _buildMobileTab(String title, String id, IconData icon) {
    final isSelected = _selectedCategory == id;

    return GestureDetector(
      onTap: () => _changeCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.neonCyan.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.neonCyan : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (!isMobile) ...[
                  Icon(
                    Icons.science,
                    color: AppTheme.neonCyan,
                    size: isMobile ? 24 : 32,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMobile ? 'LAB UPGRADES' : 'LAB UPGRADE HUB',
                        style: AppTheme.heading1(context).copyWith(
                          fontSize: isMobile ? 18 : (isTablet ? 24 : 28),
                          letterSpacing: isMobile ? 1 : 2,
                          shadows: [
                            Shadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        Text(
                          _getCategoryDescription(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: isTablet ? 10 : 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Coins Display
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 6 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  border: Border.all(
                    color: Colors.amber.withValues(
                      alpha: 0.5 + _glowAnimation.value * 0.3,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(
                        alpha: _glowAnimation.value * 0.3,
                      ),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: isMobile ? 18 : 24,
                    ),
                    SizedBox(width: isMobile ? 4 : 8),
                    ValueListenableBuilder<int>(
                      valueListenable: widget.game.totalCoins,
                      builder: (context, coins, _) {
                        return Text(
                          '$coins',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 20,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isMobile, bool isTablet) {
    final sidebarWidth = isTablet ? 180.0 : 220.0;

    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        return Container(
          width: sidebarWidth * (1 - _sidebarAnimation.value),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            border: Border(
              right: BorderSide(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          child: Opacity(
            opacity: 1 - _sidebarAnimation.value,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildTab(
                  'Work Surface',
                  'surface',
                  Icons.table_restaurant,
                  isTablet,
                ),
                _buildTab(
                  'Lighting',
                  'lighting',
                  Icons.lightbulb_outline,
                  isTablet,
                ),
                _buildTab(
                  'Background',
                  'background',
                  Icons.wallpaper,
                  isTablet,
                ),
                _buildTab('Beaker Stand', 'stand', Icons.science, isTablet),
                const Spacer(),
                if (!isTablet)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Customize your lab environment',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(
    String title,
    String id,
    IconData icon, [
    bool isCompact = false,
  ]) {
    final isSelected = _selectedCategory == id;
    final itemCount = _catalog.where((i) => i.category == id).length;
    final unlockedCount = _catalog
        .where((i) => i.category == id && _unlockedItems.contains(i.id))
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppTheme.neonCyan.withValues(alpha: 0.15)
            : Colors.transparent,
        border: isSelected
            ? Border.all(color: AppTheme.neonCyan, width: 2)
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _changeCategory(id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 12 : 16,
              horizontal: isCompact ? 8 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.neonCyan : Colors.grey,
                  size: isCompact ? 20 : 22,
                ),
                SizedBox(width: isCompact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                      if (!isCompact)
                        Text(
                          '$unlockedCount/$itemCount unlocked',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(bool isMobile, bool isTablet) {
    final items = _catalog
        .where((i) => i.category == _selectedCategory)
        .toList();

    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 2;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 16.0 : 24.0)),
        child: items.isEmpty
            ? Center(
                child: Text(
                  'No items available',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              )
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: isMobile ? 0.7 : 0.75,
                  crossAxisSpacing: isMobile ? 12 : 20,
                  mainAxisSpacing: isMobile ? 12 : 20,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildItemCard(items[index], isMobile, isTablet),
              ),
      ),
    );
  }

  Widget _buildItemCard(LabItem item, bool isMobile, bool isTablet) {
    final isUnlocked = _unlockedItems.contains(item.id);
    final isEquipped = _equippedConfig[item.category] == item.id;
    final canAfford = widget.game.totalCoins.value >= item.price;
    final isHovered = _hoveredItemId == item.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemId = item.id),
      onExit: (_) => setState(() => _hoveredItemId = null),
      child: GestureDetector(
        onTap: () {
          if (!isUnlocked && canAfford) {
            _purchaseItem(item);
          } else if (isUnlocked && !isEquipped) {
            _equipItem(item);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(isHovered && !isMobile ? 1.05 : 1.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            border: Border.all(
              color: isEquipped
                  ? AppTheme.neonCyan
                  : (isUnlocked
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3)),
              width: isEquipped ? 3 : 2,
            ),
            boxShadow: [
              if (isEquipped)
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              if (isHovered && !isEquipped && !isMobile)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 15,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    gradient: item.gradientColors.isNotEmpty
                        ? LinearGradient(
                            colors: item.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              item.placeholderColor,
                              item.placeholderColor.withValues(alpha: 0.6),
                            ],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: item.placeholderColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (item.icon != null)
                        Center(
                          child: Icon(
                            item.icon,
                            size: isMobile ? 36 : 48,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      if (isEquipped)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppTheme.neonCyan,
                              size: isMobile ? 32 : 40,
                            ),
                          ),
                        ),
                      if (!isUnlocked)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lock,
                              size: isMobile ? 24 : 32,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Info Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isMobile) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: isTablet ? 10 : 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      if (isUnlocked)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isEquipped
                                ? null
                                : () => _equipItem(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEquipped
                                  ? Colors.grey.shade700
                                  : AppTheme.neonCyan,
                              foregroundColor: isEquipped
                                  ? Colors.white
                                  : Colors.black,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 8 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 8 : 12,
                                ),
                              ),
                            ),
                            child: Text(
                              isEquipped ? 'EQUIPPED' : 'EQUIP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: canAfford
                                ? () => _purchaseItem(item)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canAfford
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              foregroundColor: canAfford
                                  ? Colors.amber
                                  : Colors.grey,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 8 : 12,
                              ),
                              side: BorderSide(
                                color: canAfford ? Colors.amber : Colors.grey,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 8 : 12,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: isMobile ? 14 : 18,
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                Text(
                                  '${item.price}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AudioManager().playButton();
                widget.game.overlays.remove('LabUpgrade');
              },
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: isMobile ? 16 : 20,
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Text(
                      isMobile ? 'BACK' : 'BACK TO MENU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isMobile)
            Text(
              'Enhance your laboratory experience',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseDialog(LabItem item) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.neonCyan, width: 2),
      ),
      title: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: AppTheme.neonCyan,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Text(
              'Confirm Purchase',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase ${item.name}?',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cost:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: isMobile ? 18 : 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey, fontSize: isMobile ? 14 : 16),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonCyan,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 24,
              vertical: isMobile ? 10 : 12,
            ),
          ),
          child: Text(
            'Purchase',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  String _getCategoryDescription() {
    switch (_selectedCategory) {
      case 'surface':
        return 'Choose your work surface material';
      case 'lighting':
        return 'Set the perfect laboratory ambiance';
      case 'background':
        return 'Transform your lab environment';
      case 'stand':
        return 'Upgrade your beaker stand';
      default:
        return '';
    }
  }
}

class GridPainter extends CustomPainter {
  final double opacity;

  GridPainter({this.opacity = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.05 + opacity * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 40.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => oldDelegate.opacity != opacity;
}
