import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/Modules/subscription/model/subscription_plan.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class CourseSelectionBottomSheet {
  static const Color orange = Color(0xFFEC8B04);
  static const Color pink = Color(0xFFE94057);
  static const Color purple = Color(0xFF8A2BE2);
  
  static const LinearGradient brandGradient = LinearGradient(
    colors: [orange, pink, purple],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
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

  static Future<void> show(
    BuildContext context,
    SubscriptionPlan plan, {
    bool isAddonOnly = false,
  }) async {
    final controller = Get.find<SubscriptionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch initial price including default/locked courses
    controller.updateCourseSelectionPrice(plan.id);

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
                      'Select Courses',
                      style: heading(
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
                          colors: [orange, pink],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${controller.selectedCourses.length} Selected',
                        style: body(
                          12,
                          color: Colors.white,
                          fw: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Course list
              Expanded(
                child: Obx(() {
                  final sortedCourses = controller.availableCourses.toList();
                  return ListView.builder(
                    itemCount: sortedCourses.length,
                    itemBuilder: (_, i) {
                      final course = sortedCourses[i];
                      final int courseId = course.id != -1 ? course.id : course.courseId;
                      if (courseId == -1) return const SizedBox();
                      return Obx(() {
                        final isSelected = controller.selectedCourses.contains(
                          courseId,
                        );
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? orange.withOpacity(0.1)
                                : (isDark
                                      ? const Color(0xFF1E1E2E)
                                      : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? orange.withOpacity(0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: orange,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onChanged: (_) {
                              final isLocked = controller.lockedCourses.contains(courseId);
                              if (isLocked) {
                                AppSnackbar.show(
                                  'Profile Course',
                                  'This course was added during registration and is included by default.',
                                );
                                return;
                              }

                              if (isSelected) {
                                controller.selectedCourses.remove(courseId);
                              } else {
                                controller.selectedCourses.add(courseId);
                              }
                              controller.selectedCourses.refresh();
                              controller.updateCourseSelectionPrice(plan.id);
                            },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course.courseName,
                                    style: body(
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
                                if (controller.lockedCourses.contains(courseId))
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 16,
                                    color: orange,
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              controller.lockedCourses.contains(courseId)
                                  ? 'Included in Profile'
                                  : 'Amount: ₹${course.amount}',
                              style: body(
                                13,
                                color: Colors.grey.shade600,
                              ),
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
                final isEnabled = true;
                final preview = controller.previewFor(plan.id);
                
                String displayAmount = plan.amount;
                
                if (isAddonOnly) {
                  int coursesAmount = 0;
                  for (final courseId in controller.selectedCourses) {
                    if (controller.lockedCourses.contains(courseId)) continue;
                    final course = controller.availableCourses.firstWhereOrNull((c) => (c.id != -1 ? c.id : c.courseId) == courseId);
                    if (course != null) {
                      coursesAmount += course.amount.round();
                    }
                  }
                  displayAmount = coursesAmount.toString();
                } else {
                  if (preview != null) {
                    final cleaned = preview.finalPayableAmount.replaceAll(RegExp(r'[^0-9.]'), '');
                    if (cleaned.isNotEmpty) {
                      displayAmount = double.parse(cleaned).round().toString();
                    }
                  } else {
                    final cleaned = plan.amount.replaceAll(RegExp(r'[^0-9.]'), '');
                    if (cleaned.isNotEmpty) {
                      displayAmount = double.parse(cleaned).round().toString();
                    }
                  }
                }

                return GradientButton(
                  label: 'Pay ₹$displayAmount',
                  isLoading: false,
                  onTap: isEnabled
                      ? () async {
                          await controller.createOrderAndPay(plan.id, isAddonOnly: isAddonOnly);
                          Get.back();
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
}

class GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool enabled;

  const GradientButton({
    super.key,
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
          gradient: active ? CourseSelectionBottomSheet.brandGradient : null,
          color: active ? null : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: CourseSelectionBottomSheet.orange.withOpacity(0.35),
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
                  style: CourseSelectionBottomSheet.body(14, color: Colors.white, fw: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
