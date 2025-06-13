<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform One Identity config export to Markdown

  Author: M Pierson
  Date: Mar 2025
  Version: 0.90

  Use OneIMExporter.ps1 to generate source XML

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" 
                              exclude-result-prefixes="ois xs">
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:import href="OIS-JSONLib.xsl" />
  <xsl:import href="OIS-StringLib.xsl" />
  <xsl:import href="OIS-Markdown.xsl" />
  <xsl:import href="OIS-PlantUML.xsl" />
  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />

  <xsl:param name="additional-servers">
      <Servers/>
  </xsl:param>

  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />

  <xsl:variable name="OI_GREEN"         select="'#afcc9e'" />
  <xsl:variable name="OI_BLACK"         select="'#162c36'" />
  <xsl:variable name="OI_BLUE"          select="'#04aada'" />
  <xsl:variable name="OI_GRAY"          select="'#40535d'" />
  <xsl:variable name="OI_BROWN"         select="'#c8b483'" />
  <xsl:variable name="OI_ORANGE"        select="'#f79431'" />
  <xsl:variable name="OI_RED"           select="'#f05640'" />
  <xsl:variable name="OI_PINK"          select="'#f4b3b2'" />
  <xsl:variable name="OI_LIGHT_BLUE"    select="'#9dcdda'" />

 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>


   <!-- Function to format lines for a table cell -->
  <xsl:template name="format-table-lines">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="newline">\n</xsl:variable>
    <xsl:for-each select="tokenize($s, $newline)"><xsl:text>` </xsl:text><xsl:sequence select="."/><xsl:text> ` </xsl:text><br /></xsl:for-each>
  </xsl:template>

<xsl:template match="IdentityManager">

---
title: One Identity Manager Configuration for <xsl:value-of select="@name" /> 
author: OneIM As Built Generator v0.90
abstract: |
    Configuration of the <xsl:value-of select="@name" /> instance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Summary

    <xsl:call-template name="servers-summary" />



## Primary Database

<xsl:apply-templates select="PrimaryDatabase" />

## Job Servers

<xsl:apply-templates select="Servers" />

## Web Applications

<xsl:apply-templates select="WebApps" />

## Administrators

<xsl:apply-templates select="Administrators" />


# Configuration Parameters

<xsl:apply-templates select="ConfigParams" />


# Schedules

<xsl:apply-templates select="Schedules"/> 


# Application Roles

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Application role hierarchy</xsl:with-param>
        <xsl:with-param name="id" select="'summary-application-roles'" />
        <xsl:with-param name="header" select="'Application Roles'" />
        <xsl:with-param name="values">
            <tree>
                <xsl:apply-templates select="ApplicationRoles/ApplicationRole" mode="tree" />
            </tree>
        </xsl:with-param>
    </xsl:call-template>

   <xsl:apply-templates select="ApplicationRoles" mode="section">
       <xsl:with-param name="custom-role-path" select="'Custom'" />
   </xsl:apply-templates>


# Business Roles

<xsl:apply-templates select="RoleClasses" />


# IT Shops

<xsl:apply-templates select="ShoppingCenters" />

# IT Shop Approval Policies

<xsl:apply-templates select="ApprovalPolicies"> <xsl:with-param name="usage">I</xsl:with-param> </xsl:apply-templates>


# IT Shop Approval Workflows

<xsl:apply-templates select="ApprovalWorkflows"> <xsl:with-param name="usage">I</xsl:with-param> </xsl:apply-templates>

# Service Catalog

<xsl:apply-templates select="ProductGroups" />


# Account Definitions

<xsl:apply-templates select="AccountDefinitions" />


# Attestation Policies

<xsl:apply-templates select="AttestationPolicies" />


# Attestation Approval Policies

<xsl:apply-templates select="ApprovalPolicies"> <xsl:with-param name="usage">A</xsl:with-param> </xsl:apply-templates>


# Attestation Approval Workflows

<xsl:apply-templates select="ApprovalWorkflows"> <xsl:with-param name="usage">A</xsl:with-param> </xsl:apply-templates>


# Mail Templates

<xsl:apply-templates select="MailTemplates" />


# Password Policies

<xsl:apply-templates select="PasswordPolicies" />



# Integrated Systems

<xsl:apply-templates select="TargetSystems"/> 

# Synchronization Projects

<xsl:apply-templates select="SyncProjects"/> 


</xsl:template>



<!-- ===== architecture graphic ========================== -->

<xsl:template name="job-server-hosts">
    <hosts>
        <xsl:for-each select="/IdentityManager/Servers/Server[@serviceInstalled='True' and count(DeployTargets/DeployTarget) &gt; 0 and (string-length(@physicalServer) = 0 or (@physicalServer = @FQDN))]">
            <host type="job-server">
                <xsl:attribute name="name" select="@name" />
                <xsl:attribute name="FQDN" select="@FQDN" />
                <xsl:call-template name="ServerQueuesx">
                    <xsl:with-param name="server" select="." />
                </xsl:call-template>
            </host>
        </xsl:for-each>
        <xsl:for-each select="$additional-servers/Servers/Server">
            <host type="job-server">
                <xsl:attribute name="name" select="@name" />
                <xsl:attribute name="FQDN" select="@FQDN" />
                <xsl:call-template name="ServerQueuesx">
                    <xsl:with-param name="server" select="." />
                </xsl:call-template>
            </host>
        </xsl:for-each>
    </hosts>
</xsl:template>
<xsl:template name="ServerQueuesx">
    <xsl:param name="server" />
    <queues>
        <xsl:attribute name="server" select="$server/@name" />
        <xsl:variable name="server-name" select="$server/@name" />
        <xsl:for-each select="$server/configuration/category/value[@name='queue']">
            <queue>
                <xsl:attribute name="name" select="if (. = '\%COMPUTERNAME%') then concat('\', $server-name) else ." />
            </queue>
        </xsl:for-each>
    </queues>
</xsl:template>



<xsl:template name="servers-summary">
    <xsl:variable name='dbHost' select="/IdentityManager/PrimaryDatabase/@dataSource"/>
    <xsl:variable name="job-servers">
            <xsl:call-template name="job-server-hosts" />
    </xsl:variable>
    <xsl:variable name="web-apps" select="/IdentityManager/WebApps" />
    <xsl:variable name="target-systems" select="/IdentityManager/TargetSystems" />
    <xsl:variable name="sync-projects">
        <xsl:call-template name="SyncProjects-With-Systems"/>
    </xsl:variable>


