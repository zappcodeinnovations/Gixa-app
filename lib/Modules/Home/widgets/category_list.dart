import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/common/utils/app_responsive.dart';
import 'package:Gixa/services/app_verification_controller.dart';
import 'package:get/get.dart';

class CategoryList extends StatefulWidget {
  final bool isDark;
  final Color surface;
  final Color border;

  final VoidCallback onCollegesTap;
  final VoidCallback onRoadmapTap;
  final VoidCallback onCutoffTap;
  final VoidCallback onHelpTap;
  final VoidCallback onApplicationsTap;
  final VoidCallback onAssistanceTap;

  const CategoryList({
    super.key,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.onCollegesTap,
    required this.onRoadmapTap,
    required this.onCutoffTap,
    required this.onHelpTap,
    required this.onApplicationsTap,
    required this.onAssistanceTap,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList>
    with TickerProviderStateMixin {
  int? _pressedIndex;
  late AnimationController _entranceController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  //blink Variables
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _rotateController;

  List<_CategoryItem> get _activeItems {
    final items = [
      _CategoryItem(
        assetPath: 'assets/icons/college.png',
        label: 'Colleges',
        lightBg: const Color.fromARGB(255, 242, 214, 172),
        darkBg: const Color.fromARGB(255, 242, 214, 172),
        onTap: widget.onCollegesTap,
      ),
      _CategoryItem(
        assetPath: 'assets/icons/counseling_new.png',
        label: 'Counselling\nRoadmap',
        lightBg: const Color.fromARGB(255, 242, 214, 172),
        darkBg: const Color.fromARGB(255, 242, 214, 172),
        onTap: widget.onRoadmapTap,
      ),
      _CategoryItem(
        assetPath: 'assets/icons/cutoff.png',
        label: 'Cutoffs',
        lightBg: const Color.fromARGB(255, 242, 214, 172),
        darkBg: const Color.fromARGB(255, 242, 214, 172),
        onTap: widget.onCutoffTap,
      ),
      _CategoryItem(
        assetPath: 'assets/icons/support.png',
        label: 'Addmision\nSupport',
        lightBg: const Color.fromARGB(255, 242, 214, 172),
        darkBg: const Color.fromARGB(255, 242, 214, 172),
        onTap: widget.onHelpTap,
      ),
      _CategoryItem(
        assetPath: 'assets/icons/exam.png',
        label: 'App\nSupport',
        lightBg: const Color.fromARGB(255, 242, 214, 172),
        darkBg: const Color.fromARGB(255, 242, 214, 172),
        onTap: widget.onApplicationsTap,
      ),
    ];

    if (!AppVerificationController.to.hideSubscriptionUi) {
      items.add(
        _CategoryItem(
          assetPath: 'assets/icons/counselling.png',
          label: 'Subscription\nAssistance',
          lightBg: const Color.fromARGB(255, 242, 214, 172),
          darkBg: const Color.fromARGB(255, 242, 214, 172),
          onTap: widget.onAssistanceTap,
        ),
      );
    }
    return items;
  }

  @override
  void initState() {
    super.initState();

    /// 🔥 Predictor Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    /// 🔥 Rotating Ring Animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    /// 🔥 Existing Entrance Animation (KEEP SAME)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnims = List.generate(6, (i) {
      final start = (i * 0.08).clamp(0.0, 0.6);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(6, (i) {
      final start = (i * 0.08).clamp(0.0, 0.6);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = AppResponsive.categoryGridColumns(width);
        final isTablet = width >= 600;
        final iconSize = isTablet ? 78.0 : 68.0;
        final pulseSize = isTablet ? 92.0 : 80.0;
        final ringSize = isTablet ? 96.0 : 84.0;
        final innerRingSize = isTablet ? 86.0 : 76.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Obx(() {
            final items = _activeItems;
            return GridView.builder(
              key: const ValueKey("category_grid"),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isTablet ? 14 : 8,
                mainAxisSpacing: isTablet ? 22 : 18,
                childAspectRatio: isTablet ? 0.92 : 0.76,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => FadeTransition(
                opacity: _fadeAnims[i],
                child: SlideTransition(
                  position: _slideAnims[i],
                  child: _buildTile(
                    i,
                    items[i],
                    iconSize: iconSize,
                    pulseSize: pulseSize,
                    ringSize: ringSize,
                    innerRingSize: innerRingSize,
                    isTablet: isTablet,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTile(
    int index,
    _CategoryItem item, {
    required double iconSize,
    required double pulseSize,
    required double ringSize,
    required double innerRingSize,
    required bool isTablet,
  }) {
    final isPressed = index == _pressedIndex;
    final isDark = widget.isDark;
    final isPredictor = index == 1;

    Widget tile = KeyedSubtree(
      key: ValueKey("tile_$index"), // ✅ IMPORTANT FIX
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressedIndex = index);
        },
        onTapCancel: () => setState(() => _pressedIndex = null),
        onTap: () {
          setState(() => _pressedIndex = null);
          item.onTap();
        },
        child: AnimatedScale(
          scale: isPressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  /// 🔥 ROTATING RING
                  if (isPredictor)
                    RotationTransition(
                      turns: _rotateController,
                      child: Container(
                        height: ringSize,
                        width: ringSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.orange,
                              Colors.yellow,
                              Colors.orange,
                            ],
                          ),
                        ),
                      ),
                    ),

                  /// 🔥 INNER CUT
                  if (isPredictor)
                    Container(
                      height: innerRingSize,
                      width: innerRingSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                      ),
                    ),

                  /// 🔥 PULSE GLOW
                  if (isPredictor)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) {
                        return Container(
                          height: pulseSize * _pulseAnim.value,
                          width: pulseSize * _pulseAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withOpacity(0.25),
                          ),
                        );
                      },
                    ),

                  /// 🔥 MAIN ICON
                  Container(
                    height: iconSize,
                    width: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                item.darkBg.withOpacity(0.5),
                                item.darkBg.withOpacity(0.1),
                              ]
                            : [item.lightBg, Colors.white],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: FittedBox(child: Image.asset(item.assetPath)),
                    ),
                  ),

                  /// 🔥 AI BADGE
                  
                ],
              ),

              const SizedBox(height: 12),

              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 11.5 : 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    /// 🔥 FLOATING EFFECT (SAFE)
    if (isPredictor) {
      tile = AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, -4 * (_pulseAnim.value - 1)),
            child: Transform.scale(scale: _pulseAnim.value, child: child),
          );
        },
        child: tile,
      );
    }

    return tile;
  }
}

class _CategoryItem {
  final String assetPath;
  final String label;
  final Color lightBg;
  final Color darkBg;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.assetPath,
    required this.label,
    required this.lightBg,
    required this.darkBg,
    required this.onTap,
  });
}
