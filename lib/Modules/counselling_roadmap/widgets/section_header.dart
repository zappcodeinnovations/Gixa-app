import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/counselling_state_model.dart';
import '../widgets/shared_widgets.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = CounsellingUi.textPrimary(isDark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: GixaColors.pink.withOpacity(isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) =>
                GixaColors.primaryGradient.createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
