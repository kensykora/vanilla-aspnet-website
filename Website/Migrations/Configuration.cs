using System;
using System.Collections.Generic;
using System.Data.Entity.Migrations;
using System.Linq;

using Website.Models;

namespace Website.Migrations
{
    using System;
    using System.Linq;

    internal sealed class Configuration : DbMigrationsConfiguration<Website.Models.ApplicationDbContext>
    {
        public Configuration()
        {
        }

        protected override void Seed(Website.Models.ApplicationDbContext context)
        {
#if DEBUG //SEED with Test Data
            context.Users.AddOrUpdate(u => u.Id,
                new ApplicationUser[]
                {
                    new ApplicationUser()
                    {
                        Id = "8caff789-ee23-4e8d-9aeb-463359352614",
                        PasswordHash = "AE68EKPCp1yPwCwjwflGA6KBF4MQMqjlOLaWIPe9P3NWmtWjN0x04suHz5iz0mSMRA==",
                        SecurityStamp = "621e83a5-a9b4-41ef-9604-ad1441f90b76",
                        UserName = "asdf"
                    }
                }
                );
#endif
        }
    }
}