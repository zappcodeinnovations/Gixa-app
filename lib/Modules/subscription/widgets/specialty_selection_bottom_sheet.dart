import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/Modules/subscription/model/subscription_specialty_model.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class SpecialtySelectionBottomSheet {
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

  static Future<void> show(BuildContext context) async {
    final controller = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch latest specialty options
    controller.fetchSpecialtiesAddon();

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
              // Drag Handle
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

              // Title & Selected Badge Header
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Specialty',
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
                        '${controller.selectedSpecialtyAddonIds.length} Selected',
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

              // Specialties Content List
              Expanded(
                child: Obx(() {
                  if (controller.isSpecialtyLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: orange),
                    );
                  }

                  final courseList = controller.addonSpecialtyCourses;
                  if (courseList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_hospital_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No specialties available',
                            style: body(
                              14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => controller.fetchSpecialtiesAddon(forceRefresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: courseList.length,
                    itemBuilder: (_, cIdx) {
                      final course = courseList[cIdx];
                      if (course.specialties.isEmpty) return const SizedBox();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Header Tag
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 18,
                                    color: orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    course.courseName,
                                    style: heading(
                                      14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Specialties Tiles
                            ...course.specialties.map((spec) {
                              return Obx(() {
                                final isSelected = controller
                                    .selectedSpecialtyAddonIds
                                    .contains(spec.id);

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? orange.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? orange.withOpacity(0.5)
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    activeColor: orange,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onChanged: (_) {
                                      if (isSelected) {
                                        controller.selectedSpecialtyAddonIds
                                            .remove(spec.id);
                                      } else {
                                        controller.selectedSpecialtyAddonIds
                                            .add(spec.id);
                                      }
                                      controller.selectedSpecialtyAddonIds.refresh();
                                    },
                                    title: Text(
                                      spec.specialtyName,
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
                                    subtitle: Text(
                                      'Amount: ₹${spec.amount}',
                                      style: body(
                                        13,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                );
                              });
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),

              // Bottom Pay Button (Disabled if 0 items selected)
              Obx(() {
                final selectedIds = controller.selectedSpecialtyAddonIds;
                final isEnabled = selectedIds.isNotEmpty;

                double totalAmount = 0.0;
                for (final course in controller.addonSpecialtyCourses) {
                  for (final spec in course.specialties) {
                    if (selectedIds.contains(spec.id)) {
                      totalAmount += spec.amountAsDouble;
                    }
                  }
                }

                final displayPrice = totalAmount.toStringAsFixed(2);

                return _SpecialtyGradientButton(
                  label: isEnabled ? 'Pay ₹$displayPrice' : 'Select a Specialty',
                  isLoading: false,
                  enabled: isEnabled,
                  onTap: isEnabled
                      ? () async {
                          final activePlan = controller.activePlan.value;
                          if (activePlan == null) {
                            AppSnackbar.show(
                              'No Active Plan',
                              'Please purchase a base plan first to add specialties.',
                            );
                            return;
                          }

                          // Process purchase for selected specialties
                          await controller.createOrderAndPay(
                            activePlan.id,
                            isAddonOnly: true,
                          );
                          Get.back();
                        }
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SpecialtyGradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool enabled;

  const _SpecialtyGradientButton({
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
          gradient: active ? SpecialtySelectionBottomSheet.brandGradient : null,
          color: active ? null : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: SpecialtySelectionBottomSheet.orange.withOpacity(0.35),
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
                  style: SpecialtySelectionBottomSheet.body(
                    14,
                    color: active ? Colors.white : Colors.white70,
                    fw: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
