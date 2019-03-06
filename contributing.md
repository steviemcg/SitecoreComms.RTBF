## Prerequisites

- Sitecore XP v9.1 Initial Release
- Node / NPM

## Deploying the Sitecore Kernel solution

- Open Visual Studio 2017 and do a build
- 'Publish' Web to IIS - check that the hostname matches what you chose when deploying Sitecore 9
- Visit http://rtbf/unicorn.aspx and Sync

## Deploying the Angular solution

- Navigate in .\src\Angular and run: npm run dev
- Copy the resulting 2 files under .\src\Angular\dist to C:\inetpub\wwwroot\rtbf\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms

## Deploying the XConnect solutions

The following assumes XP0 is installed (all XConnect services in one folder)

### Automation Engine

- Copy the SitecoreComms.RTBF.Activities DLL and PDB files from .\src\Activities\bin\Debug to C:\inetpub\wwwroot\rtbf_xconnect\App_data\jobs\continuous\AutomationEngine
- Copy .\src\Activities\App_Data to C:\inetpub\wwwroot\rtbf_xconnect\App_data\jobs\continuous\AutomationEngine\App_Data