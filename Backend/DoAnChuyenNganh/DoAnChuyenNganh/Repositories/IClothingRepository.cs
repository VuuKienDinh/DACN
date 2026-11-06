
using DoAnChuyenNganh.Models;

namespace DoAnChuyenNganh.Repositories
{
    public interface IClothingRepository
    {
        Task<IEnumerable<ClothingItem>> GetAllAsync();

        Task<ClothingItem?> GetByIdAsync(int id);

        Task AddAsync(ClothingItem item);

        Task UpdateAsync(ClothingItem item);

        Task DeleteAsync(int id);
    }
}
