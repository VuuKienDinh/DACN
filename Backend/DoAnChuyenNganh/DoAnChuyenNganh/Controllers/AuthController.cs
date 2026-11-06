using System.Security.Cryptography;
using DoAnChuyenNganh.Data;
using DoAnChuyenNganh.DTOs;
using DoAnChuyenNganh.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DoAnChuyenNganh.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AuthController(ApplicationDbContext context)
        {
            _context = context;
        }

        private static AuthResponseDto MapToResponse(User user, string message)
        {
            return new AuthResponseDto
            {
                Id = user.Id,
                FullName = user.FullName,
                Username = user.Username,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Address = user.Address,
                Gender = user.Gender,
                BirthDate = user.BirthDate,
                Bio = user.Bio,
                AvatarUrl = user.AvatarUrl,
                CreatedAt = user.CreatedAt,
                Message = message
            };
        }

        // POST: api/Auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequestDto request)
        {
            var fullName = request.FullName?.Trim() ?? string.Empty;
            var username = request.Username?.Trim() ?? string.Empty;
            var email = (request.Email?.Trim() ?? string.Empty).ToLowerInvariant();
            var password = request.Password ?? string.Empty;

            if (string.IsNullOrWhiteSpace(fullName))
                return BadRequest(new { message = "Vui lòng nhập họ và tên" });

            if (username.Length < 3 || username.Contains(' '))
                return BadRequest(new { message = "Tên đăng nhập phải từ 3 ký tự và không chứa khoảng trắng" });

            if (string.IsNullOrWhiteSpace(email) || !email.Contains('@') || !email.Contains('.'))
                return BadRequest(new { message = "Địa chỉ email không hợp lệ" });

            if (password.Length < 6)
                return BadRequest(new { message = "Mật khẩu phải có ít nhất 6 ký tự" });

            var usernameExists = await _context.Users
                .AnyAsync(u => u.Username == username);
            if (usernameExists)
                return Conflict(new { message = "Tên đăng nhập này đã được sử dụng" });

            var emailExists = await _context.Users
                .AnyAsync(u => u.Email == email);
            if (emailExists)
                return Conflict(new { message = "Email này đã được đăng ký tài khoản" });

            var user = new User
            {
                FullName = fullName,
                Username = username,
                Email = email,
                PasswordHash = HashPassword(password),
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return StatusCode(201, MapToResponse(user, "Đăng ký tài khoản thành công"));
        }

        // POST: api/Auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
        {
            var identifier = request.UsernameOrEmail?.Trim() ?? string.Empty;
            var password = request.Password ?? string.Empty;

            if (string.IsNullOrWhiteSpace(identifier) || string.IsNullOrEmpty(password))
                return BadRequest(new { message = "Vui lòng nhập đầy đủ tài khoản và mật khẩu" });

            var normalizedEmail = identifier.ToLowerInvariant();

            var user = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Username == identifier || u.Email == normalizedEmail);

            if (user == null || !VerifyPassword(password, user.PasswordHash))
                return Unauthorized(new { message = "Tên đăng nhập/Email hoặc mật khẩu không chính xác" });

            return Ok(MapToResponse(user, "Đăng nhập thành công"));
        }

        // GET: api/Auth/profile/1
        [HttpGet("profile/{id:int}")]
        public async Task<IActionResult> GetProfile(int id)
        {
            var user = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });

            return Ok(MapToResponse(user, "Lấy thông tin tài khoản thành công"));
        }

        // PUT: api/Auth/profile/1
        [HttpPut("profile/{id:int}")]
        public async Task<IActionResult> UpdateProfile(int id, [FromBody] UpdateProfileRequestDto request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy tài khoản" });

            var fullName = request.FullName?.Trim() ?? string.Empty;
            var email = (request.Email?.Trim() ?? string.Empty).ToLowerInvariant();

            if (string.IsNullOrWhiteSpace(fullName))
                return BadRequest(new { message = "Họ và tên không được để trống" });

            if (!string.IsNullOrWhiteSpace(email))
            {
                if (!email.Contains('@') || !email.Contains('.'))
                    return BadRequest(new { message = "Địa chỉ email không hợp lệ" });

                var duplicateEmail = await _context.Users
                    .AnyAsync(u => u.Email == email && u.Id != id);
                if (duplicateEmail)
                    return Conflict(new { message = "Email này đã được sử dụng bởi tài khoản khác" });

                user.Email = email;
            }

            user.FullName = fullName;
            user.PhoneNumber = request.PhoneNumber?.Trim();
            user.Address = request.Address?.Trim();
            user.Gender = request.Gender?.Trim();
            user.BirthDate = request.BirthDate?.Trim();
            user.Bio = request.Bio?.Trim();
            user.AvatarUrl = request.AvatarUrl?.Trim();

            await _context.SaveChangesAsync();

            return Ok(MapToResponse(user, "Cập nhật hồ sơ thành công"));
        }

        // Băm mật khẩu an toàn bằng chuẩn PBKDF2-SHA256 tích hợp sẵn của .NET 8 (không cần thư viện ngoài)
        private static string HashPassword(string password)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(16);
            byte[] hash = Rfc2898DeriveBytes.Pbkdf2(
                password,
                salt,
                iterations: 100_000,
                hashAlgorithm: HashAlgorithmName.SHA256,
                outputLength: 32
            );
            return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
        }

        private static bool VerifyPassword(string password, string storedHash)
        {
            var parts = storedHash.Split('.');
            if (parts.Length != 2) return false;

            try
            {
                byte[] salt = Convert.FromBase64String(parts[0]);
                byte[] expectedHash = Convert.FromBase64String(parts[1]);
                byte[] actualHash = Rfc2898DeriveBytes.Pbkdf2(
                    password,
                    salt,
                    iterations: 100_000,
                    hashAlgorithm: HashAlgorithmName.SHA256,
                    outputLength: 32
                );
                return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
            }
            catch
            {
                return false;
            }
        }
    }
}
