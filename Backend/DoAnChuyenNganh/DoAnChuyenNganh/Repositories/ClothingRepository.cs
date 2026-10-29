
using Microsoft.EntityFrameworkCore;
using DoAnChuyenNganh.Data;
using DoAnChuyenNganh.Models;

namespace DoAnChuyenNganh.Repositories
{
    public class ClothingRepository : IClothingRepository
    {
        private readonly ApplicationDbContext _context;

        public ClothingRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        // Lấy toàn bộ quần áo
        public async Task<IEnumerable<ClothingItem>>
            GetAllAsync()
        {
            return await _context.ClothingItems
                .AsNoTracking()
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();
        }

        // Tìm quần áo theo ID
        public async Task<ClothingItem?> GetByIdAsync(int id)
        {
            return await _context.ClothingItems
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);
        }

        // Thêm quần áo
        public async Task AddAsync(ClothingItem item)
        {
            await _context.ClothingItems.AddAsync(item);
            await _context.SaveChangesAsync();
        }

        // Cập nhật quần áo
        public async Task UpdateAsync(ClothingItem item)
        {
            _context.ClothingItems.Update(item);
            await _context.SaveChangesAsync();
        }

        // Xóa quần áo
        public async Task DeleteAsync(int id)
        {
            var item = await _context.ClothingItems
                .FindAsync(id);

            if (item != null)
            {
                _context.ClothingItems.Remove(item);
                await _context.SaveChangesAsync();
            }
        }
    }
}
