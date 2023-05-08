using Microsoft.EntityFrameworkCore;

namespace WebPushApplication.Data
{
	public class WebPushDbContext: DbContext

	{
		public WebPushDbContext(DbContextOptions<WebPushDbContext> options)
		   : base(options)
		{
		}

		public DbSet<WebPushApplication.Models.Devices> Devices { get; set; }
	}
}
