using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebPush;
using WebPushApplication.Data;
using WebPushApplication.Models;

namespace WebPushApplication.Controllers
{
	public class DevicesController : Controller
	{

		private readonly WebPushDbContext _context;

		private readonly IConfiguration _configuration;

		public DevicesController(WebPushDbContext context, IConfiguration configuration)
		{
			_context = context;
			_configuration = configuration;
		}

		public async Task<IActionResult> Index()
		{
			return View(await _context.Devices.ToListAsync());
			//return View();
		}
		public IActionResult Create()
		{
			ViewBag.PublicKey = _configuration.GetSection("VapidKeys")["PublicKey"];

			return View();
		}

		[HttpPost]
		[ValidateAntiForgeryToken]
		public async Task<IActionResult> Create([Bind("Id,Name,PushEndpoint,PushP256DH,PushAuth")] Devices devices)
		{
			if (ModelState.IsValid)
			{
				_context.Add(devices);
				await _context.SaveChangesAsync();
				return RedirectToAction(nameof(Index));
			}

			return View(devices);
		}



		// GET: Devices/Delete/5
		public async Task<IActionResult> Delete(int? id)
		{
			if (id == null)
			{
				return NotFound();
			}

			var devices = await _context.Devices
				.SingleOrDefaultAsync(m => m.Id == id);
			if (devices == null)
			{
				return NotFound();
			}

			return View(devices);
		}


		// POST: Devices/Delete/5
		[HttpPost, ActionName("Delete")]
		[ValidateAntiForgeryToken]
		public async Task<IActionResult> DeleteConfirmed(int id)
		{
			var devices = await _context.Devices.SingleOrDefaultAsync(m => m.Id == id);
			_context.Devices.Remove(devices);
			await _context.SaveChangesAsync();
			return RedirectToAction(nameof(Index));
		}
	}
}
