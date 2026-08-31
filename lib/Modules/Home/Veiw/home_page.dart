import 'dart:async';
import 'dart:math' as math;
import 'package:Gixa/Modules/Assistance/view/counselor_page.dart';
import 'package:Gixa/Modules/Auth/controllers/otp_controller.dart';
import 'package:Gixa/Modules/Chatbot/view/admission_chat_view.dart';
import 'package:Gixa/Modules/Chatbot/view/chatbot_view.dart';
import 'package:Gixa/Modules/Home/widgets/premium_home_card.dart';
import 'package:Gixa/Modules/cutoff/view/state_wise_distribution_page.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:Gixa/Modules/Collage/controller/collage_list_controller.dart';
import 'package:Gixa/Modules/Collage/veiw/collage_list_page.dart';
import 'package:Gixa/Modules/Faq/controller/faq_controller.dart';
import 'package:Gixa/Modules/Home/widgets/category_list.dart';
import 'package:Gixa/Modules/Home/widgets/chatbot_floating_button.dart';
import 'package:Gixa/Modules/Home/widgets/city_avatar.dart';
import 'package:Gixa/Modules/Home/widgets/college_card.dart';
import 'package:Gixa/Modules/Home/widgets/counselling_banner.dart';
import 'package:Gixa/Modules/Home/widgets/home_alert_slider.dart';
import 'package:Gixa/Modules/Home/widgets/home_subscription_highlight_card.dart';
import 'package:Gixa/Modules/Home/widgets/news_card.dart';
import 'package:Gixa/Modules/Home/widgets/prediction_banner.dart';
import 'package:Gixa/Modules/Home/widgets/rank_predictor_card.dart';
import 'package:Gixa/Modules/Home/widgets/update_tile.dart';
import 'package:Gixa/Modules/Home/widgets/home_header.dart';
import 'package:Gixa/Modules/Home/widgets/search_bar.dart';
import 'package:Gixa/Modules/Home/widgets/section_header.dart';
import 'package:Gixa/Modules/Home/widgets/stream_card.dart';
import 'package:Gixa/Modules/comparison/view/compare_colleges_page.dart';
import 'package:Gixa/Modules/counselling_roadmap/view/counselling_roadmap_screen.dart';
import 'package:Gixa/Modules/cutoff/view/cutoff_graph.dart';
import 'package:Gixa/Modules/favourite/model/fevorite_model.dart';
import 'package:Gixa/Modules/favourite/view/favourite_colleges_page.dart';
import 'package:Gixa/Modules/notification/controller/notification_controller.dart';
import 'package:Gixa/Modules/predication/controller/prediction_controller.dart';
import 'package:Gixa/Modules/predication/model/predication_model.dart';
import 'package:Gixa/Modules/predication/view/ai_prediction_result_view.dart';
import 'package:Gixa/Modules/predication/view/predication_view.dart';
import 'package:Gixa/Modules/rank_predication/view/neet_rank_view.dart';
import 'package:Gixa/Modules/register/view/register_page.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/Modules/subscription/view/subscription_plan_page.dart';
import 'package:Gixa/common/utils/app_responsive.dart';
import 'package:Gixa/common/widgets/primeum_dailog.dart';
import 'package:Gixa/naivgation/controller/nav_bar_controller.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:Gixa/services/auth_guard.dart';
import 'package:Gixa/services/token_services.dart';
import 'package:Gixa/services/app_verification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/common/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:showcaseview/showcaseview.dart';
import '../controller/home_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final HomeController controller = Get.find<HomeController>();
  final MainNavController navController = Get.find();
  // final NotificationController notificationController =
  //     Get.find<NotificationController>();
  final NotificationController notificationController =
      Get.isRegistered<NotificationController>()
      ? Get.find<NotificationController>()
      : Get.put(NotificationController());
  final CollegeListController collegeListController =
      Get.isRegistered<CollegeListController>()
      ? Get.find<CollegeListController>()
      : Get.put(CollegeListController());
  final FaqController faqController = Get.isRegistered<FaqController>()
      ? Get.find<FaqController>()
      : Get.put(FaqController());
  final PredictionController predictionController =
      Get.isRegistered<PredictionController>()
      ? Get.find<PredictionController>()
      : Get.put(PredictionController());
  final SubscriptionController subscriptionController =
      Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>()
      : Get.put(SubscriptionController());

  final RxBool _isCheckingPremiumStatus = true.obs;
  final GetStorage _box = GetStorage();

  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _rankPredictorKey = GlobalKey();
  final GlobalKey _predictionKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _featuredCollegeKey = GlobalKey();
  final GlobalKey _chatbotKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareHomePageData());
      faqController.fetchFaqs();
      collegeListController.fetchColleges();

      _startHomeTour();
    });
  }

  void _startHomeTour() {
    final hasSeenTour = _box.read('home_tour_seen') ?? false;

    if (hasSeenTour) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([
        _searchKey,
        // _rankPredictorKey,
        _predictionKey,
        _categoryKey,
        _featuredCollegeKey,
        _chatbotKey,
      ]);

      _box.write('home_tour_seen', true);
    });
  }

  Future<void> _prepareHomePageData({
    bool forceRefreshSubscription = false,
  }) async {
    if (!notificationController.hasLoaded.value) {
      await notificationController.fetchNotifications(forceRefresh: true);
    }

    final shouldLoadAuthenticatedData =
        await _shouldLoadAuthenticatedHomeData();
    if (!shouldLoadAuthenticatedData) {
      _isCheckingPremiumStatus.value = false;
      return;
    }

    await subscriptionController.ensureActivePlanReady(
      forceRefresh: forceRefreshSubscription,
    );

    // if (mounted && _isCheckingPremiumStatus) {
    //   setState(() {
    //     _isCheckingPremiumStatus = false;
    //   });
    // }
    _isCheckingPremiumStatus.value = false;
  }

  Future<bool> _shouldLoadAuthenticatedHomeData() async {
    final isRegistered = _box.read('registration_completed') == true;
    if (!isRegistered) return false;

    final accessToken = await TokenService.getAccessToken();
    final refreshToken = await TokenService.getRefreshToken();

    return (accessToken != null && accessToken.trim().isNotEmpty) ||
        (refreshToken != null && refreshToken.trim().isNotEmpty);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(() async {
        await notificationController.fetchNotifications(forceRefresh: true);

        final shouldLoadAuthenticatedData =
            await _shouldLoadAuthenticatedHomeData();
        if (!shouldLoadAuthenticatedData) return;
        await subscriptionController.ensureActivePlanReady(forceRefresh: true);
      }());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openRankPredictor() {
    Get.to(() => NeetRankView());
  }

  void _openPredictionSection() {
    AuthGuard.checkAccess(
      onAllowed: () {
        // Only redirect if user was already logged in, otherwise go to home
        final isRegistered =
            GetStorage().read('registration_completed') == true;
        final otpController = Get.isRegistered<OtpController>()
            ? Get.find<OtpController>()
            : null;
        if (isRegistered &&
            otpController != null &&
            otpController.isLoggedIn.value == true) {
          Get.toNamed(AppRoutes.prediction);
        } else {
          // Always go to home after login
          final navController = Get.isRegistered<MainNavController>()
              ? Get.find<MainNavController>()
              : null;
          if (navController != null) {
            navController.currentIndex.value = 0;
            navController.isBottomBarVisible.value = true;
          }
        }
      },
    );
  }

  void _openSearchSection() {
    AuthGuard.checkAccess(
      onAllowed: () {
        final isRegistered =
            GetStorage().read('registration_completed') == true;
        final otpController = Get.isRegistered<OtpController>()
            ? Get.find<OtpController>()
            : null;
        if (isRegistered &&
            otpController != null &&
            otpController.isLoggedIn.value == true) {
          Get.toNamed(AppRoutes.search);
        } else {
          final navController = Get.isRegistered<MainNavController>()
              ? Get.find<MainNavController>()
              : null;
          if (navController != null) {
            navController.currentIndex.value = 0;
            navController.isBottomBarVisible.value = true;
          }
        }
      },
    );
  }

  // void _openPremiumPlans() {
  //   AuthGuard.checkAccess(onAllowed: () => Get.to(() => SubscriptionPage()));
  // }

  void _openPremiumPlans() {
    AuthGuard.checkAccess(onAllowed: () => Get.toNamed(AppRoutes.subscription));
  }

  void _openCounselorSection() {
    AuthGuard.checkAccess(
      onAllowed: () => Get.to(() => const CounselorListView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontalPadding = AppResponsive.horizontalPadding(context);
    final contentMaxWidth = AppResponsive.maxContentWidth(context);
    final isTablet = AppResponsive.isTablet(context);

    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final border = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return ShowCaseWidget(
      blurValue: 1,
      autoPlayDelay: const Duration(seconds: 1),
      builder: (context) => Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: false,
        floatingActionButton: Obx(() {
          final isVisible = navController.isBottomBarVisible.value;

          return IgnorePointer(
            ignoring: !isVisible,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 1.35),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChatBotFloatingButton(
                    onTap: () {
                      AuthGuard.checkAccess(
                        onAllowed: () {
                          Get.toNamed(AppRoutes.chatBot);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              navController.updateScroll(notification.direction);
              return true;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: isTablet ? 24 : 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isTablet ? 24 : 20,
                          horizontalPadding,
                          16,
                        ),
                        child: HomeHeader(
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          borderColor: border,
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Showcase(
                          key: _searchKey,
                          title: "Search Colleges",
                          description:
                              "Search colleges, counselling, cutoff and admission details instantly.",
                          titleTextStyle: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          descTextStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                          tooltipBackgroundColor: const Color(0xFF7B3FE4),
                          targetBorderRadius: BorderRadius.circular(18),
                          targetPadding: const EdgeInsets.all(6),
                          blurValue: 1,
                          disableMovingAnimation: false,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: InkWell(
                            onTap: _openSearchSection,
                            borderRadius: BorderRadius.circular(16),
                            child: AbsorbPointer(
                              child: HomeSearchBar(
                                background: inputBg,
                                hintColor: textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // const SizedBox(height: 18),

                      // Padding(
                      //   padding: EdgeInsets.symmetric(
                      //     horizontal: horizontalPadding,
                      //   ),
                      //
                      //   child: Showcase(
                      //     key: _rankPredictorKey,
                      //
                      //     title: "NEET Rank Predictor",
                      //
                      //     description:
                      //         "Predict your expected NEET rank instantly based on your marks and get better college insights.",
                      //
                      //     titleTextStyle: GoogleFonts.inter(
                      //       fontSize: 18,
                      //       fontWeight: FontWeight.w700,
                      //       color: Colors.white,
                      //     ),
                      //
                      //     descTextStyle: GoogleFonts.inter(
                      //       fontSize: 14,
                      //       color: Colors.white.withOpacity(0.92),
                      //       height: 1.4,
                      //     ),
                      //
                      //     tooltipBackgroundColor: const Color(0xFF7B3FE4),
                      //
                      //     targetBorderRadius: BorderRadius.circular(24),
                      //
                      //     targetPadding: const EdgeInsets.all(6),
                      //
                      //     blurValue: 1,
                      //
                      //     disableMovingAnimation: false,
                      //
                      //     tooltipPadding: const EdgeInsets.symmetric(
                      //       horizontal: 18,
                      //       vertical: 16,
                      //     ),
                      //
                      //     child: RankPredictorShortcutCard(
                      //       onTap: _openRankPredictor,
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 14),
                      PredictionBanner(onTap: _openPredictionSection),

                      const SizedBox(height: 18),

                      // HomeSubscriptionHighlightCard(onTap: _openPremiumPlans),

                      // =========================
                      // CATEGORY LIST
                      // =========================
                      SizedBox(height: 18),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: CategoryList(
                          key: const ValueKey("category_list"),
                          isDark: isDark,
                          surface: surface,
                          border: border,
                          onCollegesTap: () {
                            AuthGuard.checkAccess(
                              onAllowed: () {
                                Get.to(() => CollegeListPage());
                              },
                            );
                          },
                          onRoadmapTap: () {
                            AuthGuard.checkAccess(
                              onAllowed: () {
                                Get.to(() => CounsellingRoadmapScreen());
                              },
                            );
                          },

                          onCutoffTap: () {
                            AuthGuard.checkAccess(
                              onAllowed: () {
                                if (controller.canAccessCutoff()) {
                                  Get.to(
                                    () => StateWiseDistributionGraphPage(),
                                  );
                                } else {
                                  Get.dialog(const PremiumLockDialog());
                                }
                              },
                            );
                          },
                          // onHelpTap: () => Get.toNamed('/chat-bot'),
                          onHelpTap: () {
                            AuthGuard.checkAccess(
                              onAllowed: () {
                                Get.toNamed(AppRoutes.admissionChat);
                              },
                            );
                          },
                          onAssistanceTap: () {
                            AuthGuard.checkAccess(
                              onAllowed: () {
                                Get.to(() => const CounselorListView());
                              },
                            );
                          },
                          onApplicationsTap: () =>
                              Get.toNamed(AppRoutes.ticket),
                        ),
                      ),
                      const SizedBox(height: 20),

                      HomeAlertSlider(),

                      const SizedBox(height: 10),
                      Obx(() {
                        final colleges = collegeListController.colleges;
                        final displayCount = isTablet ? 3 : 2;

                        if (collegeListController.isLoading.value &&
                            colleges.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                child: SectionHeader(
                                  title: 'featured_colleges'.tr,
                                  onSeeAll: () =>
                                      Get.to(() => CollegeListPage()),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: isTablet ? 380 : 330,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(left: 16),
                                  itemCount: displayCount,
                                  itemBuilder: (context, index) {
                                    return _buildShimmerCard(
                                      isTablet,
                                      isDark,
                                      border,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }

                        if (colleges.isEmpty) {
                          return const SizedBox();
                        }

                        final displayColleges = colleges
                            .take(displayCount)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: SectionHeader(
                                title: 'featured_colleges'.tr,
                                onSeeAll: () => Get.to(() => CollegeListPage()),
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// 🔥 Horizontal Cards
                            SizedBox(
                              height: isTablet ? 380 : 330,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(left: 16),
                                itemCount: displayColleges.length,
                                itemBuilder: (context, index) {
                                  final college = displayColleges[index];

                                  return CollegeCard(
                                    id: college.id,
                                    name: college.name,
                                    location: college.state.name,
                                    // rank: "AIR ${college. ?? '--'}",
                                    imageUrl: college.displayImage ?? "",
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }),

                      Obx(() {
                        if (_isCheckingPremiumStatus.value) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            20,
                            horizontalPadding,
                            0,
                          ),
                          child: HomePlansSection(),
                        );
                      }),
                      const SizedBox(height: 30),

                      Obx(() {
                        if (AppVerificationController.to.hideSubscriptionUi) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            CounsellingBanner(onTap: _openCounselorSection),
                            const SizedBox(height: 30),
                          ],
                        );
                      }),

                      /// =========================
                      /// FAQ SECTION
                      /// =========================
                      Obx(() {
                        if (faqController.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (faqController.faqList.isEmpty) {
                          return const SizedBox();
                        }

                        final faqs = faqController.displayedFaqs;
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADER
                              Row(
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    color: Color.fromARGB(255, 236, 139, 4),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "FAQs",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              /// FAQ LIST
                              ...faqs.map((faq) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(.05)
                                          : Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      if (!isDark)
                                        const BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),

                                    iconColor: kHomeAccentColor,
                                    collapsedIconColor: Colors.grey,

                                    title: Row(
                                      children: [
                                        const Icon(
                                          Icons.question_answer,
                                          size: 18,
                                          color: Color.fromARGB(
                                            255,
                                            236,
                                            139,
                                            4,
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Text(
                                            faq.question,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.black.withOpacity(.2)
                                              : const Color(0xFFF5F7FB),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          faq.answer,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 6),

                              /// SHOW MORE BUTTON
                              if (faqController.faqList.length > 3)
                                Center(
                                  child: TextButton(
                                    onPressed: faqController.toggleFaqs,
                                    style: TextButton.styleFrom(
                                      foregroundColor: kHomeAccentColor,
                                    ),
                                    child: Text(
                                      faqController.showAllFaqs.value
                                          ? "Show Less"
                                          : "View All FAQs",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      // =========================
                      // NEET HERO SECTION
                      // =========================
                      NeetHeroSection(
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isTablet, bool isDark, Color border) {
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: isTablet ? 340 : 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: (isTablet ? 340 : 280) * (9 / 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// INSIGHT CARD
// =========================

class InsightCard extends StatefulWidget {
  final String subtitleKey;
  final String imageUrl;
  final Color color;
  final VoidCallback? onTap;

  const InsightCard({
    required this.subtitleKey,
    required this.imageUrl,
    required this.color,
    this.onTap,
    super.key,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glowAnim = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final color = widget.color;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) =>
                Transform.scale(scale: _scaleAnim.value, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark
                    ? Color.lerp(
                        const Color(0xFF1A1A2E),
                        color.withOpacity(0.18),
                        0.9,
                      )
                    : Colors.white,
                border: Border.all(
                  color: _isPressed
                      ? color.withOpacity(0.55)
                      : color.withOpacity(isDark ? 0.28 : 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(
                      _isPressed ? 0.08 : (isDark ? 0.22 : 0.14),
                    ),
                    blurRadius: _isPressed ? 8 : 20,
                    spreadRadius: -2,
                    offset: Offset(0, _isPressed ? 2 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // ── soft tinted background wash ──────────────
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(isDark ? 0.14 : 0.07),
                              color.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── large blurred circle accent (bottom-right) ─
                    Positioned(
                      right: -18,
                      bottom: -18,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(isDark ? 0.12 : 0.10),
                        ),
                      ),
                    ),

                    // ── content ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: color.withOpacity(isDark ? 0.20 : 0.12),
                              border: Border.all(
                                color: color.withOpacity(isDark ? 0.30 : 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Image.network(
                              widget.imageUrl,
                              height: width * 0.07,
                              width: width * 0.07,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.auto_awesome_rounded,
                                color: color,
                                size: width * 0.065,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── title ────────────────────────────────
                          Text(
                            widget.subtitleKey.tr,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── "Explore now" pill ───────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: color.withOpacity(isDark ? 0.20 : 0.10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explore',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: color,
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class _GradientChip extends StatelessWidget {
  final String label;

  const _GradientChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        /// 🔥 CHIP GRADIENT
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFFF3D6B)],
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D6B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class NeetHeroSection extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const NeetHeroSection({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  /// 🔥 GIXA GRADIENT
  LinearGradient get gixaGradient => const LinearGradient(
    colors: [
      Color(0xFFFF8A00),
      Color(0xFFFF3D6B),
      Color(0xFF7B3FE4),
      Color(0xFF3A8DFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),

      /// 🔥 SOFT GRADIENT BACKGROUND
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [
      //       const Color(0xFFFF3D6B).withOpacity(0.06),
      //       const Color(0xFF3A8DFF).withOpacity(0.05),
      //       Colors.transparent,
      //     ],
      //     begin: Alignment.topCenter,
      //     end: Alignment.bottomCenter,
      //   ),
      // ),
      child: Column(
        children: [
          /// 🔹 HEADING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                /// 🔥 GRADIENT TEXT
                ShaderMask(
                  shaderCallback: (bounds) => gixaGradient.createShader(bounds),
                  child: Text(
                    "Plan Your NEET UG&PG Journey",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: width * 0.055,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Explore colleges, predict rank chances & counselling roadmap",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: width * 0.032,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 🔹 ILLUSTRATION
          SizedBox(
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// 🔥 GRADIENT GLOW CIRCLE
                Container(
                  width: width * 0.55,
                  height: width * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF3D6B).withOpacity(0.25),
                        const Color(0xFF7B3FE4).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                /// 🧞 IMAGE
                Image.asset(
                  "assets/icons/animated_gixa.png",
                  height: 300,
                  fit: BoxFit.contain,
                ),

                /// 🔥 CHIPS
                Positioned(
                  top: 10,
                  left: 40,
                  child: _GradientChip(label: "NEET UG"),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _GradientChip(label: "NEET PG"),
                ),
                Positioned(
                  bottom: 70,
                  left: 20,
                  child: _GradientChip(label: "AIQ"),
                ),
                Positioned(
                  bottom: 70,
                  right: 30,
                  child: _GradientChip(label: "State Quota"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