```{.plantuml caption="Identity Manager environment overview"}

!include_many /home/mpierson/projects/quest/OneIM/posh-exporter/header.puml

top to bottom direction

<!-- database -->
Boundary(main, "Server <xsl:value-of select="/IdentityManager/PrimaryDatabase/@dataSource"/>", $tags="OI_System") {
    ComponentDb(main_database, "<xsl:value-of select="/IdentityManager/PrimaryDatabase/@dbName"/>", "primary database", $tags="OneIM_DB")
    <!-- job servers -->
    <xsl:for-each select="$job-servers/hosts/host[@name=$dbHost]">
        <xsl:for-each select="queues/queue">
        together {
            Component(JQ_<xsl:value-of select="translate(string-join(($dbHost,@name), '_'), '\%/', '')" />, "<xsl:value-of select="@name" />", "job queue", $tags="OneIM_JQ")

            <xsl:variable name='queue' select="@name"/>
            <xsl:for-each select="$sync-projects/SyncProjects/Sync[Infos/Info/Server/@queue = $queue]">
                Component(SYNC_<xsl:value-of select="translate(SyncProject/@id, '\%/-', '')" />, "<xsl:value-of select="SyncProject/@name" />", "Synchronization project", $tags="OneIM_SYNC")
            </xsl:for-each>

        </xsl:for-each>
        }
    </xsl:for-each>
}

<!-- app servers -->
together {
<xsl:for-each select="$job-servers/hosts/host[not(@name=$dbHost)]">
    Boundary(JS_<xsl:value-of select="@name"/>, "Server <xsl:value-of select="@name"/>", $tags="OI_System") {
    <xsl:variable name='host' select="@name"/>
    <xsl:variable name='fqdn' select="@FQDN"/>

    <!-- job queues -->
    together {
    <xsl:for-each select="queues/queue">
        together {

        Component(JQ_<xsl:value-of select="translate(string-join(($host, @name), '_'), '\%/', '')" />, "<xsl:value-of select="@name" />", "job queue", $tags="OneIM_JQ")

        <xsl:variable name='queue' select="@name"/>
        <xsl:for-each select="$sync-projects/SyncProjects/Sync[Infos/Info/Server/@queue = $queue]">
            Component(SYNC_<xsl:value-of select="translate(SyncProject/@id, '\%/-', '')" />, "<xsl:value-of select="SyncProject/@name" />", "Synchronization project", $tags="OneIM_SYNC")
        </xsl:for-each>

        }
    </xsl:for-each>
    }

 }
</xsl:for-each>
}

<!-- web apps -->
Boundary(WebApps, "Identity Manager Web Applications", $tags="OI_System") {
<xsl:for-each-group select="$web-apps/WebApp" group-by="@host">
    <xsl:variable name="host-fqdn" select="current-grouping-key()" />
    together {
    <xsl:for-each select="current-group()">
        Component(WEB_<xsl:value-of select="translate(string-join(($host-fqdn, @id), '_'), '\%/-', '')" />, "<xsl:value-of select="@path" />", "<xsl:value-of select="AppType/@name" />", $tags="OneIM_AP")
    </xsl:for-each>
    }
</xsl:for-each-group>
}

<!-- target systems -->
Boundary(TargetSystems, "Target Systems", $tags="OI_System") {
<xsl:for-each select="$target-systems/TargetSystem">
    Component(TS_<xsl:value-of select="translate(@name, ':/', '')"/>, "<xsl:value-of select="@name"/> (<xsl:value-of select="SyncType/@name" />)", $tags="OneIM_TS")
    <xsl:if test="SPSWebApp">
        Component(TS_<xsl:value-of select="translate(SPSWebApp/@name, ':/- ', '')"/>, "<xsl:value-of select="SPSWebApp/@name"/> (SharePoint web application)", $tags="OneIM_TSParent")

        <xsl:if test="SPSWebApp/Farm">
            Component(TS_<xsl:value-of select="translate(SPSWebApp/Farm/@name, ':/- ()', '')"/>, "<xsl:value-of select="SPSWebApp/Farm/@name"/> (SharePoint farm)", $tags="OneIM_TSParent")

        </xsl:if>
    </xsl:if>
    <xsl:if test="Forest">
        Component(TSF_<xsl:value-of select="translate(Forest/@name, ':/- ', '')"/>, "<xsl:value-of select="Forest/@name"/> (AD forest)", $tags="OneIM_TSParent")
    </xsl:if>

</xsl:for-each>
}




<!-- connections -->
Rel_L(WebApps, main_database, "uses", $tags="light")

<xsl:for-each select="$job-servers/hosts/host[not(@name=$dbHost)]">
Rel_U(JS_<xsl:value-of select="@name" />, main_database, "uses", $tags="light")
</xsl:for-each>
<xsl:for-each-group select="$web-apps/WebApp" group-by="@host">
    <xsl:variable name="host-fqdn" select="current-grouping-key()" />
    <!-- only render server if web app host is not a job server -->
    <xsl:if test="count($job-servers/hosts/host[compare(upper-case(@FQDN), upper-case($host-fqdn)) = 0]) = 0">
        <!-- web apps -->
        <xsl:for-each select="current-group()">
            Rel_U(WS_<xsl:value-of select="$host-fqdn" />, main_database, "uses", $tags="light")
        </xsl:for-each>
    </xsl:if>
</xsl:for-each-group>

<xsl:for-each select="$job-servers/hosts/host[@name=$dbHost]">
    <xsl:for-each select="queues/queue">
        Rel_U(JQ_<xsl:value-of select="translate(string-join(($dbHost,@name), '_'), '\%/', '')" />, main_database, "uses", $tags="light")
    </xsl:for-each>
</xsl:for-each>

    <xsl:for-each select="$sync-projects/SyncProjects/Sync">
        Rel_D(SYNC_<xsl:value-of select="translate(SyncProject/@id, '\%/-', '')" />, TS_<xsl:value-of select="translate(Infos/Info/RootObject/@name, ':/-() ', '')"/>, "synchronizes", $tags="light")
    </xsl:for-each>


<xsl:for-each select="$target-systems/TargetSystem">
    <xsl:if test="SPSWebApp">
        Rel_D(TS_<xsl:value-of select="translate(@name, ':/', '')"/>, TS_<xsl:value-of select="translate(SPSWebApp/@name, ':/- ', '')"/>, "", $tags="light")
        <xsl:if test="SPSWebApp/Farm">
            Rel_D( TS_<xsl:value-of select="translate(SPSWebApp/@name, ':/- ', '')"/>, TS_<xsl:value-of select="translate(SPSWebApp/Farm/@name, ':/- ()', '')"/>, "", $tags="light")
        </xsl:if>
    </xsl:if>
    <xsl:if test="Forest">
        Rel_D(TS_<xsl:value-of select="translate(@name, ':/', '')"/>, TSF_<xsl:value-of select="translate(Forest/@name, ':/- ', '')"/>, "", $tags="light")
    </xsl:if>
    <xsl:if test="ExchangeForest">
        Rel_D(TS_<xsl:value-of select="translate(@name, ':/', '')"/>, TSF_<xsl:value-of select="translate(ExchangeForest/@name, ':/- ', '')"/>, "", $tags="light")
    </xsl:if>

</xsl:for-each>

```
![Identity Manager environment overview](single.png){#fig:overview}


</xsl:template>




<!-- ===== Primary Database ======================= -->

<xsl:template match="PrimaryDatabase">

Host name
: <xsl:value-of select="@dataSource" />

Schema
: <xsl:value-of select="@dbName" />

User name
: <xsl:value-of select="@userName" />


</xsl:template>



<!-- ===== Mail Templates ======================= -->

<xsl:template match="MailTemplates">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of mail templates.'" />
        <xsl:with-param name="id" select="'summary-mail-templates'" />
        <xsl:with-param name="header"   >| Name        | Description | Format | Table | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:---:|:-----|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="MailTemplate" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>

<xsl:template match="MailTemplate" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="MailTemplateObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="MailTemplateObject/Property[@Name='TargetFormat']" /></value>
        <value><xsl:value-of select="Table/@name" /></value>
        <value><xsl:value-of select="ois:last-modified(MailTemplateObject)" /></value>
    </row>
</xsl:template>


<!-- ===== Password Policies ======================= -->

<xsl:template match="PasswordPolicies">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of password policies.'" />
        <xsl:with-param name="id" select="'summary-password-policies'" />
        <xsl:with-param name="header"   >| Name        | Description | Default? | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:--:|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="PasswordPolicy" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="PasswordPolicy" mode="section" />

</xsl:template>

<xsl:template match="PasswordPolicy" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="PasswordPolicyObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="@isDefault" /></value>
        <value><xsl:value-of select="ois:last-modified(PasswordPolicyObject)" /></value>
    </row>
</xsl:template>

<xsl:template match="PasswordPolicy" mode="section">

## <xsl:value-of select="@name" />

<xsl:value-of select="ois:markdown-definition('Description', PasswordPolicyObject/Property[@Name='Description'])" />
<xsl:value-of select="ois:markdown-definition('Custom error message', PasswordPolicyObject/Property[@Name='ErrorMessage'])" />
<xsl:value-of select="ois:markdown-definition('Check script', PasswordPolicyObject/Property[@Name='CheckScriptName'])" />
<xsl:value-of select="ois:markdown-definition('Create', PasswordPolicyObject/Property[@Name='CreateScriptName'])" />
<xsl:value-of select="ois:markdown-definition-int('Minumum length', PasswordPolicyObject/Property[@Name='MinLen'])" />
<xsl:value-of select="ois:markdown-definition-int('Maximum length', PasswordPolicyObject/Property[@Name='MaxLen'])" />
<xsl:value-of select="ois:markdown-definition-int('Max. failed logins', PasswordPolicyObject/Property[@Name='MaxBadAttempts'])" />
<xsl:value-of select="ois:markdown-definition-int('Max age (days)', PasswordPolicyObject/Property[@Name='MaxAge'])" />
<xsl:value-of select="ois:markdown-definition-int('Password history size', PasswordPolicyObject/Property[@Name='HistoryLen'])" />
<xsl:value-of select="ois:markdown-definition-int('Minimum strength', PasswordPolicyObject/Property[@Name='MinPasswordQuality'])" />
<xsl:value-of select="ois:markdown-definition('', PasswordPolicyObject/Property[@Name=''])" />
<xsl:value-of select="ois:markdown-definition('', PasswordPolicyObject/Property[@Name=''])" />
<xsl:value-of select="ois:markdown-definition('', PasswordPolicyObject/Property[@Name=''])" />
<xsl:value-of select="ois:markdown-definition('Minimum number of letters', PasswordPolicyObject/Property[@Name='MinLetters'])" />

</xsl:template>


<!-- ===== Schedules ======================= -->

<xsl:template match="Schedules">


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and (
                        @frequencyType = 'Year' or (@frequencyType = 'Month' and @frequency &gt; 4))]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24*365; yday(range_start)&lt;-1; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + years(4)'" />
        <xsl:with-param name="units" select="'year'" />
        <xsl:with-param name="date-format" select="'%Y'" />
        <xsl:with-param name="tick-units" select="'month'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 4 year view'" />
        <xsl:with-param name="figure-id" select="'schedule-4-year'" />
    </xsl:call-template>


    <xsl:call-template name="schedule-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Yearly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-yearly'" />
        <xsl:with-param name="unit" select="'Year'" />
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Year']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
                                    (contains('Year Month', @frequencyType)
                                        or @frequencyType='Week' and @frequency > 2)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24*28; mday(range_start)&lt;-1; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + months(6)'" />
        <xsl:with-param name="units" select="'month'" />
        <xsl:with-param name="date-format" select="'%B'" />
        <xsl:with-param name="tick-units" select="'month'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 6 month view'" />
        <xsl:with-param name="figure-id" select="'schedule-6-month'" />
    </xsl:call-template>

    <xsl:call-template name="schedule-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Monthly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-monthly'" />
        <xsl:with-param name="unit" select="'Month'" />
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Month']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>




    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
                                    (contains('Year Month Week', @frequencyType)
                                        or @frequencyType='Day' and @frequency > 2)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24*7; wday(range_start)&lt;-1; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + weeks(4)'" />
        <xsl:with-param name="units" select="'week'" />
        <xsl:with-param name="date-format" select="'%B %d'" />
        <xsl:with-param name="tick-units" select="'day'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 1 month view'" />
        <xsl:with-param name="figure-id" select="'schedule-1-month'" />
    </xsl:call-template>

    <xsl:call-template name="schedule-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Weekly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-weekly'" />
        <xsl:with-param name="unit" select="'Week'" />
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Week']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
                                    (contains('Year Month Week Day', @frequencyType)
                                        or @frequencyType='Hour' and @frequency > 18)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + days(7)'" />
        <xsl:with-param name="units" select="'day'" />
        <xsl:with-param name="date-format" select="'%B %d'" />
        <xsl:with-param name="tick-units" select="'day'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 1 week view'" />
        <xsl:with-param name="figure-id" select="'schedule-1-week'" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Daily_.'" />
        <xsl:with-param name="id" select="'summary-schedules-daily'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Run Every n Days | Start Time | Time Zone |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:----|:---:|:--:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Day']" mode="table-day" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
                                    (contains('Year Month Week Day', @frequencyType)
                                        or @frequencyType='Hour' and @frequency > 1)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24; minute(range_start)&lt;-0; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + hours(48)'" />
        <xsl:with-param name="units" select="'2 hours'" />
        <xsl:with-param name="date-format" select="'%H'" />
        <xsl:with-param name="tick-units" select="'hour'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 48 hour view'" />
        <xsl:with-param name="figure-id" select="'schedule-2-day'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Hourly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-hour'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Run Every n Hours | Time Zone |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:----|:---:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Hour']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
                                    (contains('Year Month Week Day Hour', @frequencyType)
                                        or @frequencyType='Min' and @frequency > 30)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now() + 3600; minute(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + hours(12)'" />
        <xsl:with-param name="units" select="'hour'" />
        <xsl:with-param name="date-format" select="'%H'" />
        <xsl:with-param name="tick-units" select="'hour'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 12 hour view'" />
        <xsl:with-param name="figure-id" select="'schedule-12-hour'" />
    </xsl:call-template>


    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Minute_.'" />
        <xsl:with-param name="id" select="'summary-schedules-minute'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Run Every n Minutes | Time Zone |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:----|:---:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Min']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
                                    (contains('Year Month Week Day Hour Min', @frequencyType))]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now() + 3600; minute(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + hours(2)'" />
        <xsl:with-param name="units" select="'15 mins'" />
        <xsl:with-param name="date-format" select="'%M'" />
        <xsl:with-param name="tick-units" select="'5 mins'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 2 hour view'" />
        <xsl:with-param name="figure-id" select="'schedule-2-hour'" />
    </xsl:call-template>



</xsl:template>
<xsl:template name="schedule-table">
    <xsl:param name="summary" />
    <xsl:param name="id" />
    <xsl:param name="unit" />
    <xsl:param name="values" />
    <xsl:variable name="header">| Name     | Description | Type | Run Every n Weeks | Run on nth Day of Week | Start Time | Time Zone |</xsl:variable>
    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="$summary" />
        <xsl:with-param name="id" select="$id" />
        <xsl:with-param name="header" select="replace($header, 'Week', $unit)" />
        <xsl:with-param name="separator">|:---------|:----------|:----|:----:|:----:|:--:|:-:|</xsl:with-param>
        <xsl:with-param name="values" select="$values" />
    </xsl:call-template>
</xsl:template>


<xsl:template match="Schedule" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ScheduleObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="SubTypes/Type" separator=", " /></value>
        <value><xsl:value-of select="StartTimes/T" separator=", " /></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="Schedule" mode="table-day">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ScheduleObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="StartTimes/T" separator=", " /></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="Schedule" mode="table-hour">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ScheduleObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>


<xsl:template name="date-timeline-graphic">
    <xsl:param name="df-rows" />
    <xsl:param name="start-date" />
    <xsl:param name="end-date" />
    <xsl:param name="units" />
    <xsl:param name="date-format" />
    <xsl:param name="tick-units" />
    <xsl:param name="figure-description" />
    <xsl:param name="figure-id" />

```{.ggplot2 }

    library(lubridate)
    library(ggplot2)
    library(tidyverse)
    library(dplyr)

    source("~/projects/quest/OneIM/posh-exporter/schedules.R")
    source("~/projects/quest/OneIM/posh-exporter/timeline_plot.R")

    png('my_plot.png', width = 800, height = 500)

    df = data.frame(col = character(), col = character(), col = numeric(), col = numeric(), col = character(), col = character(), col = character(), col = character(), col = character(), col = character(), stringsAsFactors = FALSE)
    names(df) &lt;- c("Id", "Type", "Freq", "SubFreq", "TimeOfDay", "Offset", "ShortName", "StartDate", "LastRun", "NextRun")

    s &lt;- df %&gt;%
    <xsl:value-of select="$df-rows" />
    {}

    range_start = <xsl:value-of select="$start-date" />
    range_end = <xsl:value-of select="$end-date" />

    k &lt;- calc_dates_for_schedule(s) %&gt;% filter(date &lt;= range_end) %&gt;% filter(date &gt;= range_start) %&gt;% arrange(desc(type))

    date_range &lt;- seq(range_start, range_end, by='<xsl:value-of select="$units"/>')    
    date_format &lt;- format(date_range, '<xsl:value-of select="$date-format" />')
    date_df &lt;- data.frame(date_range, date_format)

    ticks &lt;- seq(range_start, range_end, by='<xsl:value-of select="$tick-units"/>')

    plot &lt;- gen_timeline_plot(k, range_start, range_end, date_df, ticks)

```
![<xsl:value-of select="$figure-description"/>](single.png){#fig:<xsl:value-of select="$figure-id"/>}

</xsl:template>
<xsl:template match="Schedule" mode="data.frame">
    <xsl:variable name="value-template-char">_NAME_ = "_VALUE_",</xsl:variable>
    <xsl:variable name="value-template-num">_NAME_ = _VALUE_,</xsl:variable>
    <xsl:variable name="s" select="." />

    <xsl:variable name="short-name" select="ois:truncate-string(replace(@name, '&quot;', ''), 15, '...')" />
    <xsl:variable name="last-run" select="ois:is-null-string(@lastRun, '1900-01-01')" />
    <xsl:variable name="next-run" select="ois:is-null-string(@nextRun, '1900-01-01')" />

    <!-- start times, sub-times can be null in OneIM... -->
    <xsl:variable name="sub-types">
        <xsl:choose>
            <xsl:when test="SubTypes"> <xsl:copy-of select="SubTypes"/> </xsl:when>
            <xsl:otherwise><SubTypes><Type>0</Type></SubTypes></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="start-times">
        <xsl:choose>
            <xsl:when test="StartTimes"> <xsl:copy-of select="StartTimes"/> </xsl:when>
            <xsl:otherwise><StartTimes><T>0:0</T></StartTimes></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:for-each select="$sub-types/SubTypes/Type">
        <xsl:variable name="sub-type" select="." />
        <xsl:for-each select="$start-times/StartTimes/T">
            <xsl:value-of select="concat('# ', $s/@id, ' &#xa;')" />
            <xsl:value-of select="'add_row('" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Id'), '_VALUE_', $s/@id)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Type'), '_VALUE_', $s/@frequencyType)" />
            <xsl:value-of select="replace(replace($value-template-num, '_NAME_', 'Freq'), '_VALUE_', $s/@frequency)" />
            <xsl:if test="string-length($sub-type) &gt; 0">
                <xsl:value-of select="replace(replace($value-template-num, '_NAME_', 'SubFreq'), '_VALUE_', $sub-type)" />
            </xsl:if>
            <xsl:if test="string-length(.) &gt; 0">
                <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'TimeOfDay'), '_VALUE_', .)" />
            </xsl:if>
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Offset'), '_VALUE_', $s/TimeZone/@currentUTCOffset)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'ShortName'), '_VALUE_', $short-name)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'StartDate'), '_VALUE_', $s/@startDate)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'LastRun'), '_VALUE_', $last-run)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'NextRun'), '_VALUE_', $next-run)" />
            <!--
            <xsl:value-of select="concat('Name=\"',      name,           ',')" />
            <xsl:value-of select="concat('Type=\"',      frequencyType,  '\",')" />
            <xsl:value-of select="concat('Freq=\"',      frequency,      '\",')" />
            <xsl:value-of select="concat('SubFreq=\"',   subFrequency,   '\",')" />
            <xsl:value-of select="concat('TimeOfDay=\"', startTime,      '\",')" />
            <xsl:value-of select="concat('TZ`=\"',       TimeZone/@name , '\",')" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Date'), '_VALUE_', 'now()')" />
            -->
            <xsl:value-of select="') %&gt;% &#xa;'" />
        </xsl:for-each>
    </xsl:for-each>
