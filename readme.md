## Prequisites

- Sitecore XP v9.0 Update 2
- Node / NPM

## Deploying the Sitecore Kernel solution

- Open Visual Studio 2017 and do a build
- 'Publish' Web to IIS - check that the hostname matches what you chose when deploying Sitecore 9
- Visit http://rtbf/unicorn.aspx and Sync

## Deploying the XConnect solutions

- Navigate in .\src\Angular and run: npm run dev
- Copy the resulting 2 files under .\src\Angular\dist to C:\inetpub\wwwroot\rtbf\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms
- Copy the SitecoreComms.RTBF DLL and PDB files from .\src\Activities\bin\Debug to C:\inetpub\wwwroot\rtbf_xconnect\App_data\jobs\continuous\AutomationEngine

- Copy .\src\Activities\SitecoreComms.RTBF.ActivityTypes.xml to C:\inetpub\wwwroot\rtbf_xconnect\App_data\jobs\continuous\AutomationEngine\App_Data\Config\sitecore\MarketingAutomation
- Copy .\src\Activities\SitecoreComms.RTBF.Messaging.xml to C:\inetpub\wwwroot\rtbf_xconnect\App_data\jobs\continuous\AutomationEngine\App_Data\Config\sitecore\Messaging
- 
- Copy the 2 SitecoreComms.RTBF.Models.* files from .\src\Models\bin\Debug\netstandard2.0 to C:\inetpub\wwwroot\rtbf_xconnect\App_data\jobs\continuous\IndexWorker
- Copy the 2 SitecoreComms.RTBF.Models.* files from .\src\Models\bin\Debug\netstandard2.0 to C:\inetpub\wwwroot\rtbf_xconnect\bin