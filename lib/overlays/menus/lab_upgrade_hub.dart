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
  String? _hoveredItemId;
  bool _isSidebarCollapsed = false;

  late AnimationController _fadeController;
  late AnimationController _sidebarController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sidebarAnimation;

  // Catalog with enhanced descriptions
  final List<LabItem> _catalog = LabCatalog.items;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _sidebarAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sidebarController.dispose();
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
      } else {
        setState(() {}); // Update to show unlocked status
      }

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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0.9),
                  const Color(0xFF1E293B).withValues(alpha: 0.95),
                ],
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
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                        ),
                      ),
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
                      if (!isCompact)
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
      child: AnimatedCard(
        onTap: () {
          if (!isUnlocked && canAfford) {
            _purchaseItem(item);
          } else if (isUnlocked && !isEquipped) {
            _equipItem(item);
          }
        },
        hasGlow: isEquipped,
        fillColor: isEquipped
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.4),
        borderColor: isEquipped
            ? AppTheme.neonCyan
            : (isUnlocked
                  ? AppTheme.success.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3)),
        borderWidth: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.grey.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area
              Expanded(
                flex: 3,
                child: Container(
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
                        color: item.placeholderColor.withValues(alpha: 0.4),
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
                      if (isEquipped)
                        Positioned(
                          top: 8,
                          right: 8,
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
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      if (!isUnlocked)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(isMobile ? 8 : 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.lock,
                                size: isMobile ? 20 : 28,
                                color: Colors.redAccent,
                              ),
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
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 2,
                                ),
                              ],
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

                      // Action Button (Visual only, tap handled by card)
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isEquipped
                                ? null
                                : LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppTheme.neonCyan,
                                      AppTheme.neonMagenta,
                                    ],
                                  ),
                            color: isEquipped
                                ? Colors.grey.withValues(alpha: 0.2)
                                : null,
                            borderRadius: BorderRadius.circular(12),
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
                              fontSize: isMobile ? 11 : 12,
                              color: isEquipped ? Colors.white54 : Colors.black,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: canAfford
                                ? LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.amber.withValues(alpha: 0.2),
                                      Colors.orange.withValues(alpha: 0.2),
                                    ],
                                  )
                                : null,
                            color: canAfford
                                ? null
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: canAfford ? Colors.amber : Colors.grey,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 14,
                                color: canAfford ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.price}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 11 : 12,
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

  Widget _buildPurchaseDialog(LabItem item) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.neonCyan, width: 1.5),
      ),
      elevation: 20,
      shadowColor: AppTheme.neonCyan.withValues(alpha: 0.5),
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Colors.black,
              size: isMobile ? 20 : 24,
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                'Confirm Purchase',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase ${item.name}?',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18 : 20,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: isMobile ? 20 : 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 18 : 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 24,
                vertical: isMobile ? 10 : 12,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              shadowColor: Colors.transparent,
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
        ),
      ],
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
