import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/lab_catalog.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // StarField
import 'package:color_mixing_deductive/components/ui/responsive_components.dart'; // ResponsiveIconButton
import 'package:color_mixing_deductive/components/ui/animated_card.dart'; // AnimatedCard

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
          // StarField
          const Positioned.fill(
            child: StarField(starCount: 60, color: Colors.white),
          ),

          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.8),
                    const Color(0xFF1E293B).withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: CustomPaint(painter: GridPainter(opacity: 0.3)),
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
                      ShimmerEffect(
                        baseColor: Colors.white,
                        highlightColor: AppTheme.neonCyan,
                        child: Text(
                          isMobile ? 'LAB UPGRADES' : 'LAB UPGRADE HUB',
                          style: AppTheme.heading1(context).copyWith(
                            fontSize: isMobile ? 18 : (isTablet ? 24 : 28),
                            letterSpacing: isMobile ? 1 : 2,
                          ),
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

          _buildCoinsDisplay(isMobile),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 6 : 10,
      ),
      decoration: AppTheme.cosmicGlass(
        borderRadius: isMobile ? 16 : 20,
        borderColor: Colors.amber.withValues(alpha: 0.5),
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
      child: AnimatedCard(
        onTap: () {
          if (!isUnlocked && canAfford) {
            _purchaseItem(item);
          } else if (isUnlocked && !isEquipped) {
            _equipItem(item);
          }
        },
        hasGlow: isEquipped,
        fillColor: Colors.black.withValues(alpha: 0.5),
        borderColor: isEquipped
            ? AppTheme.neonCyan
            : (isUnlocked
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2)),
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

                    // Action Button (Visual only, tap handled by card)
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? Colors.grey.withValues(alpha: 0.3)
                              : AppTheme.neonCyan,
                          borderRadius: BorderRadius.circular(8),
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
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: canAfford
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canAfford ? Colors.amber : Colors.grey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 12,
                              color: canAfford ? Colors.amber : Colors.grey,
                            ),
                            SizedBox(width: 4),
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
          ResponsiveIconButton(
            onPressed: () {
              AudioManager().playButton();
              widget.game.overlays.remove('LabUpgrade');
            },
            icon: Icons.arrow_back,
            color: Colors.white,
            backgroundColor: Colors.transparent,
            borderColor: Colors.white.withValues(alpha: 0.3),
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
            child: ShimmerEffect(
              baseColor: Colors.white,
              highlightColor: AppTheme.neonCyan,
              child: Text(
                'Confirm Purchase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
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
