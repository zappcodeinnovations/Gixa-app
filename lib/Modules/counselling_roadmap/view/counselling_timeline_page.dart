import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/counselling_roadmap/controller/counselling_timeline_controller.dart';
import 'package:Gixa/Modules/counselling_roadmap/widgets/important_dates_view.dart';
import 'package:Gixa/Modules/counselling_roadmap/widgets/visual_timeline_view.dart';
import 'package:Gixa/utils/constants/colors.dart';

class CounsellingTimelinePage extends StatefulWidget {
  final int initialTabIndex; // 0 for Timeline, 1 for Dates

  const CounsellingTimelinePage({super.key, this.initialTabIndex = 0});

  @override
  State<CounsellingTimelinePage> createState() => _CounsellingTimelinePageState();
}

class _CounsellingTimelinePageState extends State<CounsellingTimelinePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CounsellingTimelineController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<CounsellingTimelineController>()
        ? Get.find<CounsellingTimelineController>()
        : Get.put(CounsellingTimelineController());

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0E0E16) : const Color(0xFFF4F6FB);
    final appBarBg = isDark ? const Color(0xFF15151F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor = isDark ? const Color(0xFF232334) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              "Counselling Schedule & Roadmap",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Obx(() => Text(
                  "${_controller.currentStateCode.value} State • ${_controller.isUG ? 'NEET UG' : 'NEET PG'}",
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: UColors.primary,
                  ),
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: textColor,
            onPressed: () => _controller.loadTimeline(forceRefresh: true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: appBarBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: UColors.primary,
              indicatorWeight: 3,
              labelColor: UColors.primary,
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF6B7280),
              labelStyle: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline_rounded, size: 16),
                      SizedBox(width: 6),
                      Text("Visual Roadmap"),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16),
                      SizedBox(width: 6),
                      Text("Important Dates"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Visual Timeline View (ET-166) ──
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: VisualTimelineView(isDark: isDark),
          ),

          // ── Tab 2: Important Dates View (ET-165) ──
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ImportantDatesView(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

