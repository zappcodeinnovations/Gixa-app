import 'package:Gixa/Modules/Collage/model/collage_model.dart';
import 'package:Gixa/Modules/CollageDetails/model/collage_details_model.dart';
import 'package:Gixa/Modules/CollageDetails/widgets/collage_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:get/get.dart';

class CoursesSection extends StatelessWidget {
  final CollegeDetail college;

  const CoursesSection({super.key, required this.college});

  @override
  Widget build(BuildContext context) {
    final ugList = college.courses.ug;
    final pgList = college.courses.pg;

    if (ugList.isEmpty && pgList.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = CollegeTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: colors.warmGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              "Academics",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: colors.surfaceGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ugList.isNotEmpty)
                _CourseCategory(
                  title: "Undergraduate (UG)",
                  items: ugList.map<String>((e) => e.name.toString()).toSet().toList(),
                  baseColor: colors.primary,
                  colors: colors,
                ),
              if (ugList.isNotEmpty && pgList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Divider(
                    color: colors.subtleBorder,
                    thickness: 1,
                    height: 1,
                  ),
                ),
              if (pgList.isNotEmpty)
                _PgCourseTreeCategory(
                  title: "Postgraduate (PG)",
                  pgList: pgList,
                  baseColor: colors.purple,
                  colors: colors,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseCategory extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color baseColor;
  final CollegeThemeColors colors;

  const _CourseCategory({
    required this.title,
    required this.items,
    required this.baseColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 16,
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [baseColor, baseColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSub,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: items.map(_buildModernChip).toList(),
        ),
      ],
    );
  }

  Widget _buildModernChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.softFill(baseColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withOpacity(colors.isDark ? 0.32 : 0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.chipText(baseColor),
          height: 1.2,
        ),
      ),
    );
  }
}

class _PgCourseTreeCategory extends StatelessWidget {
  final String title;
  final List<PgCourse> pgList;
  final Color baseColor;
  final CollegeThemeColors colors;

  const _PgCourseTreeCategory({
    required this.title,
    required this.pgList,
    required this.baseColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (pgList.isEmpty) return const SizedBox.shrink();

    // Grouping: Course Name -> Specialty Type -> List<Specialty Name>
    final grouped = <String, Map<String, List<String>>>{};
    for (final pg in pgList) {
      final cName = pg.courseName;
      var sType = pg.specialtyType?.trim();
      if (sType == null || sType.isEmpty || sType.toLowerCase() == 'null') {
        sType = 'General';
      } else {
        sType = sType.replaceAll('_', ' ');
      }
      var sName = pg.specialtyName.trim();

      grouped.putIfAbsent(cName, () => {});
      grouped[cName]!.putIfAbsent(sType, () => []);
      if (sName.isNotEmpty && sName.toLowerCase() != 'null') {
        grouped[cName]![sType]!.add(sName);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 16,
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [baseColor, baseColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSub,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...grouped.entries.map((courseEntry) {
          final courseName = courseEntry.key;
          final typeMap = courseEntry.value;

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                courseName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textMain,
                ),
              ),
              children: typeMap.entries.map((typeEntry) {
                final sType = typeEntry.key;
                final specialties = typeEntry.value.toSet().toList();

                if (specialties.isEmpty) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 16.0),
                    dense: true,
                    title: Text(
                      sType,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textSub,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        sType,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textSub,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, bottom: 12.0, top: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: specialties.map(_buildModernChip).toList(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildModernChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.softFill(baseColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withOpacity(colors.isDark ? 0.32 : 0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.chipText(baseColor),
          height: 1.2,
        ),
      ),
    );
  }
}