</xsl:template>

<!-- ===== Admins ======================= -->

<xsl:template match="Administrators">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary">Summary of administrative users</xsl:with-param>
        <xsl:with-param name="id" select="'summary-administrators'" />
        <xsl:with-param name="header"   >| User Name | Created By | Password Last Set |</xsl:with-param>
        <xsl:with-param name="separator">|:----------|:-----------|:------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="Administrator[
                                                not(starts-with(@name, 'Web'))
                                                and starts-with(AdministratorObject/Property[@Name='Password'], 'P|E')
                                            ]" mode="table" />
            </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="Administrator" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value>
            <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown(AdministratorObject/Property[@Name='XUserInserted']), 15, '...')" /> - <xsl:value-of select="AdministratorObject/Property[@Name='XDateInserted']" />
        </value>
        <value><xsl:value-of select="@passwordLastSet"/></value>
    </row>
</xsl:template>




<!-- ===== Servers ======================= -->

<xsl:template match="Servers">


Table: Summary of job servers {#tbl:summary-job-servers}

| Server      | Queues   | Deploy targets |
|:------------|:---------|:---------------|
<xsl:for-each select="Server[@serviceInstalled='True' and count(DeployTargets/DeployTarget) &gt; 0 and (string-length(@physicalServer) = 0 or (@physicalServer = @FQDN))]"
    ><xsl:sort select="@name" order="ascending"
    /><xsl:variable name="physicalServer" select="@physicalServer"
    />| **<xsl:value-of select="replace(@name, '\\', '/')" />**<xsl:if test="string-length(@FQDN) &gt; 0"> (<xsl:value-of select="@FQDN"/>)</xsl:if
    > | <xsl:call-template name="ServerQueues"><xsl:with-param name="configs" select="configuration" /></xsl:call-template
     > | <xsl:apply-templates select="DeployTargets/DeployTarget"
    /> |                 
</xsl:for-each>   

Table: Summary of job queues {#tbl:summary-job-queues}

| Server | Disabled? | Tags              | Last Fetch | Last Health Check |
|:-------|:------:|:-------------------------|:---------|:---------|
<xsl:for-each select="Server[@serviceInstalled='True']"
    ><xsl:sort select="@name" order="ascending"
    /><xsl:variable name="physicalServer" select="@physicalServer"
     />| **<xsl:value-of select="replace(@name, '\\', '/')"
  />** | <xsl:value-of select="ServerObject/Property[@Name='IsJobServiceDisabled']"
    /> | <xsl:apply-templates select="ServerTags/ServerTag"
    /> | <xsl:value-of select="ServerObject/Property[@Name='LastJobFetchTime']"
    /> | <xsl:value-of select="ServerObject/Property[@Name='LastTimeoutCheck']"
    /> |                 
</xsl:for-each>   

    <!--<xsl:apply-templates select="Server" /> -->

</xsl:template>
<xsl:template match="Server">

## <xsl:value-of select="replace(@name, '\\', '/')" />


</xsl:template>
<xsl:template name="ServerQueues">
    <xsl:param name="configs" />
    <xsl:for-each select="$configs/category/value[@name='queue']">
        <xsl:value-of select="ois:escape-for-markdown(.)" /><xsl:text> </xsl:text>
    </xsl:for-each>
</xsl:template>
<xsl:template match="DeployTarget">
    <xsl:value-of select="ois:escape-for-markdown(@fullPath)" /><xsl:text> </xsl:text>
</xsl:template>
<xsl:template match="ServerTag">
    <xsl:value-of select="ois:escape-for-markdown(@name)" /><xsl:text> </xsl:text>
</xsl:template>


<!-- ===== web apps ======================= -->

<xsl:template match="WebApps">


Table: Summary of web applications {#tbl:summary-web-applications}

| Type    | URL              | Authentication |
|:--------|:-----------------|:---------------|
<xsl:for-each select="WebApp"
    ><xsl:sort select="AppType/@name" order="ascending"
    /><xsl:variable name="physicalServer" select="@physicalServer"
    />| **<xsl:value-of select="replace(AppType/@name, '\\', '/')" 
 />** | <xsl:value-of select="@name"
 /> | <xsl:value-of select="AuthenticationType/@name"/><xsl:if test="SecondaryAuthenticationType"><br/>or<br/><xsl:value-of select="SecondaryAuthenticationType/@name"/></xsl:if
    > |                 
</xsl:for-each>   

    <!--<xsl:apply-templates select="Server" /> -->

</xsl:template>
<xsl:template match="WebApp">

## <xsl:value-of select="replace(@name, '\\', '/')" />

</xsl:template>




<!-- ===== Config Params ======================= -->

<xsl:template match="ConfigParams">


Table: Summary of custom configuration parameters {#tbl:summary-configuration-parameters}

| ConfigParam        | Enabled? | Value              | Last Modified |
|:--------------|:-----:|:---------------------------|:--------------|
<xsl:for-each select="ConfigParam[not(starts-with(Property[@Name='XUserUpdated'], 'QBM'))]"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" />** <br/><xsl:value-of select="@displayName"
    /> | <xsl:value-of select="Property[@Name='Enabled']" 
    /> | ```<xsl:value-of select="ois:truncate-string(Property[@Name='Value'], 25, '...')" 
 />``` | <xsl:value-of select="ois:last-modified(.)"
    /> |                 
</xsl:for-each>   

    <!--<xsl:apply-templates select="ConfigParam" /> -->

</xsl:template>
<xsl:template match="ConfigParam">

## <xsl:value-of select="replace(@name, '\\', '/')" />


</xsl:template>




<!-- ===== Roles ======================= -->

<xsl:template match="RoleClasses">

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Business role hierarchy</xsl:with-param>
        <xsl:with-param name="id" select="'summary-business-roles'" />
        <xsl:with-param name="header" select="'Business Roles'" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree" />
        </xsl:with-param>
    </xsl:call-template>


Table: Summary of custom role classes {#tbl:summary-role-classes}

| Name        | Description | Top Down? | Last Modified | Roles |
|:------------|:------------|:-----:|:------------------|:--:|
<xsl:for-each select="RoleClass"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="Property[@Name='Description']" 
    /> | <xsl:value-of select="@isTopDown" 
    /> | <xsl:value-of select="ois:last-modified(RoleClassObject)"
    /> | <xsl:value-of select="count(Roles/Role)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="RoleClass" mode="section" />


</xsl:template>

<xsl:template match="RoleClasses" mode="tree">
    <tree>
        <xsl:apply-templates select="RoleClass" mode="tree">
            <xsl:sort select="@fullPath" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="RoleClass" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@name" />
        <xsl:attribute name="color" select="$OI_BROWN" />
    </branch>
   <xsl:choose>
       <xsl:when test="count(Roles/Role) &gt; 10">
           <xsl:variable name='numRoles' select="count(Roles/Role)"/>
            <branch>
                <xsl:attribute name="name" select="@name" />
                <xsl:attribute name="path" select="concat(@name, '\', '[', $numRoles, ' roles]')" />
                <xsl:attribute name="color" select="$OI_GREEN" />
            </branch>
       </xsl:when>
       <xsl:when test="count(Roles/Role) &gt; 1">
           <xsl:apply-templates select="Roles/Role" mode="tree">
               <xsl:sort select="@fullPath" order="ascending" />
           </xsl:apply-templates>
       </xsl:when>
       <xsl:otherwise>
       </xsl:otherwise>
   </xsl:choose>
</xsl:template>
<xsl:template match="Role" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="concat(../../@name, '\', @fullPath)" />
        <xsl:attribute name="color" select="$OI_GREEN" />
    </branch>
</xsl:template>
<xsl:template match="ApplicationRole" mode="tree">
    <xsl:variable name="color" select="if (starts-with(@fullPath, 'Custom')) then $OI_LIGHT_BLUE else $OI_GREEN" />
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="concat(../../@name, '\', @fullPath)" />
        <xsl:attribute name="color" select="$color" />
    </branch>
</xsl:template>

<xsl:template match="RoleClass" mode="section">

## Role class: <xsl:value-of select="@name" />


<xsl:call-template name="ois:generate-table">
    <xsl:with-param name="summary">Summary of role class assignments </xsl:with-param>
    <xsl:with-param name="id" select="concat('summary-role-class-assignments-', @id)" />
    <xsl:with-param name="header"   >| Type        | Allow Assignment | Allow Direct Assignment |</xsl:with-param>
    <xsl:with-param name="separator">|:------------|:----:|:----:|</xsl:with-param>
    <xsl:with-param name="values">
        <rows>
            <xsl:apply-templates 
                select="ClassAssignments/ClassAssignment[@allowAssignment='True' or @allowDirectAssignment='True']" 
                mode="table" />
        </rows>
    </xsl:with-param>
</xsl:call-template>

<xsl:apply-templates select="Roles" mode="section" />

</xsl:template>
<xsl:template match="Roles|ApplicationRoles" mode="section">
    <xsl:param name="custom-role-path" />
    <xsl:choose>
        <xsl:when test="count(child::*) &gt; 20">
            <xsl:choose>
                <xsl:when test="string-length($custom-role-path) &gt; 0">
                    <xsl:text>&#xa;&#xa;## Custom Roles</xsl:text>
                    <xsl:apply-templates select="child::*[starts-with(@fullPath, $custom-role-path)]" mode="section"><xsl:sort select="@fullPath"/></xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
**Total roles in class**: <xsl:value-of select="count(child::*)" />

**Dynamic roles**: <xsl:value-of select="count(child::*[count(DynamicRoles/DynamicRole) &gt; 0])" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="count(Role) &gt; 10">
            <xsl:call-template name="ois:generate-table">
                <xsl:with-param name="summary" select="concat('Summary of roles of class ', ../@name)" />
                <xsl:with-param name="id" select="concat('summary-roles-', ../@id)" />
                <xsl:with-param name="header"
                    >| Name        | Users | Manager | Dynamic? | Last Modified |</xsl:with-param>
                <xsl:with-param name="separator"
                    >|:------------|:--:|:--------|:--:|:--------|</xsl:with-param>
                <xsl:with-param name="values">
                    <rows>
                        <xsl:apply-templates select="Role" mode="table">
                            <xsl:sort select="@fullPath"/>
                        </xsl:apply-templates>
                    </rows>
                </xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="Role[UserCount &gt; 0]" mode="section"><xsl:sort select="@fullPath"/></xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="Role" mode="section"><xsl:sort select="@fullPath"/></xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="Role|ApplicationRole" mode="section" >

    <xsl:text>&#xa;&#xa;### </xsl:text><xsl:value-of select="ois:escape-for-markdown(@fullPath)"/>

    <xsl:value-of select="ois:markdown-definition('Description', child::*/Property[@Name='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Manager', Manager/@name)" />
    <xsl:value-of select="ois:markdown-definition('Managers (application role)', ois:escape-for-markdown(ManagerRole/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Attestors (role)',ois:escape-for-markdown(Attestor/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Assigned Users',ois:is-null-string(UserCount/text(), string(count(UserAssignments/UserAssignment))))" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned objects'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="ObjectAssignments/ObjectAssignment" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:if test="UserAssignments/UserAssignment">
        <xsl:call-template name="ois:generate-markdown-list">
            <xsl:with-param name="header" select="'Assigned users'" />
            <xsl:with-param name="values">
                <items> <xsl:apply-templates select="UserAssignments/UserAssignment" mode="list" /> </items>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:apply-templates select="DynamicRoles" />

</xsl:template>
<xsl:template match="ClassAssignment" mode="table">
    <row>
        <value><xsl:value-of select="Type/@name"/></value>
        <value><xsl:value-of select="@allowAssignment"/></value>
        <value><xsl:value-of select="@allowDirectAssignment"/></value>
    </row>
</xsl:template>
<xsl:template match="Role" mode="table">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@fullPath)"/></value>
        <value><xsl:value-of select="ois:is-null-string(UserCount/text(), string(count(UserAssignment/Person)))"/></value>
        <value><xsl:value-of select="Manager/@name"/></value>
        <value><xsl:value-of select="ois:true-or-false(count(DynamicRoles/DynamicRole) &gt; 0)"/></value>
        <value><xsl:value-of select="ois:last-modified(RoleObject)"/></value>
    </row>
</xsl:template>
<xsl:template match="ObjectAssignment" mode="list">
    <value>
        <xsl:text>[</xsl:text><xsl:value-of select="AssignedObject/@table" /><xsl:text>] </xsl:text>
        <xsl:value-of select="ois:escape-for-markdown(AssignedObject/@name)"/>
        <xsl:text> (</xsl:text><xsl:value-of select="ois:get-origin-description(@origin)" /><xsl:text>)</xsl:text>
    </value>
</xsl:template>
<xsl:template match="UserAssignment" mode="list">
    <value>
        <xsl:text>_</xsl:text><xsl:value-of select="Person/@id"/><xsl:text>_</xsl:text>
        <xsl:text> / </xsl:text><xsl:value-of select="Person/@name" />
        <xsl:text> (</xsl:text><xsl:value-of select="ois:get-origin-description(@origin)" /><xsl:text>)</xsl:text>
    </value>
</xsl:template>
<xsl:template match="DynamicRoles">
    <xsl:choose>
    <xsl:when test="count(DynamicRole) &gt; 5">

        <xsl:text>&#xa;#### Dynamic Roles&#xa;</xsl:text>

            <xsl:call-template name="ois:generate-table">
                <xsl:with-param name="summary">Dynamic roles for <xsl:value-of select="../@name"/> role</xsl:with-param>
                <xsl:with-param name="id" select="concat('summary-dynamic-roles-', ../@id)" />
                <xsl:with-param name="header"
                    >| Name        | Criteria        | Class | Schedule | Immediate Assignment? | Last Modified |</xsl:with-param>
                <xsl:with-param name="separator"
                    >|:------------|:----------------|:-----:|:----:|:--:|:------|</xsl:with-param>
                <xsl:with-param name="values"><rows><xsl:apply-templates select="DynamicRole" mode="table" /></rows></xsl:with-param>
            </xsl:call-template>

        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="DynamicRole" mode="section" />
        </xsl:otherwise>
    </xsl:choose>

</xsl:template>
<xsl:template match="DynamicRole" mode="table">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@name)"/></value>
        <value>```<xsl:value-of select="ois:truncate-string(DynamicRoleObject/Property[@Name='WhereClause'], 45, '...')"/>```</value>
        <value><xsl:value-of select="ObjectClass/@name"/></value>
        <value><xsl:value-of select="Schedule/@name"/></value>
        <value><xsl:value-of select="DynamicRoleObject/Property[@Name='IsCalculateImmediately']"/></value>
        <value><xsl:value-of select="ois:last-modified(DynamicRoleObject)"/></value>
    </row>
</xsl:template>
<xsl:template match="DynamicRole" mode="text">
        <xsl:value-of select="concat(ois:escape-for-markdown(@name), '[', Schedule/@name, ']')"/>
</xsl:template>
<xsl:template match="DynamicRole" mode="section" >

    <xsl:text>&#xa;#### Dynamic role: </xsl:text><xsl:value-of select="@name" />

    <xsl:value-of select="ois:markdown-definition('Description', DynamicRoleObject/Property[@Name='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Class', ObjectClass/@name)" />
    <xsl:value-of select="ois:markdown-definition('Schedule', Schedule/@name)" />
    <xsl:value-of select="ois:markdown-definition('Immediate assignment', concat('_', DynamicRoleObject/Property[@Name='IsCalculateImmediately'], '_'))" />

    <xsl:text>&#xa;**Criteria**&#xa;```sql&#xa;</xsl:text>
    <xsl:value-of select="DynamicRoleObject/Property[@Name='WhereClause']" />
    <xsl:text>&#xa;```&#xa;</xsl:text>

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Exceptions'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="Exclusions/Exclusion" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="Exclusion" mode="list">
    <value>
        <xsl:text>_</xsl:text><xsl:value-of select="Person/@id"/><xsl:text>_</xsl:text>
        <xsl:text> / </xsl:text><xsl:value-of select="Person/@name" />
    </value>
</xsl:template>




<!-- ===== IT Shops ======================= -->

<xsl:template match="ShoppingCenters">
    <xsl:choose>
        <xsl:when test="count(ShoppingCenter) &gt; 1">
            <xsl:apply-templates select="ShoppingCenter" mode="section" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="ShoppingCenter/ITShops" mode="section" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="ShoppingCenter" mode="section">
    <xsl:value-of select="concat('&#xa;## Shopping Center: ', @name)" />

    <xsl:value-of select="ois:markdown-definition('Description',ShoppingCenterObject/Property[@Name='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Manager', Manager/@name)" />
    <xsl:value-of select="ois:markdown-definition('Additional Managers (application role)', ois:escape-for-markdown(ManagerRole/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Attestors (role)',ois:escape-for-markdown(Attestor/@fullPath))" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned approval policies'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="PWODecisionMethods/PWODecisionMethod" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="ITShops" mode="section" />

</xsl:template>
<xsl:template match="PWODecisionMethod" mode="list">
    <value>
        <xsl:value-of select="@name" />
    </value>
</xsl:template>

<xsl:template match="ITShops" mode="section">

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Summary of IT Shops </xsl:with-param>
        <xsl:with-param name="id" select="concat('summary-shops-', ../@id)" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree" />
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of IT Shops in ', ../@name)" />
        <xsl:with-param name="id" select="concat('summary-shops-', ../@id)" />
        <xsl:with-param name="header"   >| Name        | Shelves | Products | Customers | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:----:|:----:|:----:|:---------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="ITShop" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="ITShop" mode="section" />
</xsl:template>
<xsl:template match="ITShop" mode="section">
    <xsl:value-of select="concat('&#xa;## Shop: ', @name)" />

    <xsl:value-of select="ois:markdown-definition('Description',ITShopObject/Property[@Name='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Manager', Manager/@name)" />
    <xsl:value-of select="ois:markdown-definition('Additional Managers (application role)', ois:escape-for-markdown(ManagerRole/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Attestors (role)',ois:escape-for-markdown(Attestor/@fullPath))" />

    <xsl:value-of select="ois:markdown-definition('Assigned Users',ois:is-null-string(Customer/UserCount/text(), string(count(Customer/UserAssignments/UserAssignment))))" />
    <xsl:value-of select="ois:markdown-definition(
                            'Customer dynamic role',
                            concat(ois:escape-for-markdown(
                                Customer/DynamicRoles/DynamicRole[1]/@name), ' [Schedule: ', 
                                Customer/DynamicRoles/DynamicRole[1]/Schedule/@name, ']'))" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned approval policies'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="PWODecisionMethods/PWODecisionMethod" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of shelves in ', @name)" />
        <xsl:with-param name="id" select="concat('summary-shop-shelves-', @id)" />
        <xsl:with-param name="header"   >| Name        | Approval Policies | Products | Requests | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:---------------|:--:|:--:|:--------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Shelves/Shelf" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Shelves/Shelf[count(Products/Product) &gt; 0]" mode="section" />
</xsl:template>
<xsl:template match="Shelf" mode="section">
    <xsl:value-of select="concat('&#xa;&#xa;### Shelf: ', @name, '&#xa;')" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned approval policies'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="PWODecisionMethods/PWODecisionMethod" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Products" mode="section" />
</xsl:template>
<xsl:template match="Products" mode="section">
    <xsl:choose>
        <xsl:when test="count(Product) &gt; 20">
**Total products**: <xsl:value-of select="count(Product)" />

**Requests for products**: <xsl:value-of select="sum(Product/Requests)" />
        </xsl:when>
        <xsl:when test="count(Product) &gt; 0">
            <xsl:call-template name="ois:generate-table">
                <xsl:with-param name="summary" select="concat('Summary of products on shelf ', ../@name)" />
                <xsl:with-param name="id" select="concat('summary-shop-shelf-products-', ../@id)" />
                <xsl:with-param name="header"   >| Name        | Entitlement | Requests | Last Modified |</xsl:with-param>
                <xsl:with-param name="separator">|:------------|:------------|:--:|:--------|</xsl:with-param>
                <xsl:with-param name="values">
                    <rows> <xsl:apply-templates select="Product" mode="table" /> </rows>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>no products assigned</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="ITShop" mode="table">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@name)"/></value>
        <value><xsl:value-of select="count(Shelves/Shelf)"/></value>
        <value><xsl:value-of select="count(Shelves/Shelf/Products/Product)"/></value>
        <value><xsl:value-of select="ois:is-null-string(Customer/UserCount/text(), string(count(Customer/UserAssignment/Person)))"/></value>
        <value><xsl:value-of select="ois:last-modified(ITShopObject)"/></value>
    </row>
</xsl:template>
<xsl:template match="Shelf" mode="table">
    <row>
        <!-- strip shopping center and shop name from shelf path -->
        <value><xsl:value-of select="ois:escape-for-markdown(
                                        ois:left-trim(
                                            ois:left-trim(@fullPath, concat(../../../../@name, '\')),
                                            concat(../../@name, '\') ) )"/></value>
        <value><xsl:apply-templates select="PWODecisionMethods" mode="text" /></value>
        <value><xsl:value-of select="count(Products/Product)"/></value>
        <value><xsl:value-of select="sum(Products/Product/Requests)"/></value>
        <value><xsl:value-of select="ois:last-modified(ShelfObject)"/></value>
    </row>
</xsl:template>
<xsl:template match="Product" mode="table">
    <row>
        <!-- strip shopping center and shop name from shelf path -->
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:apply-templates select="Entitlement" mode="text" /></value>
        <value><xsl:value-of select="Requests"/></value>
        <value><xsl:value-of select="ois:last-modified(ProductObject)"/></value>
    </row>
</xsl:template>
<xsl:template match="Entitlement" mode="text">
        <xsl:text>[</xsl:text><xsl:value-of select="@table" /><xsl:text>] </xsl:text>
        <xsl:value-of select="ois:escape-for-markdown(@name)"/>
</xsl:template>
<xsl:template match="PWODecisionMethods" mode="text">
    <xsl:value-of select="PWODecisionMethod/@name" separator=", " />
</xsl:template>
<xsl:template match="ITShops" mode="tree">
    <tree>
        <xsl:attribute name="name" select="if (../@name='DEFAULT') then '' else ../@name" />
        <xsl:attribute name="color" select="$OI_BLACK" />
        <xsl:apply-templates select="ITShop" mode="tree" />
    </tree>
</xsl:template>
<xsl:template match="ITShop" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@fullPath" />
        <xsl:attribute name="color" select="if (ShoppingCenter) then $OI_BROWN else $OI_BLACK" />
        <xsl:apply-templates select="Shelves/Shelf" mode="tree" />
    </branch>
</xsl:template>
<xsl:template match="Shelf" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="ShelfObject/Property[@Name='FullPath']" />
        <xsl:attribute name="color" select="$OI_BROWN" />
    </branch>
</xsl:template>

<!-- ===== Approval policies ======================= -->

<xsl:template match="ApprovalPolicies">
    <xsl:param name="usage"/>


Table: Summary of customized approval policies {#tbl:summary-approval-policies-<xsl:value-of select="$usage" />}

| Policy        | Priority | Description                      | Last Modified |
|:--------------|:-----:|:------------------------------------|:--------------|
<xsl:for-each select="ApprovalPolicy[@usage=$usage]"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="ApprovalPolicyObject/Property[@Name='Priority']" 
    /> | <xsl:value-of select="normalize-space(replace(ApprovalPolicyObject/Property[@Name='Description'], '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(ApprovalPolicyObject)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="ApprovalPolicy[@usage=$usage]" />

</xsl:template>
<xsl:template match="ApprovalPolicy">

## <xsl:value-of select="replace(@name, '\\', '/')" />

<xsl:text>
</xsl:text>

<xsl:value-of select="ApprovalPolicyObject/Property[@Name='Description']" />

<xsl:if test="ApprovalWorkflow">

Approval workflow
: <xsl:value-of select="ApprovalWorkflow/@name" />

</xsl:if>
<xsl:if test="RenewalWorkflow">

Renewal workflow
: <xsl:value-of select="RenewalWorkflow/@name" />

</xsl:if>
<xsl:if test="UnsubscribeWorkflow">

Unsubscribe workflow
: <xsl:value-of select="UnsubscribeWorkflow/@name" />


</xsl:if>


<xsl:call-template name="mail-template-def">
    <xsl:with-param name="node" select="MailTemplateAborted"/>
    <xsl:with-param name="label">Mail template - request cancelled</xsl:with-param>
</xsl:call-template>
<xsl:call-template name="mail-template-def">
    <xsl:with-param name="node" select="MailTemplateExpired"/>
    <xsl:with-param name="label">Mail template - request expired</xsl:with-param>
</xsl:call-template>
<xsl:call-template name="mail-template-def">
    <xsl:with-param name="node" select="MailTemplateApproved"/>
    <xsl:with-param name="label">Mail template - request approved</xsl:with-param>
</xsl:call-template>
<xsl:call-template name="mail-template-def">
    <xsl:with-param name="node" select="MailTemplateDenied"/>
    <xsl:with-param name="label">Mail template - request denied</xsl:with-param>
</xsl:call-template>
<xsl:call-template name="mail-template-def">
    <xsl:with-param name="node" select="MailTemplateRenewed"/>
    <xsl:with-param name="label">Mail template - renewal approved</xsl:with-param>
</xsl:call-template>
<xsl:call-template name="mail-template-def">
    <xsl:with-param name="node" select="MailTemplateUnsubscribed"/>
    <xsl:with-param name="label">Mail template - unsubscribe approved</xsl:with-param>
</xsl:call-template>


</xsl:template>

<xsl:template name="mail-template-def">
    <xsl:param name="node" />
    <xsl:param name="label" />

<xsl:if test="$node">
<xsl:text>

</xsl:text>
<xsl:value-of select="$label"/>
: <xsl:call-template name="mail-template-reference"><xsl:with-param name="node" select="$node"/></xsl:call-template>
<xsl:text>

</xsl:text>
</xsl:if>

</xsl:template>
<xsl:template name="mail-template-reference">
    <xsl:param name="node" />

<xsl:value-of select="$node/@name" /> (<xsl:value-of select="$node/@format" />)

</xsl:template>




<!-- ===== Approval workflows ======================= -->

<xsl:template match="ApprovalWorkflows">
    <xsl:param name="usage"/>


Table: Summary of customized approval workflows {#tbl:summary-approval-workflows-<xsl:value-of select="$usage" />}

| Workflow        | Revision | Days to Abort | Description                                | Last Modified |
|:----------------|:--------:|:----:|:---------------------------------------|:--------------|
<xsl:for-each select="ApprovalWorkflow[@usage=$usage]"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="@revision"
    /> | <xsl:value-of select="ApprovalWorkflowObject/Property[@Name='DaysToAbort']"
    /> | <xsl:value-of select="normalize-space(replace(ApprovalWorkflowObject/Property[@Name='Description'], '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(ApprovalWorkflowObject)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="ApprovalWorkflow[@usage=$usage]" />

</xsl:template>
<xsl:template match="ApprovalWorkflow">

## <xsl:value-of select="replace(@name, '\\', '/')" />

<xsl:text>
</xsl:text>

<xsl:value-of select="ApprovalWorkflowObject/Property[@Name='Description']" />
<xsl:text>
</xsl:text>


<xsl:if test="Graphic">
![Overview of approval workflow <xsl:value-of select="@name"/>](images/<xsl:value-of select="Graphic/@fileName"/>){#fig:approval-workflow-overview-<xsl:value-of select="@id" />}
</xsl:if>


Table: Summary of workflow steps {#tbl:summary-approval-workflow-steps-<xsl:value-of select="@id" />}

| Level / Step        | Level | Abort (min) | Reminder (min) |Rule    | Last Modified |
|:--------------------|:----:|:-----:|:-----:|:--------------------|:--------------|
<xsl:for-each select="ApprovalSteps/ApprovalStep"
       ><xsl:sort select="@level" order="ascending"
       />| **<xsl:if test="string-length(@levelName) &gt; 0"><xsl:value-of select="replace(@levelName, '\\', '/')"/><br /></xsl:if><xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="@level"
    /> | <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='MinutesAutomaticDecision'], '0')"
    /> | <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='MinutesReminder'], '0')"
    /> | <xsl:value-of select="Rule/@name"
    /> | <xsl:value-of select="ois:last-modified(ApprovalStepObject)"
    /> |                 
</xsl:for-each>   


<xsl:for-each select="ApprovalSteps/ApprovalStep"><xsl:sort select="@level" order="ascending"/>
    <xsl:apply-templates select="." />
</xsl:for-each>   

</xsl:template>
<xsl:template match="ApprovalStep">

### <xsl:value-of select="ois:is-null-string(@levelName, 'Step')" />: <xsl:value-of select="@name" />
<xsl:text>
</xsl:text>

<xsl:value-of select="ApprovalStepObject/Property[@Name='Description']" />
<xsl:text>
</xsl:text>


| Escalate if no approver found | Additional approvers allowed | Delegation allowed | No automatic approval | Hide decision | Allow affected identity to approve |
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|     <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='EscalateIfNoApprover'], 'False')"
/> |  <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='IsAdditionalAllowed'], 'False')"
/> |  <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='IsInsteadOfAllowed'], 'False')"
/> |  <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='IsNoAutoDecision'], 'False')"
/> |  <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='IsToHideInHistory'], 'False')"
/> |  <xsl:value-of select="ois:is-null-string(ApprovalStepObject/Property[@Name='IgnoreNoDecideForPerson'], 'False')"
/> |  
   
