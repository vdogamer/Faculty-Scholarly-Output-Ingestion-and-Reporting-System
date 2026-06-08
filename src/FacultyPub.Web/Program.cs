using FacultyPub.Web.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.Configure<OpenAlexOptions>(builder.Configuration.GetSection("OpenAlex"));
builder.Services.AddHttpClient<IOpenAlexClient, OpenAlexClient>();
builder.Services.AddSingleton<IdentifierClassifier>();
builder.Services.AddScoped<IDbConnectionFactory, SqlServerConnectionFactory>();
builder.Services.AddScoped<FacultyRepository>();
builder.Services.AddScoped<OpenAlexSyncService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapRazorPages();
app.Run();
