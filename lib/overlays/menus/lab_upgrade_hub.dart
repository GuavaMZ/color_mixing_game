import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/lab_catalog.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // StarField
import 'package:color_mixing_deductive/components/ui/responsive_components.dart'; // ResponsiveIconButton
import 'package:color_mixing_deductive/components/ui/animated_card.dart'; // AnimatedCard
import 'package:color_mixing_deductive/components/ui/coins_widget.dart'; // CoinsWidget

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

  late AnimationController _fadeController;
  late AnimationController _sidebarController;
  late AnimationController _scrollController;
  late Animation<double> _sidebarAnimation;

  // Catalog with enhanced descriptions
  final List<LabItem> _catalog = LabCatalog.items;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scrollController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _sidebarAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    // Initial animation
    _fadeController.forward();

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sidebarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _unlockedItems = await SaveManager.loadUnlockedLabItems();
      _equippedConfig = await SaveManager.loadLabConfig();
    } catch (e) {
      debugPrint("Error loading lab data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fadeController.forward();
      }
    }
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fadeController.reset();
    _fadeController.forward();
    AudioManager().playButton();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Enhanced background with animated particles
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                ),
              ),
            ),
          ),

          // Animated particle background
          _AnimatedParticleBackground(),

          // StarField
          const Positioned.fill(
            child: StarField(starCount: 60, color: Colors.white),
          ),

          // Background Gradient with custom pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.7),
                    const Color(0xFF1E293B).withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: CustomPaint(painter: GridPainter(opacity: 0.2)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        // Category Selector (Horizontal Scroll)
        Container(
          height: screenWidth < 360 ? 80 : 95,
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
              _buildMobileTab(
                context,
                'Surface',
                'surface',
                Icons.table_restaurant,
              ),
              _buildMobileTab(
                context,
                'Lighting',
                'lighting',
                Icons.lightbulb_outline,
              ),
              _buildMobileTab(
                context,
                'Background',
                'background',
                Icons.wallpaper,
              ),
              _buildMobileTab(context, 'Stand', 'stand', Icons.science),
              _buildMobileTab(
                context,
                'Overhead',
                'string_lights',
                Icons.wb_incandescent,
              ),
            ],
          ),
        ),

        // Grid
        Expanded(child: _buildGrid(true, false)),
      ],
    );
  }

  Widget _buildMobileTab(
    BuildContext context,
    String title,
    String id,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == id;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDevice = screenWidth < 360;

    return GestureDetector(
      onTap: () => _changeCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: isSmallDevice ? 6 : 8,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallDevice ? 12 : 16,
          vertical: isSmallDevice ? 6 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.neonCyan.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.2),
            width: isSmallDevice ? 1.5 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.neonCyan : Colors.grey,
              size: isSmallDevice ? 20 : 24,
            ),
            SizedBox(height: isSmallDevice ? 2 : 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmallDevice ? 10 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
    int totalUnlocked = _unlockedItems.length;
    int totalItems = _catalog.length;
    double completion = totalItems > 0 ? (totalUnlocked / totalItems) * 100 : 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.9),
            const Color(0xFF1E293B).withValues(alpha: 0.9),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      (isMobile ? 'LAB UPGRADES' : 'LAB UPGRADE HUB')
                          .toUpperCase(),
                      style: AppTheme.heading1(context).copyWith(
                        fontSize: isMobile ? 12 : (isTablet ? 16 : 18),
                        letterSpacing: isMobile ? 2 : 4,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.neonCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '🔬 ${completion.toStringAsFixed(0)}% COMPLETE',
                            style: TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: isMobile ? 9 : 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCoinsDisplay(isMobile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoinsDisplay(bool isMobile) {
    return CoinsWidget(
      coinsNotifier: widget.game.totalCoins,
      useEnhancedStyle: false, // Use basic style to match the hub's design
      iconSize: isMobile ? 18 : 24,
      fontSize: isMobile ? 16 : 20,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 6 : 10,
      ),
      showIcon: true,
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F172A).withValues(alpha: 0.9),
                const Color(0xFF1E293B).withValues(alpha: 0.9),
              ],
            ),
            border: Border(
              right: BorderSide(
                color: AppTheme.neonCyan.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Opacity(
            opacity: 1 - _sidebarAnimation.value,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.dashboard, color: AppTheme.neonCyan, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                _buildTab(
                  'Overhead Lights',
                  'string_lights',
                  Icons.wb_incandescent,
                  isTablet,
                ),
                const Spacer(),
                if (!isTablet)
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.neonCyan.withValues(alpha: 0.1),
                          AppTheme.neonMagenta.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Customize your lab environment',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
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
    final progress = itemCount > 0 ? unlockedCount / itemCount : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.2),
                  AppTheme.neonMagenta.withValues(alpha: 0.2),
                ],
              )
            : null,
        color: isSelected ? null : Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: isSelected
              ? AppTheme.neonCyan
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _changeCategory(id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 12 : 16,
              horizontal: isCompact ? 8 : 12,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.neonCyan.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.neonCyan : Colors.grey,
                    size: isCompact ? 16 : 18,
                  ),
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
                              : FontWeight.w500,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: progress == 1.0
                                          ? AppTheme.success
                                          : AppTheme.neonCyan,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (progress == 1.0
                                                      ? AppTheme.success
                                                      : AppTheme.neonCyan)
                                                  .withValues(alpha: 0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$unlockedCount/$itemCount',
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.neonCyan
                                    : Colors.grey.withValues(alpha: 0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Compact version progress (just text)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.neonCyan.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unlockedCount/$itemCount',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.neonCyan
                                  : Colors.grey.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

    return Padding(
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
              itemBuilder: (context, index) {
                // Staggered animation values
                final fadeDelay = index * 0.05;
                final slideAnimation =
                    Tween<Offset>(
                      begin: const Offset(0, 50),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(
                          fadeDelay.clamp(0.0, 1.0),
                          (fadeDelay + 0.5).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );

                final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
                    .animate(
                      CurvedAnimation(
                        parent: _fadeController,
                        curve: Interval(
                          fadeDelay.clamp(0.0, 1.0),
                          (fadeDelay + 0.5).clamp(0.0, 1.0),
                          curve: Curves.easeIn,
                        ),
                      ),
                    );

                return AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: opacityAnimation.value,
                      child: Transform.translate(
                        offset: slideAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildItemCard(items[index], isMobile, isTablet),
                );
              },
            ),
    );
  }

  Widget _buildItemCard(LabItem item, bool isMobile, bool isTablet) {
    final isUnlocked = _unlockedItems.contains(item.id);
    final isEquipped = _equippedConfig[item.category] == item.id;
    final canAfford = widget.game.totalCoins.value >= item.price;

    return MouseRegion(
      child: AnimatedCard(
        onTap: () => _showItemDetail(item),
        hasGlow: isEquipped || item.rarity == LabRarity.legendary,
        fillColor: Colors.black.withValues(alpha: isEquipped ? 0.2 : 0.4),
        borderColor: isEquipped
            ? AppTheme.neonCyan
            : item.rarity.color.withValues(alpha: isUnlocked ? 0.6 : 0.3),
        borderWidth: item.rarity == LabRarity.legendary ? 2.5 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                item.rarity.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area
              Expanded(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final isLockedLegendary =
                        !isUnlocked && item.rarity == LabRarity.legendary;
                    return Container(
                      margin: EdgeInsets.all(isMobile ? 8 : 12),
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
                            color:
                                (isEquipped
                                        ? AppTheme.neonCyan
                                        : item.rarity.glowColor)
                                    .withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
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
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          // Legendary Shimmer Effect
                          if (isLockedLegendary)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 12 : 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(
                                        -2.0 + (_scrollController.value * 4.0),
                                        -2.0 + (_scrollController.value * 4.0),
                                      ),
                                      end: Alignment(
                                        -1.0 + (_scrollController.value * 4.0),
                                        -1.0 + (_scrollController.value * 4.0),
                                      ),
                                      stops: const [0.0, 0.5, 1.0],
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Rarity badge
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: item.rarity.gradient,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.rarity.glowColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${item.rarity.icon} ${item.rarity.label}',
                                style: TextStyle(
                                  color: item.rarity == LabRarity.legendary
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: isMobile ? 8 : 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (isEquipped)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonCyan,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 14,
                                ),
                              ),
                            ),
                          if (!isUnlocked)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 12 : 16,
                                ),
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: item.rarity.color,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.lock,
                                    size: isMobile ? 18 : 24,
                                    color: item.rarity.color,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Info Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 10.0 : 14.0),
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
                              color: isUnlocked ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 13 : 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isMobile) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: isTablet ? 10 : 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      // Status button
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isEquipped
                                ? null
                                : LinearGradient(
                                    colors: [
                                      AppTheme.neonCyan,
                                      AppTheme.neonMagenta,
                                    ],
                                  ),
                            color: isEquipped
                                ? Colors.grey.withValues(alpha: 0.2)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            border: isEquipped
                                ? Border.all(
                                    color: Colors.grey.withValues(alpha: 0.4),
                                  )
                                : null,
                          ),
                          child: Text(
                            isEquipped ? 'EQUIPPED' : 'EQUIP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 10 : 11,
                              color: isEquipped ? Colors.white54 : Colors.black,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: canAfford
                                ? LinearGradient(
                                    colors: [
                                      Colors.amber.withValues(alpha: 0.2),
                                      Colors.orange.withValues(alpha: 0.2),
                                    ],
                                  )
                                : null,
                            color: canAfford
                                ? null
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: canAfford ? Colors.amber : Colors.grey,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 13,
                                color: canAfford ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.price}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 10 : 11,
                                  color: canAfford ? Colors.amber : Colors.grey,
                                ),
                              ),
                            ],
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
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.7),
            const Color(0xFF1E293B).withValues(alpha: 0.9),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ResponsiveIconButton(
              onPressed: () {
                AudioManager().playButton();
                widget.game.overlays.remove('LabUpgrade');
              },
              icon: Icons.arrow_back,
              color: Colors.black,
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
            ),
          ),

          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Enhance your laboratory experience',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showItemDetail(LabItem item) {
    AudioManager().playButton();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemDetailSheet(
        item: item,
        game: widget.game,
        isUnlocked: _unlockedItems.contains(item.id),
        isEquipped: _equippedConfig[item.category] == item.id,
        onPurchase: () {
          Navigator.pop(context);
          _purchaseItem(item);
        },
        onEquip: () {
          Navigator.pop(context);
          _equipItem(item);
        },
      ),
    );
  }

  Future<void> _purchaseItem(LabItem item) async {
    if (widget.game.totalCoins.value >= item.price) {
      int newBalance = widget.game.totalCoins.value - item.price;
      widget.game.totalCoins.value = newBalance;
      await SaveManager.saveTotalCoins(newBalance);

      _unlockedItems.add(item.id);
      await SaveManager.saveUnlockedLabItems(_unlockedItems);
      AudioManager().playUnlockSound();

      // Simple unlock celebration
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) Navigator.pop(context); // Auto-close
            });
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      item.rarity.glowColor.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  item.icon ?? Icons.science,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      }

      if (_equippedConfig[item.category] == null ||
          !_unlockedItems.contains(_equippedConfig[item.category])) {
        await _equipItem(item);
      } else {
        setState(() {}); // Update to show unlocked status
      }
    } else {
      AudioManager().playError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough coins! Need ${item.price - widget.game.totalCoins.value} more.',
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.9),
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
    // Apply changes to the running game immediately
    widget.game.applyLabConfig(_equippedConfig);
    AudioManager().playButton();
    setState(() {});
  }
}

