import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';
import '../models/auth_user.dart';
import 'api_client.dart';
import 'clothing_api_service.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _localAccountsKey = 'dailyfit_local_accounts_v1';

  // Đăng ký tài khoản mới (ưu tiên lưu vào SQL Server qua Backend .NET, dự phòng Offline nếu mất mạng)
  Future<AuthUser> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final cleanUsername = username.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw const AuthException('Vui lòng nhập họ và tên hiển thị');
    }
    if (cleanUsername.length < 3 || cleanUsername.contains(' ')) {
      throw const AuthException(
        'Tên đăng nhập phải từ 3 ký tự và không chứa khoảng trắng',
      );
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw const AuthException('Địa chỉ email không hợp lệ');
    }
    if (password.length < 6) {
      throw const AuthException('Mật khẩu phải có ít nhất 6 ký tự');
    }

    if (ConfigUrl.hasBackendUrl) {
      try {
        final response = await ApiClient(
          timeout: const Duration(seconds: 6),
        ).post(
          'Auth/register',
          body: {
            'fullName': cleanName,
            'username': cleanUsername,
            'email': cleanEmail,
            'password': password,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final user = AuthUser.fromJson(data, isLocalOverride: false);
          await _cacheOfflineCredential(user: user, password: password);
          return user;
        }

        if (response.statusCode == 400 || response.statusCode == 409) {
          throw AuthException(
            _extractServerMessage(
              response.body,
              fallback: 'Thông tin đăng ký không hợp lệ hoặc đã tồn tại',
            ),
          );
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        // Nếu Backend đang tắt hoặc mất kết nối mạng -> chuyển sang lưu cục bộ an toàn
      }
    }

    return _registerOffline(
      fullName: cleanName,
      username: cleanUsername,
      email: cleanEmail,
      password: password,
    );
  }

  // Đăng nhập bằng Tên đăng nhập hoặc Email
  Future<AuthUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final cleanIdentifier = usernameOrEmail.trim();
    if (cleanIdentifier.isEmpty || password.isEmpty) {
      throw const AuthException('Vui lòng nhập đầy đủ tài khoản và mật khẩu');
    }

    if (ConfigUrl.hasBackendUrl) {
      try {
        final response = await ApiClient(
          timeout: const Duration(seconds: 6),
        ).post(
          'Auth/login',
          body: {
            'usernameOrEmail': cleanIdentifier,
            'password': password,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final serverUser = AuthUser.fromJson(data, isLocalOverride: false);
          final merged = await _mergeWithCachedAccount(serverUser);
          await _cacheOfflineCredential(user: merged, password: password);
          return merged;
        }

        if (response.statusCode == 400 || response.statusCode == 401) {
          throw AuthException(
            _extractServerMessage(
              response.body,
              fallback: 'Tên đăng nhập/Email hoặc mật khẩu không chính xác',
            ),
          );
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        // Nếu Backend ngoại tuyến -> kiểm tra tài khoản đã lưu cục bộ trên thiết bị
      }
    }

    return _loginOffline(
      identifier: cleanIdentifier,
      password: password,
    );
  }

  // Lấy thông tin tài khoản gốc trực tiếp từ SQL Server theo ID
  Future<AuthUser?> fetchRawServerProfile(int userId) async {
    if (!ConfigUrl.hasBackendUrl || userId <= 0) return null;
    try {
      final response = await ApiClient(
        timeout: const Duration(seconds: 5),
      ).get('Auth/profile/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthUser.fromJson(data, isLocalOverride: false);
      }
    } catch (_) {}
    return null;
  }

  // Lấy thông tin tài khoản từ Backend theo ID (có trộn dự phòng cục bộ)
  Future<AuthUser?> fetchProfile(int userId) async {
    final serverUser = await fetchRawServerProfile(userId);
    if (serverUser == null) return null;
    return _mergeWithCachedAccount(serverUser);
  }

  // Cập nhật thông tin hồ sơ cá nhân & ảnh đại diện (lưu SQL Server + đồng bộ cục bộ)
  Future<AuthUser> updateProfile(
    AuthUser updated, {
    String? newAvatarLocalPath,
    String? newAvatarFileName,
  }) async {
    final cleanName = updated.fullName.trim();
    final cleanEmail = updated.email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw const AuthException('Vui lòng nhập họ và tên hiển thị');
    }
    if (cleanEmail.isNotEmpty &&
        (!cleanEmail.contains('@') || !cleanEmail.contains('.'))) {
      throw const AuthException('Địa chỉ email không hợp lệ');
    }

    String resolvedAvatar = updated.avatarUrl.trim();
    if (newAvatarLocalPath != null && newAvatarLocalPath.trim().isNotEmpty) {
      resolvedAvatar = newAvatarLocalPath.trim();
      if (ConfigUrl.hasBackendUrl) {
        try {
          final rawName = (newAvatarFileName ?? '').trim();
          final safeName = rawName.contains('.') ? rawName : 'avatar.jpg';
          resolvedAvatar = await ClothingApiService().uploadImage(
            resolvedAvatar,
            safeName,
          );
        } catch (_) {
          // Nếu đang ngoại tuyến -> giữ đường dẫn ảnh cục bộ trên máy để tự đồng bộ sau
        }
      }
    }

    final candidate = updated.copyWith(
      fullName: cleanName,
      email: cleanEmail.isEmpty ? updated.email : cleanEmail,
      phoneNumber: updated.phoneNumber.trim(),
      address: updated.address.trim(),
      gender: updated.gender.trim(),
      birthDate: updated.birthDate.trim(),
      bio: updated.bio.trim(),
      avatarUrl: resolvedAvatar,
    );

    if (!candidate.isLocalAccount &&
        candidate.id > 0 &&
        ConfigUrl.hasBackendUrl) {
      try {
        final response = await ApiClient(
          timeout: const Duration(seconds: 6),
        ).put(
          'Auth/profile/${candidate.id}',
          body: {
            'fullName': candidate.fullName,
            'email': candidate.email,
            'phoneNumber': candidate.phoneNumber,
            'address': candidate.address,
            'gender': candidate.gender,
            'birthDate': candidate.birthDate,
            'bio': candidate.bio,
            'avatarUrl': candidate.avatarUrl,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final serverUser = AuthUser.fromJson(data, isLocalOverride: false);
          await _upsertCachedAccountProfile(serverUser);
          return serverUser;
        }

        if (response.statusCode == 400 || response.statusCode == 409) {
          throw AuthException(
            _extractServerMessage(
              response.body,
              fallback: 'Thông tin hồ sơ không hợp lệ hoặc email đã tồn tại',
            ),
          );
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        // Nếu Backend đang chạy bản cũ hoặc mất kết nối -> vẫn lưu hồ sơ cục bộ an toàn
      }
    } else {
      final accounts = await _loadOfflineAccounts();
      final lowerUser = candidate.username.toLowerCase();
      for (final acc in accounts) {
        final accUser = (acc['username'] ?? '').toString().toLowerCase();
        final accEmail = (acc['email'] ?? '').toString().toLowerCase();
        if (accUser != lowerUser &&
            cleanEmail.isNotEmpty &&
            accEmail == cleanEmail) {
          throw const AuthException(
            'Email này đã được sử dụng bởi tài khoản khác',
          );
        }
      }
    }

    await _upsertCachedAccountProfile(candidate);
    return candidate;
  }

  String _extractServerMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        final msg = decoded['message'].toString().trim();
        if (msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return fallback;
  }

  // --- Hỗ trợ lưu dự phòng Offline & giữ thông tin hồ sơ đồng nhất ---
  Future<AuthUser> _mergeWithCachedAccount(AuthUser serverUser) async {
    final accounts = await _loadOfflineAccounts();
    final lowerUser = serverUser.username.toLowerCase();
    for (final acc in accounts) {
      if ((acc['username'] ?? '').toString().toLowerCase() == lowerUser) {
        final cached = AuthUser.fromJson(acc);
        return serverUser.copyWith(
          phoneNumber: serverUser.phoneNumber.isNotEmpty
              ? serverUser.phoneNumber
              : cached.phoneNumber,
          address:
              serverUser.address.isNotEmpty ? serverUser.address : cached.address,
          gender:
              serverUser.gender.isNotEmpty ? serverUser.gender : cached.gender,
          birthDate: serverUser.birthDate.isNotEmpty
              ? serverUser.birthDate
              : cached.birthDate,
          bio: serverUser.bio.isNotEmpty ? serverUser.bio : cached.bio,
          avatarUrl: serverUser.avatarUrl.isNotEmpty
              ? serverUser.avatarUrl
              : cached.avatarUrl,
        );
      }
    }
    return serverUser;
  }

  Future<void> _upsertCachedAccountProfile(AuthUser user) async {
    final accounts = await _loadOfflineAccounts();
    final lowerUser = user.username.toLowerCase();
    String? existingDigest;

    for (final acc in accounts) {
      if ((acc['username'] ?? '').toString().toLowerCase() == lowerUser) {
        existingDigest = acc['passwordDigest']?.toString();
        break;
      }
    }

    accounts.removeWhere(
      (a) => (a['username'] ?? '').toString().toLowerCase() == lowerUser,
    );
    accounts.add({
      ...user.toJson(),
      if (existingDigest != null && existingDigest.isNotEmpty)
        'passwordDigest': existingDigest,
    });
    await _saveOfflineAccounts(accounts);
  }

  Future<AuthUser> _registerOffline({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final accounts = await _loadOfflineAccounts();
    final lowerUser = username.toLowerCase();

    for (final acc in accounts) {
      if ((acc['username'] ?? '').toString().toLowerCase() == lowerUser) {
        throw const AuthException('Tên đăng nhập này đã được sử dụng');
      }
      if ((acc['email'] ?? '').toString().toLowerCase() == email) {
        throw const AuthException('Email này đã được đăng ký tài khoản');
      }
    }

    final user = AuthUser(
      id: DateTime.now().millisecondsSinceEpoch % 1000000,
      fullName: fullName,
      username: username,
      email: email,
      isLocalAccount: true,
    );

    accounts.add({
      ...user.toJson(),
      'passwordDigest': _digestPassword(username.toLowerCase(), password),
    });
    await _saveOfflineAccounts(accounts);
    return user;
  }

  Future<AuthUser> _loginOffline({
    required String identifier,
    required String password,
  }) async {
    final accounts = await _loadOfflineAccounts();
    final lowerId = identifier.toLowerCase();

    for (final acc in accounts) {
      final accUser = (acc['username'] ?? '').toString();
      final accEmail = (acc['email'] ?? '').toString().toLowerCase();
      if (accUser.toLowerCase() == lowerId || accEmail == lowerId) {
        final expected = (acc['passwordDigest'] ?? '').toString();
        final actual = _digestPassword(accUser.toLowerCase(), password);
        if (expected == actual) {
          return AuthUser.fromJson(acc, isLocalOverride: true);
        }
        throw const AuthException(
          'Tên đăng nhập/Email hoặc mật khẩu không chính xác',
        );
      }
    }

    throw const AuthException(
      'Không tìm thấy tài khoản (hãy đăng ký mới hoặc bật Backend API)',
    );
  }

  Future<void> _cacheOfflineCredential({
    required AuthUser user,
    required String password,
  }) async {
    final accounts = await _loadOfflineAccounts();
    final lowerUser = user.username.toLowerCase();
    accounts.removeWhere(
      (a) => (a['username'] ?? '').toString().toLowerCase() == lowerUser,
    );
    accounts.add({
      ...user.toJson(),
      'passwordDigest': _digestPassword(lowerUser, password),
    });
    await _saveOfflineAccounts(accounts);
  }

  Future<List<Map<String, dynamic>>> _loadOfflineAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localAccountsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveOfflineAccounts(List<Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localAccountsKey, jsonEncode(accounts));
  }

  // Băm một chiều có salt cho chế độ dự phòng cục bộ
  String _digestPassword(String normalizedUsername, String password) {
    final bytes = utf8.encode('dailyfit_v1::$normalizedUsername::$password');
    int h1 = 0x811c9dc5;
    int h2 = 0x01000193;
    for (int round = 0; round < 64; round++) {
      for (final b in bytes) {
        h1 = ((h1 ^ b) * 0x01000193) & 0x7fffffff;
        h2 = ((h2 + h1 + round) * 0x5bd1e995) & 0x7fffffff;
      }
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
  }
}
