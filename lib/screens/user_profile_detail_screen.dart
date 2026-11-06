import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/clothing_service.dart';
import '../services/dailyfit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/user_avatar.dart';

class UserProfileDetailScreen extends StatefulWidget {
  final bool initialEditMode;

  const UserProfileDetailScreen({
    super.key,
    this.initialEditMode = false,
  });

  @override
  State<UserProfileDetailScreen> createState() =>
      _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _birthDateCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _bioCtrl;

  static const List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  late bool _isEditing;
  bool _isSaving = false;
  String _selectedGender = '';
  PlatformFile? _pendingAvatarFile;
  bool _clearCurrentAvatar = false;

  @override
  void initState() {
    super.initState();
    final store = DailyFitStore.instance;
    _isEditing = widget.initialEditMode;
    _fullNameCtrl = TextEditingController(text: store.activeDisplayName);
    _emailCtrl = TextEditingController(text: store.activeEmail);
    _phoneCtrl = TextEditingController(text: store.activePhone);
    _birthDateCtrl = TextEditingController(text: store.activeBirthDate);
    _addressCtrl = TextEditingController(text: store.activeAddress);
    _bioCtrl = TextEditingController(text: store.activeBio);
    _selectedGender = store.activeGender;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _syncControllersFromStore() {
    final store = DailyFitStore.instance;
    _fullNameCtrl.text = store.activeDisplayName;
    _emailCtrl.text = store.activeEmail;
    _phoneCtrl.text = store.activePhone;
    _birthDateCtrl.text = store.activeBirthDate;
    _addressCtrl.text = store.activeAddress;
    _bioCtrl.text = store.activeBio;
    _selectedGender = store.activeGender;
    _pendingAvatarFile = null;
    _clearCurrentAvatar = false;
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.image,
      );
      if (!mounted || picked == null) return;
      if (picked.path == null || picked.path!.trim().isEmpty) return;

      if (!_isEditing) {
        // Nếu người dùng đang ở chế độ Xem mà bấm chọn ảnh đại diện -> lưu ngay lập tức!
        setState(() => _isSaving = true);
        try {
          await DailyFitStore.instance.updateUserProfile(
            fullName: DailyFitStore.instance.activeDisplayName,
            newAvatarLocalPath: picked.path!,
            newAvatarFileName: picked.name,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật ảnh đại diện thành công!'),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể cập nhật ảnh đại diện: $e')),
          );
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
        return;
      }

