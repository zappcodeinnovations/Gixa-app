import 'dart:math' as math;
import 'package:Gixa/Modules/CollageDetails/controller/college_cutoff_controller.dart';
import 'package:Gixa/Modules/CollageDetails/model/college_cutoff_model.dart';
import 'package:Gixa/Modules/CollageDetails/widgets/collage_theme.dart';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CollegeCutoffTab extends StatefulWidget {
  final int collegeId;

  const CollegeCutoffTab({super.key, required this.collegeId});

  @override
  State<CollegeCutoffTab> createState() => _CollegeCutoffTabState();
}

class _CollegeCutoffTabState extends State<CollegeCutoffTab> {
  late final String _tag;
  late final CollegeCutoffController controller;

  @override
  void initState() {
    super.initState();
    _tag = 'college_cutoff_${widget.collegeId}';
    controller = Get.isRegistered<CollegeCutoffController>(tag: _tag)
        ? Get.find<CollegeCutoffController>(tag: _tag)
        : Get.put(
            CollegeCutoffController(collegeId: widget.collegeId),
            tag: _tag,
          );
  }

  @override
  void dispose() {
    if (Get.isRegistered<CollegeCutoffController>(tag: _tag)) {
      Get.delete<CollegeCutoffController>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CollegeTheme.colors(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: colors.primary),
          ),
        );
      }

      if (controller.needsAir) {
        return _infoCard(
          context,
          title: 'Add your AIR to unlock cutoff insights',
          message:
              'This college cutoff view compares your AIR with each category cutoff. Update your profile rank to see personalised chances here.',
          icon: Icons.verified_user_outlined,
          accent: colors.primary,
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _infoCard(
          context,
          title: 'Unable to load cutoff data',
          message: controller.errorMessage.value,
          icon: Icons.error_outline_rounded,
          accent: colors.danger,
          showRetry: true,
        );
      }

      final data = controller.cutoffData.value;
      final records = controller.selectedRecordsRx;
      if (data == null || records.isEmpty) {
        return _infoCard(
          context,
          title: 'No cutoff data available',
          message:
              'We could not find category-wise cutoff records for this college yet.',
          icon: Icons.analytics_outlined,
          accent: colors.secondary,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroSection(context, data),
          const SizedBox(height: 16),
          _filterSection(context),
          const SizedBox(height: 16),
          _graphSection(context, records),
          const SizedBox(height: 16),
          _categoryList(context, records),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _heroSection(
    BuildContext context,
    CollegeCategoryCutoffResponse data,
  ) {
    final colors = CollegeTheme.colors(context);
    final matchedCategories = controller.userMatchedRecords.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: colors.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Category Cutoff Match',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            controller.headlineMessage,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.subMessage,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _heroStat(
                            label: 'Your AIR',
                            value: controller.formatNumber(
                              controller.userAir.value,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _heroStat(
                            label: 'Eligible',
                            value:
                                '${controller.eligibleRecords.length}/${controller.selectedRecordsRx.length}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _heroStat(
                      label: 'Profile Category',
                      value: matchedCategories > 0
                          ? '${controller.userCategoryLabel} • $matchedCategories match'
                          : controller.userCategoryLabel,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _heroStat(
                      label: 'Your AIR',
                      value: controller.formatNumber(controller.userAir.value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroStat(
                      label: 'Eligible',
                      value:
                          '${controller.eligibleRecords.length}/${controller.selectedRecordsRx.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroStat(
                      label: 'Profile Category',
                      value: matchedCategories > 0
                          ? '${controller.userCategoryLabel} • $matchedCategories match'
                          : controller.userCategoryLabel,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Counselling year ${data.filters.year ?? '-'}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection(BuildContext context) {
    final colors = CollegeTheme.colors(context);
    final courses = controller.courseOptions;
    final quotas = controller.quotaOptions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colors.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter cutoff view',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: controller.selectedCourseName.value,
            isExpanded: true,
            items: courses
                .map(
                  (courseName) => DropdownMenuItem<String>(
                    value: courseName,
                    child: Text(courseName),
                  ),
                )
                .toList(),
            onChanged: controller.updateCourse,
            decoration: _inputDecoration(context, 'Course'),
          ),
          const SizedBox(height: 12),
          
          if (!Get.find<ProfileController>().isUGUser) ...[
            DropdownButtonFormField<String>(
              value: controller.selectedSpecialityType.value,
              isExpanded: true,
              items: controller.specialityTypeOptions
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: controller.updateSpecialityType,
              decoration: _inputDecoration(context, 'Speciality Type'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: controller.selectedSpecialityId.value,
              isExpanded: true,
              items: controller.specialityOptions
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: controller.updateSpeciality,
              decoration: _inputDecoration(context, 'Speciality'),
            ),
            const SizedBox(height: 12),
          ],
          
          DropdownButtonFormField<int>(
            value: controller.selectedQuotaId.value,
            isExpanded: true,
            items: quotas
                .map(
                  (entry) => DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: controller.updateQuota,
            decoration: _inputDecoration(context, 'Quota'),
          ),
        ],
      ),
    );
  }

  Widget _graphSection(
    BuildContext context,
    List<CollegeCategoryCutoffRecord> records,
  ) {
    final colors = CollegeTheme.colors(context);
    final matchedCount = controller.userMatchedRecords.length;
    final minRank = _scaleMin(records);
    final maxRank = _scaleMax(records);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colors.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AIR vs category cutoff',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lower AIR is better. Each row compares your AIR with the last cutoff rank for the selected categories.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: colors.textSub,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendChip(colors.primary, 'Cutoff rank', colors),
              _legendChip(colors.purple, 'Your AIR', colors),
              _legendChip(colors.success, 'Eligible gap', colors),
              if (matchedCount > 0)
                _highlightChip(
                  context,
                  label: 'Your profile category',
                  accent: colors.secondary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _profileCategoryBanner(context, matchedCount, colors),
          const SizedBox(height: 16),
          Text(
            'Categories being checked',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: records
                .map(
                  (record) => _checkedCategoryChip(
                    context,
                    record: record,
                    isHighlighted: controller.isUserCategoryMatch(record),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Column(
            children: List.generate(records.length, (index) {
              final record = records[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == records.length - 1 ? 0 : 14,
                ),
                child: _comparisonGraphRow(
                  context,
                  record: record,
                  minRank: minRank,
                  maxRank: maxRank,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _categoryList(
    BuildContext context,
    List<CollegeCategoryCutoffRecord> records,
  ) {
    final colors = CollegeTheme.colors(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: colors.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Category breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
              ),
              if (controller.userMatchedRecords.isNotEmpty)
                _highlightChip(
                  context,
                  label:
                      '${controller.userMatchedRecords.length} profile match${controller.userMatchedRecords.length == 1 ? '' : 'es'}',
                  accent: colors.secondary,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = records[index];
              final userRank = record.studentRank > 0
                  ? record.studentRank
                  : controller.userAir.value;
              final chanceColor = _chanceColor(record.chance, colors);
              final gap = controller.formatNumber(record.rankDifference.abs());
              final gapLabel = record.eligible
                  ? 'Ahead by $gap'
                  : 'Short by $gap';
              final isHighlighted = controller.isUserCategoryMatch(record);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? colors.softFill(
                          colors.secondary,
                          lightOpacity: 0.12,
                          darkOpacity: 0.24,
                        )
                      : colors.cardBackgroundSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHighlighted
                        ? colors.secondary.withOpacity(0.42)
                        : colors.subtleBorder,
                    width: isHighlighted ? 1.3 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.displayCategory,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMain,
                                ),
                              ),
                              if (isHighlighted) ...[
                                const SizedBox(height: 6),
                                _highlightChip(
                                  context,
                                  label: 'Matches your profile category',
                                  accent: colors.secondary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.softFill(chanceColor),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            record.chance,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chanceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _valueBadge(
                          context,
                          label: 'Cutoff rank',
                          value: controller.formatNumber(record.lastCutoffRank),
                          accent: colors.primary,
                        ),
                        _valueBadge(
                          context,
                          label: 'Your AIR',
                          value: controller.formatNumber(userRank),
                          accent: colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gapLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: record.eligible ? colors.success : colors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _comparisonGraphRow(
    BuildContext context, {
    required CollegeCategoryCutoffRecord record,
    required double minRank,
    required double maxRank,
  }) {
    final colors = CollegeTheme.colors(context);
    final userRank =
        (record.studentRank > 0 ? record.studentRank : controller.userAir.value)
            .toDouble();
    final cutoffRank = record.lastCutoffRank.toDouble();
    final isHighlighted = controller.isUserCategoryMatch(record);
    final relationText = record.eligible
        ? 'You are ahead by ${controller.formatNumber(record.rankDifference.abs())}'
        : 'You need ${controller.formatNumber(record.rankDifference.abs())} better rank';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colors.softFill(
                colors.secondary,
                lightOpacity: 0.12,
                darkOpacity: 0.24,
              )
            : colors.cardBackgroundSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? colors.secondary.withOpacity(0.42)
              : colors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  record.displayCategory,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isHighlighted) ...[
                _highlightChip(
                  context,
                  label: 'Your category',
                  accent: colors.secondary,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.softFill(
                    record.eligible ? colors.success : colors.danger,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.eligible ? 'Eligible' : 'Not eligible',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: record.eligible ? colors.success : colors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _valueBadge(
                context,
                label: 'Cutoff rank',
                value: controller.formatNumber(cutoffRank.toInt()),
                accent: colors.primary,
              ),
              _valueBadge(
                context,
                label: 'Your AIR',
                value: controller.formatNumber(userRank.toInt()),
                accent: colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _comparisonTrack(
            context,
            minRank: minRank,
            maxRank: maxRank,
            cutoffRank: cutoffRank,
            userRank: userRank,
            isEligible: record.eligible,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Better rank',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
              Text(
                'Higher rank number',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.formatNumber(minRank.toInt()),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
              ),
              Text(
                controller.formatNumber(maxRank.toInt()),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            relationText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: record.eligible ? colors.success : colors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonTrack(
    BuildContext context, {
    required double minRank,
    required double maxRank,
    required double cutoffRank,
    required double userRank,
    required bool isEligible,
  }) {
    final colors = CollegeTheme.colors(context);
    final userPosition = _normalizedPosition(userRank, minRank, maxRank);
    final cutoffPosition = _normalizedPosition(cutoffRank, minRank, maxRank);
    final segmentColor = isEligible ? colors.success : colors.danger;

    return LayoutBuilder(
      builder: (context, constraints) {
        const markerSize = 16.0;
        final usableWidth = math
            .max(constraints.maxWidth - markerSize, 0)
            .toDouble();
        final userLeft = userPosition * usableWidth;
        final cutoffLeft = cutoffPosition * usableWidth;
        final segmentLeft = math.min(userLeft, cutoffLeft) + (markerSize / 2);
        final segmentWidth = math
            .max((userLeft - cutoffLeft).abs(), 2)
            .toDouble();

        return SizedBox(
          height: 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 13,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.subtleBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: segmentLeft,
                width: segmentWidth,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: segmentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                top: 9,
                left: cutoffLeft,
                child: _trackDot(colors.primary, markerSize),
              ),
              Positioned(
                top: 9,
                left: userLeft,
                child: _trackDot(colors.purple, markerSize),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _trackDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _profileCategoryBanner(
    BuildContext context,
    int matchedCount,
    CollegeThemeColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackgroundSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.softFill(colors.secondary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_search_rounded,
              color: colors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Using profile category',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.userCategoryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  matchedCount > 0
                      ? 'Highlighted $matchedCount matching categor${matchedCount == 1 ? 'y' : 'ies'} in the graph and breakdown.'
                      : 'No exact category tag matched the current records, so all displayed categories are still compared against your AIR.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: colors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkedCategoryChip(
    BuildContext context, {
    required CollegeCategoryCutoffRecord record,
    required bool isHighlighted,
  }) {
    final colors = CollegeTheme.colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colors.softFill(
                colors.secondary,
                lightOpacity: 0.14,
                darkOpacity: 0.28,
              )
            : colors.cardBackgroundSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isHighlighted
              ? colors.secondary.withOpacity(0.42)
              : colors.subtleBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              record.displayCategory,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlighted ? colors.secondary : colors.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isHighlighted) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_circle_rounded, size: 14, color: colors.secondary),
          ],
        ],
      ),
    );
  }

  Widget _heroStat({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.82),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String label, CollegeThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: colors.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _highlightChip(
    BuildContext context, {
    required String label,
    required Color accent,
  }) {
    final colors = CollegeTheme.colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.softFill(accent, lightOpacity: 0.12, darkOpacity: 0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  Widget _valueBadge(
    BuildContext context, {
    required String label,
    required String value,
    required Color accent,
  }) {
    final colors = CollegeTheme.colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.softFill(accent),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color accent,
    bool showRetry = false,
  }) {
    final colors = CollegeTheme.colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: colors.surfaceGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.softFill(accent),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: colors.textSub,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadCutoffs(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final colors = CollegeTheme.colors(context);

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colors.cardBackgroundSoft,
      labelStyle: TextStyle(color: colors.textSub),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary),
      ),
    );
  }

  Color _chanceColor(String chance, CollegeThemeColors colors) {
    switch (chance.toLowerCase()) {
      case 'high':
        return colors.success;
      case 'moderate':
        return colors.primary;
      default:
        return colors.danger;
    }
  }

  double _scaleMax(List<CollegeCategoryCutoffRecord> records) {
    var maxRank = controller.userAir.value.toDouble();

    for (final record in records) {
      maxRank = math.max(
        maxRank,
        math.max(
          record.lastCutoffRank.toDouble(),
          record.studentRank.toDouble(),
        ),
      );
    }

    if (maxRank <= 0) {
      return 1000;
    }

    return math.max((maxRank * 1.08).ceilToDouble(), 1000);
  }

  double _scaleMin(List<CollegeCategoryCutoffRecord> records) {
    var minRank = controller.userAir.value > 0
        ? controller.userAir.value.toDouble()
        : records.first.lastCutoffRank.toDouble();

    for (final record in records) {
      final studentRank = record.studentRank > 0
          ? record.studentRank.toDouble()
          : controller.userAir.value.toDouble();
      minRank = math.min(
        minRank,
        math.min(record.lastCutoffRank.toDouble(), studentRank),
      );
    }

    if (minRank <= 1) {
      return 1;
    }

    return math.max((minRank * 0.88).floorToDouble(), 1);
  }

  double _normalizedPosition(double value, double minRank, double maxRank) {
    if (maxRank <= minRank) {
      return 0;
    }

    final normalized = (value - minRank) / (maxRank - minRank);
    return normalized.clamp(0.0, 1.0).toDouble();
  }
}
