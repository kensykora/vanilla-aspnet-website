using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

using Microsoft.VisualStudio.TestTools.UnitTesting;

using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;
using OpenQA.Selenium.Remote;

namespace Website.Tests.UI
{
    [TestClass]
    public abstract class UITestBase
    {
        protected IWebDriver _driver;
        public TestContext TestContext { get; set; }

        [TestInitialize]
        public void Init()
        {
            Trace.Listeners.Add(new TextWriterTraceListener(Console.Out));

            if (Config.TestType == Config.TestTypes.Remote)
            {
                _driver = _GetRemoteDriver(Config.Browser, Config.BrowserVersion, Config.OperatingSystem);
            }
            else
            {
                _driver = _GetLocalChromeDriver();
            }

            _driver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromSeconds(Config.SeleniumIdleTimeout));
            _driver.Manage().Timeouts().SetPageLoadTimeout(TimeSpan.FromSeconds(Config.SeleniumMaxDuration));

            _driver.Navigate().GoToUrl(Config.StartingUrl);
        }

        private IWebDriver _GetLocalChromeDriver()
        {
            var result = new ChromeDriver();

            return result;
        }

        private IWebDriver _GetRemoteDriver(string browser, string version, string platform)
        {
            // construct the url to sauce labs
            Uri commandExecutorUri = new Uri("http://ondemand.saucelabs.com/wd/hub");

            // set up the desired capabilities
            DesiredCapabilities desiredCapabilites = new DesiredCapabilities(browser, version, Platform.CurrentPlatform); // set the desired browser
            desiredCapabilites.SetCapability("platform", platform); // operating system to use
            desiredCapabilites.SetCapability("username", Config.SauceLabsAccountName); // supply sauce labs username
            desiredCapabilites.SetCapability("accessKey", Config.SauceLabsAccountKey); // supply sauce labs account key
            desiredCapabilites.SetCapability("name", CurrentTestName); // give the test a name
            desiredCapabilites.SetCapability("build", Config.BuildNumber);

            // start a new remote web driver session on sauce labs
            var result = new RemoteWebDriverWithSessionId(commandExecutorUri, desiredCapabilites);

            Trace.WriteLine(string.Format("\nSauceOnDemandSessionID={0} job-name={1}",
                        ((RemoteWebDriverWithSessionId)result).SessionId, CurrentTestName
                        ));

            return result;
        }

        /// <summary>called at the end of each test to tear it down</summary>
        [TestCleanup]
        public void CleanUp()
        {
            // get the status of the current test
            bool passed = TestContext.CurrentTestOutcome == UnitTestOutcome.Passed;
            try
            {
                if (_driver is RemoteWebDriverWithSessionId)
                {
                    // log the result to sauce labs
                    ((IJavaScriptExecutor)_driver).ExecuteScript("sauce:job-result=" + (passed ? "passed" : "failed"));
                }
            }
            finally
            {
                // terminate the remote webdriver session
                _driver.Quit();
            }
        }

        private string CurrentTestName
        {
            get { return Config.BuildNumber + "-" + TestContext.TestName; }
        }
    }
}