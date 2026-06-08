using System.Data;
using Microsoft.Data.SqlClient;

namespace FacultyPub.Web.Services;

public interface IDbConnectionFactory
{
    IDbConnection CreateConnection();
}

public sealed class SqlServerConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;

    public SqlServerConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Missing ConnectionStrings:DefaultConnection.");
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}
