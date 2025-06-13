# oi-doc-generators

A collection of as-built document generators for One Identity products.


# Safeguard for Privileged Passwords

Use the ExportSPP.ps1 PowerShell script to export SPP configs as XML.

Usage:
   >  Connect-Safeguard
   > ./ExportSPP.ps1 > spp-configs.xml

Export pre-requisites:

- Safeguard Powershell commands installed
- certutil.exe installed and in path (for Base64 decoding)
- active safeguard connection with (at least) Auditor permissions

Notes:

- secrets and other encrypted content is not exported
- user information is not exported, although user names are referenced, e.g. in entitlement scope
- IP addresses of assets, mail server, archive servers, etc. are included in export


Apply the _ASPSAsBuiltToMD.xsl_ transform to convert the exported XML file to Markdown.  The resulting Markdown document includes diagrams in the PlantUML language.


