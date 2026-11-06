
using Microsoft.AspNetCore.Mvc;
using DoAnChuyenNganh.DTOs;
using DoAnChuyenNganh.Models;
using DoAnChuyenNganh.Repositories;

namespace DoAnChuyenNganh.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClothingController : ControllerBase
    {
        private readonly IClothingRepository _clothingRepository;

        public ClothingController(
            IClothingRepository clothingRepository)
        {
            _clothingRepository = clothingRepository;
        }

        // GET: api/Clothing
        [HttpGet]
        public async Task<IActionResult> GetClothes()
        {
            var clothes = await
                _clothingRepository.GetAllAsync();

            return Ok(clothes);
        }

        // GET: api/Clothing/1
        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetClothingById(int id)
        {
            var item = await
                _clothingRepository.GetByIdAsync(id);

            if (item == null)
                return NotFound(new
                {
                    message = "Không tìm thấy trang phục"
                });

            return Ok(item);
        }

        // POST: api/Clothing
        [HttpPost]
        public async Task<IActionResult> AddClothing(
            [FromBody] ClothingRequestDto request)
        {
            var item = new ClothingItem
            {
                Name = request.Name,
                Type = request.Type,
                Color = request.Color,
                Style = request.Style,
                ImagePath = request.ImagePath,
                CreatedAt = DateTime.UtcNow
            };

            await _clothingRepository.AddAsync(item);

            return CreatedAtAction(
                nameof(GetClothingById),
                new { id = item.Id },
                item
            );
        }

        // PUT: api/Clothing/1
        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateClothing(
            int id,
            [FromBody] ClothingRequestDto request)
        {
            var item = await
                _clothingRepository.GetByIdAsync(id);

            if (item == null)
                return NotFound(new
                {
                    message = "Không tìm thấy trang phục"
                });

            item.Name = request.Name;
            item.Type = request.Type;
            item.Color = request.Color;
            item.Style = request.Style;
            item.ImagePath = request.ImagePath;

            await _clothingRepository.UpdateAsync(item);

            return NoContent();
        }

        // DELETE: api/Clothing/1
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteClothing(int id)
        {
            var item = await
                _clothingRepository.GetByIdAsync(id);

            if (item == null)
                return NotFound(new
                {
                    message = "Không tìm thấy trang phục"
                });

            await _clothingRepository.DeleteAsync(id);

            return NoContent();
        }
    }
}
