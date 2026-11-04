import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/counselling_roadmap/controller/counselling_timeline_controller.dart';
import 'package:Gixa/Modules/counselling_roadmap/model/counselling_timeline_model.dart';
import 'package:Gixa/Modules/counselling_roadmap/widgets/step_guidelines_sheet.dart';
import 'package:Gixa/utils/constants/colors.dart';

class VisualTimelineView extends StatelessWidget {
  final bool isDark;

  const VisualTimelineView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CounsellingTimelineController>()
        ? Get.find<CounsellingTimelineController>()
        : Get.put(CounsellingTimelineController());

    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final cardBg = isDark ? const Color(0xFF1A1A28) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C3E) : const Color(0xFFE5E7EB);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: UColors.primary),
          ),
        );
      }

      final steps = controller.filteredSteps;
      final activeStep = controller.activeStep;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROUND SWITCHER (SEGMENTED TABS) ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B2A) : const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: controller.availableRounds.map((round) {
                final isSelected = controller.selectedRound.value == round;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectRound(round),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? UColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: UColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        round,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // ── ACTIVE STAGE PROGRESS HIGHLIGHT BANNER ───────────────────────
          if (activeStep != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    UColors.primary.withOpacity(isDark ? 0.25 : 0.12),
                    UColors.primaryLight.withOpacity(isDark ? 0.20 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: UColors.primary.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: UColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CURRENT STAGE: STEP ${activeStep.stepNumber} OF ${steps.length}",
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: UColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeStep.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── VERTICAL STEPPER ROADMAP ────────────────────────────────────
          if (steps.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                "No roadmap steps available for ${controller.selectedRound.value}.",
                style: GoogleFonts.dmSans(fontSize: 14, color: subtextColor),
              ),
            ),
          ] else ...[
            ListView.builder(
              itemCount: steps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isLast = index == steps.length - 1;
                return _buildStepperItem(
                  step: step,
                  isLast: isLast,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  context: context,
                );
              },
            ),
          ],
        ],
      );
    });
  }

  Widget _buildStepperItem({
    required CounsellingTimelineStep step,
    required bool isLast,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required BuildContext context,
  }) {
    Color nodeColor;
    Widget nodeIcon;
    Color connectorColor;

    if (step.isCompleted) {
      nodeColor = const Color(0xFF10B981); // Emerald
      nodeIcon = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
      connectorColor = const Color(0xFF10B981);
    } else if (step.isActive) {
      nodeColor = UColors.primary;
      nodeIcon = Text(
        "${step.stepNumber}",
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      );
      connectorColor = isDark ? const Color(0xFF333348) : const Color(0xFFD1D5DB);
    } else {
      nodeColor = isDark ? const Color(0xFF2C2C3E) : const Color(0xFFE5E7EB);
      nodeIcon = Text(
        "${step.stepNumber}",
        style: GoogleFonts.dmSans(
          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      );
      connectorColor = isDark ? const Color(0xFF333348) : const Color(0xFFD1D5DB);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Stepper Line & Circle Node ──
          SizedBox(
            width: 38,
            child: Column(
              children: [
                // Node
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    boxShadow: step.isActive
                        ? [
                            BoxShadow(
                              color: UColors.primary.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(child: nodeIcon),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: connectorColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Right: Step Detail Card ──
          Expanded(
            child: GestureDetector(
              onTap: () => StepGuidelinesSheet.show(context, step),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: step.isActive
                        ? UColors.primary.withOpacity(0.6)
                        : borderColor,
                    width: step.isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Status tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Step ${step.stepNumber}",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: step.isCompleted
                                ? const Color(0xFF10B981)
                                : (step.isActive ? UColors.primary : subtextColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (step.isCompleted
                                    ? const Color(0xFF10B981)
                                    : (step.isActive
                                        ? UColors.primary
                                        : const Color(0xFF6B7280)))
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            step.isCompleted
                                ? "Completed"
                                : (step.isActive ? "Current" : "Upcoming"),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: step.isCompleted
                                  ? const Color(0xFF10B981)
                                  : (step.isActive
                                      ? UColors.primary
                                      : const Color(0xFF6B7280)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      step.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      step.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        height: 1.4,
                        color: subtextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Tap action: Guidelines prompt
                    Row(
                      children: [
                        Text(
                          "Tap to view guidelines & rules",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: UColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: UColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

