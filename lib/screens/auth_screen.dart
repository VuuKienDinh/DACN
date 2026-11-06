import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/dailyfit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _loginIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginIdController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(bool registerMode) {
    if (_isRegisterMode == registerMode || _isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isRegisterMode = registerMode;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _isSubmitting = true);
    try {
      final authUser = _isRegisterMode
          ? await AuthService.instance.register(
              fullName: _fullNameController.text,
              username: _usernameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await AuthService.instance.login(
              usernameOrEmail: _loginIdController.text,
              password: _passwordController.text,
            );

      await DailyFitStore.instance.setAuthenticatedUser(authUser);

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? 'Chào mừng ${authUser.fullName}! Đã tạo tài khoản thành công.'
                : 'Xin chào ${authUser.fullName}! Đăng nhập thành công.',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Đã xảy ra lỗi xử lý. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    await DailyFitStore.instance.continueAsGuest();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.iceSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DailyFitStore.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo thương hiệu DailyFit
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.checkroom_rounded,
                          size: 34,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'DailyFit',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trợ lý tủ đồ thông minh & gợi ý phối đồ theo thời tiết',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Thẻ biểu mẫu Đăng nhập / Đăng ký
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        enableBlur: false,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Thanh chuyển đổi Đăng nhập / Đăng ký
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.iceSurface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _modeTabButton(
                                        title: 'Đăng nhập',
                                        selected: !_isRegisterMode,
                                        onTap: () => _switchMode(false),
                                      ),
                                    ),
                                    Expanded(
                                      child: _modeTabButton(
                                        title: 'Đăng ký',
                                        selected: _isRegisterMode,
                                        onTap: () => _switchMode(true),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          AppColors.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 12.8,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              if (!_isRegisterMode) ...[
                                TextFormField(
                                  key: const ValueKey('login_identifier'),
                                  controller: _loginIdController,
                                  style: TextStyle(color: AppColors.text),
                                  textInputAction: TextInputAction.next,
                                  decoration: _fieldDecoration(
                                    label: 'Tên đăng nhập hoặc Email',
                                    hint: 'Ví dụ: vuukiendinh',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Vui lòng nhập tên đăng nhập hoặc email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ] else ...[
                                TextFormField(
                                  key: const ValueKey('register_fullname'),
                                  controller: _fullNameController,
                                  style: TextStyle(color: AppColors.text),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: _fieldDecoration(
                                    label: 'Họ và tên hiển thị',
                                    hint: 'Ví dụ: Vưu Kiên Định',
                                    icon: Icons.badge_outlined,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const ValueKey('register_username'),
                                  controller: _usernameController,
                                  style: TextStyle(color: AppColors.text),
                                  textInputAction: TextInputAction.next,
                                  decoration: _fieldDecoration(
                                    label: 'Tên đăng nhập',
                                    hint:
                                        'Từ 3 ký tự, viết liền (vd: vuukiendinh)',
                                    icon: Icons.alternate_email_rounded,
                                  ),
                                  validator: (val) {
                                    final v = val?.trim() ?? '';
                                    if (v.length < 3 || v.contains(' ')) {
                                      return 'Từ 3 ký tự trở lên và không có khoảng trắng';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const ValueKey('register_email'),
                                  controller: _emailController,
                                  style: TextStyle(color: AppColors.text),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: _fieldDecoration(
                                    label: 'Địa chỉ Email',
                                    hint: 'vidu@gmail.com',
                                    icon: Icons.mail_outline_rounded,
                                  ),
                                  validator: (val) {
                                    final v = val?.trim() ?? '';
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return 'Vui lòng nhập email hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],

                              TextFormField(
                                key: ValueKey(
                                  'password_${_isRegisterMode ? "reg" : "login"}',
                                ),
                                controller: _passwordController,
                                style: TextStyle(color: AppColors.text),
                                obscureText: _obscurePassword,
                                textInputAction: _isRegisterMode
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onFieldSubmitted:
                                    _isRegisterMode ? null : (_) => _submit(),
                                decoration: _fieldDecoration(
                                  label: 'Mật khẩu',
                                  hint: 'Tối thiểu 6 ký tự',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (_isRegisterMode && val.length < 6) {
                                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                                  }
                                  return null;
                                },
                              ),

                              if (_isRegisterMode) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const ValueKey(
                                    'register_confirm_password',
                                  ),
                                  controller: _confirmPasswordController,
                                  style: TextStyle(color: AppColors.text),
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _fieldDecoration(
                                    label: 'Xác nhận mật khẩu',
                                    hint: 'Nhập lại mật khẩu ở trên',
                                    icon: Icons.verified_user_outlined,
                                  ),
                                  validator: (val) {
                                    if (val != _passwordController.text) {
                                      return 'Mật khẩu xác nhận không khớp';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 20),

                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(
                                        _isRegisterMode
                                            ? 'Tạo tài khoản mới'
                                            : 'Đăng nhập',
                                      ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        'hoặc',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              OutlinedButton.icon(
                                onPressed:
                                    _isSubmitting ? null : _continueAsGuest,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                    horizontal: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.explore_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Tiếp tục với tư cách Khách',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
            Positioned(
              top: 10,
              right: 14,
              child: IconButton(
                tooltip: 'Chuyển đổi giao diện Sáng / Tối',
                onPressed: store.toggleDarkMode,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface.withValues(alpha: 0.90),
                  side: BorderSide(
                    color: AppColors.cardBorder,
                    width: 1.2,
                  ),
                ),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color:
                      isDark ? const Color(0xFFFBBF24) : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
