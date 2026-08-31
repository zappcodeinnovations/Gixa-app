import 'package:Gixa/Modules/Assistance/view/counselor_page.dart';
import 'package:Gixa/Modules/predication/controller/prediction_controller.dart';
import 'package:Gixa/Modules/rankAnalysis/view/rank_analysis_view.dart';
import 'package:Gixa/Modules/subscription/extensions/subscription_tier_extension.dart';
import 'package:Gixa/Modules/subscription/features/feature_names.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/Modules/subscription/view/subscription_plan_page.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/predication_model.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class AiPredictionResultView extends StatefulWidget {
  final PredictionData predictionData;

  AiPredictionResultView({super.key, required this.predictionData});

  static const Color _indigo = Color.fromARGB(255, 236, 139, 4);
  static const Color _indigoDark = Color.fromARGB(255, 51, 134, 242);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _bgDark = Color(0xFF0A0F1E);
  static const Color _bgLight = Color(0xFFF0F2F8);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF818CF8);

  @override
  State<AiPredictionResultView> createState() => _AiPredictionResultViewState();
}

class _AiPredictionResultViewState extends State<AiPredictionResultView> {
  final SubscriptionController ssubscriptionController =
      Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await subscriptionController.ensureActivePlanReady(forceRefresh: true);

      print(" ACTIVE PLAN: ${subscriptionController.activePlan.value}");

