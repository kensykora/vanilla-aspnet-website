using System;
using System.Collections.Generic;
using System.Linq;

using Microsoft.VisualStudio.TestTools.UnitTesting;

using Selenium.WebDriver.Extensions.JQuery;

namespace Website.Tests.UI
{
    [TestClass]
    public class RegistrationTests : UITestBase
    {
        [TestMethod]
        [TestCategory("UI")]
        [TestCategory("Interesting")]
        public void user_can_register_new_account()
        {
            var username = "testuser" + Guid.NewGuid().ToString().Replace("-", "");
            var password = Guid.NewGuid().ToString();

            _driver.FindElement(By.LinkText("Register")).Click();

            _driver.FindElement(By.Id("UserName")).SendKeys(username);
            _driver.FindElement(By.Id("Password")).SendKeys(password);
            _driver.FindElement(By.Id("ConfirmPassword")).SendKeys(password);

            _driver.FindElement(By.XPath("//input[@type=\"submit\"]")).Click();

            Assert.AreEqual("Hello " + username + "!",
                _driver.FindElement(By.XPath("//*[@id=\"logoutForm\"]/ul/li[1]/a")).Text
                );
        }
    }
}