// ─── Item Detail Bottom Sheet ────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final LabItem item;
  final ColorMixerGame game;
  final bool isUnlocked;
  final bool isEquipped;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const _ItemDetailSheet({
    required this.item,
    required this.game,
    required this.isUnlocked,
    required this.isEquipped,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = game.totalCoins.value >= item.price;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: MediaQuery.of(context).size.height * (isMobile ? 0.85 : 0.7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: item.rarity.color, width: 2)),
        boxShadow: [
          BoxShadow(
            color: item.rarity.glowColor.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                // Hero Image
                Container(
                  height: isMobile ? 180 : 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: item.gradientColors.isNotEmpty
                        ? LinearGradient(
                            colors: item.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              item.placeholderColor,
                              item.placeholderColor.withValues(alpha: 0.5),
                            ],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: item.rarity.glowColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          item.icon,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      // Rarity Badge Top Left
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.rarity.gradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: item.rarity.glowColor,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            '${item.rarity.icon} ${item.rarity.label}',
                            style: TextStyle(
                              color: item.rarity == LabRarity.legendary
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name & Category
                Text(
                  item.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: item.rarity.color.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.category.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),

                // Description & Lore
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SPECIFICATIONS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      if (item.lore.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white10),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.auto_stories,
                              color: item.rarity.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ARCHIVE DATA',
                              style: TextStyle(
                                color: item.rarity.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.lore,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Action Area Bottom
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Price Tag if not unlocked
                if (!isUnlocked)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: canAfford
                            ? Colors.amber
                            : Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: canAfford ? Colors.amber : Colors.redAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            color: canAfford ? Colors.amber : Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (isEquipped) {
                        Navigator.pop(
                          context,
                        ); // Do nothing if already equipped
                      } else if (isUnlocked) {
                        onEquip();
                      } else if (canAfford) {
                        onPurchase();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isEquipped
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.withValues(alpha: 0.2),
                                  Colors.grey.withValues(alpha: 0.3),
                                ],
                              )
                            : (isUnlocked
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.neonCyan,
                                        AppTheme.neonMagenta,
                                      ],
                                    )
                                  : (canAfford
                                        ? LinearGradient(
                                            colors: item.rarity.gradient,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.red.withValues(alpha: 0.2),
                                              Colors.black,
                                            ],
                                          ))),
                        boxShadow: [
                          if (!isEquipped && (isUnlocked || canAfford))
                            BoxShadow(
                              color:
                                  (isUnlocked
                                          ? AppTheme.neonCyan
                                          : item.rarity.glowColor)
                                      .withValues(alpha: 0.4),
                              blurRadius: 15,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isEquipped
                              ? 'ALREADY EQUIPPED'
                              : (isUnlocked
                                    ? 'EQUIP NOW'
                                    : 'PURCHASE PROTOTYPE'),
                          style: TextStyle(
                            color: isEquipped
                                ? Colors.white54
                                : (item.rarity == LabRarity.legendary &&
                                          !isUnlocked
                                      ? Colors.black
                                      : Colors.white),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedParticleBackground extends StatefulWidget {
  const _AnimatedParticleBackground();

  @override
  State<_AnimatedParticleBackground> createState() =>
      _AnimatedParticleBackgroundState();
}

class _AnimatedParticleBackgroundState
    extends State<_AnimatedParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      25,
      (index) => _Particle(
        size: 1 + (index % 4).toDouble(),
        speed: 0.3 + (index % 2).toDouble(),
        color: [
          AppTheme.neonCyan,
          AppTheme.neonMagenta,
          AppTheme.electricYellow,
          Colors.blue,
          Colors.purple,
        ][index % 5].withValues(alpha: 0.2 + (index % 3) * 0.1),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            time: _controller.value * 100,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final double size;
  final double speed;
  final Color color;

  _Particle({required this.size, required this.speed, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;

  _ParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Calculate position with wave-like motion
      final x =
          (size.width / 2) +
          (size.width / 4) *
              math.sin(0.5 * (time * particle.speed + i) * 0.02) +
          (size.width / 5) *
              math.cos(0.3 * (time * particle.speed + i * 2) * 0.03);

      final y =
          (size.height / 2) +
          (size.height / 4) *
              math.cos(0.4 * (time * particle.speed + i * 1.5) * 0.015) +
          (size.height / 5) *
              math.sin(0.3 * (time * particle.speed + i * 0.8) * 0.025);

      // Wrap around edges
      final wrappedX = x % size.width;
      final wrappedY = y % size.height;

      final finalX = wrappedX < 0 ? wrappedX + size.width : wrappedX;
      final finalY = wrappedY < 0 ? wrappedY + size.height : wrappedY;

      paint.color = particle.color;
      canvas.drawCircle(Offset(finalX, finalY), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class GridPainter extends CustomPainter {
  final double opacity;
  final Offset scrollOffset;

  GridPainter({this.opacity = 0.5, this.scrollOffset = Offset.zero});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Apply parallax translation, wrapping around the step size
    const step = 40.0;
    final dx = scrollOffset.dx % step;
    final dy = scrollOffset.dy % step;
    canvas.translate(dx, dy);

    final paint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.05 + opacity * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw lines slightly beyond the visible area to account for translation
    for (double x = -step; x <= size.width + step; x += step) {
      canvas.drawLine(Offset(x, -step), Offset(x, size.height + step), paint);
    }

    for (double y = -step; y <= size.height + step; y += step) {
      canvas.drawLine(Offset(-step, y), Offset(size.width + step, y), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.scrollOffset != scrollOffset;
}
