// ============================================================================
// signup_screen.dart
// ----------------------------------------------------------------------------
// SnapBee — Sign Up Screen (production-wired)
//
// This screen is UI + orchestration only: all registration business logic
// (unique customer_code, membership defaults, referral resolution, initial
// membership/notification/statistics rows) lives in the database triggers
// (database/schema.sql) and CustomerRepository — this file never invents
// business rules of its own, it just calls the repository and renders state.
//
// Responsiveness: LayoutBuilder + the shared AppBreakpoints tokens adapt
// padding and max content width across Mobile / Tablet / Web.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/customer_repository.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  final _mobileFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _referralFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  Uint8List? _pickedPhotoBytes;

  late final CustomerRepository _customerRepository;

  @override
  void initState() {
    super.initState();
    // The repository is the single seam to Supabase — swap this line to
    // inject a mock repository in widget tests.
    _customerRepository = CustomerRepository(Supabase.instance.client);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _mobileFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _referralFocus.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedPhotoBytes = bytes;
    });
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (!_agreedToTerms) {
      _showSnack('Please agree to the Terms & Privacy Policy to continue.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _customerRepository.signUp(
        fullName: _fullNameController.text,
        mobileNumber: _mobileController.text,
        email: _emailController.text,
        password: _passwordController.text,
        referralCodeUsed: _referralController.text.trim().isEmpty
            ? null
            : _referralController.text.trim(),
        profilePhoto: _pickedPhotoBytes == null
            ? null
            : Uint8ListSource(_pickedPhotoBytes!),
      );

      if (!mounted) return;
      _showSnack('Account created! Welcome to SnapBee.');
      // Pop back to whatever presented this screen (LoginScreen, pushed
      // from main.dart's _AuthGate). No manual navigation to a dashboard
      // is needed: _AuthGate listens to Supabase's onAuthStateChange and
      // swaps to MainScreen reactively the moment a session exists. If
      // this Supabase project requires email confirmation before a
      // session is granted, popping back to LoginScreen is exactly right
      // instead. Either way, leaving the customer stuck on this form
      // (the previous behavior) was a dead end.
      Navigator.of(context).maybePop();
    } on CustomerRegistrationException catch (e) {
      _showSnack(e.message);
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleGoogleSignUp() {
    // Not wired to Supabase OAuth yet (`signInWithOAuth(OAuthProvider.google)`)
    // — say so plainly rather than showing a snack that implies it did
    // something.
    _showSnack('Sign up with Google is not available yet. Please use email.');
  }

  void _handleLoginTap() {
    Navigator.of(context).maybePop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreenDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLightTop,
              AppColors.backgroundLightBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isLarge =
                  AppBreakpoints.isTablet(width) ||
                  AppBreakpoints.isDesktop(width);
              final horizontalPadding = AppBreakpoints.isDesktop(width)
                  ? AppSpacing.screenPadding * 3
                  : AppBreakpoints.isTablet(width)
                  ? AppSpacing.screenPadding * 2
                  : AppSpacing.screenPadding;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.screenPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppBreakpoints.maxContentWidth(width),
                    ),
                    child: _buildForm(context, isLarge),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLargeScreen) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(
        isLargeScreen
            ? AppSpacing.screenPadding * 1.5
            : AppSpacing.screenPadding,
      ),
      decoration: isLargeScreen
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(
                AppSpacing.borderRadius * 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : null,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SnapBeeLogo(),
            const SizedBox(height: 5),
            Semantics(
              header: true,
              child: Text(
                'Create Your Account',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Welcome to SnapBee',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),

            // ---------------- Profile Photo Picker ----------------
            _ProfilePhotoPicker(
              imageBytes: _pickedPhotoBytes,
              onTap: _pickProfilePhoto,
            ),
            const SizedBox(height: 18),

            // ---------------- Full Name ----------------
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: Validators.fullName,
              onSubmitted: (_) => _mobileFocus.requestFocus(),
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // ---------------- Mobile Number (+91) ----------------
            _buildMobileField(),
            const SizedBox(height: AppSpacing.fieldGap),

            // ---------------- Email ----------------
            _buildTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // ---------------- Password ----------------
            _buildPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              obscureText: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: Validators.password,
              onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // ---------------- Confirm Password ----------------
            _buildPasswordField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              label: 'Confirm Password',
              obscureText: _obscureConfirmPassword,
              onToggle: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
              onSubmitted: (_) => _referralFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // ---------------- Referral Code (optional) ----------------
            // Future-proofing for the referral program: fully optional, so
            // it never blocks a normal sign-up.
            _buildTextField(
              controller: _referralController,
              focusNode: _referralFocus,
              label: 'Referral Code (optional)',
              hint: 'e.g. SBA1B2C3',
              icon: Icons.card_giftcard_outlined,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _handleCreateAccount(),
            ),
            const SizedBox(height: 12),

            // ---------------- Terms & Privacy ----------------
            _TermsCheckbox(
              value: _agreedToTerms,
              onChanged: (value) =>
                  setState(() => _agreedToTerms = value ?? false),
            ),
            const SizedBox(height: 20),

            // ---------------- Create Account ----------------
            _PrimaryButton(
              label: 'Create Account',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleCreateAccount,
            ),
            const SizedBox(height: 20),

            const _OrDivider(),
            const SizedBox(height: 20),

            _GoogleButton(
              label: 'Continue with Google',
              onPressed: _handleGoogleSignUp,
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                Semantics(
                  button: true,
                  label: 'Login',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _handleLoginTap,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primaryGreenDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -- Shared field builders --------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
    List<String>? autofillHints,
  }) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        autofillHints: autofillHints,
        style: const TextStyle(color: AppColors.textDark, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          border: _fieldBorder(AppColors.fieldBorder),
          enabledBorder: _fieldBorder(AppColors.fieldBorder),
          focusedBorder: _fieldBorder(AppColors.primaryGreen, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildMobileField() {
    return Semantics(
      textField: true,
      label: 'Mobile number, 10 digits',
      child: TextFormField(
        controller: _mobileController,
        focusNode: _mobileFocus,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: Validators.mobileNumber,
        onFieldSubmitted: (_) => _emailFocus.requestFocus(),
        style: const TextStyle(color: AppColors.textDark, fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Mobile Number',
          hintText: '98765 43210',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                '+91',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: _fieldBorder(AppColors.fieldBorder),
          enabledBorder: _fieldBorder(AppColors.fieldBorder),
          focusedBorder: _fieldBorder(AppColors.primaryGreen, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required ValueChanged<String> onSubmitted,
  }) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: TextInputAction.next,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(color: AppColors.textDark, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter your password',
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.textMuted,
          ),
          suffixIcon: Semantics(
            button: true,
            label: obscureText ? 'Show password' : 'Hide password',
            child: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: onToggle,
            ),
          ),
          border: _fieldBorder(AppColors.fieldBorder),
          enabledBorder: _fieldBorder(AppColors.fieldBorder),
          focusedBorder: _fieldBorder(AppColors.primaryGreen, width: 1.6),
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

// ============================================================================
// Small presentational widgets kept in this file since they are only used
// by SignupScreen. Move to `presentation/widgets/` if a second screen
// (e.g. edit-profile) needs to reuse the photo picker or buttons.
// ============================================================================

class _SnapBeeLogo extends StatelessWidget {
  const _SnapBeeLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SnapBee logo',
      image: true,
      child: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Image.asset(
            'assets/logos/snapbee_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({required this.imageBytes, required this.onTap});

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: imageBytes == null
            ? 'Add profile photo'
            : 'Change profile photo',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.fieldBorder,
                backgroundImage: imageBytes != null
                    ? MemoryImage(imageBytes!)
                    : null,
                child: imageBytes == null
                    ? const Icon(
                        Icons.person_outline,
                        size: 40,
                        color: AppColors.textMuted,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: 'I agree to Terms & Privacy Policy',
            checked: value,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'I agree to the Terms & Privacy Policy',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: onPressed,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                disabledBackgroundColor: AppColors.primaryGreen.withValues(
                  alpha: 0.6,
                ),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withValues(alpha: 0.15),
                ),
              ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.fieldBorder, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.fieldBorder, thickness: 1),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 54,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            side: const BorderSide(color: AppColors.fieldBorder, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
          ),
          icon: Image.asset(
            'assets/logos/google_logo.png',
            width: 45,
            height: 45,
            fit: BoxFit.contain,
          ),
          label: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
