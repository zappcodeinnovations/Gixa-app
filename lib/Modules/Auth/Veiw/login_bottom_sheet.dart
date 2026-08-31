import 'dart:async';
import 'dart:ui';

import 'package:Gixa/Modules/Auth/controllers/otp_controller.dart';
import 'package:Gixa/common/app_colors.dart';
import 'package:Gixa/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:get_storage/get_storage.dart';

bool _isAuthSheetOpen = false;

Future<T?> showAuthBottomSheet<T>(Widget child) {
  final overlayContext = Get.overlayContext ?? Get.context;
  if (overlayContext == null) return Future<T?>.value();

  final otpController = Get.find<OtpController>();
  if (otpController.isLoggedIn.value == true) {
    return Future<T?>.value();
  }

  if (_isAuthSheetOpen) return Future<T?>.value();

  _isAuthSheetOpen = true;

  try {
    return showModalBottomSheet<T>(
      context: overlayContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    ).whenComplete(() {
      _isAuthSheetOpen = false;
    });
  } catch (e) {
    _isAuthSheetOpen = false;
    return Future<T?>.value();
  }
}

void closeAuthBottomSheet() {
  if (_isAuthSheetOpen) {
    _isAuthSheetOpen = false;
    final context = Get.overlayContext;
    if (context != null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 50,
        height: 5,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? UColors.primaryLight : UColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isLoading || widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 48, // slightly smaller height for premium look
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: kHomeBrandGradient.colors
                        .map((color) => color.withOpacity(0.55))
                        .toList(),
                    begin: kHomeBrandGradient.begin,
                    end: kHomeBrandGradient.end,
                  )
                : kHomeBrandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isPressed || isDisabled
                ? []
                : [
                    BoxShadow(
                      color: kHomeBrandGradient.colors.last.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14, // smaller font size
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final Widget child;

  const _SheetScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final safeBottom = media.viewPadding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Material(
                        color: (isDark ? UColors.darkSurface : Colors.white)
                            .withOpacity(0.85),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            75,
                            24,
                            safeBottom + 24,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: IgnorePointer(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glowing blurry decoration behind the image
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? kHomeAccentColor
                                            : UColors.primary)
                                        .withOpacity(0.35),
                                blurRadius: 40,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/login_genie.png',
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ],
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
}

class LoginBottomSheet extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const LoginBottomSheet({super.key, this.onAuthenticated});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final OtpController _otpController;

  @override
  void initState() {
    super.initState();
    _otpController = Get.isRegistered<OtpController>()
        ? Get.find<OtpController>()
        : Get.put(OtpController());
    _otpController.reset();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final otpSent = await _otpController.sendOtp(_phoneController.text.trim());
    if (!mounted || !otpSent) return;

    _isAuthSheetOpen = false;
    Navigator.of(context).pop();
    Future.microtask(() {
      showAuthBottomSheet(
        OtpVerifyBottomSheet(onAuthenticated: widget.onAuthenticated),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? UColors.darkBorder : UColors.border;
    final inputColor = isDark
        ? const Color(0xFF1E2432)
        : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : UColors.primaryDark;
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return _SheetScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genie image sits above, so we don't need the drag handle and icon here.
            const SizedBox(height: 12),
            Text(
              'Continue with mobile number',
              style: TextStyle(
                fontSize: 18, // reduced from 20
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your number to verify with OTP and unlock all app features.',
              style: TextStyle(fontSize: 12, height: 1.4, color: subTextColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Mobile number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kHomeAccentColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Enter 10-digit mobile number',
                filled: true,
                fillColor: inputColor,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+91',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 18, color: borderColor),
                    ],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: kHomeAccentColor,
                    width: 1.4,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),
              ),
              onFieldSubmitted: (_) => _sendOtp(),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Mobile number required';
                if (input.length != 10) return 'Enter valid 10-digit number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Obx(
              () => _GradientButton(
                label: 'Send OTP',
                isLoading: _otpController.isSendingOtp.value,
                onPressed: _sendOtp,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: Get.back,
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    color: isDark ? UColors.primaryLight : UColors.primaryDark,
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

class OtpVerifyBottomSheet extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const OtpVerifyBottomSheet({super.key, this.onAuthenticated});

  @override
  State<OtpVerifyBottomSheet> createState() => _OtpVerifyBottomSheetState();
}

class _OtpVerifyBottomSheetState extends State<OtpVerifyBottomSheet> {
  final _otpFieldController = TextEditingController();
  bool isOtpComplete = false;
  late final OtpController _otpController;
  String? otpErrorText;
  StreamSubscription<String>? _otpSubscription;
  Worker? _otpResetWorker;

  @override
  void initState() {
    super.initState();
    _otpController = Get.find<OtpController>();
    printHashCode();
    _otpFieldController.clear();
    listenOtp();

    _otpResetWorker = ever(_otpController.otpInputResetTrigger, (_) {
      if (mounted) {
        _otpFieldController.clear();
        setState(() {
          isOtpComplete = false;
          otpErrorText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpResetWorker?.dispose();
    _otpSubscription?.cancel();
    _otpFieldController.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  Future<void> printHashCode() async {
    try {
      print("STEP 1");

      final appSignature = await SmsAutoFill().getAppSignature;

      print("STEP 2");

      print("=================================");
      print("APP HASH CODE => $appSignature");
      print("=================================");
    } catch (e) {
      print("HASH ERROR => $e");
    }
  }

  Future<void> listenOtp() async {
    await SmsAutoFill().listenForCode();

    _otpSubscription = SmsAutoFill().code.listen((code) {
      print("🔥 OTP RECEIVED: $code");

      if (code != null && code.length == 6) {
        if (mounted) {
          _otpFieldController.text = code;
          setState(() {
            isOtpComplete = true;
          });
        }

        _otpController.otp.value = code;
        if (!_otpController.isVerifyingOtp.value) {
          _submitOtp();
        }
      }
    });
  }

  Future<void> _submitOtp() async {
    if (_otpController.isVerifyingOtp.value) return;
    if (_otpFieldController.text.trim().length != 6) return;

    FocusScope.of(context).unfocus();
    _otpController.otp.value = _otpFieldController.text.trim();
    try {
      await _otpController.verifyOtpForBottomSheet(
        onRegisteredSuccess: widget.onAuthenticated,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        otpErrorText = e.toString();
      });
    }
  }

  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? UColors.darkBorder : UColors.border;
    final inputColor = isDark
        ? const Color(0xFF1E2432)
        : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : UColors.primaryDark;
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genie image sits above, so we don't need the drag handle and icon here.
          const SizedBox(height: 12),
          Text(
            'Verify OTP',
            style: TextStyle(
              fontSize: 18, // reduced
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              'Enter the 6-digit code sent to\n+91 ${_otpController.mobileNumber.value}',
              style: TextStyle(fontSize: 12, height: 1.4, color: subTextColor),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _otpFieldController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              errorText: otpErrorText,

              hintText: '------',
              hintStyle: TextStyle(
                color: subTextColor.withOpacity(0.5),
                fontSize: 22,
                letterSpacing: 10,
              ),

              filled: true,
              fillColor: inputColor,

              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),

              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: kHomeAccentColor, width: 1.4),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.4,
                ),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.6,
                ),
              ),
            ),
            onChanged: (value) {
              _otpController.otp.value = value;

              setState(() {
                isOtpComplete = value.trim().length == 6;
                otpErrorText = null;
              });
            },
            onSubmitted: (_) => _submitOtp(),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (_otpController.canResendOtp.value) {
              return Center(
                child: TextButton(
                  onPressed: _otpController.resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: kHomeAccentColor),
                  ),
                ),
              );
            }

            return Center(
              child: Text(
                'Resend code in ${_formatCountdown(_otpController.secondsRemaining.value)}',
                style: TextStyle(
                  fontSize: 13,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Obx(
            () => _GradientButton(
              label: 'Verify OTP',
              isLoading: _otpController.isVerifyingOtp.value,
              onPressed: isOtpComplete && !_otpController.isVerifyingOtp.value
                  ? _submitOtp
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () async {
                final onAuth = widget.onAuthenticated;
                closeAuthBottomSheet();
                await Future.delayed(const Duration(milliseconds: 350));
                
                showAuthBottomSheet(
                  LoginBottomSheet(
                    onAuthenticated: onAuth,
                  ),
                );
              },
              child: Text(
                'Edit Mobile Number',
                style: TextStyle(
                  color: isDark ? UColors.primaryLight : UColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
