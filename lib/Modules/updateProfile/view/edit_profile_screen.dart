import 'dart:io';

import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/updateProfile/controller/update_profile_controller.dart';
import 'package:Gixa/services/app_verification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class _G {
  static const orange = Color(0xFFFF6B35);
  static const pink = Color(0xFFE91E8C);
  static const purple = Color(0xFF9C27B0);
  static const indigo = Color(0xFF3F51B5);
  static const blue = Color(0xFF2196F3);

  static const gradient = LinearGradient(
    colors: [orange, pink, purple, indigo, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent used for fields / icons (warm orange-pink)
  static const accent = Color(0xFFE91E8C);
  static const accentSoft = Color(0xFFFF6B35);
}

class EditProfileView extends StatelessWidget {
  EditProfileView({super.key});

  final _formKey = GlobalKey<FormState>();
  final UpdateProfileController controller =
      Get.find<UpdateProfileController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final profileController = Get.find<ProfileController>();

        await profileController.refreshProfile();

        await profileController.refreshRankEditAccess(
          forceRefreshSubscription: true,
        );
      } catch (_) {}
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D0B14)
            : const Color(0xFFF8F4FF),
        extendBodyBehindAppBar: true,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _GlassButton(
              isDark: isDark,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onTap: () => Get.back(),
            ),
          ),
          title: ShaderMask(
            shaderCallback: (b) => _G.gradient.createShader(b),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
        ),

        body: Obx(
          () => Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            Color(0xFF0D0B14),
                            Color(0xFF130E1E),
                            Color(0xFF0F1020),
                          ]
                        : const [
                            Color(0xFFFDF6FF),
                            Color(0xFFF5EEFF),
                            Color(0xFFEEF4FF),
                          ],
                  ),
                ),
              ),

              Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                  children: [
                    // Space for app bar
                    const SizedBox(height: 96),

                    _buildHeroHeader(isDark),
                    const SizedBox(height: 14),
                    _buildRemoveImageButton(isDark),
                    const SizedBox(height: 14),

                    _buildSection(
                      isDark: isDark,
                      title: 'Personal Information',
                      subtitle: 'Your personal profile details',
                      icon: Icons.person_outline_rounded,
                      gradientStart: _G.orange,
                      gradientEnd: _G.pink,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                'First Name',
                                controller.firstNameCtrl,
                                Icons.person_outline_rounded,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                'Last Name',
                                controller.lastNameCtrl,
                                Icons.account_circle_outlined,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        _field(
                          'Email Address',
                          controller.emailCtrl,
                          Icons.mail_outline_rounded,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _field(
                          'Address',
                          controller.addressCtrl,
                          Icons.location_on_outlined,
                          isDark: isDark,
                          maxLines: 3,
                        ),
                        GestureDetector(
                          onTap: () => _pickDob(context),
                          child: AbsorbPointer(
                            child: _field(
                              'Date of Birth',
                              controller.dobCtrl,
                              Icons.calendar_month_rounded,
                              isDark: isDark,
                              readOnly: true,
                            ),
                          ),
                        ),
                        Obx(() => _buildGenderDropdown(isDark)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      isDark: isDark,
                      title: 'Academic Details',
                      subtitle: 'Examination and academic info',
                      icon: Icons.school_outlined,
                      gradientStart: _G.pink,
                      gradientEnd: _G.purple,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                '10th %',
                                controller.tenthCtrl,
                                Icons.looks_one_outlined,
                                isDark: isDark,
                                suffix: '%',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                '12th %',
                                controller.twelthCtrl,
                                Icons.looks_two_outlined,
                                isDark: isDark,
                                suffix: '%',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        _field(
                          '12th PCB',
                          controller.twelthPcbCtrl,
                          Icons.biotech_outlined,
                          isDark: isDark,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        Obx(() {
                          final profileController =
                              Get.find<ProfileController>();

                          final isLocked = profileController.isRankLocked;

                          if (AppVerificationController.to.hideSubscriptionUi) {
                            return const SizedBox.shrink();
                          }

                          return GestureDetector(
                            onTap: () {
                              if (isLocked) {
                                Get.toNamed('/subscription');
                              }
                            },

                            child: _field(
                              'All India Rank',
                              controller.airCtrl,
                              Icons.workspace_premium_rounded,

                              isDark: isDark,

                              keyboardType: TextInputType.number,

                              /// ✅ MAIN CONDITION
                              readOnly: isLocked,

                              helperText: isLocked
                                  ? '🔒 Buy subscription to edit AIR rank'
                                  : '✏️ AIR rank editable',

                              suffixIcon: isLocked
                                  ? Icons.lock_rounded
                                  : Icons.edit_rounded,

                              lockedField: isLocked,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      isDark: isDark,
                      title: 'Other Details',
                      subtitle: 'Additional information',
                      icon: Icons.info_outline_rounded,
                      gradientStart: _G.purple,
                      gradientEnd: _G.indigo,
                      children: [
                        _field(
                          'Nationality',
                          controller.nationalityCtrl,
                          Icons.public_rounded,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSection(
                      isDark: isDark,
                      title: 'Counselling Details',
                      subtitle: 'Preferences for recommendations',
                      icon: Icons.assignment_outlined,
                      gradientStart: _G.indigo,
                      gradientEnd: _G.blue,
                      children: [
                        _field(
                          'Course',
                          controller.courseCtrl,
                          Icons.menu_book_rounded,
                          isDark: isDark,
                        ),
                        _field(
                          'State',
                          controller.stateCtrl,
                          Icons.map_outlined,
                          isDark: isDark,
                          readOnly: true,
                          helperText: 'State cannot be changed',
                          suffixIcon: Icons.lock_rounded,
                          lockedField: true,
                        ),
                        if (Get.find<ProfileController>().specialtyCtrl.text.isNotEmpty)
                          _field(
                            'Specialty',
                            Get.find<ProfileController>().specialtyCtrl,
                            Icons.local_hospital_rounded,
                            isDark: isDark,
                            readOnly: true,
                            helperText: 'Specialty cannot be changed',
                            suffixIcon: Icons.lock_rounded,
                            lockedField: true,
                          ),
                        _field(
                          'Category',
                          controller.categoryCtrl,
                          Icons.category_rounded,
                          isDark: isDark,
                          readOnly: true,
                          helperText: 'Category cannot be changed',
                          suffixIcon: Icons.lock_rounded,
                          lockedField: true,
                        ),
                        _field(
                          'NEET Score',
                          controller.neetScoreCtrl,
                          Icons.monitor_heart_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          helperText: 'NEET score cannot be changed',
                          suffixIcon: Icons.lock_rounded,
                          lockedField: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSupportTicketCard(isDark),

                    // const SizedBox(height: 10),
                  ],
                ),
              ),

              // Loading overlay
              if (controller.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(_G.pink),
                    ),
                  ),
                ),
            ],
          ),
        ),

        bottomNavigationBar: _buildSaveBar(),
      ),
    );
  }

  Widget _buildSupportTicketCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1428) : Colors.white,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.orange.withOpacity(0.18)),

        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),

            blurRadius: 18,

            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF6B35)],
                  ),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.support_agent_rounded,
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
                      'Counselling Support',

                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,

                        color: isDark ? Colors.white : const Color(0xFF1A1428),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Need help updating counselling details?',

                      style: GoogleFonts.nunito(
                        fontSize: 11.5,

                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'To update AIR Rank, Category, NEET Score, or Course details after confirmation, please raise a support ticket. Our support team will verify and update your details.',

            style: GoogleFonts.nunito(
              fontSize: 13.5,
              height: 1.6,

              fontWeight: FontWeight.w600,

              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/ticket');
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),

                elevation: 0,

                padding: const EdgeInsets.symmetric(vertical: 14),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              icon: const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.white,
                size: 18,
              ),

              label: Text(
                'Raise Support Ticket',

                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveImageButton(bool isDark) {
    return Obx(() {
      final hasNetworkImage =
          Get.find<ProfileController>()
              .profile
              .value
              ?.profilePictureUrl
              ?.isNotEmpty ==
          true;

      final hasLocalImage = controller.profileImage.value != null;

      if (!hasNetworkImage && !hasLocalImage) {
        return const SizedBox.shrink();
      }

      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),

          onPressed: () {
            Get.dialog(
              AlertDialog(
                backgroundColor: isDark
                    ? const Color(0xFF1A1428)
                    : Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                title: Text(
                  'Remove Image?',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                ),

                content: Text(
                  'Are you sure you want to remove your profile image?',
                  style: GoogleFonts.nunito(),
                ),

                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),

                    onPressed: () async {
                      Get.back();

                      await controller.removeProfileImage();
                    },

                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },

          icon: const Icon(Icons.delete_outline_rounded, size: 18),

          label: Text(
            'Remove Profile Image',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
      );
    });
  }

  // ── Hero header ──────────────────────────────────────────────
  Widget _buildHeroHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: _G.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _G.pink.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'PROFILE SETTINGS',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: .8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Edit Your\nProfile',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your profile updated for better\npredictions & college recommendations.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2.5,
                    ),
                  ),
                  child: Obx(
                    () {
                      final localImg = controller.profileImage.value;
                      final networkUrl = Get.find<ProfileController>().profile.value?.profilePictureUrl;
                      final hasNetworkImg = networkUrl?.isNotEmpty == true;

                      return CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.22),
                        backgroundImage: localImg != null
                            ? FileImage(localImg) as ImageProvider
                            : (hasNetworkImg ? NetworkImage(networkUrl!) : null),
                        child: localImg == null && !hasNetworkImg
                            ? const Icon(
                                Icons.person,
                                size: 46,
                                color: Colors.white,
                              )
                            : null,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: _G.pink,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ─────────────────────────────────────────────
  Widget _buildSection({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color gradientStart,
    required Color gradientEnd,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1428) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(isDark ? 0.08 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: gradientStart.withOpacity(isDark ? 0.15 : 0.10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1428),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thin gradient divider
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientStart.withOpacity(0.5),
                  gradientEnd.withOpacity(0.0),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),

          ...children,
        ],
      ),
    );
  }

  // ── Gender dropdown ──────────────────────────────────────────
  Widget _buildGenderDropdown(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: DropdownButtonFormField<String>(
        value: controller.genderValue.value.isEmpty
            ? null
            : controller.genderValue.value,

        dropdownColor: isDark ? const Color(0xFF2A1E40) : Colors.white,

        style: GoogleFonts.nunito(
          fontSize: 14,

          color: isDark ? Colors.white : const Color(0xFF1A1428),

          fontWeight: FontWeight.w600,
        ),

        items: ['Male', 'Female', 'Other']
            .map(
              (gender) =>
                  DropdownMenuItem<String>(value: gender, child: Text(gender)),
            )
            .toList(),

        onChanged: (value) {
          controller.genderValue.value = value ?? '';
        },

        decoration: _fieldDecoration('Gender', Icons.wc_rounded, isDark),
      ),
    );
  }

  // ── Text field ───────────────────────────────────────────────
  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    required bool isDark,
    bool readOnly = false,
    String? suffix,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    IconData? suffixIcon,
    bool lockedField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: () {
          if (!readOnly && (ctrl.text == '0' || ctrl.text == '0.0')) {
            ctrl.clear();
          }
        },
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A1428),
        ),
        inputFormatters: label.contains('%') || label.contains('PCB')
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : label.contains('Rank') || label.contains('Score')
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration:
            _fieldDecoration(
              label,
              icon,
              isDark,
              lockedField: lockedField,
            ).copyWith(
              suffixText: suffix,
              helperText: helperText,
              helperStyle: GoogleFonts.nunito(
                fontSize: 10.5,
                color: lockedField ? _G.orange : Colors.grey,
              ),
              suffixIcon: suffixIcon == null
                  ? null
                  : Icon(
                      suffixIcon,
                      color: lockedField ? Colors.grey : _G.pink,
                      size: 18,
                    ),
            ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label,
    IconData icon,
    bool isDark, {
    bool lockedField = false,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: GoogleFonts.nunito(
        fontSize: 13,
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
      prefixIcon: ShaderMask(
        shaderCallback: (b) => _G.gradient.createShader(b),
        blendMode: BlendMode.srcIn,
        child: Icon(icon, size: 20),
      ),
      filled: true,
      fillColor: lockedField
          ? (isDark ? const Color(0xFF1A1825) : const Color(0xFFF1F1F1))
          : (isDark ? const Color(0xFF231A35) : const Color(0xFFF9F4FF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: lockedField
              ? Colors.grey.withOpacity(0.25)
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : _G.purple.withOpacity(0.10)),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _G.pink, width: 1.6),
      ),
    );
  }

  // ── Save bar ─────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Obx(
        () => Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: _G.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _G.pink.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _onSavePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _onSavePressed() {
    if (controller.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;
    controller.updateProfile();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: _G.pink,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (croppedFile != null) {
        controller.setProfileImage(File(croppedFile.path));
      }
    }
  }

  Future<void> _pickDob(BuildContext context) async {
    DateTime initialDate = DateTime(2000);
    if (controller.dobCtrl.text.isNotEmpty) {
      final parsed = DateTime.tryParse(controller.dobCtrl.text);
      if (parsed != null) initialDate = parsed;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _G.pink,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.dobCtrl.text = picked.toIso8601String().split('T').first;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Glass icon button for app bar
// ─────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({
    required this.isDark,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: child,
      ),
    );
  }
}
