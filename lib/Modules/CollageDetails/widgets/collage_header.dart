import 'package:Gixa/Modules/CollageDetails/model/collage_details_model.dart';
import 'package:Gixa/Modules/CollageDetails/widgets/collage_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CollegeHeaderSection extends StatelessWidget {
  final CollegeDetail college;

  const CollegeHeaderSection({super.key, required this.college});

  @override
  Widget build(BuildContext context) {
    final colors = CollegeTheme.colors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: colors.surfaceGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: colors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.softFill(colors.primary, lightOpacity: 0.10, darkOpacity: 0.20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "College profile",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              college.name,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.softFill(colors.pink, lightOpacity: 0.10, darkOpacity: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colors.pink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    college.address.isNotEmpty
                        ? (college.address.toLowerCase().contains(college.state.name.toLowerCase())
                            ? college.address
                            : "${college.address}, ${college.state.name}")
                        : "${college.state.name}, India",
                    style: GoogleFonts.inter(
                      color: colors.textSub,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTag(
                    text: college.instituteType.name,
                    baseColor: colors.secondary,
                    icon: Icons.account_balance_rounded,
                    colors: colors,
                  ),
                  if (college.yearEstablished != null &&
                      college.yearEstablished.toString().trim().isNotEmpty &&
                      college.yearEstablished.toString().trim().toLowerCase() != 'none' &&
                      college.yearEstablished.toString().trim().toLowerCase() != 'null') ...[
                    const SizedBox(width: 10),
                    _buildTag(
                      text: "Est. ${college.yearEstablished}",
                      baseColor: colors.primary,
                      icon: Icons.history_rounded,
                      colors: colors,
                    ),
                  ],
                  const SizedBox(width: 10),
                  // _buildTag(
                  //   text: "Gixa recommended",
                  //   baseColor: colors.purple,
                  //   icon: Icons.auto_awesome_rounded,
                  //   colors: colors,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color baseColor,
    required IconData icon,
    required CollegeThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.softFill(baseColor, lightOpacity: 0.10, darkOpacity: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withOpacity(colors.isDark ? 0.34 : 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.chipText(baseColor),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
