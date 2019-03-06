using System;
using Microsoft.Extensions.Logging;
using Sitecore.Framework.Conditions;
using Sitecore.Framework.Messaging;
using Sitecore.XConnect.Schema;
using Sitecore.Xdb.MarketingAutomation.Core.Activity;
using Sitecore.Xdb.MarketingAutomation.Core.Processing.Plan;
using SitecoreComms.RTBF.Models.Messaging;
using SitecoreComms.RTBF.Models.Messaging.Buses;

namespace SitecoreComms.RTBF.Activities
{
    public class ExecuteRightToBeForgottenActivity : IActivity
    {
        private readonly IMessageBus<ExecuteRightToBeForgottenBus> _bus;
        private readonly ILogger<IActivity> _logger;

        public IActivityServices Services { get; set; }

        public ExecuteRightToBeForgottenActivity(IMessageBus<ExecuteRightToBeForgottenBus> bus, ILogger<ExecuteRightToBeForgottenActivity> logger)
        {
            Condition.Requires(logger, nameof(logger)).IsNotNull();

            _bus = bus;
            _logger = logger;
        }

        public ActivityResult Invoke(IContactProcessingContext context)
        {
            Condition.Requires(context, nameof(context)).IsNotNull();

            try
            {
                var message = new ExecuteRightToBeForgottenMessage
                {
                    ContactIdentifier = context.Contact.GetAlias()
                };

                _bus.Send(message);

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