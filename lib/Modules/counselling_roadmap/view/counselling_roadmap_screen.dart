import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../model/counselling_state_model.dart';
import '../widgets/shared_widgets.dart';
import '../controller/counselling_roadmap_controller.dart';
import '../widgets/hero_card.dart';
import '../widgets/fee_card.dart';
import '../widgets/documents_section.dart';
import '../widgets/state_selector.dart';
import '../widgets/section_header.dart';
import '../widgets/ug_pg_toggle.dart';
import '../widgets/extra_sections.dart';
import '../widgets/intro_slider.dart';
import '../widgets/process_rounds_timeline.dart';
import '../widgets/info_cards_sections.dart';
import '../widgets/detailed_eligibility_view.dart';
import '../widgets/detailed_reservation_view.dart';
import '../widgets/detailed_cap_fees_view.dart';
import '../widgets/detailed_alerts_ref_view.dart';
import '../widgets/addon_contact_banner.dart';
import '../widgets/important_dates_view.dart';
import '../widgets/visual_timeline_view.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:Gixa/Modules/addon_contact/controller/addon_contact_controller.dart';
import 'package:Gixa/Modules/subscription/controller/subsciption_history_controller.dart';
import 'package:Gixa/Modules/choice_filling/controller/predication_sheet_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Layout breakpoints
// ─────────────────────────────────────────────────────────────────────────────
const double _kTabletPortraitBreak = 700;   // sidebar appears
const double _kTabletLandscapeBreak = 900;  // wider sidebar
const double _kSidebarNarrow = 190.0;       // 700–899 px
const double _kSidebarWide = 260.0;         // 900+ px

const List<String> _kSectionTitles = [
  "🗓️ Schedule & Process",
  "✅ Eligibility",
  "📊 Reservation",
  "💰 CAP Rounds & Fees",
  "🚨 Alerts & Quick Ref",
];

