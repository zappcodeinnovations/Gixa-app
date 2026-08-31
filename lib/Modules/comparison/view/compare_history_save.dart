import 'package:Gixa/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/compare_history_controller.dart';

// ─── Shared color palette (matches CompareCollegesView) ──────────────────────
class _C {
  static const orange = Color(0xFFFF6B2C);
  static const orangeSurface = Color(0xFFFFF4EE);
  static const dark = Color(0xFF12100E);
  static const darkCard = Color(0xFF1C1A18);
  static const textPrimary = Color(0xFF1A1614);
  static const textSecondary = Color(0xFF7A736E);
  static const lightBg = Color(0xFFFAF8F6);
  static const lightCard = Color(0xFFFFFFFF);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
}

class CompareHistoryView extends StatelessWidget {
  const CompareHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CompareHistoryController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _C.dark : _C.lightBg,
      appBar: _buildAppBar(isDark, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.historyList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: _C.orange,
              strokeWidth: 2.5,
            ),
          );
        }

        if (controller.historyList.isEmpty) {
          return _EmptyState(isDark: isDark);
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: controller.historyList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = controller.historyList[index];
            return Obx(() {
              final isSelected = controller.selectedIds.contains(item.id);
              return _HistoryCard(
                item: item,
                isDark: isDark,
                isSelected: isSelected,
                isSelectionMode: controller.isSelectionMode.value,
                onTap: () {
                  if (controller.isSelectionMode.value) {
                    controller.toggleSelection(item.id);
                  } else {
                    Get.toNamed(AppRoutes.compareCollage, arguments: item);
                  }
                },
              );
            });
          },
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, CompareHistoryController controller) {
    final textColor = isDark ? Colors.white : _C.textPrimary;
    return AppBar(
      backgroundColor: isDark ? _C.dark : _C.lightBg,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleSelectionMode();
          } else {
            Get.back();
          }
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            controller.isSelectionMode.value
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: textColor,
          ),
        ),
      ),
      title: Obx(() => Text(
            controller.isSelectionMode.value
                ? "${controller.selectedIds.length} Selected"
                : "History",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          )),
      actions: [
        Obx(() {
          if (controller.historyList.isEmpty) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                if (controller.isSelectionMode.value) {
                  if (controller.selectedIds.isNotEmpty) {
                    _showDeleteConfirmation(controller);
                  } else {
                    controller.toggleSelectionMode();
                  }
                } else {
                  controller.toggleSelectionMode();
                }
              },
              icon: Icon(
                controller.isSelectionMode.value
                    ? Icons.delete_forever_rounded
                    : Icons.delete_outline_rounded,
                color: controller.isSelectionMode.value &&
                        controller.selectedIds.isEmpty
                    ? textColor.withOpacity(0.5)
                    : _C.orange,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showDeleteConfirmation(CompareHistoryController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete History"),
        content: Text(
            "Are you sure you want to delete ${controller.selectedIds.length} items?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSelected();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final dynamic item;
  final bool isDark;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;

  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? _C.darkCard : _C.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: _C.orange, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: isSelected
                        ? _C.orange.withOpacity(0.15)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top accent strip + date row ──
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _C.orange.withOpacity(0.2)
                        : _C.orange.withOpacity(isDark ? 0.12 : 0.06),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelectionMode
                                ? (isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded)
                                : Icons.history_rounded,
                            size: 16,
                            color: isSelected ? _C.orange : _C.orange,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            item.createdDate ?? "—",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? _C.orange
                                  : (isDark ? Colors.white60 : _C.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      _CountBadge(count: item.totalColleges),
                    ],
                  ),
                ),

                // ── College rows ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    children: [
                      ...(item.colleges as List)
                          .take(3)
                          .map((college) => _CollegeRow(
                                college: college,
                                isDark: isDark,
                              )),
                      if ((item.colleges as List).length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 48),
                          child: Text(
                            "+ ${(item.colleges as List).length - 3} more",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── College Row ──────────────────────────────────────────
class _CollegeRow extends StatelessWidget {
  final dynamic college;
  final bool isDark;

  const _CollegeRow({required this.college, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = (college.collegeName as String?) ?? "";
    final city = (college.city as String?) ?? "";

    final initials = name.isNotEmpty
        ? name
            .split(" ")
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : "?";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _C.orangeSurface,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _C.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _C.textPrimary,
                  ),
                ),
                if (city.isNotEmpty)
                  Text(
                    city,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : _C.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Count Badge ──────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _C.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$count Colleges",
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _C.orange,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _C.orangeSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 42,
                color: _C.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No History Yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _C.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You haven't compared any colleges yet.\nStart comparing to save results here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : _C.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.compareCollage),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.orange,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _C.orange.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  "Start Comparing",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}