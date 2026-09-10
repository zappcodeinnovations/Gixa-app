import 'dart:io';

import 'package:Gixa/Modules/ticket/view/ticket_details.dart';
import 'package:Gixa/services/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Gixa/services/app_verification_controller.dart';

import '../controller/ticket_controller.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

// ─────────────────────────────────────────────
//  GIXA BRAND TOKENS
// ─────────────────────────────────────────────
class GixaColors {
  static const Color orange = Color(0xFFFF6B1A);
  static const Color rose = Color(0xFFE8416B);
  static const Color magenta = Color(0xFFC4207A);

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, rose, magenta],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient brandVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orange, rose, magenta],
  );

  static Color get brandSoft => orange.withOpacity(0.10);
  static Color get roseSoft => rose.withOpacity(0.10);

  // Status
  static const Color statusOpen = Color(0xFFFF6B1A);
  static const Color statusPending = Color(0xFFE8416B);
  static const Color statusProgress = Color(0xFF7C3AED);
  static const Color statusClosed = Color(0xFF16A34A);
}

// ─────────────────────────────────────────────
//  GRADIENT HELPERS
// ─────────────────────────────────────────────
class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => GixaColors.brand.createShader(
      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
    ),
    child: Text(text, style: style),
  );
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon(this.icon, {this.size = 22});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (b) =>
        GixaColors.brand.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
    child: Icon(icon, size: size, color: Colors.white),
  );
}

