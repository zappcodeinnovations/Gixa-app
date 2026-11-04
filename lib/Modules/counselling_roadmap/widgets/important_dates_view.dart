import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/counselling_roadmap/controller/counselling_timeline_controller.dart';
import 'package:Gixa/Modules/counselling_roadmap/model/counselling_timeline_model.dart';
import 'package:Gixa/services/calendar_sync_service.dart';
import 'package:Gixa/utils/constants/colors.dart';

class ImportantDatesView extends StatelessWidget {
  final bool isDark;

  const ImportantDatesView({super.key, required this.isDark});

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

      final dates = controller.filteredDates;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROUND FILTER CHIPS ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: controller.availableDateRounds.map((round) {
                final isSelected = controller.selectedDateRound.value == round;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      round == 'All' ? 'All Rounds' : round,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF374151)),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: UColors.primary,
                    backgroundColor: isDark ? const Color(0xFF202030) : const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? UColors.primary
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    onSelected: (_) => controller.selectDateRound(round),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── DATES LIST ──────────────────────────────────────────────────
          if (dates.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 40, color: subtextColor),
                  const SizedBox(height: 10),
                  Text(
                    "No counselling dates found for this round.",
                    style: GoogleFonts.dmSans(fontSize: 14, color: subtextColor),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              itemCount: dates.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = dates[index];
                return _buildDateCard(
                  item: item,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                );
              },
            ),
          ],
        ],
      );
    });
  }

  Widget _buildDateCard({
    required CounsellingDateEvent item,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (item.isOngoing) {
      statusColor = const Color(0xFF10B981); // Emerald
      statusText = "Ongoing";
      statusIcon = Icons.sensors_rounded;
    } else if (item.isUpcoming) {
      statusColor = const Color(0xFF3B82F6); // Blue
      statusText = "Upcoming";
      statusIcon = Icons.access_time_rounded;
    } else {
      statusColor = const Color(0xFF6B7280); // Gray
      statusText = "Closed";
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isOngoing ? statusColor.withOpacity(0.4) : borderColor,
          width: item.isOngoing ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Round tag & Status badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: UColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.round,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: UColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Title ──
          Text(
            item.title,
            style: GoogleFonts.dmSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // ── Description ──
          if (item.description.isNotEmpty) ...[
            Text(
              item.description,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                height: 1.45,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Date Range Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13131E) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: item.isOngoing ? statusColor : UColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.formattedDateRange,
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Add to Calendar Button ──
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: item.startDate != null
                  ? () {
                      CalendarSyncService.addEventToCalendar(
                        title: "${item.round}: ${item.title}",
                        startDate: item.startDate!,
                        endDate: item.endDate,
                        description: item.description,
                      );
                    }
                  : null,
              icon: const Icon(Icons.notification_add_outlined, size: 14),
              label: Text(
                "Add to Calendar",
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: UColors.primary,
                side: BorderSide(color: UColors.primary.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