      setState(() {
        _pendingAvatarFile = picked;
        _clearCurrentAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _removeAvatar() async {
    if (!_isEditing) {
      setState(() => _isSaving = true);
      try {
        await DailyFitStore.instance.updateUserProfile(
          fullName: DailyFitStore.instance.activeDisplayName,
          avatarUrl: '',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gỡ ảnh đại diện, chuyển về chữ viết tắt.'),
          ),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    setState(() {
      _pendingAvatarFile = null;
      _clearCurrentAvatar = true;
    });
  }

  void _onTapAvatar() {
    if (_isSaving) return;
    final currentAvatar = _effectiveAvatarPreview(DailyFitStore.instance);
    if (currentAvatar.isEmpty) {
      _pickAvatarFromGallery();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: AppColors.isDark
            ? BorderSide(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.24),
              )
            : BorderSide.none,
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ảnh đại diện hồ sơ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Chọn ảnh mới từ thư viện',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAvatarFromGallery();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Gỡ ảnh đại diện hiện tại',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _effectiveAvatarPreview(DailyFitStore store) {
    if (_pendingAvatarFile?.path != null &&
        _pendingAvatarFile!.path!.trim().isNotEmpty) {
      return _pendingAvatarFile!.path!;
    }
    if (_clearCurrentAvatar) return '';
    return store.activeAvatarPath;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 21, 1, 1);
    final raw = _birthDateCtrl.text.trim();
    final parts = raw.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null && y > 1920 && y <= now.year) {
        initial = DateTime(y, m, d);
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked == null) return;

    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    setState(() {
      _birthDateCtrl.text = '$dd/$mm/${picked.year}';
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);

    try {
      final store = DailyFitStore.instance;
      await store.updateUserProfile(
        fullName: _fullNameCtrl.text,
        email: _emailCtrl.text,
        phoneNumber: _phoneCtrl.text,
        address: _addressCtrl.text,
        gender: _selectedGender,
        birthDate: _birthDateCtrl.text,
        bio: _bioCtrl.text,
        avatarUrl: _clearCurrentAvatar ? '' : store.activeAvatarPath,
        newAvatarLocalPath: _pendingAvatarFile?.path,
        newAvatarFileName: _pendingAvatarFile?.name,
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _pendingAvatarFile = null;
        _clearCurrentAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thông tin hồ sơ cá nhân!'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật hồ sơ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = DailyFitStore.instance;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa hồ sơ' : 'Thông tin cá nhân'),
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () {
                _syncControllersFromStore();
                setState(() => _isEditing = true);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Sửa'),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: Text(
                'Lưu',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          store.currentUser,
          store.isGuestSession,
          store.preferences,
          store.favorites,
          store.plannedOutfits,
          ClothingService.instance.items,
        ]),
        builder: (context, _) {
          final authUser = store.currentUser.value;
          final prefs = store.preferences.value;
          final displayName = store.activeDisplayName;
          final avatarPreview = _effectiveAvatarPreview(store);
          final clothesCount = ClothingService.instance.items.value.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thẻ Đầu trang Ảnh đại diện + Tên + Thống kê nhanh
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  enableBlur: false,
                  child: Column(
                    children: [
                      UserAvatar(
                        avatarPath: avatarPreview,
                        displayName: displayName,
                        size: 94,
                        showCameraBadge: true,
                        tooltip: 'Đổi ảnh đại diện',
                        onTap: _onTapAvatar,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isSaving ? null : _onTapAvatar,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: Text(
                          avatarPreview.isEmpty
                              ? 'Thêm ảnh đại diện'
                              : 'Đổi ảnh đại diện',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          authUser != null
                              ? '@${authUser.username} · Tài khoản DailyFit'
                              : 'Chế độ Khách (Guest)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (store.activeBio.isNotEmpty && !_isEditing) ...[
                        const SizedBox(height: 10),
                        Text(
                          store.activeBio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _miniStat(
                            value: '$clothesCount',
                            label: 'Trang phục',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.subtleBorder,
                          ),
                          _miniStat(
                            value: '${store.favorites.value.length}',
                            label: 'Yêu thích',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.subtleBorder,
                          ),
                          _miniStat(
                            value: '${store.plannedOutfits.value.length}',
                            label: 'Lịch mặc',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_isEditing)
                  _buildEditForm()
                else ...[
                  // Thẻ Thông tin liên hệ & Cá nhân chi tiết
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    enableBlur: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thông tin cá nhân & Liên hệ',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _infoTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Họ và tên',
                          value: displayName,
                        ),
                        const Divider(height: 22),
                        _infoTile(
                          icon: Icons.alternate_email_rounded,
                          label: 'Tên đăng nhập',
                          value: authUser != null
                              ? '@${authUser.username}'
                              : 'Chế độ Khách (Chưa đăng ký)',
                        ),
                        const Divider(height: 22),
                        _infoTile(
                          icon: Icons.mail_outline_rounded,
                          label: 'Địa chỉ Email',
                          value: store.activeEmail,
                          emptyHint: 'Chưa cập nhật email',
                        ),
                        const Divider(height: 22),
                        _infoTile(
                          icon: Icons.phone_outlined,
                          label: 'Số điện thoại',
                          value: store.activePhone,
                          emptyHint: 'Chưa cập nhật số điện thoại',
                        ),
                        const Divider(height: 22),
                        _infoTile(
                          icon: Icons.home_outlined,
                          label: 'Địa chỉ nhà',
                          value: store.activeAddress,
                          emptyHint: 'Chưa cập nhật địa chỉ nhà',
                        ),
                        const Divider(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _infoTile(
                                icon: Icons.wc_rounded,
                                label: 'Giới tính',
                                value: store.activeGender,
                                emptyHint: 'Chưa chọn',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _infoTile(
                                icon: Icons.cake_outlined,
                                label: 'Ngày sinh',
                                value: store.activeBirthDate,
                                emptyHint: 'Chưa chọn',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Thẻ Sở thích thời trang & Khu vực
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    enableBlur: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hồ sơ phong cách & Khu vực',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _infoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Khu vực thời tiết hiện tại',
                          value: prefs.city,
                        ),
                        const Divider(height: 22),
                        _infoTile(
                          icon: Icons.style_outlined,
                          label: 'Phong cách yêu thích',
                          value: prefs.preferredStyles.join(' · '),
                        ),
                        const Divider(height: 22),
                        _infoTile(
                          icon: Icons.palette_outlined,
                          label: 'Bảng màu chủ đạo',
                          value: prefs.favoriteColors.join(' · '),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      _syncControllersFromStore();
                      setState(() => _isEditing = true);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: const Text('Chỉnh sửa thông tin cá nhân'),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final wasLoggedIn = authUser != null;
                      navigator.popUntil((route) => route.isFirst);
                      await store.logout();
                      if (wasLoggedIn) {
                        messenger?.showSnackBar(
                          const SnackBar(
                            content: Text('Đã đăng xuất tài khoản thành công.'),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      foregroundColor:
                          authUser != null ? AppColors.error : AppColors.primary,
                      side: BorderSide(
                        color: (authUser != null
                                ? AppColors.error
                                : AppColors.primary)
                            .withValues(alpha: 0.38),
                      ),
                    ),
                    icon: Icon(
                      authUser != null
                          ? Icons.logout_rounded
                          : Icons.login_rounded,
                      size: 19,
                    ),
                    label: Text(
                      authUser != null
                          ? 'Đăng xuất tài khoản'
                          : 'Đăng nhập / Tạo tài khoản',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    String emptyHint = 'Chưa cập nhật',
  }) {
    final hasValue = value.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hasValue ? value.trim() : emptyHint,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  color: hasValue ? AppColors.text : AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildEditForm() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      enableBlur: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cập nhật thông tin cá nhân',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Điền đầy đủ số điện thoại, email và địa chỉ để hồ sơ đồng bộ trên toàn ứng dụng.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('profile_fullname'),
              controller: _fullNameCtrl,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: AppColors.text),
              decoration: _fieldDecoration(
                label: 'Họ và tên hiển thị *',
                hint: 'Ví dụ: Vưu Kiên Định',
                icon: Icons.person_outline_rounded,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('profile_email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.text),
              decoration: _fieldDecoration(
                label: 'Địa chỉ Email',
                hint: 'Ví dụ: dinhvuu11@gmail.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (val) {
                final trimmed = val?.trim() ?? '';
                if (trimmed.isNotEmpty &&
                    (!trimmed.contains('@') || !trimmed.contains('.'))) {
                  return 'Địa chỉ email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('profile_phone'),
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppColors.text),
              decoration: _fieldDecoration(
                label: 'Số điện thoại',
                hint: 'Ví dụ: 0909 123 456',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('profile_address'),
              controller: _addressCtrl,
              keyboardType: TextInputType.streetAddress,
              maxLines: 2,
              style: TextStyle(color: AppColors.text),
              decoration: _fieldDecoration(
                label: 'Địa chỉ nhà',
                hint: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố',
                icon: Icons.home_outlined,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Giới tính',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genders.map((g) {
                final selected = _selectedGender == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedGender = selected ? '' : g;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('profile_birthdate'),
              controller: _birthDateCtrl,
              style: TextStyle(color: AppColors.text),
              decoration: _fieldDecoration(
                label: 'Ngày sinh',
                hint: 'dd/MM/yyyy (Ví dụ: 11/11/2004)',
                icon: Icons.cake_outlined,
                suffixIcon: IconButton(
                  tooltip: 'Chọn ngày sinh trên lịch',
                  onPressed: _pickBirthDate,
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('profile_bio'),
              controller: _bioCtrl,
              maxLines: 2,
              style: TextStyle(color: AppColors.text),
              decoration: _fieldDecoration(
                label: 'Giới thiệu bản thân',
                hint: 'Chia sẻ ngắn gọn về gu ăn mặc hoặc sở thích của bạn',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 19),
              label: Text(
                _isSaving ? 'Đang lưu hồ sơ...' : 'Lưu thông tin hồ sơ',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      _syncControllersFromStore();
                      setState(() => _isEditing = false);
                    },
              child: const Text('Hủy chỉnh sửa'),
            ),
          ],
        ),
      ),
    );
  }
}
