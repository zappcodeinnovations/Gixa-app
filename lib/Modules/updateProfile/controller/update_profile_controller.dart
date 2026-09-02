import 'dart:io';

import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/Profile/models/profile_model.dart';
import 'package:Gixa/routes/app_routes.dart';
import 'package:Gixa/services/profile_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Gixa/Modules/updateProfile/model/update_profile.dart';
import 'package:Gixa/services/update_profile_services.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:Gixa/utils/fcm_utils.dart';

class UpdateProfileController extends GetxController {
  /// ðŸ”„ UI State
  final RxBool isLoading = false.obs;
  final RxBool isProfileCompleted = false.obs;

  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController neetCtrl = TextEditingController();
  final TextEditingController tenthCtrl = TextEditingController();
  final TextEditingController twelthCtrl = TextEditingController();
  final TextEditingController twelthPcbCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();
  final TextEditingController casteCtrl = TextEditingController();
  final TextEditingController nationalityCtrl = TextEditingController();
  final RxString genderValue = ''.obs;
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController airCtrl = TextEditingController();
  final TextEditingController courseCtrl = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController neetScoreCtrl = TextEditingController();

  /// ðŸ“¸ Profile image
  final Rx<File?> profileImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    // Pre-fill from existing profile data
    try {
      final profileCtrl = Get.find<ProfileController>();
      final profile = profileCtrl.profile.value;
      if (profile != null) {
        loadFromProfile(profile);
      }
    } catch (_) {}
  }

  void setProfileImage(File image) {
    profileImage.value = image;
  }

  String _normalizeOptionalText(String? value) {
    return value?.trim() ?? '';
  }

  String _normalizeDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final iso = DateTime.tryParse(raw);
    if (iso != null) return raw.split('T').first;
    final parts = raw.split(RegExp(r'[-/.]'));
    if (parts.length == 3 && parts[0].length <= 2) {
      final reordered =
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      if (DateTime.tryParse(reordered) != null) return reordered;
    }
    return raw;
  }

  String? _normalizeGenderValue(String? value) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'm':
      case 'Male':
        return 'Male';

      case 'f':
      case 'Female':
        return 'Female';

      case 'Other':
        return 'Other';

      default:
        return value?.trim().isEmpty == true ? null : value?.trim();
    }
  }

  void loadFromProfile(ProfileModel profile) {
    firstNameCtrl.text = profile.user.firstName;
    lastNameCtrl.text = profile.user.lastName;
    neetCtrl.text = profile.neetScore?.toString() ?? '';
    tenthCtrl.text = profile.tenthPercentage ?? '';
    twelthCtrl.text = profile.twelthPercentage ?? '';
    twelthPcbCtrl.text = profile.twelthPcb ?? '';
    casteCtrl.text = profile.caste ?? '';
    nationalityCtrl.text = (profile.nationality?.trim().isNotEmpty ?? false)
        ? profile.nationality!
        : 'Indian';
    genderValue.value = _normalizeGenderValue(profile.gender) ?? '';
    dobCtrl.text = _normalizeDate(profile.dateOfBirth);
    addressCtrl.text = profile.address ?? '';
    courseCtrl.text = profile.course ?? '';
    stateCtrl.text = profile.state ?? '';
    categoryCtrl.text = profile.category ?? '';
    neetScoreCtrl.text = profile.neetScore?.toString() ?? '';
    emailCtrl.text = profile.user.email ?? '';
    airCtrl.text = profile.allIndiaRank?.toString() ?? '';
  }

  int? _neetScoreForUpdate() {
    int existingScore = 0;

    try {
      existingScore =
          Get.find<ProfileController>().profile.value?.neetScore ?? 0;
    } catch (_) {}

    final input = neetCtrl.text.trim();
    final parsedScore = int.tryParse(input);

    if (existingScore > 0) {
      final attemptedChange = input.isEmpty
          ? true
          : (parsedScore == null || parsedScore != existingScore);

      if (attemptedChange) {
        AppSnackbar.show(
          'NEET Score Locked',
          'NEET score can update only once',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return null;
    }

    return parsedScore;
  }

  Future<void> removeProfileImage() async {
    try {
      isLoading.value = true;

      await ProfileService.deleteProfileImage();

      profileImage.value = null;

      try {
        final profileCtrl = Get.find<ProfileController>();

        await profileCtrl.fetchProfile(force: true);

        loadFromProfile(profileCtrl.profile.value!);
      } catch (_) {}

      AppSnackbar.show(
        'Success',
        'Profile image removed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to remove profile image',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (isLoading.value) return;

    try {
      final firstName = firstNameCtrl.text.trim();
      final lastName = lastNameCtrl.text.trim();
      
      if (!RegExp(r"^[a-zA-Z\s\-\.\']+$").hasMatch(firstName)) {
        AppSnackbar.show(
          'Validation',
          'Enter a valid first name',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      if (!RegExp(r"^[a-zA-Z\s\-\.\']+$").hasMatch(lastName)) {
        AppSnackbar.show(
          'Validation',
          'Enter a valid last name',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final newNeetScoreText = neetCtrl.text.trim();
      isLoading.value = true;
      final existingNeetScore =
          Get.find<ProfileController>().profile.value?.neetScore ?? 0;
      final canUpdateNeetScore = existingNeetScore <= 0;
      final parsedNewNeetScore = int.tryParse(newNeetScoreText);

      final profileCtrl = Get.find<ProfileController>();

      final existingAirRank = profileCtrl.profile.value?.allIndiaRank ?? 0;

      final newAirRank = int.tryParse(airCtrl.text.trim());
      final existingAirRankText = _normalizeOptionalText(
        profileCtrl.profile.value?.allIndiaRank?.toString(),
      );
      final currentAirRankText = _normalizeOptionalText(airCtrl.text);
      final didAttemptAirRankChange = currentAirRankText != existingAirRankText;

      /// FREE USER LOCK ONLY WHEN USER ACTUALLY TRIES TO CHANGE AIR RANK
      if (profileCtrl.isRankLocked && didAttemptAirRankChange) {
        AppSnackbar.show(
          'Subscription Required',
          'Buy a premium plan to edit AIR rank',
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.toNamed('/subscription');

        return;
      }

      /// ONLY ONE TIME EDIT
      if (didAttemptAirRankChange &&
          profileCtrl.profile.value?.allIndiaRankUpdatedOnce == true &&
          newAirRank != null &&
          newAirRank != existingAirRank) {
        AppSnackbar.show(
          'AIR Rank Locked',
          'AIR rank can only be updated once per subscription',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      if (parsedNewNeetScore != null && parsedNewNeetScore > 720) {
        AppSnackbar.show(
          'Invalid NEET Score',
          'NEET score must be between 0 and 720',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!canUpdateNeetScore) {
        final attemptedChange = newNeetScoreText.isEmpty
            ? true
            : parsedNewNeetScore == null ||
                  parsedNewNeetScore != existingNeetScore;

        if (attemptedChange) {
          AppSnackbar.show(
            'NEET Score Locked',
            'NEET score cannot be updated',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final UpdateProfileRequest request = UpdateProfileRequest(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        neetScore: canUpdateNeetScore ? parsedNewNeetScore : null,
        tenthPercentage: double.tryParse(tenthCtrl.text) ?? 0,
        twelthPercentage: double.tryParse(twelthCtrl.text) ?? 0,
        twelthPcb: double.tryParse(twelthPcbCtrl.text),
        nationality: nationalityCtrl.text.trim(),
        gender: genderValue.value.isEmpty ? null : genderValue.value,
        dateOfBirth: dobCtrl.text.isNotEmpty && dobCtrl.text.trim() != ''
            ? DateTime.tryParse(_normalizeDate(dobCtrl.text))
            : null,
        state: int.tryParse(stateCtrl.text),
        course: int.tryParse(courseCtrl.text),
        address: addressCtrl.text.trim(),
        profilePicture: profileImage.value,
        air: airCtrl.text.trim().isNotEmpty
            ? int.tryParse(airCtrl.text.trim())
            : null,
        fcmToken: await FcmUtils.getFcmToken(),
      );

      final UpdateProfileResponse response =
          await UpdateProfileService.updateProfile(request);

      isProfileCompleted.value = response.isProfileCompleted;

      AppSnackbar.show(
        'Success',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );

      /// Refresh profile data & navigate back only after fetch completes
      try {
        final profileCtrl = Get.find<ProfileController>();
        await profileCtrl.fetchProfile(force: true);
        // Wait for profile observable to update before navigating
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}
      Get.offNamed(AppRoutes.profile);
    } catch (e) {
      AppSnackbar.show(
        'Update Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    neetCtrl.dispose();
    tenthCtrl.dispose();
    twelthCtrl.dispose();
    twelthPcbCtrl.dispose();
    casteCtrl.dispose();
    nationalityCtrl.dispose();
    dobCtrl.dispose();
    addressCtrl.dispose();
    super.onClose();
  }
}
