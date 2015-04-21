using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Runtime.Remoting.Messaging;

namespace Website.Tests.UI
{
    public static class Config
    {
        public static string SauceLabsAccountName
        {
            get { return Environment.GetEnvironmentVariable("SAUCELABS_ACCOUNT_NAME"); }
        }

        public static string SauceLabsAccountKey
        {
            get { return Environment.GetEnvironmentVariable("SAUCELABS_ACCOUNT_KEY"); }
        }

        public static string StartingUrl
        {
            get { return string.IsNullOrEmpty(SeleniumStartingUrl) ? "http://localhost:51206/" : SeleniumStartingUrl; }
        }

        public static string SeleniumStartingUrl
        {
            get { return Environment.GetEnvironmentVariable("SELENIUM_STARTING_URL") ?? string.Empty; }
        }

        public enum TestTypes
        {
            Local,
            Remote
        }

        public static TestTypes TestType
        {
            get
            {
                return string.IsNullOrEmpty(SeleniumStartingUrl) ? TestTypes.Local : TestTypes.Remote;
            }
        }

        public static string Platform
        {
            get { return Environment.GetEnvironmentVariable("TEST_PLATFORM") ?? "WIN8_1"; }
        }

        public static string OperatingSystem
        {
            get { return Environment.GetEnvironmentVariable("TEST_OS") ?? "Windows 2012 R2"; }
        }

        public static string Browser
        {
            get { return Environment.GetEnvironmentVariable("TEST_BROWSER") ?? "chrome"; }
        }

        public static string BrowserVersion
        {
            get { return Environment.GetEnvironmentVariable("TEST_BROWSER_VERSION") ?? "37"; }
        }

        public static string SeleniumHost
        {
            get { return Environment.GetEnvironmentVariable("SELENIUM_HOST") ?? "ondemand.saucelabs.com"; }
        }

        public static string SeleniumPort
        {
            get { return Environment.GetEnvironmentVariable("SELENIUM_PORT") ?? "4444"; }
        }

        public static string BuildNumber
        {
            get { return Environment.GetEnvironmentVariable("BUILD_NAME") ?? string.Empty; }
        }

        public static int SeleniumIdleTimeout
        {
            get
            {
                int result;

                if (!int.TryParse(Environment.GetEnvironmentVariable("SELENIUM_IDLE_TIMEOUT"), out result))
                {
                    result = 300;
                }
                    
                return result;
            }
        }

        public static int SeleniumMaxDuration
        {
            get
            {
                int result;

                if (!int.TryParse(Environment.GetEnvironmentVariable("SELENIUM_MAX_DURATION"), out result))
                {
                    result = 300;    
                }

                return result;
            }
        }
    }
}