</xsl:template>


<!-- ===== Service Catalog ======================= -->

<xsl:template match="ProductGroups">

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Service catalog hierarchy</xsl:with-param>
        <xsl:with-param name="id" select="'summary-service-catalog'" />
        <xsl:with-param name="header" select="'Service Catalog'" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree" />
        </xsl:with-param>
    </xsl:call-template>


 <!--<xsl:for-each select="ProductGroup[count(Products/Product/ITShopOrg[not(Requests='0')]) &gt; 0]" -->
Table: Summary of service catalog categories with items {#tbl:summary-service-catalog-groups}

| Cateogry              | Description           | Approval Policy | Products | Requests |
|:----------------------|:----------------------|:----------------|:------:|:------:|
<xsl:for-each select="ProductGroup[count(Products/Product) &gt; 0]"
       ><xsl:sort select="@fullPath" order="ascending"
     />| **<xsl:value-of select="replace(@fullPath, '\\', '/')" 
  />** | <xsl:if test="Image"
             >![](images/<xsl:value-of select="Image" />){.category-image-small} </xsl:if
        ><xsl:value-of select="Description"
    /> | <xsl:value-of select="ApprovalPolicy/@name"
    /> | <xsl:value-of select="count(Products/Product)"
    /> | <xsl:value-of select="sum(Products/Product/ITShopOrg/Requests)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="ProductGroup[count(Products/Product/ITShopOrg[not(Requests='0')]) &gt; 0]" />

</xsl:template>
<xsl:template match="ProductGroup">

## Category: <xsl:value-of select="replace(@fullPath, '\\', '/')" />
<xsl:text>

</xsl:text>

<xsl:if test="Description">
 <xsl:if test="Image"
      >![](images/<xsl:value-of select="Image" />){.category-image-small} </xsl:if
 ><xsl:value-of select="Description"
/></xsl:if>

<xsl:if test="ApprovalPolicy">
<xsl:text>

</xsl:text>
**Approval policy**: <xsl:value-of select="@name"/>

Approval workflows:

<xsl:if test="ApprovalPolicy/RequestWorkflow">- Request: <xsl:value-of select="ApprovalPolicy/RequestWorkflow/@name" />
</xsl:if>
<xsl:if test="ApprovalPolicy/RenewalWorkflow">- Renew: <xsl:value-of select="ApprovalPolicy/RenewalWorkflow/@name" />
</xsl:if>
<xsl:if test="ApprovalPolicy/UnsubscribeWorkflow">- Unsubscribe: <xsl:value-of select="ApprovalPolicy/UnsubscribeWorkflow/@name" />
</xsl:if>

</xsl:if>

<xsl:if test="count(Products/Product) &gt; 0">

<xsl:choose>
<xsl:when test="count(Products/Product) &lt; 20">
<xsl:text>

</xsl:text>
Table: Summary of serivce catalog items {#tbl:summary-service-catalog-items-<xsl:value-of select="@id" />}

| Product               | Description           | Approval Policy | Requests |
|:----------------------|:----------------------|:----------------|:------:|
<xsl:for-each select="Products/Product"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="@name" 
  />** | <xsl:if test="Image"
             >![](images/<xsl:value-of select="Image" />){.category-image-small} </xsl:if
        ><xsl:value-of select="Description"
    /> | <xsl:value-of select="ApprovalPolicy/@name"
    /> | <xsl:value-of select="ITShopOrg/Requests"
    /> |                 
</xsl:for-each>   
</xsl:when>
<xsl:otherwise>
<xsl:text>

</xsl:text>
**Total items in category**: <xsl:value-of select="count(Products/Product)" />

**Requests for items in category**: <xsl:value-of select="sum(Products/Product/Requests)" />
</xsl:otherwise>
</xsl:choose>

</xsl:if>

</xsl:template>

<xsl:template match="ProductGroups" mode="tree">
    <tree>
        <xsl:apply-templates select="ProductGroup" mode="tree">
            <xsl:sort select="@fullPath" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="ProductGroup" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@fullPath" />
        <xsl:attribute name="color" select="$OI_BROWN" />
    </branch>
</xsl:template>



<!-- ===== Attestation Policies ======================= -->

<xsl:template match="AttestationPolicies">

Table: Summary of attestation policies in use {#tbl:summary-attestatation-policies}

| Policy            | Procedure       | Approval Policy | Schedule  | Last Modified | Cases |
|:------------------|:----------------|:----------------|:----------|:---------|:--:|
<xsl:for-each select="AttestationPolicy[not(Cases='0')]"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="Procedure/@name"
    /> | <xsl:value-of select="ApprovalPolicy/@name"
    /> | <xsl:value-of select="Schedule/@name"
    /> | <xsl:value-of select="ois:last-modified(AttestationPolicyObject)"
    /> | <xsl:value-of select="Cases"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="AttestationPolicy[not(Cases='0')]" />

</xsl:template>
<xsl:template match="AttestationPolicy">

## Policy: <xsl:value-of select="@name" />
<xsl:text>
</xsl:text>

<xsl:if test="string-length(AttestationPolicyObject/Property[@Name='Description']) &gt; 0">

<xsl:value-of select="AttestationPolicyObject/Property[@Name='Description']"/>
</xsl:if>



### Procedure

<xsl:apply-templates select="Procedure" />


<xsl:if test="count(PolicyRuns/PolicyRun[not(Cases='0')]) &gt; 0">
<xsl:text>
</xsl:text>
### Attestation Runs


<xsl:choose>
    <xsl:when test="count(PolicyRuns/PolicyRun[not(Cases='0')]) &lt; 20">

Table: Policy runs for <xsl:value-of select="@name" /> {#tbl:summary-attestatation-run-<xsl:value-of select="@id" />}

| Date        | Total Cases | Open Cases |
|:------------|:----:|:----:|
<xsl:for-each select="PolicyRuns/PolicyRun[not(Cases='0')]"
       ><xsl:sort select="@sortableDate" order="ascending"
     />| **<xsl:value-of select="@processDate" 
  />** | <xsl:value-of select="Cases"
    /> | <xsl:value-of select="OpenCases"
    /> |                 
</xsl:for-each>   
</xsl:when>
<xsl:otherwise>

**Total runs**: <xsl:value-of select="count(PolicyRuns/PolicyRun[not(Cases='0')])" />
<br />
**Open cases**: <xsl:value-of select="sum(PolicyRuns/PolicyRun/OpenCases)" />
<br />
**Total cases**: <xsl:value-of select="sum(PolicyRuns/PolicyRun/Cases)" />

</xsl:otherwise>
</xsl:choose>

</xsl:if>

</xsl:template>

<xsl:template match="Procedure">
<xsl:text>
</xsl:text>
**Name**: <xsl:value-of select="@name" />

**Type**: <xsl:value-of select="Type/@name" />

**Table**: <xsl:value-of select="Table/@name" />

**Report**: <xsl:value-of select="Report/@name" />


<xsl:if test="string-length(ProcedureObject/Property[@Name='Description']) &gt; 0">
<xsl:text>

</xsl:text>
<xsl:value-of select="ProcedureObject/Property[@Name='Description']"/>
</xsl:if>


Table: Procedure templates {#tbl:summary-attestatation-procedure-templates-<xsl:value-of select="../@id" />}

| Attribute        | Label | Template |
|:------------|:-----------|:---------------|
| **Grouping column 1** | <xsl:value-of select="ProcedureObject/Property[@Name='StructureDisplay1']" /> | <xsl:if test="string-length(ProcedureObject/Property[@Name='StructureDisplayPattern1']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='StructureDisplayPattern1']" />`</xsl:if> |
| **Grouping column 2** | <xsl:value-of select="ProcedureObject/Property[@Name='StructureDisplay2']" /> | <xsl:if test="string-length(ProcedureObject/Property[@Name='StructureDisplayPattern2']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='StructureDisplayPattern2']" />`</xsl:if> |
| **Grouping column 3** | <xsl:value-of select="ProcedureObject/Property[@Name='StructureDisplay3']" /> | <xsl:if test="string-length(ProcedureObject/Property[@Name='StructureDisplayPattern3']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='StructureDisplayPattern3']" />`</xsl:if> |
| **Property 1** | <xsl:value-of select="ProcedureObject/Property[@Name='PropertyInfo1']" /> | <xsl:if test="string-length(ProcedureObject/Property[@Name='PropertyInfoPattern1']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='PropertyInfoPattern1']" />`</xsl:if> |
| **Property 2** | <xsl:value-of select="ProcedureObject/Property[@Name='PropertyInfo2']" /> | <xsl:if test="string-length(ProcedureObject/Property[@Name='PropertyInfoPattern2']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='PropertyInfoPattern2']" />`</xsl:if> |
| **Property 3** | <xsl:value-of select="ProcedureObject/Property[@Name='PropertyInfo3']" /> | <xsl:if test="string-length(ProcedureObject/Property[@Name='PropertyInfoPattern3']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='PropertyInfoPattern3']" />`</xsl:if> |
| **Related object 1** |  | <xsl:if test="string-length(ProcedureObject/Property[@Name='ObjectKey1']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='ObjectKey1']" />`</xsl:if> |
| **Related object 2** |  | <xsl:if test="string-length(ProcedureObject/Property[@Name='ObjectKey2']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='ObjectKey2']" />`</xsl:if> |
| **Related object 3** |  | <xsl:if test="string-length(ProcedureObject/Property[@Name='ObjectKey3']) &gt; 0">`<xsl:value-of select="ProcedureObject/Property[@Name='ObjectKey3']" />`</xsl:if> |

</xsl:template>









<!-- ===== Account Definitions ======================= -->

<xsl:template match="AccountDefinitions">


Table: Summary of account definitions {#tbl:summary-account-definitions}

| Policy            | Target        | Default Behaviour  | Last Modified      |
|:------------------|:--------------|:-------------------|:-------------------|
<xsl:for-each select="AccountDefinition"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="TargetSystem/@name" 
    /> | <xsl:value-of select="DefaultBehavior/@name"
    /> | <xsl:value-of select="ois:last-modified(AccountDefinitionObject)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="AccountDefinition" />

</xsl:template>
<xsl:template match="AccountDefinition">

## <xsl:value-of select="replace(@name, '\\', '/')" />

<xsl:if test="string-length(Description) &gt; 0">
**Description**: <xsl:value-of select="Description" />
</xsl:if>

<xsl:if test="RequiredAccountDef">
**Parent account definition**: <xsl:value-of select="RequiredAccountDef/@name" />
</xsl:if>

### Manage Levels

Table: Manage levels for account definition <xsl:value-of select="@name"/> {#tbl:account-definition-behaviors-<xsl:value-of select="@id" />}

| Level     | Description       | Last Modified |
|:----------|:------------------|:--------------|
<xsl:for-each select="Behaviors/Behavior"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="Property[@Name='Description']" 
    /> | <xsl:value-of select="ois:last-modified(.)"
    /> |                 
</xsl:for-each>   

<xsl:if test="DataMappings/DataMapping">
    <xsl:variable name="accountDef" select="@id" />
    <xsl:variable name="targetTable" select="TargetSystem/@table" />

### IT Data Mapping

Table: IT Data columns for account definition <xsl:value-of select="@name"/> {#tbl:account-definition-data-maps-<xsl:value-of select="@id" />}

| Column            | Fixed Value       | Default Value |
|:------------------|:----:|:---------------------------|
<xsl:for-each select="DataMappings/DataMapping"
    ><xsl:sort select="Column/@name" order="ascending"
     />| <xsl:value-of select="$targetTable"/>: **<xsl:value-of select="Column/@name"
  />** | <xsl:value-of select="@fixValue" 
    /> | <xsl:if test="string-length(@fixValue) = 0"><xsl:value-of select="DefaultValue/@table"/> - <xsl:value-of select="DefaultValue/@longName"/></xsl:if
     > |                 
</xsl:for-each>   

<xsl:for-each select="DataMappings/DataMapping[count(DataMaps/DataMap) &gt; 0]">
 
#### <xsl:value-of select="$targetTable"/>: <xsl:value-of select="Column/@name" />

<xsl:if test="DefaultValue">
**Default value**: <xsl:value-of select="DefaultValue/@table"/> - <xsl:value-of select="DefaultValue/@longName" />
</xsl:if>

  <xsl:if test="DataMaps/DataMap">

Table: ITData assignments for column <xsl:value-of select="$targetTable"/> - <xsl:value-of select="Column/@name"/> {#tbl:account-definition-data-map-values-<xsl:value-of select="$accountDef" />-<xsl:value-of select="$targetTable"/>-<xsl:value-of select="Column/@name" />}

| Structure                        | Column Value       | 
|:---------------------------------|:-------------------|
<xsl:for-each select="DataMaps/DataMap"
   ><xsl:sort select="@name" order="ascending"
    />| <xsl:value-of select="Structure/Type/@name"/>: **<xsl:value-of select="Structure/@name" 
 />** | <xsl:value-of select="ois:is-null-string(Value/@longName,Value/@name)" 
   /> |                 
</xsl:for-each>   


  </xsl:if>

 </xsl:for-each>   
</xsl:if>


</xsl:template>


<!-- ===== Scripts ======================= -->

<xsl:template match="Scripts">
# Scripts


Table: Summary of custom scripts {#tbl:summary-scripts}

| Script        | Locked? | Description              | Last Modified |
|:--------------|:-----:|:---------------------------|:--------------|
<xsl:for-each select="Script"
       ><xsl:sort select="@name"    order="ascending"
     />| **<xsl:value-of select="@name"
  />** | <xsl:value-of select="Property[@Name='IsLocked']" 
    /> | <xsl:value-of select="normalize-space(replace(Property[@Name='Description'], '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(.)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="Script" />

</xsl:template>
<xsl:template match="Script">

## <xsl:value-of select="@name" />

```monobasic
<xsl:value-of select="Property[@Name='ScriptCode']" />

```
</xsl:template>




<!-- ===== target systems ======================= -->

<xsl:template match="TargetSystems">


Table: Summary of integrated systems {#tbl:summary-target-systems}

| System        | Type           | Managed By |Owner Role |
|:--------------|:---------------|:----:|:---------------|
<xsl:for-each select="TargetSystem"
><xsl:sort select="SyncType/@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="SyncType/@name"
    /> | <xsl:value-of select="@managedBy"
    /> | <xsl:value-of select="translate(OwnerRole/@fullPath, '\', '/')"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="TargetSystem" />

</xsl:template>
<xsl:template match="TargetSystem">
    <xsl:variable name="objectKey" select="@key" />
    <xsl:variable name="spsFarmKey" select="SPSWebApp/Farm/@key" />


## <xsl:value-of select="SyncType/@name"/>: <xsl:value-of select="replace(@name, '\\', '/')" />

**Containers**: <xsl:value-of select="ois:is-null-string(ObjectCounts/Containers/text(), '0')" />

**Groups**: <xsl:value-of select="ois:is-null-string(ObjectCounts/Groups/text(), '0')" />

**Accounts**: <xsl:value-of select="ois:is-null-string(ObjectCounts/Accounts/text(), '0')" />

<xsl:apply-templates select="Forest|ExchangeForest" />
<xsl:apply-templates select="SPSWebApp" />




<xsl:if test="count(/IdentityManager/SyncProjects/SyncProject[contains(concat($objectKey,$spsFarmKey),Connections/Connection/RootObjConnectionInfos/RootObjConnectionInfo/RootObject/@key)]) &gt; 0">

**Sync projects**:

<xsl:for-each select="/IdentityManager/SyncProjects/SyncProject[contains(concat($objectKey,$spsFarmKey),Connections/Connection/RootObjConnectionInfos/RootObjConnectionInfo/RootObject/@key)]">
- <xsl:value-of select="@name" />
</xsl:for-each>   

</xsl:if>

</xsl:template>

<xsl:template match="Forest|ExchangeForest">

**Active Directory forest**: <xsl:value-of select="@name" />

</xsl:template>

<xsl:template match="SPSWebApp">

**SharePoint web application**: <xsl:value-of select="@name"
/><xsl:if test="Farm"><xsl:value-of select="concat('&#xa;&#xa;**SharePoint farm**: ', Farm/@name)" /></xsl:if>

</xsl:template>




<xsl:template name="SyncProjects-With-Systems">

    <SyncProjects>
        <xsl:for-each select="/IdentityManager/SyncProjects/SyncProject">
            <Sync>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                </xsl:copy>
                <Infos>
                    <xsl:for-each select="Connections/Connection/RootObjConnectionInfos/RootObjConnectionInfo">
                        <Info>
                            <xsl:attribute name="server" select="Server/@name" />
                            <xsl:attribute name="queue" select="Server/@queue" />
                            <xsl:attribute name="RootObjectKey" select="RootObject/@key" />
                            <xsl:copy-of select="Server" />
                            <xsl:copy-of select="RootObject" />
                        </Info>
                    </xsl:for-each>
                </Infos>
            </Sync>
        </xsl:for-each>
    </SyncProjects>

</xsl:template>



<!-- ===== Sync Projects ======================= -->

<xsl:template match="SyncProjects">


Table: Summary of synchronization projects {#tbl:summary-synchronization-projects}

| Project        | Description           | Notes                      | Last Modified |
|:--------------|:---------------|:---------------------------|:---------------|
<xsl:for-each select="SyncProject"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="SyncProjectObject/Property[@Name='Description']"
    /> | <xsl:call-template name="ois:escape-for-markdown-table">
            <xsl:with-param name="s"><xsl:value-of select="SyncProjectObject/Property[@Name='OriginInfo']"/></xsl:with-param></xsl:call-template
     > | <xsl:value-of select="ois:last-modified(SyncProjectObject)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="SyncProject" />

</xsl:template>

<xsl:template match="SyncProject">

## <xsl:value-of select="@name" />

Table: Startup configurations for <xsl:value-of select="@name" /> {#tbl:synchronization-project-start-<xsl:value-of select="@id"/>}

| Project        | Direction | Revisions | Variable Set  | Workflow           | Schedules   |
|:--------------|:-----:|:-----:|:--------|:---------------|:------------------|
<xsl:for-each select="StartInfos/StartInfo"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@displayName, '\\', '/')" 
     />** | <xsl:value-of select="@direction"
     /> | <xsl:value-of select="@revisionHandling"
     /> | <xsl:value-of select="VariableSet/@name"
     /> | <xsl:value-of select="Workflow/@name"
     /> | <xsl:value-of select="JobAutoStarts/JobAutoStart/Schedule/@name" separator=", "
     /> |                 
</xsl:for-each>   



<xsl:apply-templates select="VariableSets/VariableSet" />



### Workflows

Table: Synchronization workflows for <xsl:value-of select="@name" /> {#tbl:synchronization-project-workflow-<xsl:value-of select="@id"/>}

| Workflow        | Description         | Direction  | Revisions | Conflict Resolution | Exception Handling |
|:----------------|:--------------------|:------:|:-------:|:-------:|:---------:|
<xsl:for-each select="Workflows/Workflow"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@displayName, '\\', '/')" 
     />** | <xsl:value-of select="WorkflowObject/Property[@Name='Description']"
     /> | <xsl:value-of select="@direction"
     /> | <xsl:value-of select="@revisionHandling"
     /> | <xsl:value-of select="@conflictResolution"
     /> | <xsl:value-of select="@exceptionHandling"
     /> |                 
</xsl:for-each>   

<xsl:apply-templates select="Workflows/Workflow" />


### Mapping

<xsl:for-each select="SystemMaps/SystemMap">

Table: Property mapping for <xsl:value-of select="@name" /> {#tbl:synchronization-project-map-<xsl:value-of select="@id"/>}

|  <xsl:value-of select="LeftSchema/@name" />  |  Options    | <xsl:value-of select="RightSchema/@name" /> |
|:-------------------------|:-----:|:--------------------------|
<xsl:for-each select="Rules/Rule"
><xsl:sort select="@isKeyRule" order="descending" /><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="@propertyLeft" 
  />** | <xsl:value-of select="if(@isKeyRule='True') then 'Key' else ''"
    /> | **<xsl:value-of select="@propertyRight"
  />** |                 
</xsl:for-each>   


</xsl:for-each>

</xsl:template>

<xsl:template match="VariableSet">

### Variable Set: <xsl:value-of select="@name" />

Table: Values for variable set <xsl:value-of select="@name" /> {#tbl:synchronization-project-variables-<xsl:value-of select="@id"/>}

| Variable        | Value | Secret? | System Variable? |
|:----------------|:-----------------|:-----:|:-----:|
<xsl:for-each select="Variables/Variable"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="@name" 
     />** | <xsl:value-of select="if(@isSecret='True') then '[secret]' else @value"
     /> | <xsl:value-of select="@isSecret"
     /> | <xsl:value-of select="@isSystemVariable"
     /> |                 
</xsl:for-each>   

</xsl:template>


<xsl:template match="Workflow">

#### Workflow: <xsl:value-of select="@name" />

Table: Synchronization steps for <xsl:value-of select="@name" /> {#tbl:synchronization-project-workflow-steps-<xsl:value-of select="@id"/>}

| Step        | Description         | Direction  | Inactive? | Data Import? | Exception Handling |
|:----------------|:--------------------|:------:|:-------:|:---------:|:--------:|
<xsl:for-each select="Steps/Step"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="@name" 
     />** | <xsl:value-of select="StepObject/Property[@Name='Description']"
     /> | <xsl:value-of select="@direction"
     /> | <xsl:value-of select="@isDeactivated"
     /> | <xsl:value-of select="@isImport"
     /> | <xsl:value-of select="@exceptionHandling"
     /> |                 
</xsl:for-each>   

</xsl:template>






<!-- ===== generic functions ======================= -->

  <!-- Function to extract last modified string -->
  <xsl:function name="ois:last-modified" as="xs:string">
    <xsl:param name="o"/>

    <xsl:variable name="result">
        <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown($o/Property[@Name='XUserUpdated']), 15, '...')" /> - <xsl:value-of select="$o/Property[@Name='XDateUpdated']" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function> 


  <xsl:function name="ois:get-origin-description" as="xs:string">
      <xsl:param name="origin" as="xs:integer"/>
      <xsl:variable name="result">
          <xsl:call-template name="ois:select-by-index">
              <xsl:with-param name="i" select="$origin" />
              <xsl:with-param name="values">
                      <v>direct</v>
                      <v>inherited</v>
                      <v>direct + inherited</v>
                      <v>dynamic</v>
              </xsl:with-param>
          </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="$result" />
  </xsl:function>


  <!-- de-reference pointer -->
  <xsl:template name="get-object-name">
      <xsl:param name="id" />
      <xsl:value-of select="//IdentityManager/TargetSystems/TargetSystem[@id = $id]/@name"/>
      <xsl:value-of select="//IdentityManager/SyncProjects/SyncProject[@id = $id]/@name"/>
  </xsl:template>

</xsl:stylesheet>
