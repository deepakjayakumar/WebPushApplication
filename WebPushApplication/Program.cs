using Microsoft.EntityFrameworkCore;
using System.Configuration;
using WebPushApplication.Data;

var builder = WebApplication.CreateBuilder(args);

var configuration = new ConfigurationBuilder().AddJsonFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appsettings.json")).Build();
// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<WebPushDbContext>(option => option.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
	app.UseExceptionHandler("/Home/Error");
	// The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
	app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

	if (configuration.GetSection("VapidKeys")["PublicKey"].Length == 0 || configuration.GetSection("VapidKeys")["PrivateKey"].Length == 0)
	{
#pragma warning disable MVC1005 // Cannot use UseMvc with Endpoint Routing
	app.UseMvc(routes =>
	{
		routes.MapRoute(
			name: "default",
			template: "{controller=WebPush}/{action=GenerateKeys}/{id?}");
	});
#pragma warning restore MVC1005 // Cannot use UseMvc with Endpoint Routing

	return;
	}
#pragma warning disable MVC1005 // Cannot use UseMvc with Endpoint Routing
//app.UseMvc();
#pragma warning restore MVC1005 // Cannot use UseMvc with Endpoint Routing

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
	name: "default",
	pattern: "{controller=Devices}/{action=Index}/{id?}");

app.Run();
