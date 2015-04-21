using System;
using System.Web.Mvc;
using System.Web.Routing;

[assembly: WebActivatorEx.PreApplicationStartMethod(
    typeof(Website.App_Start.LoaderIOVerifierRouteRegistration), "PreStart")]

namespace Website.App_Start {
    public static class LoaderIOVerifierRouteRegistration {
        public static void PreStart() {
            RouteTable.Routes.IgnoreRoute("loaderio-{key}.txt");
        }
    }
}