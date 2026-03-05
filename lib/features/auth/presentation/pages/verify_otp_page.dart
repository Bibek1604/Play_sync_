import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/database/hive_service.dart';
import '../providers/password_reset_providers.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  final String? email;

  const VerifyOtpPage({super.key, this.email});

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  String _email = '';
  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  bool get _isAllFilled => _otpControllers.every((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _startResendTimer();
    // Auto-focus first input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _loadEmail() async {
    // Try to get email from passed argument first
    if (widget.email != null && widget.email!.isNotEmpty) {
      setState(() => _email = widget.email!);
      await _saveEmailToHive(widget.email!);
      return;
    }

    // Otherwise load from Hive
    final box = await HiveService.openUserBox();
    final savedEmail = box.get('password_reset_email', defaultValue: '');
    setState(() => _email = savedEmail);
  }

  Future<void> _saveEmailToHive(String email) async {
    final box = await HiveService.openUserBox();
    await box.put('password_reset_email', email);
  }

  Future<void> _saveOtpToHive(String otp) async {
    final box = await HiveService.openUserBox();
    await box.put('password_reset_otp', otp);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleOtpChange(int index, String value) {
    if (value.isEmpty) {
      setState(() {});
      return;
    }

    // Only allow single digit
    if (value.length > 1) {
      _otpControllers[index].text = value[0];
    }

    // Auto-focus next field
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last field - submit if all filled
      _focusNodes[index].unfocus();
    }
    setState(() {}); // rebuild for button enable/submit gating
  }

  void _handleBackspace(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpValue() {
    return _otpControllers.map((c) => c.text).join('');
  }

  Future<void> _handleContinue() async {
    final otp = _getOtpValue();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: AppSpacing.md),
            const Expanded(child: Text('Please enter a valid 6-digit OTP')),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          margin: EdgeInsets.all(AppSpacing.lg),
        ),
      );
      return;
    }

    // Save OTP to Hive and navigate — backend validates at reset-password step
    await _saveOtpToHive(otp);

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/reset-password',
      arguments: {'email': _email, 'otp': otp},
    );
  }

  Future<void> _handleResendOtp() async {
    if (_resendSeconds > 0 || _isResending || _email.isEmpty) return;

    setState(() => _isResending = true);

    await ref
        .read(passwordResetNotifierProvider.notifier)
        .sendPasswordResetOtp(_email);

    if (!mounted) return;

    final resetState = ref.read(passwordResetNotifierProvider);
    if (resetState.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('OTP sent! Check your email.')),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          margin: EdgeInsets.all(AppSpacing.lg),
        ),
      );
      // Clear previous OTP boxes
      for (final c in _otpControllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startResendTimer();
    } else {
      final msg = resetState.failure?.message
          ?? resetState.message
          ?? 'Could not resend OTP. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(msg)),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          margin: EdgeInsets.all(AppSpacing.lg),
        ),
      );
    }

    setState(() => _isResending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  height: 80,
                  width: 80,
                  margin: EdgeInsets.only(bottom: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),

                // Title
                Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  'We sent a 6-digit code to',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  _email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.xxl),

                // OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => _buildOtpBox(index),
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),

                // Continue Button
                ElevatedButton(
                  onPressed: (_isLoading || !_isAllFilled) ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Resend OTP with countdown
                Column(
                  children: [
                    if (_resendSeconds > 0)
                      Text(
                        'Resend code in $_resendSeconds s',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: (_isResending || _email.isEmpty)
                            ? null
                            : _handleResendOtp,
                        child: _isResending
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive code? ",
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final isFilled = _otpControllers[index].text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? AppColors.primary.withOpacity(0.25)
                : Colors.black.withOpacity(0.06),
            blurRadius: isFocused ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isFilled
              ? AppColors.primary.withOpacity(0.08)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.border, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: isFilled ? AppColors.primary.withOpacity(0.5) : AppColors.border,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.primary, width: 2.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        onChanged: (value) => _handleOtpChange(index, value),
        onTap: () {
          _otpControllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _otpControllers[index].text.length),
          );
        },
      ),
    );
  }
}
