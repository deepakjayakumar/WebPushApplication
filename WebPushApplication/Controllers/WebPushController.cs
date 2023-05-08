using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebPush;
using WebPushApplication.Data;

namespace WebPushApplication.Controllers
{
	public class WebPushController : Controller
	{
		private readonly IConfiguration _configuration;

		private readonly WebPushDbContext _context;

		public WebPushController(WebPushDbContext context, IConfiguration configuration)
		{
			_context = context;
			_configuration = configuration;
		}

		public IActionResult Send(int? id)
		{
			return View();
		}

		[HttpPost, ActionName("Send")]
		[ValidateAntiForgeryToken]
		public async Task<IActionResult> Send(int id)
		{
			var payload = Request.Form["payload"];
			var device = await _context.Devices.SingleOrDefaultAsync(m => m.Id == id);

			string vapidPublicKey = _configuration.GetSection("VapidKeys")["PublicKey"];
			string vapidPrivateKey = _configuration.GetSection("VapidKeys")["PrivateKey"];

			var pushSubscription = new PushSubscription(device.PushEndpoint, device.PushP256DH, device.PushAuth);
			var vapidDetails = new VapidDetails("mailto:example@example.com", vapidPublicKey, vapidPrivateKey);

			var webPushClient = new WebPushClient();
			webPushClient.SendNotification(pushSubscription, payload, vapidDetails);

			return View();
		}

		public IActionResult GenerateKeys()
		{
			var keys = VapidHelper.GenerateVapidKeys();
			ViewBag.PublicKey = keys.PublicKey;
			ViewBag.PrivateKey = keys.PrivateKey;
			return View();
		}

		
	}
}
