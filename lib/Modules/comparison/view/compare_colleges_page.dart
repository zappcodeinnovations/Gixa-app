import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Gixa/Modules/comparison/controller/college_compare_controller.dart';
import 'package:Gixa/Modules/comparison/model/college_compare_model.dart';
import 'package:Gixa/routes/app_routes.dart';

// ─── All colors in a top-level class so every widget can access them ─────────
class _C {
  static const orange = Color(0xFFFF6B2C);
  static const orangeSurface = Color(0xFFFFF4EE);
  static const dark = Color(0xFF12100E);
  static const darkCard = Color(0xFF1C1A18);
  static const darkSurface = Color(0xFF252220);
  static const textPrimary = Color(0xFF1A1614);
  static const textSecondary = Color(0xFF7A736E);
  static const lightBg = Color(0xFFFAF8F6);
  static const lightCard = Color(0xFFFFFFFF);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
}

class CompareCollegesView extends StatefulWidget {
  const CompareCollegesView({super.key});

  @override
  State<CompareCollegesView> createState() => _CompareCollegesViewState();
}

class _CompareCollegesViewState extends State<CompareCollegesView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isFromHistory = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _isFromHistory = args != null && args is! Map;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CollegeCompareController>().initFromArgs(args);
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollegeCompareController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _C.dark : _C.lightBg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _C.orange,
                  strokeWidth: 2.5,
                ),
              );
            }

            final result = controller.compareResult.value;
            if (result == null || result.comparison.length < 2) {
              return _EmptyState(isDark: isDark);
            }

            final colleges = result.comparison;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 110),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeaderRow(colleges, isDark),
                    const SizedBox(height: 32),
                    _buildQuickStats(colleges, isDark),
                    const SizedBox(height: 28),
                    _buildChartSection(colleges, isDark),
                    const SizedBox(height: 28),
                    _buildAiInsightCard(colleges, isDark),
                  ],
                ),
              ),
            );
          }),

          // Floating Save Button
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Obx(() {
              final isLoading = controller.isLoading.value;
              final result = controller.compareResult.value;
              final hasData = result != null && result.comparison.length >= 2;
              if (!_isFromHistory && !isLoading && hasData) {
                return _buildSaveButton(controller);
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final textColor = isDark ? Colors.white : _C.textPrimary;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: textColor,
          ),
        ),
      ),
      title: Text(
        "Compare",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.savedComparision),
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 10, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _C.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_rounded, color: Colors.white, size: 15),
                SizedBox(width: 5),
                Text(
                  "Saved",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── HEADER CARDS ────────────────────────────────────────
  Widget _buildHeaderRow(List<CollegeComparison> colleges, bool isDark) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // IntrinsicHeight so both cards grow to the same height
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: colleges.map((college) {
              final words = college.collegeName
                  .split(' ')
                  .where((e) => e.isNotEmpty);
              final initials = words
                  .take(2)
                  .map((e) => e[0])
                  .join()
                  .toUpperCase();

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  decoration: BoxDecoration(
                    color: isDark ? _C.darkCard : _C.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _C.orangeSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _C.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        college.collegeName,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white : _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // _chanceTag(college.admissionChances),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // VS badge — only for exactly 2 colleges
        if (colleges.length == 2)
          Positioned(
            top: 38,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _C.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _C.orange.withOpacity(0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                "VS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chanceTag(String chance) {
    final c = chance.toLowerCase();
    final Color color;
    if (c.contains("high")) {
      color = _C.green;
    } else if (c.contains("moderate")) {
      color = _C.amber;
    } else {
      color = _C.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        chance,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  // ─── QUICK STATS ─────────────────────────────────────────
  Widget _buildQuickStats(List<CollegeComparison> colleges, bool isDark) {
    final rows = [
      _StatRowData(
        Icons.location_on_rounded,
        "Location",
        colleges.map((e) => e.city.isNotEmpty ? e.city : "N/A").toList(),
        _C.orange,
      ),
      _StatRowData(
        Icons.bedroom_child_rounded,
        "Hostel",
        colleges.map((e) => e.hostelAvailable ? "✓ Yes" : "✗ No").toList(),
        const Color(0xFF8B5CF6),
      ),
      _StatRowData(
        Icons.qr_code_rounded,
        "Code",
        colleges
            .map((e) => e.collegeCode.isNotEmpty ? e.collegeCode : "N/A")
            .toList(),
        const Color(0xFF06B6D4),
      ),
      _StatRowData(
        Icons.history_edu_rounded,
        "Est.",
        colleges.map((e) => e.yearEstablished?.toString() ?? "N/A").toList(),
        _C.green,
      ),
      _StatRowData(
        Icons.account_balance_rounded,
        "Type",
        colleges.map((e) => e.instituteTypeName ?? "N/A").toList(),
        const Color(0xFFEC4899),
      ),
      _StatRowData(
        Icons.map_rounded,
        "State",
        colleges.map((e) => e.stateName ?? "N/A").toList(),
        const Color(0xFF14B8A6),
      ),
      _StatRowData(
        Icons.event_seat_rounded,
        "Seats",
        colleges.map((e) => e.totalSeatsCount.toString()).toList(),
        _C.orange,
      ),
      _StatRowData(
        Icons.email_rounded,
        "Email",
        colleges.map((e) => e.contactEmail ?? "N/A").toList(),
        const Color(0xFF64748B),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Overview", isDark),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? _C.darkCard : _C.lightCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  _buildStatRow(row, isDark),
                  if (i < rows.length - 1)
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(_StatRowData row, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: row.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(row.icon, size: 14, color: row.color),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : _C.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...row.values.map((v) => Expanded(child: _valueText(v, isDark))),
        ],
      ),
    );
  }

  Widget _valueText(String v, bool isDark) {
    Color color = isDark ? Colors.white : _C.textPrimary;
    if (v.startsWith("✓")) color = _C.green;
    if (v.startsWith("✗")) color = _C.red;

    return Text(
      v,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      ),
    );
  }

  // ─── CHART ───────────────────────────────────────────────
  Widget _buildChartSection(List<CollegeComparison> colleges, bool isDark) {
    double getHeight(String chance) {
      final c = chance.toLowerCase();
      if (c.contains("high")) return 5.0;
      if (c.contains("moderate")) return 3.2;
      if (c.contains("low")) return 1.6;
      return 1.0;
    }

    Color getColor(String chance) {
      final c = chance.toLowerCase();
      if (c.contains("high")) return _C.green;
      if (c.contains("moderate")) return _C.amber;
      if (c.contains("low")) return _C.red;
      return Colors.grey;
    }

    String getShortLabel(String chance) {
      final c = chance.toLowerCase();
      if (c.contains("high")) return "High";
      if (c.contains("moderate")) return "Moderate";
      if (c.contains("low")) return "Low";
      return "–";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Admission Probability", isDark),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          decoration: BoxDecoration(
            color: isDark ? _C.darkCard : _C.lightCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: colleges.map((c) {
                  final color = getColor(c.admissionChances);
                  final words = c.collegeName
                      .split(' ')
                      .where((e) => e.isNotEmpty);
                  final initials = words
                      .take(2)
                      .map((e) => e[0])
                      .join()
                      .toUpperCase();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "$initials · ${getShortLabel(c.admissionChances)}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : _C.textSecondary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 6,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1.5,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.shade100,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= colleges.length) {
                              return const SizedBox.shrink();
                            }
                            final words = colleges[idx].collegeName
                                .split(' ')
                                .where((e) => e.isNotEmpty);
                            final initials = words
                                .take(2)
                                .map((e) => e[0])
                                .join()
                                .toUpperCase();
                            final color = getColor(
                              colleges[idx].admissionChances,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    initials,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    getShortLabel(
                                      colleges[idx].admissionChances,
                                    ),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white38
                                          : _C.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            isDark ? _C.darkSurface : Colors.white,
                        tooltipRoundedRadius: 10,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        getTooltipItem: (group, _, rod, __) {
                          final idx = group.x.toInt();
                          if (idx < 0 || idx >= colleges.length) return null;
                          final c = colleges[idx];
                          return BarTooltipItem(
                            c.collegeName,
                            TextStyle(
                              color: isDark ? Colors.white : _C.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '\n${c.admissionChances}',
                                style: TextStyle(
                                  color: getColor(c.admissionChances),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    barGroups: colleges.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final c = entry.value;
                      final h = getHeight(c.admissionChances);
                      final col = getColor(c.admissionChances);

                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: h,
                            gradient: LinearGradient(
                              colors: [col.withOpacity(0.55), col],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 36,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 6,
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── AI INSIGHT ──────────────────────────────────────────
  Widget _buildAiInsightCard(List<CollegeComparison> colleges, bool isDark) {
    CollegeComparison? best;
    for (final c in colleges) {
      if (c.admissionChances.toLowerCase().contains("high")) {
        best = c;
        break;
      }
    }
    best ??= colleges.isNotEmpty ? colleges.first : null;
    if (best == null) return const SizedBox.shrink();

    final bestName = best.collegeName;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B2C), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.orange.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Recommendation",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Based on your profile, $bestName offers the best match with higher admission probability and available seats.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SAVE BUTTON ─────────────────────────────────────────
  Widget _buildSaveButton(CollegeCompareController controller) {
    return Obx(() {
      final saved = controller.isSaved.value;
      return GestureDetector(
        onTap: () {
          if (!saved) {
            controller.saveComparedColleges();
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Limit reached of save comparisons.",style: TextStyle(color: Colors.redAccent),),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: saved ? Colors.green : _C.orange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (saved ? Colors.green : _C.orange).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              saved ? "Saved" : "Save Comparison",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _sectionLabel(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark ? Colors.white : _C.textPrimary,
      ),
    );
  }
}

// ─── Stat row data model ──────────────────────────────────
class _StatRowData {
  final IconData icon;
  final String label;
  final List<String> values;
  final Color color;
  _StatRowData(this.icon, this.label, this.values, this.color);
}

// ─── Empty State ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _C.orangeSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 42,
                color: _C.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Nothing to compare",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _C.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Select at least two colleges to see an AI-powered side-by-side comparison.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : _C.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Get.toNamed("/college"),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _C.orange,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _C.orange.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  "Select Colleges",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