const List<IconData> _kSectionIcons = [
  Icons.calendar_month_rounded,
  Icons.check_circle_outline_rounded,
  Icons.pie_chart_outline_rounded,
  Icons.payments_outlined,
  Icons.notifications_active_outlined,
];

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class CounsellingRoadmapScreen extends StatelessWidget {
  CounsellingRoadmapScreen({super.key});

  CounsellingRoadmapController get controller =>
      Get.isRegistered<CounsellingRoadmapController>()
      ? Get.find<CounsellingRoadmapController>()
      : Get.put(CounsellingRoadmapController());

  AddonContactController get addonContactController =>
      Get.isRegistered<AddonContactController>()
      ? Get.find<AddonContactController>()
      : Get.put(AddonContactController());

  SubscriptionHistoryController get historyController =>
      Get.isRegistered<SubscriptionHistoryController>()
      ? Get.find<SubscriptionHistoryController>()
      : Get.put(SubscriptionHistoryController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyController.ensureLoaded();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = CounsellingUi.textPrimary(isDark);
    final borderColor = CounsellingUi.border(isDark);
    final appBarBg = isDark ? const Color(0xFF15151F) : Colors.white;
    final scaffoldBg = isDark
        ? const Color(0xFF0E0E16)
        : const Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(context, isDark, textColor, borderColor, appBarBg),
      body: SafeArea(
        top: false,
        child: Obx(() {
          // Observe isUG so AnimatedSwitcher fires on UG/PG toggle
          final _ = controller.isUG;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(controller.isUG),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isTabletPortrait = width >= _kTabletPortraitBreak;
                  final isTabletLandscape = width >= _kTabletLandscapeBreak;
                  final double sidebarWidth = isTabletLandscape
                      ? _kSidebarWide
                      : _kSidebarNarrow;

                  if (isTabletPortrait) {
                    return _TabletLayout(
                      controller: controller,
                      historyController: historyController,
                      isDark: isDark,
                      borderColor: borderColor,
                      sidebarWidth: sidebarWidth,
                    );
                  }

                  return _PhoneLayout(
                    controller: controller,
                    historyController: historyController,
                    isDark: isDark,
                    borderColor: borderColor,
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
    Color appBarBg,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: appBarBg,
      surfaceTintColor: appBarBg,
      foregroundColor: textColor,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: textColor,
        ),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Get.back();
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: GixaColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: GixaColors.pink.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            "Counselling Roadmap",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHONE LAYOUT  (width < 700)
// Horizontal chip scroll + content below — mirrors the original behaviour
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneLayout extends StatelessWidget {
  final CounsellingRoadmapController controller;
  final SubscriptionHistoryController historyController;
  final bool isDark;
  final Color borderColor;

  const _PhoneLayout({
    required this.controller,
    required this.historyController,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (Get.isRegistered<PredictionSheetController>()) {
          await Get.find<PredictionSheetController>().fetchPredictionSheets();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: CounsellingUi.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top sections (always visible) ──
              _TopSections(
                controller: controller,
                historyController: historyController,
                isDark: isDark,
                borderColor: borderColor,
              ),

              const SizedBox(height: 22),

              // ── Swipe hint ──
              _SwipeHint(isDark: isDark),

              // ── Horizontal chip row ──
              // .value is read here, inside the Obx lambda, then passed as plain bool.
              Obx(() {
                final selectedTab = controller.selectedSectionTab.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      5,
                      (i) => _SectionChip(
                        index: i,
                        isDark: isDark,
                        isSelected: selectedTab == i,
                        onTap: () => controller.selectSectionTab(i),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 22),

              // ── Selected section content ──
              // tab and state are resolved inside the Obx lambda.
              Obx(() {
                final tab = controller.selectedSectionTab.value;
                final state = controller.selectedState;
                return _SectionContent(
                  tab: tab,
                  state: state,
                  isDark: isDark,
                  borderColor: borderColor,
                );
              }),
            ],
          ),
        ),
      ),
      ),
    );
  }
}


class _TabletLayout extends StatelessWidget {
  final CounsellingRoadmapController controller;
  final SubscriptionHistoryController historyController;
  final bool isDark;
  final Color borderColor;
  final double sidebarWidth;

  const _TabletLayout({
    required this.controller,
    required this.historyController,
    required this.isDark,
    required this.borderColor,
    required this.sidebarWidth,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarBg = isDark
        ? const Color(0xFF13131C)
        : const Color(0xFFF0F2F8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Vertical nav rail ──
        SizedBox(
          width: sidebarWidth,
          child: Container(
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                right: BorderSide(color: CounsellingUi.border(isDark)),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: _VerticalNavRail(
                controller: controller,
                isDark: isDark,
                sidebarWidth: sidebarWidth,
              ),
            ),
          ),
        ),

        // ── Right: scrollable content ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (Get.isRegistered<PredictionSheetController>()) {
                await Get.find<PredictionSheetController>().fetchPredictionSheets();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top sections ──
                _TopSections(
                  controller: controller,
                  historyController: historyController,
                  isDark: isDark,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 28),

                // ── Selected section content ──
                // tab and state are resolved inside the Obx lambda.
                Obx(() {
                  final tab = controller.selectedSectionTab.value;
                  final state = controller.selectedState;
                  return _SectionContent(
                    tab: tab,
                    state: state,
                    isDark: isDark,
                    borderColor: borderColor,
                  );
                }),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERTICAL NAV RAIL  (tablet sidebar)
// ─────────────────────────────────────────────────────────────────────────────

class _VerticalNavRail extends StatelessWidget {
  final CounsellingRoadmapController controller;
  final bool isDark;
  final double sidebarWidth;

  const _VerticalNavRail({
    required this.controller,
    required this.isDark,
    required this.sidebarWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedSectionTab.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rail header label
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                "SECTIONS",
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
            ),

            ...List.generate(5, (i) {
              final isSelected = selected == i;
              return _NavRailItem(
                index: i,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => controller.selectSectionTab(i),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _NavRailItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavRailItem({
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF6B35);
    final inactiveColor = isDark ? Colors.white60 : Colors.black54;
    final activeBg = activeColor.withOpacity(0.10);
    final hoverBg = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: hoverBg,
          splashColor: activeColor.withOpacity(0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: activeColor.withOpacity(0.25))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                // Leading indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  _kSectionIcons[index],
                  size: 17,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _kSectionTitles[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP SECTIONS  (shared by both layouts)
// AddonBanner · PredictionSheets · UG/PG Toggle · State Selector · HeroCard
// ─────────────────────────────────────────────────────────────────────────────

class _TopSections extends StatelessWidget {
  final CounsellingRoadmapController controller;
  final SubscriptionHistoryController historyController;
  final bool isDark;
  final Color borderColor;

  const _TopSections({
    required this.controller,
    required this.historyController,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.selectedState;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ADDON CONTACT BANNER ──────────────────────────────────
          if (historyController.hasActiveAddonPlan()) ...[
            AddonContactBanner(isDark: isDark),
            const SizedBox(height: 20),
          ],

          // ── PREDICTION SHEETS (CHOICE FILLING) ───────────────────
          Obx(() {
            final sheetController =
                Get.isRegistered<PredictionSheetController>()
                ? Get.find<PredictionSheetController>()
                : Get.put(PredictionSheetController());

            if (sheetController.isLoading.value &&
                sheetController.sheets.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }

            if (sheetController.sheets.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.list_alt_rounded,
                  title: "Choice Filling Sheets",
                ),
                const SizedBox(height: 12),
                for (final sheet in (sheetController.isExpanded.value
                    ? sheetController.sheets
                    : sheetController.sheets.take(2)))
                  Builder(
                    builder: (context) {
                      final isExcel =
                          sheet.fileName.toLowerCase().endsWith('.xls') ||
                          sheet.fileName.toLowerCase().endsWith('.xlsx') ||
                          sheet.fileName.toLowerCase().endsWith('.csv') ||
                          sheet.fileUrl.toLowerCase().endsWith('.xls') ||
                          sheet.fileUrl.toLowerCase().endsWith('.xlsx') ||
                          sheet.fileUrl.toLowerCase().endsWith('.csv');

                      final iconColor = isExcel ? Colors.green : Colors.red;
                      final iconData = isExcel
                          ? Icons.table_chart_rounded
                          : Icons.picture_as_pdf_rounded;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(iconData, color: iconColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sheet.fileName.isNotEmpty
                                        ? sheet.fileName
                                        : 'Choice Filling Document',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: iconColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isExcel ? "EXCEL" : "PDF",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: iconColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tap to download',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () =>
                                  sheetController.openSheet(sheet),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.cloud_download_rounded,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (sheetController.sheets.length > 2)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => sheetController.toggleExpanded(),
                      icon: Icon(
                        sheetController.isExpanded.value
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      label: Text(
                        sheetController.isExpanded.value
                            ? "Show Less"
                            : "Show More (${sheetController.sheets.length - 2})",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // UG / PG toggle removed as it is now determined by profile

          // ── STATE SELECTOR ──────────────────────────────────────
          const SectionLabel(label: "Select State"),
          const SizedBox(height: 10),
          StateSelector(
            controller: controller,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 20),

          // ── HERO CARD ───────────────────────────────────────────
          HeroCard(state: state),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHONE CHIP  (horizontal scroll row item)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionChip extends StatelessWidget {
  final int index;
  final bool isDark;
  /// Resolved OUTSIDE build() — passed from the parent Obx lambda.
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionChip({
    required this.index,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // No .value access here — isSelected is a plain bool from the Obx caller.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.12)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : CounsellingUi.border(isDark),
          ),
        ),
        child: Text(
          _kSectionTitles[index],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFFFF6B35)
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWIPE HINT  (phone only)
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeHint extends StatelessWidget {
  final bool isDark;
  const _SwipeHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_outlined, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                "Swipe for more",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward, size: 10, color: color),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CONTENT  (resolves which view to show — NO Stack)
//
// Root cause fix: the original code used Stack + mixed if/else-if, meaning
// children overlapped and the Stack could collapse to zero height.
// Now we use a plain if/else chain that returns exactly one widget.
// ─────────────────────────────────────────────────────────────────────────────

class _SectionContent extends StatelessWidget {
  /// Both [tab] and [state] must be resolved by the caller inside an Obx lambda
  /// so that GetX reactive tracking works correctly. This widget itself does
  /// NOT access any Rx .value — it receives plain, already-resolved values.
  final int tab;
  final CounsellingStateData state;
  final bool isDark;
  final Color borderColor;

  const _SectionContent({
    required this.tab,
    required this.state,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // tab and state are plain values — no .value access needed here.

    if (tab == 1) {
      return DetailedEligibilityView(
        state: state,
        isDark: isDark,
        borderColor: borderColor,
      );
    }

    if (tab == 2) {
      return DetailedReservationView(
        state: state,
        isDark: isDark,
        borderColor: borderColor,
      );
    }

    if (tab == 3) {
      return DetailedCapFeesView(
        state: state,
        isDark: isDark,
        borderColor: borderColor,
      );
    }

    if (tab == 4) {
      return DetailedAlertsRefView(
        state: state,
        isDark: isDark,
        borderColor: borderColor,
      );
    }

    // tab == 0 — Schedule & Process
    return _ScheduleSection(state: state, isDark: isDark, borderColor: borderColor);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULE & PROCESS SECTION  (tab 0)
// Extracted from inline Column to a named widget for clarity
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final CounsellingStateData state;
  final bool isDark;
  final Color borderColor;

  const _ScheduleSection({
    required this.state,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── VISUAL ROADMAP & DATES QUICK-LAUNCH BANNER ──────────────
        _buildTimelineBanners(context, isDark, borderColor),
        const SizedBox(height: 24),

        // ── INTRO CARDS ─────────────────────────────────────────────
        if (state.introCards.isNotEmpty) ...[
          IntroSlider(
            introCards: state.introCards,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 28),
        ],

        // ── ET-166: VISUAL COUNSELLING ROADMAP (STEPPER) ───────────
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                icon: Icons.timeline_rounded,
                title: "Visual Counselling Roadmap",
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.counsellingTimeline),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen_rounded, size: 16, color: GixaColors.orange),
                    const SizedBox(width: 4),
                    Text(
                      "Full View",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GixaColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        VisualTimelineView(isDark: isDark),
        const SizedBox(height: 32),

        // ── ET-165: IMPORTANT COUNSELLING DATES ─────────────────────
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                icon: Icons.calendar_month_rounded,
                title: "Important Counselling Dates",
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.importantDates),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen_rounded, size: 16, color: GixaColors.orange),
                    const SizedBox(width: 4),
                    Text(
                      "Full View",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GixaColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ImportantDatesView(isDark: isDark),
        const SizedBox(height: 32),

        // ── PROCESS ROUNDS (Horizontal Timeline) ────────────────────
        if (state.processRounds.isNotEmpty) ...[
          ProcessRoundsTimeline(
            rounds: state.processRounds,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 32),
        ],

        // ── RE-REGISTRATION RULES ────────────────────────────────────
        if (state.reRegistrationRules.isNotEmpty) ...[
          ReRegistrationSection(
            rules: state.reRegistrationRules,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 32),
        ],

        // ── SEAT DISTRIBUTION ────────────────────────────────────────
        if (state.seatDistributions.isNotEmpty) ...[
          SeatDistributionSection(
            distributions: state.seatDistributions,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 32),
        ],

        // ── ALERTS & WARNINGS ────────────────────────────────────────
        if (state.alerts.isNotEmpty) ...[
          AlertsSection(
            alerts: state.alerts,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 32),
        ],

        // ── REQUIRED DOCUMENTS ──────────────────────────────────────
        const SectionHeader(
          icon: Icons.description_outlined,
          title: "Required Documents",
        ),
        const SizedBox(height: 12),
        DocumentsSection(documents: state.documents),
        const SizedBox(height: 22),

        // ── FEES / SECURITY ─────────────────────────────────────────
        const SectionHeader(
          icon: Icons.payments_outlined,
          title: "Fees & Security Deposit",
        ),
        const SizedBox(height: 12),
        FeeCard(
          fees: state.fees,
          isDark: isDark,
          borderColor: borderColor,
        ),
        const SizedBox(height: 22),

        // ── ELIGIBILITY CRITERIA ─────────────────────────────────────
        if (state.eligibility.isNotEmpty) ...[
          const SectionHeader(
            icon: Icons.check_circle_outline,
            title: "Eligibility Criteria",
          ),
          const SizedBox(height: 12),
          EligibilitySection(
            eligibility: state.eligibility,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 22),
        ],

        // ── RESERVATION CATEGORIES ──────────────────────────────────
        if (state.reservations.isNotEmpty) ...[
          const SectionHeader(
            icon: Icons.pie_chart_outline,
            title: "Seat Reservation Policy",
          ),
          const SizedBox(height: 12),
          ReservationsSection(
            reservations: state.reservations,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 22),
        ],

        // ── CONTACT INFO ────────────────────────────────────────────
        if (state.contactInfo != null) ...[
          const SectionHeader(
            icon: Icons.contact_support_outlined,
            title: "Contact Information",
          ),
          const SizedBox(height: 12),
          ContactInfoSection(
            contactInfo: state.contactInfo,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _buildTimelineBanners(BuildContext context, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A28) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: CounsellingUi.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GixaColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flash_on_rounded, size: 16, color: GixaColors.orange),
              ),
              const SizedBox(width: 8),
              Text(
                "Live Counselling Tracker",
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.counsellingTimeline),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          GixaColors.orange.withOpacity(isDark ? 0.25 : 0.12),
                          GixaColors.pinkLight.withOpacity(isDark ? 0.2 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GixaColors.orange.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timeline_rounded, size: 16, color: GixaColors.orange),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: GixaColors.orange),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Visual Roadmap",
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Step 1 ➔ Step 5",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.importantDates),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222232) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 16, color: GixaColors.blue),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: GixaColors.blue),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Important Dates",
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Sync with Calendar",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
