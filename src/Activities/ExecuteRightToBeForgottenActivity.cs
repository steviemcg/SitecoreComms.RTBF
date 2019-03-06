using System;
using Microsoft.Extensions.Logging;
using Sitecore.Framework.Conditions;
using Sitecore.XConnect;
using Sitecore.XConnect.Client;
using Sitecore.Xdb.MarketingAutomation.Core.Activity;
using Sitecore.Xdb.MarketingAutomation.Core.Processing.Plan;

namespace SitecoreComms.RTBF.Activities
{
    public class ExecuteRightToBeForgottenActivity : IActivity
    {
        private readonly IXdbContext _xdbContext;
        private readonly ILogger<IActivity> _logger;

        public IActivityServices Services { get; set; }

        public ExecuteRightToBeForgottenActivity(IXdbContext xdbContext, ILogger<ExecuteRightToBeForgottenActivity> logger)
        {
            Condition.Requires(xdbContext, nameof(xdbContext)).IsNotNull();
            Condition.Requires(logger, nameof(logger)).IsNotNull();

            _xdbContext = xdbContext;
            _logger = logger;
        }

        public ActivityResult Invoke(IContactProcessingContext context)
        {
            Condition.Requires(context, nameof(context)).IsNotNull();

            try
            {
                _xdbContext.ExecuteRightToBeForgotten(context.Contact);
                _xdbContext.Submit();

                return new SuccessExitPlan();
            }
            catch (Exception e)
            {
                _logger.LogError(0, e, "ExecuteRightToBeForgottenActivity failed");
                return new Failure("ExecuteRightToBeForgottenActivity failed", TimeSpan.FromMinutes(5));
            }
        }
    }
}