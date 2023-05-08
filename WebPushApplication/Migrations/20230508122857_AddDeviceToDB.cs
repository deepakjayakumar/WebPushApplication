using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WebPushApplication.Migrations
{
    /// <inheritdoc />
    public partial class AddDeviceToDB : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Devices",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PushEndpoint = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PushP256DH = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PushAuth = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Devices", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Devices");
        }
    }
}
