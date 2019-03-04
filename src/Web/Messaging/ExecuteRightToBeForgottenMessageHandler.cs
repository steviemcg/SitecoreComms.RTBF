using System;
using System.Threading.Tasks;
using Sitecore;
using Sitecore.Diagnostics;
using Sitecore.EmailCampaign.Model.Messaging;
using Sitecore.Framework.Conditions;
using Sitecore.Framework.Messaging;
using Sitecore.Framework.Messaging.DeferStrategies;
using Sitecore.XConnect;
using Sitecore.XConnect.Client.Configuration;
using Sitecore.XConnect.Collection.Model;
using SitecoreComms.RTBF.Models.Messaging;
using SitecoreComms.RTBF.Models.Messaging.Buses;

namespace SitecoreComms.RTBF.Web.Messaging
{
    public class Test
    {
        public Test()
        {
            try
            {
            }
            catch (Exception e)
            {
                throw;
            }
        }
    }

    [UsedImplicitly]
    public class ExecuteRightToBeForgottenMessageHandler : IMessageHandler<ExecuteRightToBeForgottenMessage>
    {
        private readonly IDeferStrategy<DeferDetectionByResultBase<HandlerResult>> _deferStrategy;
        private readonly IMessageBus<ExecuteRightToBeForgottenBus> _bus;

        public ExecuteRightToBeForgottenMessageHandler(
            IDeferStrategy<DeferDetectionByResultBase<HandlerResult>> deferStrategy,
            IMessageBus<ExecuteRightToBeForgottenBus> bus)
        {
            Condition.Requires(deferStrategy, nameof(deferStrategy)).IsNotNull();
            Condition.Requires(bus, nameof(bus)).IsNotNull();

            _deferStrategy = deferStrategy;
            _bus = bus;
        }

        public async Task Handle([NotNull] ExecuteRightToBeForgottenMessage message, IMessageReceiveContext receiveContext, IMessageReplyContext replyContext)
        {
            Condition.Requires(message, nameof(message)).IsNotNull();
            Condition.Requires(receiveContext, nameof(receiveContext)).IsNotNull();
            Condition.Requires(replyContext, nameof(replyContext)).IsNotNull();

            var result = await _deferStrategy.ExecuteAsync(
                _bus,
                message,
                receiveContext,
                async () => await SendMessage(message)).ConfigureAwait(false);

            Log.Debug(result.Deferred
                ? $"[{nameof(ExecuteRightToBeForgottenMessageHandler)}] deferred contact '{message.ContactIdentifier}'."
                : $"[{nameof(ExecuteRightToBeForgottenMessageHandler)}] processed contact '{message.ContactIdentifier}'");
        }

        private async Task<HandlerResult> SendMessage(ExecuteRightToBeForgottenMessage message)
        {
            try
            {
                Log.Info($"[{nameof(ExecuteRightToBeForgottenMessageHandler)}] Executing Right to be Forgotten on '{message.ContactIdentifier}'", this);

                using (var client = SitecoreXConnectClientConfiguration.GetClient())
                {
                    var identifiedContactReference = new IdentifiedContactReference(message.ContactIdentifier.Source, message.ContactIdentifier.Identifier);

                    var contact = await client.GetContactAsync(identifiedContactReference, new ContactExpandOptions(PhoneNumberList.DefaultFacetKey));
                    if (contact == null)
                    {
                        Log.Error($"[{nameof(ExecuteRightToBeForgottenMessageHandler)}] Failed to execute right to be forgotten on '{message.ContactIdentifier}' - Contact not found", this);
                        return new HandlerResult(HandlerResultType.Error);
                    }

                    try
                    {
                        client.ExecuteRightToBeForgotten(contact);
                        await client.SubmitAsync();
                        return new HandlerResult(HandlerResultType.Successful);
                    }
                    catch (Exception ex)
                    {
                        Log.Error($"[{nameof(ExecuteRightToBeForgottenMessageHandler)}] Failed to execute right to be forgotten on '{message.ContactIdentifier}'", ex, this);
                        return new HandlerResult(HandlerResultType.Error);
                    }
                }
            }
            catch (Exception ex)
            {
                Log.Error($"[{nameof(ExecuteRightToBeForgottenMessageHandler)}] Failed to execute right to be forgotten", ex, this);
                return new HandlerResult(HandlerResultType.Error);
            }
        }
    }
}