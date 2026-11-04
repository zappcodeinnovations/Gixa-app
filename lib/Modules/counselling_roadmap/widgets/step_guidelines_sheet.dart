import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/counselling_roadmap/model/counselling_timeline_model.dart';
import 'package:Gixa/utils/constants/colors.dart';

class StepGuidelinesSheet extends StatelessWidget {
  final CounsellingTimelineStep step;

  const StepGuidelinesSheet({super.key, required this.step});

  static void show(BuildContext context, CounsellingTimelineStep step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StepGuidelinesSheet(step: step),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161622) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

    final statusColor = step.isCompleted
        ? const Color(0xFF10B981)
        : (step.isActive ? UColors.primary : const Color(0xFF6B7280));

    final statusLabel = step.isCompleted
        ? "Completed"
        : (step.isActive ? "Current Stage" : "Upcoming Stage");

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header: Round & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: UColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${step.round} • Step ${step.stepNumber}",
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: UColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      step.isCompleted
                          ? Icons.check_circle_rounded
                          : (step.isActive
                              ? Icons.play_circle_fill_rounded
                              : Icons.schedule_rounded),
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Step Title
          Text(
            step.title,
            style: GoogleFonts.dmSans(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Step Description
          Text(
            step.description,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              height: 1.5,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 20),

          // Guidelines Title
          Row(
            children: [
              Icon(Icons.rule_folder_outlined, size: 18, color: UColors.primary),
              const SizedBox(width: 8),
              Text(
                "Guidelines & Official Rules",
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Guidelines List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: step.guidelines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final rule = step.guidelines[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F30) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: UColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: UColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: UColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Got it",
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

