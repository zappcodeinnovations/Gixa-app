import 'dart:math';
import 'dart:ui';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/predication/view/ai_prediction_result_view.dart';
import 'package:Gixa/Modules/predication/view/chat_bot_prediction_view.dart';
import 'package:Gixa/Modules/predication/widgets/ai_activation_dialog.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shake/shake.dart';
import 'package:Gixa/Modules/subscription/widgets/course_selection_bottom_sheet.dart';
import '../controller/prediction_controller.dart';

class PredictionView extends StatefulWidget {
  const PredictionView({super.key});

  @override
  State<PredictionView> createState() => _PredictionViewState();
}

class _PredictionViewState extends State<PredictionView>
    with TickerProviderStateMixin {
  final PredictionController controller =
      Get.isRegistered<PredictionController>()
      ? Get.find<PredictionController>()
      : Get.put(PredictionController());

  final RxString aiMessage = "Analyzing your rank...".obs;
  final RxInt aiStep = 0.obs;
  final RxString selectedIqNri = ''.obs;

  ShakeDetector? detector;

  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  static const Color _indigo = Color.fromARGB(255, 236, 139, 4);
  static const Color _indigoDark = Color(0xFF4338CA);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _bgDark = Color(0xFF080E1A);
  static const Color _bgLight = Color(0xFFF0F2F9);
  static const Color _cardLight = Color(0xFFFFFFFF);

  List<Map<String, dynamic>> _buildAiSteps() {
    return [
      {
        "icon": Icons.person_search_outlined,
        "msg": "reading_your_rank".tr + " ${controller.userAir.value}...",
      },
      {
        "icon": Icons.location_city_outlined,
        "msg": "scanning_colleges".tr + "...",
      },
      {
        "icon": Icons.verified_user_outlined,
        "msg": "applying_reservation".tr + "...",
      },
      {"icon": Icons.school_outlined, "msg": "searching_colleges".tr + "..."},
      {
        "icon": Icons.account_balance_outlined,
        "msg": "checking_quota_seats".tr + "...",
      },
      {"icon": Icons.history_edu_outlined, "msg": "analyzing_cutoffs".tr},
      {"icon": Icons.leaderboard_outlined, "msg": "ranking_colleges".tr},
      {"icon": Icons.auto_awesome_outlined, "msg": "generating_results".tr},
    ];
  }

  @override
  void initState() {
    super.initState();

    // Always set selectedYear to current year
    controller.selectedYear.value = DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureBootstrap();
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    detector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) {
        _showAiActivation();
      },

      shakeThresholdGravity: 7,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    detector?.stopListening();
    super.dispose();
  }

  void _openAiChatBot() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.92,

        decoration: const BoxDecoration(
          color: Color(0xFF0B1120),

          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),

        child: const ChatBotPredictionView(),
      ),

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      enterBottomSheetDuration: const Duration(milliseconds: 500),

      exitBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _startAiMessages({
    Duration totalDuration = const Duration(seconds: 3),
  }) async {
    final steps = _buildAiSteps();
    if (steps.isEmpty) return;

    final stepDelay = steps.length <= 1
        ? totalDuration
        : Duration(
            milliseconds: (totalDuration.inMilliseconds / steps.length).floor(),
          );

    for (int i = 0; i < steps.length; i++) {
      if (!controller.isPredictionLoading.value) break;
      aiStep.value = i;
      aiMessage.value = steps[i]["msg"] as String;
      if (i < steps.length - 1) {
        await Future.delayed(stepDelay);
      }
    }
  }

  void _showAiActivation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AiActivationDialog(
        onCompleted: () {
          _openAiChatBot();
        },
      ),

      barrierDismissible: false,

      barrierColor: Colors.black.withOpacity(isDark ? 0.72 : 0.35),
    );
  }

  List<String> _horizontalOptions() {
    return controller.reservationHorizontals
        .where((e) => e != "IQ" && e != "I.Q")
        .toList();
  }

  Map<String, String> _categoryFullForms() {
    return controller
            .stateCategoryMap[controller.selectedState.value]
            ?.availableCategoriesFullForms ??
        const <String, String>{};
  }

  Map<String, String> _horizontalCategoryFullForms() {
    return controller
            .stateCategoryMap[controller.selectedState.value]
            ?.availableHorizontalCategoriesFullForms ??
        const <String, String>{};
  }

  String _formatStateLabel(String state) {
    final stateDisplay =
        controller.stateCategoryMap[state]?.stateDisplay.trim() ?? '';
    return stateDisplay.isEmpty ? state : stateDisplay;
  }

  String _formatOptionLabel(String code, Map<String, String> fullForms) {
    final fullForm = fullForms[code]?.trim() ?? '';
    if (fullForm.isEmpty || fullForm.toLowerCase() == code.toLowerCase()) {
      return code;
    }
    return '$code ($fullForm)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      extendBodyBehindAppBar: true,
      appBar: _appBar(isDark),
      body: Stack(
        children: [
          Positioned.fill(child: _GridBackground(isDark: isDark)),

          RefreshIndicator(
            onRefresh: () async {
              await controller.refreshPageData();
            },
            displacement: 60,
            color: _indigo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  _rankCard(isDark),
                  const SizedBox(height: 20),
                  _sectionLabel("Basic Details"),
                  const SizedBox(height: 10),
                  _basicDetails(isDark),
                  const SizedBox(height: 20),
                  _reservationSection(isDark),
                  const SizedBox(height: 10),
                  _sectionLabel("Preferences"),
                  const SizedBox(height: 10),
                  _preferences(isDark),
                ],
              ),
            ),
          ),

          Positioned(left: 16, right: 16, bottom: 24, child: _predictButton()),

          Obx(() {
            if (!controller.isPredictionLoading.value) {
              return const SizedBox();
            }
            return _AiOverlay(
              aiSteps: _buildAiSteps(),
              aiStep: aiStep,
              pulseCtrl: _pulseCtrl,
              rotateCtrl: _rotateCtrl,
            );
          }),
        ],
      ),
    );
  }

  Widget _iqNriQuota(bool isDark) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(isDark),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 DYNAMIC IQ FROM BACKEND
        Obx(() {
          final horizontals = controller.reservationHorizontals;

          final iqList = horizontals
              .where(
                (e) => e.toUpperCase() == "I.Q." || e.toUpperCase() == "I.Q",
              )
              .toList();

          return Column(
            children: [
              /// Show IQ if exists
              if (iqList.isNotEmpty)
                ...iqList.map((iq) => _quotaTile(iq, isDark)).toList(),

              /// Always show NRI
              _quotaTile("NRI ", isDark),
            ],
          );
        }),

        const SizedBox(height: 8),

        Row(
          children: const [
            Icon(Icons.info_outline, size: 12, color: _cyan),
            SizedBox(width: 5),
            Text(
              "IQ & NRI quotas have higher cutoff ranks",
              style: TextStyle(
                fontSize: 10,
                color: _cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _quotaTile(String label, bool isDark) {
    final selected = selectedIqNri.value == label;
    final displayLabel = _formatOptionLabel(
      label,
      _horizontalCategoryFullForms(),
    );

    return GestureDetector(
      onTap: () {
        if (selectedIqNri.value == label) {
          selectedIqNri.value = '';
        } else {
          selectedIqNri.value = label;
        }

        // IQ/I.Q belongs to horizontal reservation, not main quota dropdown value.
        if (label == 'IQ' || label == 'I.Q') {
          controller.handleHorizontalSelection(label);
        } else {
          controller.selectedHorizontals.remove('IQ');
          controller.selectedHorizontals.remove('I.Q');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _indigo.withOpacity(0.08)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _indigo.withOpacity(0.4)
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? _indigo : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? _indigo
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────
  PreferredSizeWidget _appBar(bool isDark) => AppBar(
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: isDark ? Colors.white : Colors.black87,

    centerTitle: true,

    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_indigo, _cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _indigo.withOpacity(0.5), blurRadius: 8),
            ],
          ),
        ),

        const SizedBox(width: 7),

        Text(
          "College Predictor".tr,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    ),

    // actions: [
    //   Padding(
    //     padding: const EdgeInsets.only(right: 12),

    //     child: GestureDetector(
    //       onTap: () {
    //         Get.to(
    //           () => const ChatBotPredictionView(),
    //           transition: Transition.rightToLeft,
    //           duration: const Duration(milliseconds: 350),
    //         );
    //       },

    //       child: Container(
    //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

    //         decoration: BoxDecoration(
    //           gradient: const LinearGradient(colors: [_indigo, _cyan]),

    //           borderRadius: BorderRadius.circular(14),

    //           boxShadow: [
    //             BoxShadow(
    //               color: _indigo.withOpacity(0.25),
    //               blurRadius: 10,
    //               offset: const Offset(0, 4),
    //             ),
    //           ],
    //         ),

    //         child: const Row(
    //           children: [
    //             Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),

    //             SizedBox(width: 6),

    //             Text(
    //               "AI Chat",
    //               style: TextStyle(
    //                 color: Colors.white,
    //                 fontSize: 11,
    //                 fontWeight: FontWeight.w700,
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // ],
  );

  // ─── Rank Card ────────────────────────────────────────────────────
  Widget _rankCard(bool isDark) => Obx(
    () => Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        isDark,
        borderColor: _indigo.withOpacity(isDark ? 0.3 : 0.15),
        glowColor: _indigo.withOpacity(0.08),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: _emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "YOUR MERIT RANK",
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                controller.isProfileLoading.value
                    ? const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _indigo,
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "#${controller.userAir.value}",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _indigo,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "AIR",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 4),
                const Text(
                  "All India Rank",
                  style: TextStyle(
                    fontSize: 10,
                    color: _cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_indigo.withOpacity(0.12), _cyan.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _indigo.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Icon(
                  controller.isFreeUser
                      ? Icons.lock_outline_rounded
                      : Icons.verified_rounded,
                  color: _indigo,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.isFreeUser ? "Free Plan" : "Auto-fetched",
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionLabel(String titleKey) => Row(
    children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_indigo, _cyan],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        titleKey.tr.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: _indigo.withOpacity(0.8),
        ),
      ),
    ],
  );

  Widget _reservationSection(bool isDark) => Obx(() {
    final profileController = Get.find<ProfileController>();
    final primaryState = profileController.profile.value?.state?.trim() ?? '';
    final selectedState = controller.selectedState.value.trim();

    if (primaryState.isEmpty ||
        selectedState.isEmpty ||
        selectedState.toLowerCase() != primaryState.toLowerCase() ||
        (profileController.profile.value?.horizontals ?? []).isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Reservation"),
        const SizedBox(height: 10),
        _reservation(isDark),
        const SizedBox(height: 20),
      ],
    );
  });

  // ─── Basic Details ────────────────────────────────────────────────
  Widget _basicDetails(bool isDark) => Column(
    children: [
      Obx(() {
        if (!controller.isFreeUser) {
          return const SizedBox();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _indigo.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _indigo.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: _indigo),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: "Rank, State & Category ",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _indigo,
                        ),
                      ),
                      const TextSpan(
                        text:
                            "are locked on the Free Plan.\nUpgrade to Premium to unlock full customization and smarter Gixa AI predictions.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      Obx(() {
        final profileController = Get.find<ProfileController>();
        final profileState = profileController.profile.value?.state;

        if (profileState == null || profileState.isEmpty) {
          return const SizedBox();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEC8B04).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEC8B04).withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFFEC8B04)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Primary State: $profileState",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC8B04),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      SizedBox(height: 10),
      Obx(() {
        /// 🔥 PRINT STATES COUNT
        print("📍 Total States: ${controller.stateList.length}");

        /// 🔥 PRINT ALL STATES
        print("📍 States List:");
        for (var s in controller.stateList) {
          print("➡️ ${s.name}");
        }

        return _aiDropdown(
          // label: "state".tr,
          label: 'Secondary State'.tr,
          icon: Icons.map_outlined,
          value: controller.selectedState.value,
          items: ['Select State', ...controller.stateList.map((e) => e.name)],
          itemLabelBuilder: (val) =>
              val == 'Select State' ? 'Select State' : _formatStateLabel(val),
          enabled: true,
          onChanged: (v) {
            if (v == null) return;
            controller.onStateChanged(v);
            print('State wise course for pg: State: ${controller.selectedState.value}, Course: ${controller.selectedCourse.value}');
          },
          isDark: isDark,
        );
      }),
      const SizedBox(height: 10),
      Obx(
        () => _aiDropdown(
          label: "category".tr,
          icon: Icons.group_outlined,
          value: controller.selectedCategory.value,
          items: controller.categoryList.map((e) => e.name).toList(),
          enabled: false,
          suffixIcon: Icons.lock_outline_rounded,
          itemLabelBuilder: (item) =>
              _formatOptionLabel(item, _categoryFullForms()),
          onChanged: (v) {
            if (v == null) return;
            controller.selectedCategory.value = v;
          },
          isDark: isDark,
        ),
      ),
      const SizedBox(height: 10),
      Obx(() {
        final profileController = Get.find<ProfileController>();
        final p = profileController.profile.value;
        final profileCourse = p?.course?.trim() ?? '';
        
        final predictionCourses = p?.predictionCourses ?? [];
        
        final subCtrl = Get.isRegistered<SubscriptionController>()
            ? Get.find<SubscriptionController>()
            : Get.put(SubscriptionController());
        final purchasedCourses = subCtrl.purchasedCourseNames;
        
        final Set<String> combinedCourses = {};
        if (predictionCourses.isNotEmpty) {
          combinedCourses.addAll(predictionCourses);
        } else if (profileCourse.isNotEmpty) {
          combinedCourses.add(profileCourse);
        }
        
        combinedCourses.addAll(purchasedCourses);

        final List<String> dropdownItems = [
          'Select Course',
          ...(combinedCourses.isNotEmpty
              ? combinedCourses
              : controller.currentAvailableCourses.map((e) => e.name)),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _aiDropdown(
              label: "course".tr,
              icon: Icons.school_outlined,
              value: controller.selectedCourse.value,
              items: dropdownItems,
              errorText: controller.courseError.value.isNotEmpty
                  ? controller.courseError.value
                  : null,
              enabled: true, // Allow user to select course
              suffixIcon: null,
              onChanged: (v) {
                if (v == null) return;
                if (v == 'Select Course') {
                  controller.selectedCourse.value = 'Select Course';
                } else {
                  controller.selectedCourse.value = v;
                  controller.courseError.value = '';
                  // Reset specialty when course changes
                  controller.selectedSpecialty.value = 'Select Specialty';
                }
                print('State wise course for pg: State: ${controller.selectedState.value}, Course: ${controller.selectedCourse.value}');
              },
              isDark: isDark,
            ),
            TextButton.icon(
              onPressed: () {
                final activePlan = subCtrl.activePlan.value;
                if (activePlan == null) {
                  AppSnackbar.show('No Active Plan', 'Please purchase a base plan first to add courses.');
                  return;
                }
                CourseSelectionBottomSheet.show(context, activePlan, isAddonOnly: true);
              },
              icon: const Icon(Icons.add_circle_outline, size: 14, color: _indigo),
              label: const Text(
                'Add Course',
                style: TextStyle(
                  fontSize: 12,
                  color: _indigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        );
      }),
      Obx(() {
        final profileController = Get.find<ProfileController>();

        final selectedCourseName = controller.selectedCourse.value;
        List<String> specialtyItems = ['Select Specialty'];

        if (selectedCourseName != 'Select Course' &&
            selectedCourseName.isNotEmpty) {
          final targetList = controller.currentAvailableCourses;
          final userRegisteredSpecialty =
              profileController.profile.value?.specialty;

          for (final course in targetList) {
            if (course.name == selectedCourseName) {
              for (final s in course.specialties) {
                if (userRegisteredSpecialty != null &&
                    userRegisteredSpecialty.isNotEmpty) {
                  if (s.name == userRegisteredSpecialty) {
                    specialtyItems.add(s.name);
                  }
                } else {
                  specialtyItems.add(s.name);
                }
              }
              break;
            }
          }
        }

        if (specialtyItems.length <= 1) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 10),
            _aiDropdown(
              label: "Specialty",
              icon: Icons.local_hospital_outlined,
              value: specialtyItems.contains(controller.selectedSpecialty.value)
                  ? controller.selectedSpecialty.value
                  : 'Select Specialty',
              items: specialtyItems,
              enabled: true,
              suffixIcon: null,
              onChanged: (v) {
                if (v == null) return;
                controller.selectedSpecialty.value = v;
              },
              isDark: isDark,
            ),
          ],
        );
      }),
    ],
  );

  // ─── Reservation ──────────────────────────────────────────────────
  Widget _reservation(bool isDark) => Obx(() {
        final profileController = Get.find<ProfileController>();
        final userHorizontals =
            profileController.profile.value?.horizontals ?? [];

        if (userHorizontals.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: userHorizontals
                    .map((e) => _checkTile(e, isDark))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: _cyan),
                  const SizedBox(width: 5),
                  const Text(
                    "Reservations significantly affect results",
                    style: TextStyle(
                      fontSize: 10,
                      color: _cyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });

  // ─── Preferences ─────────────────────────────────────────────────
  Widget _preferences(bool isDark) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(isDark),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "institute_type".tr.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 8),

        /// Institute Type
        Obx(
          () {
            final isMcc = controller.effectiveState.toUpperCase() == 'MCC';
            return _pillRow(
              items: ["Govt", isMcc ? "Deemed" : "Pvt", "Both"],
              values: ["Govt", "Pvt", "Both"],
              selected: controller.selectedInstituteType.value,
              onTap: (v) => controller.selectedInstituteType.value = v,
              isDark: isDark,
            );
          }
        ),

        const SizedBox(height: 14),

        Obx(() {
          final quotaItems = controller.availableQuotasForSelectedState;
          // Add a placeholder for 'Select Quota' if nothing is selected
          final showHint = controller.selectedQuota.value.trim().isEmpty;
          final dropdownItems = [if (showHint) 'Select Quota', ...quotaItems];
          return _aiDropdown(
            label: "Select Quota".tr,
            icon: Icons.account_balance_outlined,
            value: showHint ? 'Select Quota' : controller.selectedQuota.value,
            items: dropdownItems,
            onChanged: (String? v) {
              if (v == null || v == 'Select Quota') {
                controller.selectedQuota.value = '';
              } else {
                controller.selectedQuota.value = v;
              }
            },
            isDark: isDark,
          );
        }),
      ],
    ),
  );

  Widget _predictButton() => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_indigo, _indigoDark],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _indigo.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: Obx(() {
        final isBusy =
            controller.isPredictionLoading.value ||
            controller.isInitializing.value;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isBusy
              ? null
              : () async {
                  aiStep.value = 0;
                  final predictionFuture = controller.fetchPrediction(
                    minimumLoadingDuration: const Duration(seconds: 3),
                  );
                  _startAiMessages(totalDuration: const Duration(seconds: 3));
                  await predictionFuture;
                },
          child: Opacity(
            opacity: isBusy ? 0.72 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "predict".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ),
  );

  // ─── Shared: pill selector ────────────────────────────────────────
  Widget _pillRow({
    required List<String> items,
    required List<String> values,
    required String selected,
    required Function(String) onTap,
    required bool isDark,
  }) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: List.generate(items.length, (i) {
        final sel = selected == values[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(values[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(colors: [_indigo, _indigoDark])
                    : null,
                borderRadius: BorderRadius.circular(9),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: _indigo.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );

  // ─── Check tile — called from inside Obx, so NO inner Obx needed ──
  Widget _checkTile(String label, bool isDark) {
    final selected = controller.selectedHorizontals.contains(label);
    final displayLabel = _formatOptionLabel(
      label,
      _horizontalCategoryFullForms(),
    );
    final isLocked = controller.lockedHorizontals.contains(label);

    return GestureDetector(
      onTap: () => controller.handleHorizontalSelection(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _indigo.withOpacity(0.08)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _indigo.withOpacity(0.4)
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? _indigo : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? _indigo : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? _indigo
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Input ─────────────────────────────────────────────────────
  Widget _aiInput({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required Function(String) onChanged,
    required bool isDark,
    TextInputType keyboard = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    onChanged: onChanged,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      prefixIcon: Icon(icon, size: 16, color: _indigo.withOpacity(0.7)),
      filled: true,
      fillColor: isDark ? _surface : _cardLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: _inputBorder(isDark),
      enabledBorder: _inputBorder(isDark),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _indigo.withOpacity(0.5), width: 1.5),
      ),
    ),
  );

  Widget _aiDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    String Function(String)? itemLabelBuilder,
    bool enabled = true,
    String? helperText,
    String? errorText,
    IconData? suffixIcon,
  }) {
    final uniqueItems = <String>[];
    for (final item in items) {
      if (!uniqueItems.contains(item)) {
        uniqueItems.add(item);
      }
    }

    final selectedValue = uniqueItems.contains(value) ? value : null;

    final inputDec = InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.white : _indigo),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 18, color: isDark ? Colors.white : _indigo),
      filled: true,
      fillColor: enabled
          ? (isDark ? _surface : _cardLight)
          : (isDark ? const Color(0xFF2A3441) : Colors.grey.shade100),
      helperText: helperText,
      errorText: errorText,
      helperStyle: TextStyle(
        fontSize: 11,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      errorStyle: TextStyle(fontSize: 11, color: Colors.redAccent.shade200),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white38 : Colors.black26,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _indigo.withOpacity(0.7), width: 1.5),
      ),
    );

    return IgnorePointer(
      ignoring: !enabled,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DropdownButtonFormField<String>(
            value: selectedValue,
            isExpanded: true,
            decoration: inputDec,
            icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : _indigo),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: enabled
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            dropdownColor: isDark ? _surface : _cardLight,
            items: uniqueItems.map((e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(
                  itemLabelBuilder?.call(e) ?? e,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && enabled) {
                onChanged(val);
              }
            },
          );
        },
      ),
    );
  }

  OutlineInputBorder _inputBorder(bool isDark) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.06),
    ),
  );

  BoxDecoration _cardDecoration(
    bool isDark, {
    Color? borderColor,
    Color? glowColor,
  }) => BoxDecoration(
    color: isDark ? _surface : _cardLight,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color:
          borderColor ??
          (isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06)),
    ),
    boxShadow: [
      BoxShadow(
        color: glowColor ?? Colors.black.withOpacity(isDark ? 0.2 : 0.04),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// _AiOverlay — separate StatefulWidget
// Rule: AnimatedBuilder and Obx must NEVER be nested inside each other.
// All reactive reads happen in Obx; all animation reads in AnimatedBuilder.
// ══════════════════════════════════════════════════════════════════════════════
class _AiOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> aiSteps;
  final RxInt aiStep;
  final AnimationController pulseCtrl;
  final AnimationController rotateCtrl;

  const _AiOverlay({
    required this.aiSteps,
    required this.aiStep,
    required this.pulseCtrl,
    required this.rotateCtrl,
  });

  @override
  State<_AiOverlay> createState() => _AiOverlayState();
}

class _AiOverlayState extends State<_AiOverlay> {
  // ─── Design tokens ────────────────────────────────────────────────
  static const Color _indigo = Color.fromARGB(255, 236, 139, 4);
  static const Color _indigoDark = Color.fromARGB(255, 51, 134, 242);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _emerald = Color(0xFF10B981);

  // Dark theme card colors
  static const Color _darkCard = Color(0xFF0D1526);
  static const Color _darkTrack = Color(0xFF1A2540);

  // Light theme card colors
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightTrack = Color(0xFFF0F2F9);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? _darkCard : _lightCard;
    final trackColor = isDark ? _darkTrack : _lightTrack;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark
        ? _cyan.withOpacity(0.65)
        : _indigo.withOpacity(0.55);
    final borderColor = isDark
        ? _indigo.withOpacity(0.22)
        : _indigo.withOpacity(0.12);
    final barrierColor = isDark
        ? Colors.black.withOpacity(0.72)
        : Colors.black.withOpacity(0.40);

    return Positioned.fill(
      child: Container(
        color: barrierColor,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withOpacity(isDark ? 0.18 : 0.10),
                    blurRadius: 48,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _emblem(isDark),
                  const SizedBox(height: 18),

                  // ── Title
                  Text(
                    "Gixa Prediction Engine",
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Subtitle chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _indigo.withOpacity(isDark ? 0.12 : 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _indigo.withOpacity(isDark ? 0.2 : 0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _emerald,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _emerald.withOpacity(0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Powered by AI · Real-time analysis",
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Divider
                  Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.06),
                    height: 1,
                  ),

                  const SizedBox(height: 16),

                  // ── Steps + scan bar — single Obx
                  Obx(() {
                    final step = widget.aiStep.value;
                    return Column(
                      children: [
                        ...widget.aiSteps.asMap().entries.map(
                          (e) => _stepRow(
                            index: e.key,
                            icon: e.value["icon"] as IconData,
                            msg: e.value["msg"] as String,
                            currentStep: step,
                            isDark: isDark,
                            trackColor: trackColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _scanBar(
                          currentStep: step,
                          isDark: isDark,
                          trackColor: trackColor,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Spinning emblem ──────────────────────────────────────────────
  Widget _emblem(bool isDark) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (light mode: softer)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _indigo.withOpacity(isDark ? 0.22 : 0.12),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Rotating sweep gradient ring
          AnimatedBuilder(
            animation: widget.rotateCtrl,
            builder: (_, __) => Transform.rotate(
              angle: widget.rotateCtrl.value * 2 * pi,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _indigo.withOpacity(0),
                      _indigo.withOpacity(isDark ? 0.7 : 0.45),
                      _cyan.withOpacity(isDark ? 0.45 : 0.3),
                      _indigo.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Static track ring
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03),
            ),
          ),

          // Pulsing core
          AnimatedBuilder(
            animation: widget.pulseCtrl,
            builder: (_, __) {
              final scale = 0.86 + 0.14 * widget.pulseCtrl.value;
              final glowOpacity = 0.35 + 0.25 * widget.pulseCtrl.value;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_indigo, _indigoDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _indigo.withOpacity(glowOpacity),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Step row ─────────────────────────────────────────────────────
  Widget _stepRow({
    required int index,
    required IconData icon,
    required String msg,
    required int currentStep,
    required bool isDark,
    required Color trackColor,
  }) {
    final isDone = index < currentStep;
    final isActive = index == currentStep;

    // Colors shift between themes
    final activeTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final doneTextColor = isDark ? Colors.white54 : Colors.black38;
    final pendingTextColor = isDark ? Colors.white12 : Colors.black26;
    final activeIconColor = _indigo;
    final doneIconColor = _emerald;
    final pendingIconColor = isDark ? Colors.white12 : Colors.black12;

    final textColor = isActive
        ? activeTextColor
        : (isDone ? doneTextColor : pendingTextColor);
    final iconColor = isActive
        ? activeIconColor
        : (isDone ? doneIconColor : pendingIconColor);

    // Step indicator widget
    Widget indicator;
    if (isDone) {
      indicator = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _emerald.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: _emerald, size: 10),
      );
    } else if (isActive) {
      indicator = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          color: _indigo,
          backgroundColor: _indigo.withOpacity(0.15),
        ),
      );
    } else {
      indicator = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1.5,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? _indigo.withOpacity(isDark ? 0.10 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? _indigo.withOpacity(isDark ? 0.28 : 0.18)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          indicator,
          const SizedBox(width: 10),
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (isDone)
            Text(
              "✓",
              style: TextStyle(
                color: _emerald.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Scan progress bar ────────────────────────────────────────────
  Widget _scanBar({
    required int currentStep,
    required bool isDark,
    required Color trackColor,
  }) {
    final progress = (currentStep / (widget.aiSteps.length - 1)).clamp(
      0.02,
      1.0,
    );
    final pct = (progress * 100).round();

    final labelColor = isDark ? Colors.white38 : Colors.black38;
    final barTrackColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 11,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(width: 4),
                Text(
                  "PROCESSING",
                  style: TextStyle(
                    fontSize: 8.5,
                    letterSpacing: 1.6,
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // Percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _cyan.withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _cyan.withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              child: Text(
                "$pct%",
                style: const TextStyle(
                  fontSize: 9,
                  color: _cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Track
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              // Background track
              Container(height: 4, color: barTrackColor),
              // Animated fill
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_indigo, _cyan]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: _cyan.withOpacity(isDark ? 0.55 : 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Step dots
        Row(
          children: List.generate(widget.aiSteps.length, (i) {
            final done = i < currentStep;
            final active = i == currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 3,
                decoration: BoxDecoration(
                  color: done
                      ? _emerald.withOpacity(0.6)
                      : active
                      ? _indigo
                      : (isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Background Grid ──────────────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  final bool isDark;
  const _GridBackground({required this.isDark});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter(isDark: isDark));
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.025)
      ..strokeWidth = 0.5;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}
