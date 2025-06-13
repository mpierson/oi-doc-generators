# oi-doc-generators

A collection of as-built document generators for One Identity products.


## Safeguard for Privileged Passwords

Use the ExportSPP.ps1 PowerShell script to export SPP configs as XML.

Usage:

``` sh
   Connect-Safeguard
   ./ExportSPP.ps1 > spp-configs.xml
```

Export pre-requisites:

- Safeguard Powershell commands installed
- certutil.exe installed and in path (for Base64 decoding)
- active safeguard connection with (at least) Auditor permissions

Notes:

- secrets and other encrypted content is not exported
- user information is not exported, although user names are referenced, e.g. in entitlement scope
- IP addresses of assets, mail server, archive servers, etc. are included in export


Once the SPP configs have been exported as XML, apply the _SPPAsBuiltToMD.xsl_ transform to convert the export file to Markdown.  The resulting Markdown document includes diagrams in the PlantUML language.

Transform pre-requisites:

- XSLT v2 processor (e.g. SaxonB)


## Safeguard for Privileged Sessions

Use /opt/scb/var/db/scb.xml, or extract _config.xml_ from an export or support bundle.

Apply the _SPSAsBuiltToMD.xsl_ transform to convert the configuration file to Markdown.  The resulting Markdown document includes diagrams in the PlantUML language.

Transform pre-requisites:

- XSLT v2 processor (e.g. SaxonB)
- OIS-IPv4Lib.xsl transform library


## syslog-ng Store Box

Use /opt/ssb/var/db/ssb.xml, or extract _config.xml_ from an export or support bundle.

Apply the _SSBAsBuiltToMD.xsl_ transform to convert the configuration file to Markdown.  The resulting Markdown document includes diagrams in the PlantUML language.

Transform pre-requisites:

- XSLT v2 processor (e.g. SaxonB)
- OIS-IPv4Lib.xsl transform library
- OIS-JSONLib.xsl transform library
- OIS-SSBMIBsLib.xsl transform library, including MIB definitions


## One Identity Manager

Use the golang DB exporter to generate an XML document of OneIM configuration.


Export pre-requisites:

- SQLServer username and password with (at least) read access to OneIM database
- platform-specific version of exporter


Use one or more of the following transforms to create Markdown:

- AsBuiltToMD-Configuration.xsl
- AsBuiltToMD-Customization.xsl
- AsBuiltToMD-WebProjects.xsl

Markdown files may include diagrams in the PlantUML and R (ggplot2) languages.

Transform pre-requisites:

- XSLT v2 processor (e.g. SaxonB)
- OIS-IPv4Lib.xsl transform library
- OIS-StringLib.xsl transform library
- OIS-MarkdownLib.xsl transform library
- OIS-PlantUMLLib.xsl transform library
- schedules.R and timeline\_plot.R scripts

