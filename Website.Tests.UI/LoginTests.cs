using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using OpenQA.Selenium;

namespace Website.Tests.UI
{
    [TestClass]
    public class LoginTests : UITestBase
    {

        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Interesting")]
        public void user_can_login()
        {
            var username = "asdf"; //Website.Migrations.Configuration.Seed()
            var password = "asdfasdf";

            _driver.FindElement(By.LinkText("Log in")).Click();

            _driver.FindElement(By.Id("UserName")).SendKeys(username);
            _driver.FindElement(By.Id("Password")).SendKeys(password);

            _driver.FindElement(By.XPath("//input[@type=\"submit\"]")).Click();

            Assert.AreEqual("Hello " + username + "!",
                _driver.FindElement(By.XPath("//*[@id=\"logoutForm\"]/ul/li[1]/a")).Text
                );
        }
    }
}
