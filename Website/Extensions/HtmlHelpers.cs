using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Web;
using System.Web.Mvc;

namespace Website.Extensions
{
    public static class HtmlHelpers
    {
        public static HtmlString GetVersionInfoHtml(this HtmlHelper<dynamic> h)
        {
            var v = FileVersionInfo.GetVersionInfo(Assembly.GetExecutingAssembly().Location);
            var sb = new StringBuilder();
#if !DEBUG
            sb.Append("<!--");
#endif
            sb.Append(new HtmlString(string.Format("- {0} - {1}", v.FileVersion, GetAssemblyInformationalVersion())));
#if !DEBUG
            sb.Append("-->");
#endif
            return new HtmlString(sb.ToString());
        }

        private static string GetAssemblyInformationalVersion()
        {
            object[] attr = Assembly.GetExecutingAssembly().GetCustomAttributes(typeof(AssemblyInformationalVersionAttribute), false);
            if (attr.Length > 0)
            {
                AssemblyInformationalVersionAttribute aca = (AssemblyInformationalVersionAttribute)attr[0];
                return aca.InformationalVersion;
            }

            return null;
        }
    }
}