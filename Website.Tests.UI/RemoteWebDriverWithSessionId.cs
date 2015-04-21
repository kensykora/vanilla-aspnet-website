using System;
using System.Collections.Generic;
using System.Linq;

using OpenQA.Selenium.Remote;
using System.Reflection;

namespace Website.Tests.UI
{
    public class RemoteWebDriverWithSessionId : RemoteWebDriver
    {
        public RemoteWebDriverWithSessionId(Uri uri, DesiredCapabilities capabilities)
            : base(uri, capabilities)
        {
        }

        public string SessionId
        {
            get
            {
                var sessionIdProperty = typeof(RemoteWebDriver).GetProperty("SessionId", BindingFlags.Instance | BindingFlags.NonPublic);
                if (sessionIdProperty != null)
                {
                    SessionId sessionId = sessionIdProperty.GetValue(this, null) as SessionId;
                    if (sessionId != null)
                    {
                        return sessionId.ToString();
                    }
                };

                return null;
            }
        }
    }
}