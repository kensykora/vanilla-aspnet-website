using System;
using System.Collections.Generic;
using System.Linq;

using Microsoft.VisualStudio.TestTools.UnitTesting;

using OpenQA.Selenium;

namespace Website.Tests.UI
{
    [TestClass]
    public class HomepageTests : UITestBase
    {
        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Not Interesting")]
        public void can_visit_homepage()
        {
            Assert.AreEqual("ASP.NET", _driver.FindElement(By.XPath("//h1")).Text);
        }

        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Not Interesting")]
        public void can_browse_to_about_page()
        {
            _driver.FindElement(By.LinkText("About")).Click();
            Assert.AreEqual("About.", _driver.FindElement(By.XPath("//h2")).Text);
        }

        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Not Interesting")]
        public void can_browse_to_contact_page()
        {
            _driver.FindElement(By.LinkText("Contact")).Click();
            Assert.AreEqual("Contact.", _driver.FindElement(By.XPath("//h2")).Text);
        }

        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Not Interesting")]
        public void can_browse_to_login()
        {
            _driver.FindElement(By.LinkText("Log in")).Click();
            Assert.AreEqual("Log in.", _driver.FindElement(By.XPath("//h2")).Text);
        }

        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Not Interesting")]
        public void can_browse_to_registration()
        {
            _driver.FindElement(By.LinkText("Register")).Click();
            Assert.AreEqual("Register.", _driver.FindElement(By.XPath("//h2")).Text);
        }
    }
}