// Solid gradient box button
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          gradient: isLoading ? null : GixaColors.brand,
          color: isLoading ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: GixaColors.rose.withOpacity(0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN VIEW
// ─────────────────────────────────────────────
class CreateTicketView extends StatefulWidget {
  CreateTicketView({super.key});

  @override
  State<CreateTicketView> createState() => _CreateTicketViewState();
}

class _CreateTicketViewState extends State<CreateTicketView> {
  final TicketController controller = Get.put(TicketController());
  final ScrollController _scrollController = ScrollController();
  final FocusNode subjectFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  void _focusToField(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);

    Scrollable.ensureVisible(
      focusNode.context!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  List<String> get subjectOptions {
    final options = [
      TicketController.billingPaymentOption,
      TicketController.airRankUpdateOption,
      TicketController.categoryUpdateOption,
      TicketController.neetScoreUpdateOption,
      TicketController.courseChangeOption,
      TicketController.technicalIssueOption,
      TicketController.appBugOption,
      TicketController.subscriptionIssueOption,
      TicketController.predictionIssueOption,
      TicketController.othersOption,
    ];

    if (AppVerificationController.to.hideSubscriptionUi) {
      options.remove(TicketController.subscriptionIssueOption);
    }

    return options;
  }

  final TextEditingController subjectController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  Future<void> _pickAttachment(BuildContext context) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                _BottomSheetTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Pick from Gallery',
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                _BottomSheetTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take a Photo',
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (action == null) return;
    try {
      if (action == 'gallery') {
        final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
          imageQuality: 25,
          maxWidth: 1280,
          maxHeight: 1280,
        );
        if (pickedFiles != null && pickedFiles.isNotEmpty) {
          List<File> validFiles = [];
          for (final pickedFile in pickedFiles) {
            File file;
            if (pickedFile.path.isNotEmpty &&
                await File(pickedFile.path).exists()) {
              file = File(pickedFile.path);
            } else {
              final tempDir = Directory.systemTemp;
              final fileName =
                  DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
              final tempPath = '${tempDir.path}/$fileName';
              await pickedFile.saveTo(tempPath);
              file = File(tempPath);
            }
            final fileSize = await file.length();
            if (fileSize > 500 * 1024) {
              AppSnackbar.show(
                'Error',
                'File ${file.path.split('/').last.split('\\').last} is too large. Please upload files smaller than 500KB.',
              );
              continue;
            }
            validFiles.add(file);
          }
          if (validFiles.isNotEmpty) {
            controller.addAttachments(validFiles);
          }
        }
      } else if (action == 'camera') {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 25,
          maxWidth: 1280,
          maxHeight: 1280,
        );
        if (pickedFile != null) {
          File file;
          if (pickedFile.path.isNotEmpty &&
              await File(pickedFile.path).exists()) {
            file = File(pickedFile.path);
          } else {
            final tempDir = Directory.systemTemp;
            final fileName =
                DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
            final tempPath = '${tempDir.path}/$fileName';
            await pickedFile.saveTo(tempPath);
            file = File(tempPath);
          }
          final fileSize = await file.length();
          if (fileSize > 500 * 1024) {
            AppSnackbar.show(
              'Error',
              'File size is too large. Please upload a file smaller than 500KB.',
            );
            return;
          }
          controller.addAttachment(file);
        }
      }
    } catch (e) {
      AppSnackbar.show('Error', 'Failed to pick file');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0A12) : const Color(0xFFF4EFF7);
    final surfaceColor = isDark ? const Color(0xFF1C1520) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A0A12);
    final subTextColor = isDark
        ? const Color(0xFF9E7A90)
        : const Color(0xFF6B4560);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : GixaColors.magenta.withOpacity(0.12);
    final inputBg = isDark ? const Color(0xFF261828) : const Color(0xFFF9F5FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(textColor, surfaceColor, borderColor),
      body: Obx(() {
        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HeroBanner()),
            SliverToBoxAdapter(
              child: _StatsRow(
                controller: controller,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'New Ticket',
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() => _CreateFormCard(
                controller: controller,
                subjectController: subjectController,
                subjectFocus: subjectFocus,
                descriptionFocus: descriptionFocus,
                descriptionController: descriptionController,
                subjectOptions: subjectOptions,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textColor: textColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
                inputBg: inputBg,
                onPickAttachment: () => _pickAttachment(context),
              )),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Previous Tickets',
                trailing: controller.tickets.length > 3
                    ? GestureDetector(
                        onTap: () {
                          controller.showAllTickets.toggle();
                        },
                        child: _GradientText(
                          controller.showAllTickets.value ? 'Show less' : 'See all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              ),
            ),
            _buildTicketList(
              isDark,
              surfaceColor,
              textColor,
              subTextColor,
              borderColor,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(
    Color textColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        color: surfaceColor,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: GixaColors.brandSoft,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: borderColor),
                    ),
                    child: const _GradientIcon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Support Tickets',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: GixaColors.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Gixa',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList(
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    if (controller.isListLoading.value) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(GixaColors.rose),
          ),
        ),
      );
    }

    if (controller.tickets.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyTickets(
          subTextColor: subTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
      );
    }

    final itemCount = controller.showAllTickets.value
        ? controller.tickets.length
        : (controller.tickets.length > 3 ? 3 : controller.tickets.length);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ticket = controller.tickets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TicketCard(
              ticket: ticket,
              isDark: isDark,
              surfaceColor: surfaceColor,
              textColor: textColor,
              subTextColor: subTextColor,
              borderColor: borderColor,
              onTap: () async {
                final ok = await controller.fetchTicketDetails(ticket.id);
                if (ok) {
                  Get.to(() => TicketDetailsView());
                } else {
                  AppSnackbar.show(
                    'Error',
                    controller.errorMessage.value.isEmpty
                        ? 'Failed to load ticket details'
                        : controller.errorMessage.value,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          );
        }, childCount: itemCount),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HERO BANNER
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 140,
      decoration: BoxDecoration(
        gradient: GixaColors.brand,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 50,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '24/7 Support',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'How can we help you?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our support team will contact you within 24 hours regarding this ticket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.82),
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

// ─────────────────────────────────────────────
//  STATS ROW
// ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.controller,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
  });

  final TicketController controller;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final open = controller.tickets
        .where((t) => t.status.toLowerCase() == 'open')
        .length;
    final inProgress = controller.tickets
        .where(
          (t) =>
              ['in_progress', 'in progress'].contains(t.status.toLowerCase()),
        )
        .length;
    final closed = controller.tickets
        .where((t) => t.status.toLowerCase() == 'closed')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Open',
            value: open,
            color: GixaColors.statusOpen,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'In Progress',
            value: inProgress,
            color: GixaColors.statusProgress,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Resolved',
            value: closed,
            color: GixaColors.statusClosed,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surfaceColor,
    required this.borderColor,
  });
  final String label;
  final int value;
  final Color color;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => GixaColors.brand.createShader(
                Rect.fromLTWH(0, 0, b.width, b.height),
              ),
              child: Text(
                '$value',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.padding});
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A0A12);
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CREATE FORM CARD
// ─────────────────────────────────────────────
class _CreateFormCard extends StatelessWidget {
  const _CreateFormCard({
    required this.controller,
    required this.subjectController,
    required this.descriptionController,
    required this.subjectOptions,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.inputBg,
    required this.onPickAttachment,
    required this.subjectFocus,
    required this.descriptionFocus,
  });

  final TicketController controller;
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final List<String> subjectOptions;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final Color inputBg;
  final VoidCallback onPickAttachment;
  final FocusNode subjectFocus;
  final FocusNode descriptionFocus;

