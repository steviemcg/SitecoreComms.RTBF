using System;
using Sitecore.Framework.Messaging;
using Sitecore.Pipelines;
using SitecoreComms.RTBF.Models.Messaging.Buses;

namespace SitecoreComms.RTBF.Web.Messaging
{
    public class InitializeMessageBus
    {
        private readonly IServiceProvider _serviceProvider;

        public InitializeMessageBus(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public void Process(PipelineArgs args)
        {
            _serviceProvider.StartMessageBus<ExecuteRightToBeForgottenBus>();
        }
    }
}