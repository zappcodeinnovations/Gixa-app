import 'package:Gixa/routes/app_routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Gixa/common/app_colors.dart';
import 'package:Gixa/utils/constants/colors.dart';

import '../controllers/otp_controller.dart';

class LoginWithOtpPage extends StatelessWidget {
  LoginWithOtpPage({super.key});

  final controller = Get.find<OtpController>();
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color primaryColor = kHomeAccentColor;
  final Color textDark = const Color(0xFF1A1A2E);
  final Color textGrey = const Color(0xFF9E9EA7);
  final Color borderColor = UColors.border;
  final Color bgColor = Colors.white;

  Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (phoneController.text.isEmpty && controller.mobileNumber.value.isNotEmpty) {
      phoneController.text = controller.mobileNumber.value;
    }
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _buildBackgroundGlow(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      _buildBackButton(),
                      const SizedBox(height: 24),
                      _buildIllustration(size),
                      const SizedBox(height: 24),
                      _buildIntroTag(),
                      const SizedBox(height: 14),
                      Text(
                        'Login with OTP',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: UColors.primaryDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We will send a secure one time password to your mobile number.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textGrey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildFormCard(context),
                      const SizedBox(height: 22),
                      _buildTermsText(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGETS =====================

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: UColors.softSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: UColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: UColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildIllustration(Size size) {
    return Center(
      child: Container(
        height: size.width * 0.58,
        width: size.width * 0.58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              UColors.primary.withOpacity(0.14),
              UColors.primaryLight.withOpacity(0.12),
              UColors.secondary.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: UColors.border),
        ),
        child: Center(
          child: SizedBox(
            height: size.width * 0.48,
            width: size.width * 0.48,
            child: Lottie.asset('assets/lottie/otp.json'),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -40,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: UColors.primaryLight.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 150,
          left: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: UColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: UColors.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome_rounded, size: 16, color: UColors.primary),
          SizedBox(width: 8),
          Text(
            'Fast and secure sign in',
            style: TextStyle(
              color: UColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: UColors.border),
        boxShadow: [
          BoxShadow(
            color: UColors.primaryLight.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhoneInput(),
          const SizedBox(height: 20),
          _buildLoginButton(context),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile number",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textDark,
            letterSpacing: 1.0,
          ),
          decoration: InputDecoration(
            hintText: '+00-0000-000-0000',
            hintStyle: TextStyle(
              color: textGrey.withOpacity(0.6),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            filled: true,
            fillColor: UColors.softSurface,
            counterText: '',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "+91",
                    style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                      color: UColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 20,
                    color: borderColor,
                  ),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Mobile number required';
            if (value.length != 10) return 'Enter valid 10-digit number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final otpSent = await controller.sendOtp(
                      phoneController.text,
                    );
                    if (!context.mounted || !otpSent) return;
                    Navigator.of(context).pushNamed(
                      AppRoutes.verifyOtp,
                      arguments: {'mobileNumber': phoneController.text},
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: primaryColor.withOpacity(0.5),
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Ink(
                  decoration: BoxDecoration(
                    gradient: kHomeBrandGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: UColors.primaryDark, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Get OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(
            fontSize: 13,
            color: textGrey,
          ),
          children: [
            TextSpan(
              text: "Sign Up",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Navigate to sign up
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: "By continuing, you agree to our ",
          style: TextStyle(fontSize: 11, color: textGrey, height: 1.5),
          children: [
            TextSpan(
              text: "Terms of Service",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  openUrl("https://gixa.in/terms-conditions/");
                },
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  openUrl("https://gixa.in/privacy-policy/");
                },
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