  InputDecoration _inputDeco({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: subTextColor,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: subTextColor.withOpacity(0.6),
      ),
      filled: true,
      fillColor: inputBg,
      prefixIcon: prefixIcon != null
          ? _GradientIcon(prefixIcon, size: 18)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GixaColors.rose, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: GixaColors.magenta.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: GixaColors.brand,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Ticket',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'We\'ll get back to you shortly',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Form body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Dropdown
                _FieldLabel(label: 'Subject', color: subTextColor),
                const SizedBox(height: 6),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: controller.selectedSubjectOption.value,
                        dropdownColor: surfaceColor,
                        icon: const _GradientIcon(
                          Icons.expand_more_rounded,
                          size: 20,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _inputDeco(label: 'Select subject'),
                        items: subjectOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(opt),
                          );
                        }).toList(),
                        onChanged: (value) {
                          controller.setSubjectOption(value);

                          controller.subjectError.value = '';

                          if (controller.isOtherSubjectSelected) {
                            controller.subject.value = '';
                          } else {
                            controller.subject.value = value ?? '';

                            subjectController.clear();
                          }
                        },
                      ),
                      if (controller.subjectError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            controller.subjectError.value,
                            style: TextStyle(color: Colors.red, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),

                // Other subject input
                Obx(() {
                  if (!controller.isOtherSubjectSelected) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const SizedBox(height: 14),

                      _FieldLabel(label: 'Specify Issue', color: subTextColor),

                      const SizedBox(height: 6),

                      TextField(
                        controller: subjectController,
                        focusNode: subjectFocus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textColor,
                        ),

                        decoration: _inputDeco(
                          label: 'Enter Issue',
                          hint: 'Type your issue subject',
                          prefixIcon: Icons.edit_note_rounded,
                        ),

                        onChanged: (v) {
                          controller.subject.value = v.trim();

                          controller.subjectError.value = '';
                        },
                      ),
                      if (controller.subjectError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            controller.subjectError.value,
                            style: const TextStyle(color: Colors.red, fontSize: 11),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 14),

                // Attachment
                _FieldLabel(
                  label: 'Attachment (optional)',
                  color: subTextColor,
                ),
                const SizedBox(height: 6),
                _AttachmentSection(
                  controller: controller,
                  inputBg: inputBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onPick: onPickAttachment,
                ),

                const SizedBox(height: 14),

                // Description
                _FieldLabel(label: 'Description', color: subTextColor),
                const SizedBox(height: 6),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: descriptionController,
                        focusNode: descriptionFocus,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textColor,
                        ),
                        decoration: _inputDeco(
                          label: 'Describe the issue',
                          hint: 'Provide as much detail as possible…',
                          prefixIcon: Icons.description_outlined,
                        ).copyWith(alignLabelWithHint: true),
                        onChanged: (v) => controller.description.value = v,
                      ),
                      if (controller.descriptionError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            controller.descriptionError.value,
                            style: TextStyle(color: Colors.red, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Submit
                Obx(
                  () => _GradientButton(
                    label: controller.isLoading.value
                        ? 'Submitting...'
                        : 'Submit Ticket',

                    isLoading: controller.isLoading.value,

                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            AuthGuard.checkAccess(
                              onAllowed: () async {
                                FocusScope.of(context).unfocus();

                                final didCreate = await controller
                                    .createTicket();

                                if (didCreate) {
                                  /// CLEAR UI CONTROLLERS
                                  subjectController.clear();

                                  descriptionController.clear();

                                  /// SUCCESS BOTTOM SHEET
                                  if (context.mounted) {
                                    showModalBottomSheet(
                                      context: context,

                                      isScrollControlled: true,

                                      backgroundColor: Colors.transparent,

                                      builder: (_) {
                                        final isDark =
                                            Theme.of(context).brightness ==
                                            Brightness.dark;

                                        final bgColor = isDark
                                            ? const Color(0xFF1C1520)
                                            : Colors.white;

                                        final textColor = isDark
                                            ? Colors.white
                                            : const Color(0xFF1A0A12);

                                        final subTextColor = isDark
                                            ? Colors.white70
                                            : Colors.grey;

                                        return Container(
                                          padding: const EdgeInsets.all(24),

                                          decoration: BoxDecoration(
                                            color: bgColor,

                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(32),
                                                ),
                                          ),

                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,

                                            children: [
                                              Container(
                                                width: 70,
                                                height: 70,

                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(.12),

                                                  shape: BoxShape.circle,
                                                ),

                                                child: const Icon(
                                                  Icons.check_circle,

                                                  color: Colors.green,

                                                  size: 42,
                                                ),
                                              ),

                                              const SizedBox(height: 20),

                                              Text(
                                                "Ticket Submitted",

                                                style: TextStyle(
                                                  fontSize: 22,

                                                  fontWeight: FontWeight.w800,

                                                  color: textColor,
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              Text(
                                                "Your support ticket has been submitted successfully. Our team will contact you soon.",

                                                textAlign: TextAlign.center,

                                                style: TextStyle(
                                                  color: subTextColor,

                                                  height: 1.5,

                                                  fontSize: 14,
                                                ),
                                              ),

                                              const SizedBox(height: 26),

                                              SizedBox(
                                                width: double.infinity,

                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFE8416B),

                                                    elevation: 0,

                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),

                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                    ),
                                                  ),

                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },

                                                  child: const Text(
                                                    "Done",

                                                    style: TextStyle(
                                                      color: Colors.white,

                                                      fontWeight:
                                                          FontWeight.w700,

                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              SizedBox(
                                                height: MediaQuery.of(
                                                  context,
                                                ).padding.bottom,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                }
                              },
                            );
                          },
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ATTACHMENT SECTION
// ─────────────────────────────────────────────
class _AttachmentSection extends StatelessWidget {
  const _AttachmentSection({
    required this.controller,
    required this.inputBg,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.onPick,
  });

  final TicketController controller;
  final Color inputBg;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final files = controller.selectedAttachments;
      if (files.isEmpty) {
        return GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: GixaColors.magenta.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: GixaColors.brand,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Screenshot(s)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: GixaColors.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Upload',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          ...files.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;
            final isImage = [
              '.jpg',
              '.jpeg',
              '.png',
              '.gif',
              '.bmp',
              '.webp',
            ].any((ext) => file.path.toLowerCase().endsWith(ext));
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GixaColors.rose.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: GixaColors.brand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            file.path.split('/').last.split('\\').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.removeAttachmentAt(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: GixaColors.rose.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: GixaColors.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isImage)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      child: Image.file(
                        file,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          GestureDetector(
            onTap: onPick,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: GixaColors.magenta.withOpacity(0.18),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: GixaColors.rose, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Add More',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GixaColors.rose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets({
    required this.subTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });
  final Color subTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GixaColors.orange.withOpacity(0.12),
                  GixaColors.magenta.withOpacity(0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const _GradientIcon(
              Icons.confirmation_number_outlined,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tickets yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Submit your first ticket above to get support',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: subTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TICKET CARD
// ─────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.onTap,
  });

  final dynamic ticket;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return GixaColors.statusOpen;
      case 'closed':
        return GixaColors.statusClosed;
      case 'pending':
        return GixaColors.statusPending;
      case 'in_progress':
      case 'in progress':
        return GixaColors.statusProgress;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.support_agent_rounded;
      case 'closed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'in_progress':
      case 'in progress':
        return Icons.sync_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      default:
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ticket.status as String;
    final color = _statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.12), width: 1.2),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// STATUS ICON
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.18),
                        color.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.15)),
                  ),
                  child: Icon(_statusIcon(status), color: color, size: 24),
                ),

                const SizedBox(width: 14),

                /// CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: color.withOpacity(0.18),
                              ),
                            ),
                            child: Text(
                              _statusLabel(status).toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          if ((ticket.ticketNumber as String).isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '#${ticket.ticketNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: subTextColor.withOpacity(0.5),
                ),
              ],
            ),

            // const SizedBox(height: 16),

            // /// SUPPORT MESSAGE BOX
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(14),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         GixaColors.orange.withOpacity(0.08),
            //         GixaColors.rose.withOpacity(0.05),
            //       ],
            //     ),
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(color: GixaColors.orange.withOpacity(0.10)),
            //   ),
            //   child: Row(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Container(
            //         width: 34,
            //         height: 34,
            //         decoration: BoxDecoration(
            //           gradient: GixaColors.brand,
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: const Icon(
            //           Icons.support_agent_rounded,
            //           color: Colors.white,
            //           size: 18,
            //         ),
            //       ),

            //       // const SizedBox(width: 12),

            //       // Expanded(
            //       //   child: Column(
            //       //     crossAxisAlignment: CrossAxisAlignment.start,
            //       //     children: [
            //       //       Text(
            //       //         "Support Team Update",
            //       //         style: GoogleFonts.plusJakartaSans(
            //       //           fontSize: 12,
            //       //           fontWeight: FontWeight.w700,
            //       //           color: textColor,
            //       //         ),
            //       //       ),

            //       //       const SizedBox(height: 4),

            //       //       Text(
            //       //         "Our support team will contact you within 24 hours regarding this ticket.",
            //       //         style: GoogleFonts.plusJakartaSans(
            //       //           fontSize: 12,
            //       //           height: 1.5,
            //       //           fontWeight: FontWeight.w500,
            //       //           color: subTextColor,
            //       //         ),
            //       //       ),
            //       //     ],
            //       //   ),
            //       // ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM SHEET TILE
// ─────────────────────────────────────────────
class _BottomSheetTile extends StatelessWidget {
  const _BottomSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: GixaColors.brand,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
