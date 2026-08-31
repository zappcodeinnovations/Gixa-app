import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/subscription/controller/subsciption_history_controller.dart';
import 'package:Gixa/Modules/subscription/model/subscription_purchase_model.dart';
import 'package:Gixa/Modules/subscription/view/subscription_history_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/subscription_controller.dart';
import '../model/subscription_plan.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:Gixa/services/app_verification_controller.dart';
import 'package:Gixa/Modules/subscription/widgets/course_selection_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
class _T {
  // Brand palette
  static const orange = Color(0xFFEC8B04);
  static const pink = Color(0xFFE94057);
  static const purple = Color(0xFF8A2BE2);
  static const blue = Color(0xFF3A86FF);

  // Gradients
  static const brandGradient = LinearGradient(
    colors: [orange, pink, purple],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const heroBg = LinearGradient(
    colors: [Color(0xFF1A0533), Color(0xFF0D1B4B), Color(0xFF0B2340)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardGlow = LinearGradient(
    colors: [purple, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle heading(
    double size, {
    Color? color,
    FontWeight fw = FontWeight.bold,
  }) => GoogleFonts.sora(
    fontSize: size,
    fontWeight: fw,
    color: color ?? Colors.white,
  );

  static TextStyle body(
    double size, {
    Color? color,
    FontWeight fw = FontWeight.normal,
  }) => GoogleFonts.dmSans(fontSize: size, fontWeight: fw, color: color);
}

// ─────────────────────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────────────────────
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with TickerProviderStateMixin {
  final controller = Get.find<SubscriptionController>();
  final historyController = Get.find<SubscriptionHistoryController>();
  final Map<int, TextEditingController> _couponControllers = {};

  // Reactive selected plan
  final RxInt selectedPlanId = RxInt(-1);

  late AnimationController _heroAnimCtrl;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();

    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(parent: _heroAnimCtrl, curve: Curves.easeOut);
    _heroAnimCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.ensurePlanCatalogLoaded();
      await controller.ensureActivePlanReady();
      await historyController.ensureLoaded();
      
      if (controller.plans.isNotEmpty) {
        if (Get.arguments != null && Get.arguments['planId'] != null) {
          final int pId = Get.arguments['planId'] as int;
          selectedPlanId.value = pId;
          final plan = controller.plans.firstWhereOrNull((p) => p.id == pId);
          if (plan != null) {
            // Auto open the details bottom sheet for the selected plan
            _openConfirmSheet(context, plan);
          }
        } else {
          // Auto-select recommended plan
          final rec = controller.plans.firstWhereOrNull((p) => p.isRecommended);
          selectedPlanId.value = rec?.id ?? controller.plans.first.id;
        }
      }
    });
  }

  @override
  void dispose() {
    _heroAnimCtrl.dispose();
    for (final c in _couponControllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _couponControllerFor(int planId) =>
      _couponControllers.putIfAbsent(planId, () => TextEditingController());

  int _parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned)?.round() ?? 0;
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final allPlans = controller.plans.toList();
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF4F6FF),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _T.orange),
          );
        }
        
        if (AppVerificationController.to.hideSubscriptionUi) {
          return Center(
            child: Text(
              "No plans available at the moment.",
              style: _T.body(16, color: isDark ? Colors.white70 : Colors.black54),
            ),
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Hero
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _heroFade,
                    child: _HeroHeader(size: size),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 10)),

                // Plan cards
                // REGULAR PLANS
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final plan = allPlans[i];
                      final isAddon = plan.isAddon == true;

                      Widget card = Obx(
                        () => _PlanCard(
                          plan: plan,
                          isSelected: selectedPlanId.value == plan.id,
                          isPurchased: historyController.isPlanActive(plan.id),
                          couponTec: _couponControllerFor(plan.id),
                          controller: controller,
                          isDark: isDark,
                          parseAmount: _parseAmount,
                          onSelect: () {
                            selectedPlanId.value = plan.id;
                          },
                          onProceed: () => _openConfirmSheet(context, plan),
                        ),
                      );

                      if (isAddon) {
                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF332200) : const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFB020), width: 1.5),
                              ),
                              child: Text(
                                "SUBSCRIBE ADDON PLANS: FOR ROUND BY ROUND CHOICE FILLING PROCESS",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFFB020) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFFB020), size: 32),
                            const SizedBox(height: 8),
                            card,
                          ],
                        );
                      }
                      
                      return card;
                    }, childCount: allPlans.length),
                  ),
                ),


                // Bottom padding for sticky bar
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),

            // Sticky bottom bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Obx(
                () => _StickyBottomBar(
                  plans: controller.plans,
                  selectedPlanId: selectedPlanId.value,
                  controller: controller,
                  historyController: historyController,
                  isDark: isDark,
                  parseAmount: _parseAmount,
                  onContinue: () {
                    if (selectedPlanId.value == -1) return;
                    final plan = controller.plans.firstWhereOrNull(
                      (p) => p.id == selectedPlanId.value,
                    );
                    if (plan == null) return;
                    _openConfirmSheet(context, plan);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Subscription',
        style: _T.heading(17, color: isDark ? Colors.white : Colors.black87),
      ),
      iconTheme: IconThemeData(color: isDark ? Colors.white70 : Colors.black54),
      actions: [
        TextButton.icon(
          onPressed: () => Get.to(() => const SubscriptionHistoryPage()),
          icon: Icon(
            Icons.history_rounded,
            size: 18,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          label: Text(
            'History',
            style: _T.body(13, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ],
    );
  }

  // ── Confirm sheet ──────────────────────────────────────────
  void _openConfirmSheet(BuildContext context, SubscriptionPlan plan) {
    final profileController = Get.find<ProfileController>();
    final profile = profileController.profile.value;
    final user = profile?.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = _parseAmount(plan.amount);

    Get.bottomSheet(
      Obx(() {
        final isCreatingOrder = controller.isCreatingOrder.value;
        final preview = controller.previewFor(plan.id);
        final payable = preview != null
            ? _parseAmount(preview.finalPayableAmount)
            : amount;

        return WillPopScope(
          onWillPop: () async => !isCreatingOrder,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121218) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Title row
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => _T.brandGradient.createShader(b),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm Purchase',
                        style: _T.heading(
                          18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: isCreatingOrder ? null : () => Get.back(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // User info card
                  _SheetInfoCard(
                    isDark: isDark,
                    children: [
                      _SheetRow(
                        'Name',
                        user != null
                            ? '${user.firstName} ${user.lastName}'.trim()
                            : '-',
                        isDark: isDark,
                      ),
                      _SheetRow(
                        'Mobile',
                        user?.mobileNumber ?? '-',
                        isDark: isDark,
                      ),
                      _SheetRow('Plan', plan.planName, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🔥 UNLOCKED FEATURES (Addon logic)
                  if (plan.isAddon == true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E24)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Add-on Unlocks",
                                style: _T.heading(
                                  14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (plan.features.isNotEmpty)
                            ...plan.features
                                .where((f) => f.isEnabled)
                                .map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            f.featureTitle,
                                            style: _T.body(
                                              13,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Retains all regular plan features",
                                    style: _T.body(
                                      13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fw: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Discount breakdown
                  if (preview != null &&
                      _parseAmount(preview.couponDiscount) > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.green.withOpacity(0.07),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Base Amount',
                                style: _T.body(
                                  13,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                              Text(
                                '₹$amount',
                                style: _T.body(
                                  13,
                                  color: Colors.grey,
                                  fw: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.discount_rounded,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Coupon (${preview.couponApplied ?? ''})',
                                    style: _T.body(13, color: Colors.green),
                                  ),
                                ],
                              ),
                              Text(
                                '- ₹${_parseAmount(preview.couponDiscount)}',
                                style: _T.body(
                                  13,
                                  color: Colors.green,
                                  fw: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Payable
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _T.orange.withOpacity(0.12),
                          _T.purple.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _T.orange.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payable Amount',
                          style: _T.body(
                            14,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fw: FontWeight.w500,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (b) =>
                              _T.brandGradient.createShader(b),
                          child: Text(
                            '₹$payable',
                            style: _T.heading(20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Continue CTA
                  _GradientButton(
                    label: 'Continue',
                    isLoading: isCreatingOrder,
                    onTap: isCreatingOrder
                        ? null
                        : () async {
                            Get.back();

                            /// ADDON PLAN
                            if (plan.isAddon == true) {
                              await controller.createOrderAndPay(plan.id);

                              return;
                            }

                            /// REGULAR PLAN
                            _openStateSelectionDialog(context, plan);
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  // ── State selection (logic unchanged) ─────────────────────
  Future<void> _openStateSelectionDialog(
    BuildContext context,
    SubscriptionPlan plan,
  ) async {
    final controller = Get.find<SubscriptionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileController = Get.find<ProfileController>();
    final userState = profileController.profile.value?.state;

    final feature = plan.features.firstWhereOrNull(
      (f) => f.featureLimit != null,
    );
    if (feature == null || feature.featureLimit == null) {
      AppSnackbar.show('Configuration Error', 'State limit not configured.');
      return;
    }
    final int maxStates = feature.featureLimit!;

    try {
      await controller.loadStates();
    } catch (e) {
      AppSnackbar.show('Error', 'Failed to load states');
      return;
    }

    if (controller.availableStates.isEmpty) {
      AppSnackbar.show('Error', 'No states available');
      return;
    }

    final stateItem = controller.availableStates.firstWhereOrNull(
      (e) => e.name.toLowerCase() == userState?.toLowerCase(),
    );
    if (stateItem != null) {
      final int primaryId = int.tryParse(stateItem.id?.toString() ?? '') ?? -1;
      if (primaryId != -1 && !controller.selectedStates.contains(primaryId)) {
        controller.selectedStates.add(primaryId);
      }
    }
    controller.selectedStates.refresh();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121218) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select States',
                      style: _T.heading(
                        18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_T.orange, _T.pink],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${controller.selectedStates.length} / $maxStates',
                        style: _T.body(
                          12,
                          color: Colors.white,
                          fw: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _T.orange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: _T.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        maxStates == 1
                            ? 'Your primary state is already selected.'
                            : 'Primary state selected. Choose ${maxStates - 1} more state${maxStates - 1 > 1 ? 's' : ''}.',
                        style: _T.body(
                          12.5,
                          color: _T.orange,
                          fw: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // State list
              Expanded(
                child: Obx(() {
                  if (controller.isStateLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: _T.orange),
                    );
                  }

                  final sortedStates = controller.availableStates.toList()
                    ..sort((a, b) {
                      final aName = (a.name ?? '').toLowerCase();
                      final bName = (b.name ?? '').toLowerCase();
                      final userStateLower = userState?.toLowerCase() ?? '';

                      final isPrimaryA = aName == userStateLower;
                      final isPrimaryB = bName == userStateLower;
                      if (isPrimaryA && !isPrimaryB) return -1;
                      if (!isPrimaryA && isPrimaryB) return 1;

                      final isMccA = aName == 'mcc';
                      final isMccB = bName == 'mcc';
                      if (isMccA && !isMccB) return -1;
                      if (!isMccA && isMccB) return 1;

                      return aName.compareTo(bName);
                    });

                  return ListView.builder(
                    itemCount: sortedStates.length,
                    itemBuilder: (_, i) {
                      final state = sortedStates[i];
                      final int stateId =
                          int.tryParse(state.id?.toString() ?? '') ?? -1;
                      if (stateId == -1) return const SizedBox();
                      return Obx(() {
                        final isSelected = controller.selectedStates.contains(
                          stateId,
                        );
                        final isPrimary =
                            state.name.toLowerCase() ==
                            userState?.toLowerCase();
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _T.orange.withOpacity(0.1)
                                : (isDark
                                      ? const Color(0xFF1E1E2E)
                                      : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? _T.orange.withOpacity(0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: _T.orange,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onChanged: isPrimary
                                ? null
                                : (_) {
                                    if (isSelected) {
                                      controller.selectedStates.remove(stateId);
                                    } else {
                                      if (controller.selectedStates.length >=
                                          maxStates) {
                                        AppSnackbar.show(
                                          'Limit Reached',
                                          'Max $maxStates states allowed',
                                        );
                                        return;
                                      }
                                      controller.selectedStates.add(stateId);
                                    }
                                    controller.selectedStates.refresh();
                                  },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    state.fullForm != null && state.fullForm!.isNotEmpty
                                        ? '${state.name} (${state.fullForm})'
                                        : (state.name.toLowerCase() == 'mcc'
                                            ? '${state.name} (All India Counseling)'
                                            : state.name) ?? 'Unknown',
                                    style: _T.body(
                                      14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fw: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _T.purple.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_rounded,
                                          size: 11,
                                          color: _T.purple,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Primary',
                                          style: _T.body(
                                            10,
                                            color: _T.purple,
                                            fw: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),

              // Continue button
              Obx(() {
                final isEnabled =
                    controller.selectedStates.isNotEmpty &&
                    controller.selectedStates.length <= maxStates;
                return _GradientButton(
                  label:
                      'Continue  (${controller.selectedStates.length}/$maxStates)',
                  isLoading: false,
                  onTap: isEnabled
                      ? () async {
                          if (controller.availableCourses.isNotEmpty) {
                            Get.back();
                            await CourseSelectionBottomSheet.show(context, plan);
                          } else {
                            await controller.createOrderAndPay(plan.id);
                            Get.back();
                          }
                        }
                      : null,
                  enabled: isEnabled,
                );
              }),
            ],
          ),
        );
      },
    );
  }



  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HERO HEADER
// ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final Size size;
  const _HeroHeader({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10 + 3,
        bottom: 30,
        left: 20,
        right: 20,
      ),
      // decoration: const BoxDecoration(
      //   gradient: _T.heroBg,
      //   borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2BE2), Color(0xFF3A86FF)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '✦ PLANS  ✦',
              style: _T.body(10, color: Colors.white70, fw: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (b) => _T.brandGradient.createShader(b),
            child: Text(
              'Choose Your Plan',
              style: _T.heading(20, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock powerful insights for your business.\nSimple pricing. Cancel anytime.',
            textAlign: TextAlign.center,
            style: _T.body(
              13,
              color: isDark
                  ? Colors.white70
                  : const Color.fromARGB(137, 35, 35, 35),
            ),
          ),
          const SizedBox(height: 28),

          // Feature pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroFeature(
                icon: Icons.bolt_rounded,
                label: 'Fast Access',
                isDark: isDark,
              ),
              const SizedBox(width: 14),
              _HeroFeature(
                icon: Icons.shield_rounded,
                label: 'Secure',
                isDark: isDark,
              ),
              const SizedBox(width: 14),
              _HeroFeature(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _HeroFeature({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _T.orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: _T.body(
              10,
              color: isDark ? Colors.white : Colors.black87,
              fw: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PLAN CARD
// ─────────────────────────────────────────────────────────────
class _PlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isPurchased;
  final TextEditingController couponTec;
  final SubscriptionController controller;
  final bool isDark;
  final int Function(String) parseAmount;
  final VoidCallback onSelect;
  final VoidCallback onProceed;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isPurchased,
    required this.couponTec,
    required this.controller,
    required this.isDark,
    required this.parseAmount,
    required this.onSelect,
    required this.onProceed,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.015,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _PlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleCtrl.forward().then((_) => _scaleCtrl.reverse());
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isDark = widget.isDark;
    final isRec = plan.isRecommended;
    final isSelected = widget.isSelected;
    final amount = widget.parseAmount(plan.amount);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14141E) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isSelected
                  ? _T.orange.withOpacity(0.7)
                  : (isRec
                        ? _T.purple.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.15)),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: [
              if (isSelected || isRec)
                BoxShadow(
                  color: isSelected
                      ? _T.orange.withOpacity(0.25)
                      : _T.purple.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header ──────────────────────────────
              if (isRec) _buildRecommendedBanner(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan name + selection indicator
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.planName,
                                style: _T.heading(
                                  14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (plan.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plan.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: _T.body(
                                    12,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fw: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isSelected ? _T.brandGradient : null,
                            color: isSelected
                                ? null
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Obx(() {
                      final preview = widget.controller.previewFor(plan.id);
                      final payable = preview != null
                          ? widget.parseAmount(preview.planPayableAmount)
                          : amount;
                      final hasDiscount =
                          preview != null &&
                          widget.parseAmount(preview.couponDiscount) > 0;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) =>
                                _T.brandGradient.createShader(b),
                            child: Text(
                              '₹$payable',
                              style: _T.heading(24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Valid till ${plan.durationDays} days',
                              style: _T.body(
                                12,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹$amount',
                                style: _T.body(
                                  11,
                                  color: Colors.grey,
                                  fw: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),

                    const SizedBox(height: 18),

                    // First 2 features always visible
                    ...plan.features
                        .take(2)
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF43E97B),
                                        Color(0xFF38F9D7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f.featureTitle,
                                    style: _T.body(
                                      13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                    if (plan.features.length > 2) const SizedBox(height: 10),

                    if (plan.features.length > 2)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Row(
                          children: [
                            Text(
                              _expanded ? 'Hide Details' : 'View All Features',
                              style: _T.body(
                                12.5,
                                color: _T.orange,
                                fw: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: _T.orange,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (plan.features.length > 2)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _expanded
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 14),
                                  ...plan.features
                                      .skip(2)
                                      .map(
                                        (f) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF43E97B),
                                                          Color(0xFF38F9D7),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.check_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  f.featureTitle,
                                                  style: _T.body(
                                                    13,
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                    const SizedBox(height: 14),

                    // Coupon section always visible
                    _CouponSection(
                      plan: plan,
                      couponTec: widget.couponTec,
                      controller: widget.controller,
                      isDark: isDark,
                      parseAmount: widget.parseAmount,
                    ),

                    const SizedBox(height: 18),

                    // CTA Button
                    Obx(() {
                      final preview = widget.controller.previewFor(plan.id);
                      final payable = preview != null
                          ? widget.parseAmount(preview.finalPayableAmount)
                          : amount;

                      if (widget.isPurchased) {
                        return SizedBox(
                          width: double.infinity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Active Plan',
                                  style: _T.body(
                                    14,
                                    color: Colors.green,
                                    fw: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return _GradientButton(
                        label: isRec ? '✦  Get Premium  ✦' : 'Select Plan',
                        isLoading: false,
                        onTap: () => widget.onProceed(),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        gradient: _T.brandGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'MOST POPULAR',
            style: _T.body(11, color: Colors.white, fw: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  COUPON SECTION
// ─────────────────────────────────────────────────────────────
class _CouponSection extends StatefulWidget {
  final SubscriptionPlan plan;
  final TextEditingController couponTec;
  final SubscriptionController controller;
  final bool isDark;
  final int Function(String) parseAmount;

  const _CouponSection({
    required this.plan,
    required this.couponTec,
    required this.controller,
    required this.isDark,
    required this.parseAmount,
  });

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  final FocusNode _focusNode = FocusNode();

  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isApplying = widget.controller.isApplyingCoupon(widget.plan.id);

      final error = widget.controller.couponErrorFor(widget.plan.id);

      final preview = widget.controller.previewFor(widget.plan.id);

      final isCouponApplied =
          preview != null && widget.parseAmount(preview.couponDiscount) > 0;

      final isAddon = widget.plan.isAddon == true;

      Color borderColor;
      if (error.isNotEmpty) {
        borderColor = Colors.redAccent;
      } else if (isCouponApplied) {
        borderColor = Colors.green;
      } else if (_isFocused) {
        borderColor = _T.orange;
      } else if (_isHovered) {
        borderColor = _T.orange.withOpacity(.55);
      } else {
        borderColor = isAddon
            ? (widget.isDark ? Colors.white.withOpacity(.5) : _T.orange.withOpacity(.3))
            : (widget.isDark
                  ? Colors.white.withOpacity(.25)
                  : Colors.grey.withOpacity(.25));
      }

      final bgColor = isAddon
          ? (widget.isDark ? Colors.white.withOpacity(0.2) : _T.orange.withOpacity(.05))
          : (widget.isDark ? Colors.white.withOpacity(.06) : Colors.white);

      final textColor = isCouponApplied
          ? Colors.green
          : (widget.isDark ? Colors.white : Colors.black87);

      final hintColor = isAddon
          ? (widget.isDark ? Colors.white70 : Colors.black54)
          : (widget.isDark ? Colors.white54 : Colors.grey);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_rounded,
                size: 16,
                color: isAddon ? (widget.isDark ? Colors.white : _T.orange) : _T.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Have a coupon?',
                style: _T.body(
                  13,
                  color: isAddon ? (widget.isDark ? Colors.white : _T.orange) : _T.orange,
                  fw: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: _isFocused ? 1.01 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: bgColor,
                        border: Border.all(
                          color: borderColor,
                          width: _isFocused ? 1.8 : 1.2,
                        ),
                        boxShadow: [
                          if (_isFocused)
                            BoxShadow(
                              color: _T.orange.withOpacity(.18),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            )
                          else if (_isHovered)
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                        ],
                        gradient: isCouponApplied
                            ? LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(.10),
                                  Colors.green.withOpacity(.03),
                                ],
                              )
                            : null,
                      ),
                      child: TextFormField(
                        focusNode: _focusNode,
                        controller: widget.couponTec,
                        enabled: !isCouponApplied && !isApplying,
                        textCapitalization: TextCapitalization.characters,
                        style: _T.body(
                          13,
                          color: textColor,
                          fw: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter coupon code',
                          hintStyle: _T.body(13, color: hintColor),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isCouponApplied
                                    ? Colors.green.withOpacity(.12)
                                    : _isFocused
                                    ? _T.orange.withOpacity(.12)
                                    : Colors.grey.withOpacity(.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.local_offer_rounded,
                                size: 18,
                                color: isCouponApplied
                                    ? Colors.green
                                    : _isFocused
                                    ? _T.orange
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          suffixIcon: isCouponApplied
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              _CouponButton(
                label: isCouponApplied ? 'Remove' : 'Apply',
                color: isCouponApplied
                    ? Colors.redAccent
                    : isAddon
                    ? (widget.isDark ? Colors.white : _T.orange)
                    : _T.orange,
                textColor: isCouponApplied
                    ? Colors.white
                    : isAddon
                    ? (widget.isDark ? Colors.black : Colors.white)
                    : Colors.white,
                isLoading: isApplying,
                onTap: isCouponApplied
                    ? () {
                        widget.controller.clearCoupon(widget.plan.id);
                        widget.couponTec.clear();
                      }
                    : () {
                        FocusScope.of(context).unfocus();

                        widget.controller.applyCoupon(
                          planId: widget.plan.id,
                          couponCode: widget.couponTec.text.trim(),
                        );
                      },
              ),
            ],
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    error,
                    style: _T.body(
                      11.5,
                      color: Colors.redAccent,
                      fw: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (isCouponApplied) ...[
            const SizedBox(height: 12),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: const ValueKey('coupon_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.discount_rounded,
                      size: 15,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'You save ₹${widget.parseAmount(preview!.couponDiscount)}',
                      style: _T.body(
                        12,
                        color: Colors.green,
                        fw: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  STICKY BOTTOM BAR
// ─────────────────────────────────────────────────────────────
class _StickyBottomBar extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final int selectedPlanId;
  final SubscriptionController controller;
  final SubscriptionHistoryController historyController;
  final bool isDark;
  final int Function(String) parseAmount;
  final VoidCallback onContinue;

  const _StickyBottomBar({
    required this.plans,
    required this.selectedPlanId,
    required this.controller,
    required this.historyController,
    required this.isDark,
    required this.parseAmount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final plan = plans.firstWhereOrNull((p) => p.id == selectedPlanId);
    if (plan == null) return const SizedBox.shrink();

    final isPurchased = historyController.isPlanActive(plan.id);
    final preview = controller.previewFor(plan.id);
    final amount = parseAmount(plan.amount);
    final payable = preview != null
        ? parseAmount(preview.planPayableAmount)
        : amount;
    final hasDiscount =
        preview != null && parseAmount(preview.couponDiscount) > 0;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E0E1A).withOpacity(0.97)
            : Colors.white.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.planName,
                  style: _T.body(
                    13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => _T.brandGradient.createShader(b),
                      child: Text(
                        '₹$payable',
                        style: _T.heading(22, color: Colors.white),
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹$amount',
                        style: _T.body(
                          12,
                          color: Colors.grey,
                          fw: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: isPurchased
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active',
                          style: _T.body(
                            14,
                            color: Colors.green,
                            fw: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _GradientButton(
                    label: 'Continue  →',
                    isLoading: false,
                    onTap: onContinue,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FeatureChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: 11,
            color: isDark ? Colors.greenAccent : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            label.length > 18 ? '${label.substring(0, 18)}…' : label,
            style: _T.body(11, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool enabled;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null && !isLoading;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active ? _T.brandGradient : null,
          color: active ? null : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _T.orange.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: _T.body(14, color: Colors.white, fw: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

class _CouponButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final VoidCallback? onTap;
  const _CouponButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(isLoading ? 0.6 : 1.0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    key: const ValueKey('text'),
                    style: _T.body(13, color: textColor, fw: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}

// Sheet helper widgets
class _SheetInfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SheetInfoCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _SheetRow(this.label, this.value, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: _T.body(13, color: isDark ? Colors.white : Colors.black45),
          ),
          Text(
            value,
            style: _T.body(
              13,
              color: isDark ? Colors.white : Colors.black87,
              fw: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
