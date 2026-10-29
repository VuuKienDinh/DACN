
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace DoAnChuyenNganh.Controllers
{
    public class ClothingImageUploadRequest
    {
        [Required]
        public IFormFile File { get; set; } = null!;
    }

    [ApiController]
    [Route("api/Clothing")]
    public class ClothingImagesController : ControllerBase
    {
        private readonly IWebHostEnvironment _environment;

        public ClothingImagesController(
            IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        [HttpPost("upload-image")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(5 * 1024 * 1024)]
        public async Task<IActionResult> UploadImage(
            [FromForm] ClothingImageUploadRequest request)
        {
            var file = request.File;

            if (file == null || file.Length == 0)
            {
                return BadRequest("Vui lòng chọn ảnh.");
            }

            // Giới hạn ảnh 5 MB
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(
                    "Dung lượng ảnh không được vượt quá 5 MB.");
            }

            // Chỉ chấp nhận các định dạng ảnh thông dụng
            var extension = Path.GetExtension(
                file.FileName).ToLowerInvariant();

            var allowedExtensions = new[]
            {
                ".jpg", ".jpeg", ".png", ".webp"
            };

            var allowedTypes = new[]
            {
                "image/jpeg", "image/png", "image/webp"
            };

            if (!allowedExtensions.Contains(extension) ||
                !allowedTypes.Contains(file.ContentType))
            {
                return BadRequest(
                    "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.");
            }

            // Đường dẫn thư mục lưu ảnh
            var webRoot = _environment.WebRootPath ??
                Path.Combine(
                    _environment.ContentRootPath,
                    "wwwroot");

            var uploadFolder = Path.Combine(
                webRoot, "uploads");

            Directory.CreateDirectory(uploadFolder);

            // Tạo tên ảnh duy nhất
            var fileName =
                $"{Guid.NewGuid():N}{extension}";

            var filePath = Path.Combine(
                uploadFolder, fileName);

            // Lưu ảnh vào Backend
            await using (var stream =
                new FileStream(
                    filePath, FileMode.CreateNew))
            {
                await file.CopyToAsync(stream);
            }

            // Trả về đường dẫn ảnh
            var imagePath = $"/uploads/{fileName}";

            return Ok(new
            {
                imagePath = imagePath
            });
        }
    }
}
