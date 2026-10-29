
using System.ComponentModel.DataAnnotations;

namespace DoAnChuyenNganh.DTOs
{
    public class ClothingRequestDto
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Type { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Color { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Style { get; set; } = string.Empty;

        public string? ImagePath { get; set; }
    }
}