      _showCompareSuggestion();
    });
  }

  final RxString selectedFilter = "All".obs;

  final PredictionController controller = Get.find();

  final RxList<CollegeModel> selectedColleges = <CollegeModel>[].obs;

  final SubscriptionController subscriptionController =
      Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>()
      : Get.put(SubscriptionController());

  String _normalizedInstituteType(CollegeModel college) {
    return college.instituteType.trim().toLowerCase();
  }

  bool _isGovernmentCollege(CollegeModel college) {
    final instituteType = _normalizedInstituteType(college);
    return instituteType.contains("government") || instituteType == "govt";
  }

  bool _isPrivateBucketCollege(CollegeModel college) {
    final instituteType = _normalizedInstituteType(college);
    if (instituteType.isEmpty) return false;
    return !_isGovernmentCollege(college);
  }

  String _instituteTypeLabel(CollegeModel college) {
    final instituteType = college.instituteType.trim();
    if (instituteType.isEmpty) {
      final isMcc = controller.effectiveState.toUpperCase() == 'MCC';
      return isMcc ? "Deemed" : "Private";
    }
    if (_isGovernmentCollege(college)) return "Government";
    return instituteType;
  }

  void _showCompareSuggestion() {
    final isPremiumUser = subscriptionController.activePlan.value != null;

    final hasEnoughColleges = widget.predictionData.collegeList.length >= 2;

    if (isPremiumUser && hasEnoughColleges) {
      Future.delayed(const Duration(milliseconds: 800), () {
        AppSnackbar.show(
          "Compare Colleges",
          "Select any 2 suitable colleges to compare instantly.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AiPredictionResultView._surface,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        );
      });
    }
  }

  Widget _buildFilterTabs() {
    final govtCount = widget.predictionData.collegeList
        .where(_isGovernmentCollege)
        .length;
    final pvtCount = widget.predictionData.collegeList
        .where(_isPrivateBucketCollege)
        .length;
    final allCount = widget.predictionData.collegeList.length;

    final isMcc = controller.effectiveState.toUpperCase() == 'MCC';
    final pvtLabel = isMcc ? "Deemed" : "Private";

    final filterLabels = [
      {"label": "All", "count": allCount},
      {"label": "Government", "count": govtCount},
      {"label": pvtLabel, "count": pvtCount},
    ];

    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: filterLabels.map((item) {
              final type = item["label"] as String;
              final count = item["count"] as int;
              final selected = selectedFilter.value == type;

              return Expanded(
                child: GestureDetector(
                  onTap: () => selectedFilter.value = type,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AiPredictionResultView._indigo
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        // â”€â”€ Badge pill â”€â”€
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.22)
                                : Colors.black.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Main Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final govtColleges = widget.predictionData.collegeList
        .where(_isGovernmentCollege)
        .toList();
    final privateColleges = widget.predictionData.collegeList
        .where(_isPrivateBucketCollege)
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? AiPredictionResultView._bgDark
          : AiPredictionResultView._bgLight,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroSection(isDark),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.withOpacity(.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "These are your predicted college list to be filled in round 1 to last round",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.blue.shade200
                                  : Colors.blue.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildIQMessageBanner(isDark),

                  const SizedBox(height: 10),
                  if (controller.selectedInstituteType.value == "Both")
                    _buildFilterTabs(),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ];
        },
        body: _buildResultSection(isDark, govtColleges, privateColleges),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCompareButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AiPredictionResultView._indigo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "Gixa AI Predictions",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeroSection(bool isDark) {
    final horizontalText = controller.selectedHorizontals.isEmpty
        ? "None"
        : controller.selectedHorizontals.join(", ");

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF111827) : const Color(0xFFF8F8F8),
      padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2333) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.07),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank + Match count row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "YOUR RANK",
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "#${controller.userAir.value}",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AiPredictionResultView._indigo,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "AIR",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Match count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 20,
                  ),
                  // decoration: BoxDecoration(
                  //   color: isDark
                  //       ? Colors.white.withOpacity(0.06)
                  //       : Colors.black.withOpacity(0.04),
                  //   borderRadius: BorderRadius.circular(20),
                  //   border: Border.all(
                  //     color: isDark
                  //         ? Colors.white.withOpacity(0.1)
                  //         : Colors.black.withOpacity(0.1),
                  //     width: 0.5,
                  //   ),
                  // ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AiPredictionResultView._indigo,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.predictionData.totalCount} Matches",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                "AIR ${controller.userAir.value}",
                controller.selectedCourse.value,
                controller.selectedCategory.value,
                controller.selectedState.value,
                "Horizontal: $horizontalText",
              ].map((tag) => _miniTag(tag, isDark)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIQMessageBanner(bool isDark) {
    if (widget.predictionData.message == null ||
        widget.predictionData.message!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(.2), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.predictionData.message!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      // decoration: BoxDecoration(
      //   color: isDark
      //       ? Colors.white.withOpacity(0.06)
      //       : Colors.black.withOpacity(0.05),
      //   borderRadius: BorderRadius.circular(20),
      //   border: Border.all(
      //     color: isDark
      //         ? Colors.white.withOpacity(0.1)
      //         : Colors.black.withOpacity(0.08),
      //     width: 0.5,
      //   ),
      // ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildResultSection(
    bool isDark,
    List<CollegeModel> govtColleges,
    List<CollegeModel> privateColleges,
  ) {
    return Obx(() {
      // Use the new feature lock logic

      final isUnlocked = subscriptionController.canAccessFeature(
        FeatureNames.selectedStateCollegePrediction,
      );

      List<CollegeModel> displayList = [];

      if (controller.selectedInstituteType.value == "Govt") {
        displayList = govtColleges;
      } else if (controller.selectedInstituteType.value == "Pvt") {
        displayList = privateColleges;
      } else if (selectedFilter.value == "Government") {
        displayList = govtColleges;
      } else if (selectedFilter.value == "Private" || selectedFilter.value == "Deemed") {
        displayList = privateColleges;
      } else {
        displayList = List<CollegeModel>.from(
          widget.predictionData.collegeList,
        );
      }

      if (displayList.isEmpty) {
        return _buildSuggestionUI(isDark);
      }

      /// ðŸ”’ FREE USER â†’ LOCKED UI
      if (!isUnlocked) {
        return _buildLockedList(isDark, displayList);
      }

      return _buildList(context: context, list: displayList, isDark: isDark);
    });
  }

  Widget _buildList({
    required BuildContext? context,
    required List<CollegeModel> list,
    required bool isDark,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: list.length + 1,
      itemBuilder: (ctx, index) {
        if (index == list.length) {
          return _buildUpgradeAddonBanner(isDark);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _collegeCard(ctx, list[index], isDark, index),
        );
      },
    );
  }

  Widget _buildLockedList(bool isDark, List<CollegeModel> list) {
    return Column(
      children: [
        // ðŸ”¥ PREMIUM BANNER
        Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AiPredictionResultView._indigo,
                AiPredictionResultView._indigoDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AiPredictionResultView._indigo.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Bubble
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white),
              ),

              const SizedBox(width: 12),

              // ðŸ§  Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${list.length} Colleges Unlocked",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Upgrade to Premium to view full details",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // ðŸš€ CTA BUTTON
              GestureDetector(
                onTap: controller.goToPremium,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Upgrade",
                    style: TextStyle(
                      color: AiPredictionResultView._indigoDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ðŸ”’ LOCKED LIST
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: list.length + 1,
            itemBuilder: (_, index) {
              if (index == list.length) {
                return _buildUpgradeAddonBanner(isDark);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _lockedCard(isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _lockedCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AiPredictionResultView._surface
            : AiPredictionResultView._cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ðŸ”¹ REAL LAYOUT (but hidden content)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ðŸ”¹ Type + icon row
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.circle, size: 10, color: Colors.grey),
                  ],
                ),

                const SizedBox(height: 10),

                // ðŸ”¹ College name (hidden)
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                const SizedBox(height: 14),

                // ðŸ”¹ Buttons layout
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ðŸ”¥ BLUR + LOCK OVERLAY
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.55)
                      : Colors.white.withOpacity(0.6),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 24,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ No Govt Message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildNoGovtMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(.2), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Government seats likely unavailable at your rank â€” showing Private colleges.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ College Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _collegeCard(
    BuildContext context,
    CollegeModel college,
    bool isDark,
    int index,
  ) {
    final isGovt = _isGovernmentCollege(college);
    final typeLabel = _instituteTypeLabel(college);

    return Obx(() {
      final isSelected = selectedColleges.contains(college);

      return GestureDetector(
        onTap: () {
          if (selectedColleges.contains(college)) {
            selectedColleges.remove(college);
          } else {
            if (selectedColleges.length < 2) {
              selectedColleges.add(college);
            } else {
              AppSnackbar.show(
                "Limit Reached",
                "Select up to 2 colleges to compare",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AiPredictionResultView._surface,
                colorText: Colors.white,
                margin: const EdgeInsets.all(12),
                // borderRadius: 12,
                duration: const Duration(seconds: 2),
              );
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AiPredictionResultView._indigo.withOpacity(0.07)
                : (isDark
                      ? AiPredictionResultView._surface
                      : AiPredictionResultView._cardLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AiPredictionResultView._indigo.withOpacity(0.6)
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.06)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AiPredictionResultView._indigo.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Top row: type badge + selection icon
                Row(
                  children: [
                    _typeTag(isGovt, typeLabel),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? AiPredictionResultView._indigo
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // â”€â”€ College name
                Text(
                  college.collegeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 5),

                // â”€â”€ Course
                Text(
                  college.courseName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // â”€â”€ Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _outlineBtn(
                        label: "Rank Analysis",
                        icon: Icons.bar_chart_rounded,
                        isDark: isDark,
                        onTap: () {
                          Get.to(
                            () => RankAnalysisScreen(),
                            arguments: {
                              "college_id": college.id,
                              "college_code": college.collegeCode,
                              "college_name": college.collegeName,
                              "course": controller.selectedCourse.value,
                              "category": controller.selectedCategory.value,
                              "rank": controller.userAir.value,
                              "round": controller.selectedRound.value,
                              "year": controller.selectedYear.value,
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _solidBtn(
                        label: "View Details",
                        icon: Icons.arrow_forward_rounded,
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.collageDetails,
                            arguments: {"collegeId": college.id},
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _typeTag(bool isGovt, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isGovt
            ? Colors.green.withOpacity(0.1)
            : const Color(0xFFEC8B04).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isGovt ? Colors.green : const Color(0xFFEC8B04),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isGovt ? Colors.green.shade700 : const Color(0xFFEC8B04),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineBtn({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _solidBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AiPredictionResultView._indigo,
              AiPredictionResultView._indigoDark,
            ],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AiPredictionResultView._indigo.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 13, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Compare FAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCompareButton() {
    return Obx(() {
      if (selectedColleges.length < 2) return const SizedBox();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AiPredictionResultView._indigo,
              AiPredictionResultView._indigoDark,
            ],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AiPredictionResultView._indigo.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              final codes = selectedColleges
                  .map((e) => e.collegeCode.toString())
                  .toList();
              Get.toNamed(
                AppRoutes.compareCollage,
                arguments: {"collegeCodes": codes},
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Compare",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "${selectedColleges.length}",
                        style: const TextStyle(
                          color: AiPredictionResultView._indigoDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSuggestionUI(bool isDark) {
    final cardColor = isDark
        ? AiPredictionResultView._surface
        : AiPredictionResultView._cardLight;

    final textColor = isDark ? Colors.white : Colors.black87;

    final subTextColor = isDark ? Colors.white54 : Colors.black45;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Icon
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AiPredictionResultView._indigo,
                            AiPredictionResultView._indigoDark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AiPredictionResultView._indigo.withOpacity(
                              0.25,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "No Colleges Found",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: "Unlock ",
                            style: TextStyle(
                              color: AiPredictionResultView._indigo,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(
                            text:
                                "Premium to explore colleges from other states and access smarter AI-powered predictions.",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Features
                    Column(
                      children: [
                        _modernFeatureTile(
                          Icons.public_rounded,
                          "Other State Colleges",
                          isDark,
                        ),
                        _modernFeatureTile(
                          Icons.auto_awesome_rounded,
                          "AI Premium Suggestions",
                          isDark,
                        ),
                        _modernFeatureTile(
                          Icons.school_outlined,
                          "More College Matches",
                          isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Upgrade Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.goToPremium,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AiPredictionResultView._indigo,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Upgrade Premium",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.ticket);
                        // Get.to(CounselorListView());
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AiPredictionResultView._indigo.withOpacity(
                              0.12,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AiPredictionResultView._indigo,
                                    AiPredictionResultView._indigoDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Need Counselling Help?",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    "Raise a ticket and connect with our counselling team.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AiPredictionResultView._indigo
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: AiPredictionResultView._indigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        "Edit Preferences",
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildUpgradeAddonBanner(isDark),
        ],
      ),
    );
  }

  Widget _modernFeatureTile(IconData icon, String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AiPredictionResultView._indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AiPredictionResultView._indigo, size: 18),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //   Widget _suggestionTile({
  //     required IconData icon,
  //     required String text,
  //     required bool isDark,
  //   }) {
  //     return Container(
  //       margin: const EdgeInsets.symmetric(vertical: 4),
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  //       decoration: BoxDecoration(
  //         color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
  //         borderRadius: BorderRadius.circular(10),
  //         border: Border.all(
  //           color: isDark
  //               ? Colors.white.withOpacity(0.06)
  //               : Colors.black.withOpacity(0.04),
  //           width: 1,
  //         ),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, color: AiPredictionResultView._accent, size: 16),
  //           const SizedBox(width: 10),
  //           Expanded(
  //             child: Text(
  //               text,
  //               style: TextStyle(
  //                 fontSize: 11.5,
  //                 color: isDark ? Colors.white70 : Colors.black54,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  Widget _buildUpgradeAddonBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark
            ? AiPredictionResultView._surface
            : const Color(0xFFF8FAFF),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AiPredictionResultView._indigo.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AiPredictionResultView._indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AiPredictionResultView._indigo.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AiPredictionResultView._indigo,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Upgrade to addon plan for one to one counselling process",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: controller.goToPremium,
              style: ElevatedButton.styleFrom(
                backgroundColor: AiPredictionResultView._indigo,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Show Plan",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
