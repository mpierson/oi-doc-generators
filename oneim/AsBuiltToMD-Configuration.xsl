<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform One Identity config export to Markdown

  Author: M Pierson
  Date: Mar 2025
  Version: 0.91

  Use exporter.exe to generate source XML

 -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" 
                              exclude-result-prefixes="ois xs">

  <xsl:include href="OIS-Project.xsl" />
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:import href="OIS-JSONLib.xsl" />
  <xsl:import href="OIS-StringLib.xsl" />
  <xsl:import href="OIS-Markdown.xsl" />
  <xsl:import href="OIS-PlantUML.xsl" />
  <xsl:import href="OIS-SVG.xsl" />
  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />

  <xsl:param name="additional-servers">
      <Servers/>
  </xsl:param>
  <xsl:param name="ext-project">
      <project/>
  </xsl:param>


  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />

  <xsl:variable name="OI_GREEN"         select="'#afcc9e'" />
  <xsl:variable name="OI_BLACK"         select="'#162c36'" />
  <xsl:variable name="OI_BLUE"          select="'#04aada'" />
  <xsl:variable name="OI_GRAY"          select="'#40535d'" />
  <xsl:variable name="OI_JACARTA"       select="'#3f2c69'" />
  <xsl:variable name="OI_MONTE_CARLO"   select="'#77c8b3'" />
  <xsl:variable name="OI_JAFFA"         select="'#ee8a54'" />
  <xsl:variable name="OI_NEPAL"         select="'#82a7c5'" />
  <xsl:variable name="OI_PEAR"          select="'#cddb28'" />
  <xsl:variable name="OI_LOBLOLLY"      select="'#cad4d7'" />
  <xsl:variable name="OI_BLUE_LAGOON"   select="'#00969f'" />
  <xsl:variable name="QUEST_ORANGE"     select="'#fb4f14'" />


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
author: OneIM As Built Generator v0.91
abstract: |
    Configuration of the <xsl:value-of select="@name" /> instance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Summary

    <xsl:apply-templates select="$ext-project/project" />
    <xsl:apply-templates select="." mode="servers-summary" />
    <xsl:apply-templates select="$ext-project/project/environments" />


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
                <xsl:apply-templates select="ApplicationRoles/ApplicationRole" mode="tree">
                    <xsl:sort select="@fullPath" />
                </xsl:apply-templates>
            </tree>
        </xsl:with-param>
    </xsl:call-template>

   <xsl:apply-templates select="ApplicationRoles" mode="section">
       <xsl:with-param name="custom-role-path" select="'Custom'" />
   </xsl:apply-templates>


# Organization Structures

<xsl:apply-templates select="Departments|Locations|CostCenters" />

# Business Roles

<xsl:apply-templates select="RoleClasses" />

# IT Shop

## Shopping Centers and Shops

<xsl:apply-templates select="ShoppingCenters" />

## Approval Policies

<xsl:apply-templates select="ApprovalPolicies"> <xsl:with-param name="usage">I</xsl:with-param> </xsl:apply-templates>


## Approval Workflows

<xsl:apply-templates select="ApprovalWorkflows"> <xsl:with-param name="usage">I</xsl:with-param> </xsl:apply-templates>

## Approver Selection Rules

<xsl:apply-templates select="ApprovalDecisionRules"> <xsl:with-param name="usage">I</xsl:with-param> </xsl:apply-templates>

## Service Catalog

<xsl:apply-templates select="CatalogGroups" />


# Account Definitions

<xsl:apply-templates select="AccountDefinitions" />


# Attestation

<xsl:apply-templates select="AttestationPolicies" />


## Approval Policies

<xsl:apply-templates select="ApprovalPolicies"> <xsl:with-param name="usage">A</xsl:with-param> </xsl:apply-templates>


## Approval Workflows

<xsl:apply-templates select="ApprovalWorkflows"> <xsl:with-param name="usage">A</xsl:with-param> </xsl:apply-templates>


<xsl:apply-templates select="AttestationProcedures" />


<xsl:apply-templates select="ComplianceRules" />


# Password Policies

<xsl:apply-templates select="PasswordPolicies" />



# Integrated Systems

<xsl:apply-templates select="TargetSystems"/> 

# Synchronization Projects

<xsl:apply-templates select="SyncProjects"/> 


</xsl:template>


<!-- ===== project ============================== -->

<xsl:template match="project">
    <xsl:value-of select="ois:markdown-definition('Project', @name)" />
    <xsl:value-of select="ois:markdown-definition('Description', description)" />
    <xsl:value-of select="ois:markdown-definition('Customer',
        concat( '[', customer/@fullName, '](', customer/@url, ')' )
    )" />
</xsl:template>
<xsl:template match="environments">
        <xsl:value-of select="ois:markdown-heading-2('Environments')" />
        <xsl:apply-templates select="environment" />
</xsl:template>
<xsl:template match="environment">
        <xsl:value-of select="ois:markdown-heading-3(@name)" />
        <xsl:apply-templates select="deploy_def" />
</xsl:template>

<!-- ===== architecture graphic ========================== -->

<xsl:template match="Servers" mode="job-server-hosts">
    <hosts>
        <xsl:for-each select="Server[@serviceInstalled='true' and count(DeployTargets/DeployTarget) &gt; 0 and (string-length(@physicalServer) &gt; 0 or (@physicalServer = @FQDN))]">
            <xsl:sort select="@name" />
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



<xsl:template match="IdentityManager" mode="servers-summary">
    <xsl:variable name='dbHost' select="PrimaryDatabase/@dataSource"/>
    <xsl:variable name="job-servers">
            <xsl:apply-templates select="Servers" mode="job-server-hosts" />
    </xsl:variable>
    <xsl:variable name="web-apps" select="WebApps" />
    <xsl:variable name="target-systems" select="TargetSystems" />
    <xsl:variable name="sync-projects">
        <xsl:call-template name="SyncProjects-With-Systems"/>
    </xsl:variable>


```{.plantuml caption="Identity Manager overview"}

!include_many /home/mpierson/projects/quest/OneIM/posh-exporter/header.puml

top to bottom direction

<!-- database -->
    Boundary(main, "Server <xsl:value-of select="PrimaryDatabase/@DataSource"/>", $tags="OI_System") {
    ComponentDb(main_database, "<xsl:value-of select="ois:is-null-string(PrimaryDatabase/@InitialCatalog, /IdentityManager/@name)"/>", "primary database", $tags="OneIM_DB")
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

<!-- job servers -->
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
    Component(TS_<xsl:value-of select="translate(@id, '\%/-', '')"/>, "<xsl:value-of select="@name"/> (<xsl:value-of select="SyncType/@name" />)", $tags="OneIM_TS")
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
    Component(TSHR, "HR Source", $tags="OneIM_TS")
}




<!-- connections -->
Rel(WebApps, main_database, "uses", $tags="light")
Rel(TargetSystems, main_database, "uses", $tags="light")

<xsl:for-each select="$job-servers/hosts/host[not(@name=$dbHost)]">
Rel_U(JS_<xsl:value-of select="@name" />, main_database, "uses", $tags="light")
</xsl:for-each>

<!--
<xsl:for-each-group select="$web-apps/WebApp" group-by="@host">
    <xsl:variable name="host-fqdn" select="current-grouping-key()" />
    <xsl:if test="count($job-servers/hosts/host[compare(upper-case(@FQDN), upper-case($host-fqdn)) = 0]) = 0">
        <xsl:for-each select="current-group()">
            Rel_U(WEB_<xsl:value-of select="translate(string-join(($host-fqdn, @id), '_'), '\%/-', '')" />, main_database, "uses", $tags="light")
        </xsl:for-each>
    </xsl:if>
</xsl:for-each-group>
-->

<xsl:for-each select="$job-servers/hosts/host[@name=$dbHost]">
    <xsl:for-each select="queues/queue">
        Rel_U(JQ_<xsl:value-of select="translate(string-join(($dbHost,@name), '_'), '\%/', '')" />, main_database, "uses", $tags="light")
    </xsl:for-each>
</xsl:for-each>

<!--
    <xsl:for-each select="$sync-projects/SyncProjects/Sync[Infos/Info/RootObject]">
        <xsl:variable name="ts">
            <xsl:choose>
                <xsl:when test="Infos/Info/RootObject/@id='QER-T-Person'">TSHR</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('TS_', translate(Infos/Info/RootObject/@id, '\%/-', ''))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        Rel_D(SYNC_<xsl:value-of select="translate(SyncProject/@id, '\%/-', '')" />, <xsl:value-of select="$ts"/>, "synchronizes", $tags="light")
    </xsl:for-each>
-->

<xsl:for-each select="$target-systems/TargetSystem">
    <xsl:if test="SPSWebApp">
        Rel_D(TS_<xsl:value-of select="translate(@id, '\%/-', '')"/>, TS_<xsl:value-of select="translate(SPSWebApp/@name, ':/- ', '')"/>, "", $tags="light")
        <xsl:if test="SPSWebApp/Farm">
            Rel_D( TS_<xsl:value-of select="translate(@id, '\%/-', '')"/>, TS_<xsl:value-of select="translate(SPSWebApp/Farm/@name, ':/- ()', '')"/>, "", $tags="light")
        </xsl:if>
    </xsl:if>
    <xsl:if test="Forest">
        Rel_D(TS_<xsl:value-of select="translate(@id, '\%/-', '')"/>, TSF_<xsl:value-of select="translate(Forest/@name, ':/- ', '')"/>, "", $tags="light")
    </xsl:if>
    <xsl:if test="ExchangeForest">
        Rel_D(TS_<xsl:value-of select="translate(@id, '\%/-', '')"/>, TSF_<xsl:value-of select="translate(ExchangeForest/@name, ':/- ', '')"/>, "", $tags="light")
    </xsl:if>

</xsl:for-each>

```
![Identity Manager overview](single.png){#fig:overview}


</xsl:template>




<!-- ===== Primary Database ======================= -->

<xsl:template match="PrimaryDatabase">

Identity Manager version
: <xsl:value-of select="../@version" />

Host name
: <xsl:value-of select="@DataSource" />

Schema
: <xsl:value-of select="@InitialCatalog" />

User name
: <xsl:value-of select="@UserID" />


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
        <value><xsl:value-of select="MailTemplateProperties/Property[@Field='Description']"/></value>
        <value><xsl:value-of select="MailTemplateProperties/Property[@Field='TargetFormat']" /></value>
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
        <value><xsl:value-of select="ois:encode-breaks-for-markdown-table(PasswordPolicyProperties/Property[@Field='Description'])"/></value>
        <value><xsl:value-of select="@isDefault" /></value>
        <value><xsl:value-of select="ois:last-modified(PasswordPolicyProperties)" /></value>
    </row>
</xsl:template>

<xsl:template match="PasswordPolicy" mode="section">

## <xsl:value-of select="@name" />

<xsl:value-of select="ois:markdown-definition('Description', PasswordPolicyProperties/Property[@Field='Description'])" />
<xsl:value-of select="ois:markdown-definition('Custom error message', PasswordPolicyProperties/Property[@Field='ErrorMessage'])" />
<xsl:value-of select="ois:markdown-definition('Check script', PasswordPolicyProperties/Property[@Field='CheckScriptName'])" />
<xsl:value-of select="ois:markdown-definition('Create', PasswordPolicyProperties/Property[@Field='CreateScriptName'])" />
<xsl:value-of select="ois:markdown-definition-int('Minumum length', PasswordPolicyProperties/Property[@Field='MinLen'])" />
<xsl:value-of select="ois:markdown-definition-int('Maximum length', PasswordPolicyProperties/Property[@Field='MaxLen'])" />
<xsl:value-of select="ois:markdown-definition-int('Max. failed logins', PasswordPolicyProperties/Property[@Field='MaxBadAttempts'])" />
<xsl:value-of select="ois:markdown-definition-int('Max age (days)', PasswordPolicyProperties/Property[@Field='MaxAge'])" />
<xsl:value-of select="ois:markdown-definition-int('Password history size', PasswordPolicyProperties/Property[@Field='HistoryLen'])" />
<xsl:value-of select="ois:markdown-definition-int('Minimum strength', PasswordPolicyProperties/Property[@Field='MinPasswordQuality'])" />
<xsl:value-of select="ois:markdown-definition('', PasswordPolicyProperties/Property[@Field=''])" />
<xsl:value-of select="ois:markdown-definition('', PasswordPolicyProperties/Property[@Field=''])" />
<xsl:value-of select="ois:markdown-definition('', PasswordPolicyProperties/Property[@Field=''])" />
<xsl:value-of select="ois:markdown-definition('Minimum number of letters', PasswordPolicyProperties/Property[@Field='MinLetters'])" />

</xsl:template>


<!-- ===== Schedules ======================= -->

<xsl:template match="Schedules">


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and (
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
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Year']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
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
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Month']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>




    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
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
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Week']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
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
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Day']" mode="table-day" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
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
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Hour']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
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
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Min']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
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
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="ScheduleProperties/Property[@Field='Description']"/></xsl:call-template></value>
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
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="ScheduleProperties/Property[@Field='Description']"/></xsl:call-template></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="StartTimes/T" separator=", " /></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="Schedule" mode="table-hour">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="ScheduleProperties/Property[@Field='Description']"/></xsl:call-template></value>
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

    <xsl:if test="string-length(@frequencyType) &gt; 0">

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
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'StartDate'), '_VALUE_', ois:is-null-string($s/@startDate, '1800-01-01'))" />
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
</xsl:if>
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
                                                and starts-with(normalize-space(Property[@Field='Password']), 'P|E')
                                            ]" mode="table" />
            </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="Administrator" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value>
            <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown(Property[@Field='XUserInserted']), 15, '...')" /> - <xsl:value-of select="Property[@Field='XDateInserted']" />
        </value>
        <value><xsl:value-of select="@passwordLastSet"/></value>
    </row>
</xsl:template>




<!-- ===== Servers ======================= -->

<xsl:template match="Servers">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary">Summary of job servers</xsl:with-param>
        <xsl:with-param name="id" select="'summary-job-servers'" />
        <xsl:with-param name="header"   >| Server      | Queues  | Deploy targets |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:--------|:---------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="
                            Server[ @serviceInstalled='true' 
                            and 
                            count(DeployTargets/DeployTarget) &gt; 0 
                            and 
                            ( string-length(@physicalServer) = 0 or (@physicalServer = @FQDN) )
                        ]" mode="table">
                    <xsl:sort select="@name" order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary">Summary of job queues</xsl:with-param>
        <xsl:with-param name="id" select="'summary-job-queues'" />
        <xsl:with-param name="header"   >| Queue | Disabled? | Tags              | Last Health Check |</xsl:with-param>
        <xsl:with-param name="separator">|:-------|:------:|:-------------------------|:---------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="Server[@serviceInstalled='true']" mode="table-queues">
                    <xsl:sort select="@name" order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <!--<xsl:apply-templates select="Server" /> -->

</xsl:template>
<xsl:template match="Server" mode="table">
    <row>
        <value><xsl:value-of select="concat(
                        ois:escape-for-markdown(@name),
                        if ( string-length(@FQDN) &gt; 0 ) then concat( ' (', @FQDN, ')' ) else ''
        )"/></value>
        <value>
            <xsl:call-template name="ois:generate-markdown-table-list">
                <xsl:with-param name="values">
                    <items>
                        <xsl:apply-templates select="configuration/category/value[@name='queue']" mode="queue-list-item">
                            <xsl:sort select="@name" order="ascending" />
                        </xsl:apply-templates>
                    </items>
                </xsl:with-param>
            </xsl:call-template>
        </value>
        <value>
            <xsl:call-template name="ois:generate-markdown-table-list">
                <xsl:with-param name="values">
                    <items>
                        <xsl:apply-templates select="DeployTargets/DeployTarget" mode="table-list-item">
                            <xsl:sort select="@fullPath" order="ascending" />
                        </xsl:apply-templates>
                    </items>
                </xsl:with-param>
            </xsl:call-template>
        </value>
    </row>
</xsl:template>
<xsl:template match="Server" mode="table-queues">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@name)" /></value>
        <value><xsl:value-of select="ServerProperties/Property[@Field='IsJobServiceDisabled']" /></value>
        <value>
            <xsl:call-template name="ois:generate-markdown-table-list">
                <xsl:with-param name="values">
                    <items>
                        <xsl:apply-templates select="ServerTags/ServerTag" mode="table-list-item">
                            <xsl:sort select="@name" order="ascending" />
                        </xsl:apply-templates>
                    </items>
                </xsl:with-param>
            </xsl:call-template>
        </value>
        <value><xsl:value-of select="ServerProperties/Property[@Field='LastTimeoutCheck']" /></value>
    </row>
</xsl:template>


<xsl:template match="Server">

## <xsl:value-of select="replace(@name, '\\', '/')" />


</xsl:template>
<xsl:template match="value" mode="queue-list-item">
    <value> <xsl:value-of select="." /> </value>
</xsl:template>
<xsl:template match="DeployTarget" mode="table-list-item">
    <value> <xsl:value-of select="@fullPath" /> </value>
</xsl:template>
<xsl:template match="ServerTag" mode="table-list-item">
    <value> <xsl:value-of select="@name" /> </value>
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

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of custom configuration parameters'" />
        <xsl:with-param name="id" select="'configuration-parameters'" />
        <xsl:with-param name="header">| ConfigParam        | Value | Enabled? | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:-------------------|:------------------|:--:|:-------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="ConfigParam[not(starts-with(Property[@Field='XUserUpdated'], 'QBM'))]" mode="table">
                    <xsl:sort select="@fullPath"/>
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <!--<xsl:apply-templates select="ConfigParam" /> -->
</xsl:template>
<xsl:template match="ConfigParam">

## <xsl:value-of select="replace(@name, '\\', '/')" />


</xsl:template>

<xsl:template match="ConfigParam" mode="table">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@fullPath)"/></value>
        <value><xsl:value-of select="
            if ( upper-case(@name) eq 'PASSWORD' ) then '[hidden]'
            else ois:markdown-inline-code(Property[@Field='Value'], 45)
        "/></value>
        <value><xsl:value-of select="@enabled"/></value>
        <value><xsl:value-of select="ois:last-modified(.)"/></value>
    </row>
</xsl:template>


<!-- ===== Structures ======================= -->

<xsl:template match="Departments|Locations|CostCenters">
    <xsl:if test="count(*) &gt; 0" >
        <xsl:value-of select="ois:markdown-heading-2(string(node-name()))" />
    </xsl:if>

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary" select="concat('Hierarchy of ', node-name())" />
        <xsl:with-param name="id" select="concat('summary-', node-name())" />
        <xsl:with-param name="header" select="string(node-name())" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree">
                <xsl:sort select="@fullPath" />
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of ', node-name())" />
        <xsl:with-param name="id" select="concat('summary-roles-', node-name())" />
        <xsl:with-param name="header">| Name        | Users | Manager | Dynamic? | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:--:|:--------|:--:|:--------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="*" mode="table">
                    <xsl:sort select="@fullPath"/>
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="*" mode="section">
        <xsl:sort select="@fullPath" />
    </xsl:apply-templates>

</xsl:template>


<xsl:template match="Departments|Locations|CostCenters" mode="tree">
    <tree>
        <xsl:apply-templates select="*" mode="tree">
            <xsl:sort select="@fullPath" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="Department|Location|CostCenter" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="concat(../../@name, '\', @fullPath)" />
        <xsl:attribute name="color" select="$OI_JAFFA" />
    </branch>
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
     />** | <xsl:value-of select="RoleClassProperties/Property[@Field='Description']" 
    /> | <xsl:value-of select="@isTopDown" 
    /> | <xsl:value-of select="ois:last-modified(RoleClassProperties)"
    /> | <xsl:value-of select="count(Roles/Role)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="RoleClass" mode="section">
    <xsl:sort select="@name" />
</xsl:apply-templates>


</xsl:template>

<xsl:template match="RoleClasses" mode="tree">
    <tree>
        <xsl:apply-templates select="RoleClass" mode="tree">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="RoleClass" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@name" />
        <xsl:attribute name="color" select="$OI_NEPAL" />
    </branch>
   <xsl:choose>
       <xsl:when test="count(Roles/Role) &gt; 10">
           <xsl:variable name='numRoles' select="count(Roles/Role)"/>
            <branch>
                <xsl:attribute name="name" select="@name" />
                <xsl:attribute name="path" select="concat(@name, '\', '[', $numRoles, ' roles]')" />
                <xsl:attribute name="color" select="$OI_JAFFA" />
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
        <xsl:attribute name="color" select="$OI_JAFFA" />
    </branch>
</xsl:template>
<xsl:template match="ApplicationRole" mode="tree">
    <xsl:variable name="color" select="if (starts-with(@fullPath, 'Custom')) then $OI_JACARTA else $OI_JAFFA" />
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
                select="ClassAssignments/ClassAssignment[lower-case(@allowAssignment)='true' or lower-case(@allowDirectAssignment)='true']" 
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
                    >|:------------|:--:|:------|:--:|:---------|</xsl:with-param>
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

<xsl:template match="Role|ApplicationRole|Department|Location|CostCenter" mode="section" >

    <xsl:value-of select="ois:markdown-heading-3(ois:is-null-string(@fullPath, '[name or path missing]'))" />

    <xsl:value-of select="ois:markdown-definition('Description', child::*/Property[@Field='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Manager', Manager/@name)" />
    <xsl:value-of select="ois:markdown-definition('Managers (application role)', ois:escape-for-markdown(ManagerRole/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Attestors (role)',ois:escape-for-markdown(Attestor/@fullPath))" />
    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned users'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="UserAssignments/UserAssignment[Member]" mode="list" /> </items>
        </xsl:with-param>
        <xsl:with-param name="max-size" select="10" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Primary assigned users'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="PrimaryAssignments/PrimaryAssignment" mode="list" /> </items>
        </xsl:with-param>
        <xsl:with-param name="max-size" select="10" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned objects'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="ObjectAssignments/ObjectAssignment" mode="list" /> </items>
        </xsl:with-param>
        <xsl:with-param name="max-size" select="20" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'IT Data Mapping'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="ITDatas/ITData" mode="list" /> </items>
        </xsl:with-param>
        <xsl:with-param name="max-size" select="20" />
    </xsl:call-template>

    <xsl:apply-templates select="DynamicRoles" />

</xsl:template>
<xsl:template match="ITData" mode="list">
    <value><xsl:value-of select="concat(@displayValue, ': **', @fixValue, Value/@fQDN,  Value/@canonicalName, Value/@displayName, '**')" /></value>
</xsl:template>
<xsl:template match="ClassAssignment" mode="table">
    <row>
        <value><xsl:value-of select="Type/@name"/></value>
        <value><xsl:value-of select="@allowAssignment"/></value>
        <value><xsl:value-of select="@allowDirectAssignment"/></value>
    </row>
</xsl:template>
<xsl:template match="Role|Department|Location|CostCenter" mode="table">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@fullPath)"/></value>
        <value><xsl:value-of select="ois:is-null-string(UserCount/text(), string(count(UserAssignments/UserAssignment) + count(PrimaryAssignments/PrimaryAssignment)))"/></value>
        <value><xsl:value-of select="Manager/@name"/></value>
        <value><xsl:value-of select="ois:true-or-false(count(DynamicRoles/DynamicRole) &gt; 0)"/></value>
        <value><xsl:value-of select="ois:last-modified(*[1])"/></value>
    </row>
</xsl:template>
<xsl:template match="ObjectAssignment" mode="list">
    <value>
        <xsl:text>[</xsl:text><xsl:value-of select="AssignedObject/@table" /><xsl:text>] </xsl:text>
        <xsl:value-of select="ois:escape-for-markdown(
                AssignedObject/@name | 
                AssignedObject/@accountName |
                AssignedObject/@displayName
            )"/>
        <xsl:text> (</xsl:text><xsl:value-of select="ois:get-origin-description(@origin)" /><xsl:text>)</xsl:text>
    </value>
</xsl:template>
<xsl:template match="PrimaryAssignment" mode="list">
    <value>
            <xsl:text>_</xsl:text><xsl:value-of select="@fullName"/><xsl:text>_</xsl:text>
            <xsl:text> / </xsl:text><xsl:value-of select="@name" />
    </value>
</xsl:template>
<xsl:template match="UserAssignment" mode="list">
    <value>
        <xsl:if test="Member">
            <xsl:text>_</xsl:text><xsl:value-of select="Member/@fullName"/><xsl:text>_</xsl:text>
            <xsl:text> / </xsl:text><xsl:value-of select="Member/@name" />
            <xsl:text> [</xsl:text><xsl:value-of select="ois:get-origin-description(@origin)" /><xsl:text>]</xsl:text>
        </xsl:if>
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
        <value>```<xsl:value-of select="ois:truncate-string(DynamicRoleProperties/Property[@Field='WhereClause'], 45, '...')"/>```</value>
        <value><xsl:value-of select="ObjectClass/@name"/></value>
        <value><xsl:value-of select="Schedule/@name"/></value>
        <value><xsl:value-of select="DynamicRoleProperties/Property[@Field='IsCalculateImmediately']"/></value>
        <value><xsl:value-of select="ois:last-modified(DynamicRoleObject)"/></value>
    </row>
</xsl:template>
<xsl:template match="DynamicRole" mode="text">
        <xsl:value-of select="concat(ois:escape-for-markdown(@name), '[', Schedule/@name, ']')"/>
</xsl:template>
<xsl:template match="DynamicRole" mode="section" >

    <xsl:text>&#xa;#### Dynamic role: </xsl:text><xsl:value-of select="@name" />

    <xsl:value-of select="ois:markdown-definition('Description', DynamicRoleProperties/Property[@Field='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Class', ObjectClass/@name)" />
    <xsl:value-of select="ois:markdown-definition('Schedule', Schedule/@name)" />
    <xsl:value-of select="ois:markdown-definition('Immediate assignment', concat('_', DynamicRoleProperties/Property[@Field='IsCalculateImmediately'], '_'))" />

    <xsl:text>&#xa;**Criteria**&#xa;```sql&#xa;</xsl:text>
    <xsl:value-of select="DynamicRoleProperties/Property[@Field='WhereClause']" />
    <xsl:text>&#xa;```&#xa;</xsl:text>

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Exceptions'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="Exclusions/Exclusion" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Recalculation trigger columns'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="RecalcProperties/RecalcProperty" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="Exclusion" mode="list">
    <value>
        <xsl:value-of select="concat(
                        Person/@fullName, ' (', Person/@name, ')',
                        if (Description) then 
                            concat(' - ', Description)
                        else ''
            )" />
    </value>
</xsl:template>
<xsl:template match="RecalcProperty" mode="list">
    <value>
        <xsl:value-of select="concat( @caption, ' (_', @name, '_)')" />
    </value>
</xsl:template>





<!-- ===== IT Shops ======================= -->

<xsl:template match="ShoppingCenters">
    <xsl:choose>
        <xsl:when test="count(ShoppingCenter) &gt; 1">
            <xsl:apply-templates select="ShoppingCenter" mode="section" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="ShoppingCenter/Shops" mode="section" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="ShoppingCenter" mode="section">
    <xsl:value-of select="concat('&#xa;### Shopping Center: ', @name)" />

    <xsl:value-of select="ois:markdown-definition('Description',ShoppingCenterProperties/Property[@Field='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Manager', Manager/@name)" />
    <xsl:value-of select="ois:markdown-definition('Additional Managers (application role)', ois:escape-for-markdown(ManagerRole/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Attestors (role)',ois:escape-for-markdown(Attestor/@fullPath))" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned approval policies'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="PWODecisionMethods/PWODecisionMethod" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Summary of shopping center</xsl:with-param>
        <xsl:with-param name="id" select="concat('summary-shops-', @id)" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree"/>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Shops" mode="section">
        <xsl:sort select="@name" order="ascending" />
    </xsl:apply-templates>

</xsl:template>
<xsl:template match="PWODecisionMethod" mode="list">
    <value>
        <xsl:value-of select="@name" />
    </value>
</xsl:template>
<xsl:template match="ApprovalPolicy" mode="list">
    <value>
        <xsl:value-of select="@name" />
    </value>
</xsl:template>

<xsl:template match="Shops" mode="section">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of Shops in ', ../@name)" />
        <xsl:with-param name="id" select="concat('summary-shops-', ../@id)" />
        <xsl:with-param name="header"   >| Name        | Shelves | Products | Customers | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:----:|:----:|:----:|:---------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Shop" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Shop" mode="section" />
</xsl:template>
<xsl:template match="Shop" mode="section">
    <xsl:value-of select="concat('&#xa;#### Shop: ', @name)" />

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary" select="concat('Tree view of shop ', @name)" />
        <xsl:with-param name="id" select="concat('summary-shop-', @id)" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree"/>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:value-of select="ois:markdown-definition('Description',ShopProperties/Property[@Field='Description'])" />
    <xsl:value-of select="ois:markdown-definition('Manager', Manager/@name)" />
    <xsl:value-of select="ois:markdown-definition('Additional Managers (application role)', ois:escape-for-markdown(ManagerRole/@fullPath))" />
    <xsl:value-of select="ois:markdown-definition('Attestors (role)',ois:escape-for-markdown(Attestor/@fullPath))" />

    <xsl:value-of select="ois:markdown-definition('Assigned Users',ois:is-null-string(string(sum(Customers/Customer/UserCount)), string(count(Customers/Customer/UserAssignments/UserAssignment))))" />
    <xsl:if test="Customers/Customer/DynamicRoles/DynamicRole">
        <xsl:value-of select="ois:markdown-definition(
                            'Customer dynamic role',
                            concat(ois:escape-for-markdown(
                                Customers/Customer[1]/DynamicRoles/DynamicRole[1]/@name), ' [Schedule: ', 
                                Customers/Customer[1]/DynamicRoles/DynamicRole[1]/Schedule/@name, ']'))" />
    </xsl:if>

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
            <rows> 
                <xsl:apply-templates select="Shelves/Shelf" mode="table">
                    <xsl:sort select="@name" order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Shelves/Shelf[count(Products/Product) &gt; 0]" mode="section">
        <xsl:sort select="@name" order="ascending" />
    </xsl:apply-templates>
</xsl:template>
<xsl:template match="Shelf" mode="section">
    <xsl:value-of select="concat('&#xa;&#xa;##### Shelf: ', @name, '&#xa;')" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned approval policies'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="ApprovalPolicies/ApprovalPolicy" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Products" mode="section">
        <xsl:sort select="@name" order="ascending" />
    </xsl:apply-templates>
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
                    <rows> <xsl:apply-templates select="Product" mode="table">
                            <xsl:sort select="@name" order="ascending" />
                        </xsl:apply-templates>
                    </rows>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>no products assigned</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="Shop" mode="table">
    <row>
        <value><xsl:value-of select="ois:escape-for-markdown(@name)"/></value>
        <value><xsl:value-of select="count(Shelves/Shelf)"/></value>
        <value><xsl:value-of select="count(Shelves/Shelf/Products/Product)"/></value>
        <value><xsl:value-of select="ois:is-null-string(string(sum(Customers/Customer/UserCount)), string(count(Customers/Customer/UserAssignment/Person)))"/></value>
        <value><xsl:value-of select="ois:last-modified(ShopProperties)"/></value>
    </row>
</xsl:template>
<xsl:template match="Shelf" mode="table">
    <row>
        <!-- strip shopping center and shop name from shelf path (some poorly defined shelves have no fullPath) -->
        <value><xsl:value-of select="ois:escape-for-markdown(
                                        if ( string-length(@fullPath) &gt; 0 ) then
                                            ois:left-trim(
                                                ois:left-trim(@fullPath, concat(../../@name, '\')),
                                                concat(../../@name, '\') ) 
                                        else @name
        )"/></value>
        <value><xsl:apply-templates select="ApprovalPolicies" mode="text" /></value>
        <value><xsl:value-of select="count(Products/Product)"/></value>
        <value><xsl:value-of select="sum(Products/Product/Requests)"/></value>
        <value><xsl:value-of select="ois:last-modified(ShelfProperties)"/></value>
    </row>
</xsl:template>
<xsl:template match="Product" mode="table">
    <row>
        <!-- strip shopping center and shop name from shelf path -->
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:apply-templates select="Entitlement" mode="text" /></value>
        <value><xsl:value-of select="Requests"/></value>
        <value><xsl:value-of select="ois:last-modified(ProductProperties)"/></value>
    </row>
</xsl:template>
<xsl:template match="Entitlement" mode="text">
        <xsl:text>[</xsl:text><xsl:value-of select="@table" /><xsl:text>] </xsl:text>
        <xsl:value-of select="ois:escape-for-markdown(@name)"/>
</xsl:template>
<xsl:template match="PWODecisionMethods" mode="text">
    <xsl:value-of select="PWODecisionMethod/@name" separator=", " />
</xsl:template>
<xsl:template match="ApprovalPolicies" mode="text">
    <xsl:value-of select="ApprovalPolicy/@name" separator=", " />
</xsl:template>
<xsl:template match="ShoppingCenter" mode="tree">
    <tree>
        <xsl:attribute name="name" select="if (@name='DEFAULT') then '' else @name" />
        <xsl:attribute name="color" select="$OI_BLACK" />
        <xsl:apply-templates select="Shops/Shop" mode="branch">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="Shops" mode="tree">
    <tree>
        <xsl:attribute name="name" select="if (../@name='DEFAULT') then '' else ../@name" />
        <xsl:attribute name="color" select="$OI_BLACK" />
        <xsl:apply-templates select="Shop" mode="branch">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="Shop" mode="tree">
    <tree>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="color" select="$OI_BLACK" />
        <xsl:apply-templates select="Customers/Customer" mode="branch" />
        <xsl:apply-templates select="Shelves/Shelf" mode="branch">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="Shop" mode="branch">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@fullPath" />
        <xsl:attribute name="color" select="$OI_BROWN" />
        <xsl:apply-templates select="Customers/Customer" mode="branch" />
        <xsl:apply-templates select="ApprovalPolicies/ApprovalPolicy" mode="branch">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
        <xsl:apply-templates select="Shelves/Shelf" mode="branch">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
    </branch>
</xsl:template>
<xsl:template match="Customer" mode="branch">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@fullPath" />
        <xsl:attribute name="color" select="$OI_GREEN" />
    </branch>
</xsl:template>
<xsl:template match="Shelf" mode="branch">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@fullPath" />
        <xsl:attribute name="color" select="$OI_BROWN" />
        <xsl:apply-templates select="ApprovalPolicies/ApprovalPolicy" mode="branch">
            <xsl:sort select="@name" order="ascending" />
        </xsl:apply-templates>
    </branch>
</xsl:template>
<xsl:template match="ApprovalPolicy" mode="branch">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="concat(../../@fullPath,'\', 'Approval policy: ',  @name)" />
        <xsl:attribute name="color" select="$OI_RED" />
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
  />** | <xsl:value-of select="ApprovalPolicyProperties/Property[@Field='Priority']" 
    /> | <xsl:value-of select="normalize-space(replace(ApprovalPolicyProperties/Property[@Field='Description'], '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(ApprovalPolicyProperties)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="ApprovalPolicy[@usage=$usage]" />

</xsl:template>
<xsl:template match="ApprovalPolicy">
    <xsl:value-of select="ois:markdown-heading-3(replace(@name, '\\', '/'))" />

    <xsl:value-of select="ApprovalPolicyProperties/Property[@Field='Description']" />

    <xsl:value-of select="ois:markdown-heading-4('Approval Workflows')" />
    <xsl:value-of select="ois:markdown-definition('Request', RequestWorkflow/@name)" />
    <xsl:value-of select="ois:markdown-definition('Renewal', RenewalWorkflow/@name)" />
    <xsl:value-of select="ois:markdown-definition('Unsubscribe', UnsubscribeWorkflow/@name)" />

    <xsl:if test="string-length(
                    MailTemplateAborted/@name ||
                    MailTemplateExpired/@name ||
                    MailTemplateApproved/@name ||
                    MailTemplateDenied/@name ||
                    MailTemplateRenewed/@name ||
                    MailTemplateUnsubscribed/@name 
                ) &gt; 0">
        <xsl:value-of select="ois:markdown-heading-4('Mail Templates')" />

        <xsl:value-of select="ois:markdown-definition('Request cancelled', MailTemplateAborted/@name)" />
        <xsl:value-of select="ois:markdown-definition('Request expired', MailTemplateExpired/@name)" />
        <xsl:value-of select="ois:markdown-definition('Request approved', MailTemplateApproved/@name)" />
        <xsl:value-of select="ois:markdown-definition('Request denied', MailTemplateDenied/@name)" />
        <xsl:value-of select="ois:markdown-definition('Renewal appoved', MailTemplateRenewed/@name)" />
        <xsl:value-of select="ois:markdown-definition('Unsubscribe approved', MailTemplateUnsubscribed/@name)" />
    </xsl:if>

</xsl:template>





<!-- ===== Approval workflows ======================= -->

<xsl:template match="ApprovalWorkflows">
    <xsl:param name="usage"/>


Table: Summary of approval workflows {#tbl:summary-approval-workflows-<xsl:value-of select="$usage" />}

| Workflow        | Revision | Days to Abort | Description                                | Last Modified |
|:----------------|:--------:|:----:|:---------------------------------------|:--------------|
<xsl:for-each select="ApprovalWorkflow[@usage=$usage]"
       ><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="@revision"
    /> | <xsl:value-of select="@daysToAbort"
    /> | <xsl:value-of select="normalize-space(replace(Description, '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(ApprovalWorkflowProperties)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="ApprovalWorkflow[@usage=$usage]" />

</xsl:template>
<xsl:template match="ApprovalWorkflow">

    <xsl:value-of select="ois:markdown-heading-3(replace(@name, '\\', '/'))" />

    <xsl:apply-templates select="." mode="diagram" />

    <xsl:value-of select="Description" />

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of workflow steps'" />
        <xsl:with-param name="id" select="concat('summary-approval-workflow-steps-', @id)" />
        <xsl:with-param name="header">| Level / Step        | Level | Rule    | Abort (min) | Reminder (min) | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:--------------------|:----:|:-----:|:-----:|:-----:|:--------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="ApprovalSteps/ApprovalStep" mode="table">
                    <xsl:sort select="@level" order="ascending" data-type="number" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="ApprovalSteps/ApprovalStep">
        <xsl:sort select="@level" order="ascending" data-type="number"/>
    </xsl:apply-templates>

</xsl:template>

<xsl:template match="ApprovalStep" mode="table">
    <row>
        <value><xsl:apply-templates select="." mode="text" /></value>
        <value><xsl:value-of select="
                    concat(
                        @level,
                        if ( @subLevel != '0' ) then concat('.', @subLevel) else ''
                    )
        " /></value>
        <value><xsl:value-of select="Rule/@name" /></value>
        <value><xsl:value-of select="ois:is-null-string(ApprovalStepProperties/Property[@Field='MinutesAutomaticDecision'], '0')" /></value>
        <value><xsl:value-of select="ois:is-null-string(ApprovalStepProperties/Property[@Field='MinutesReminder'], '0')" /></value>
        <value><xsl:value-of select="ois:last-modified(ApprovalStepProperties)" /></value>
    </row>
</xsl:template>
<xsl:template match="ApprovalStep" mode="text">
    <xsl:if test="@levelName"><xsl:value-of select="concat(@levelName, ' - ')" /></xsl:if>
    <xsl:value-of select="@name" />
</xsl:template>

<xsl:template match="ApprovalStep">

    <xsl:value-of select="ois:markdown-heading-4(
                concat('Level ', @level, ': ', ois:is-null-string(@levelName, @name)))" />

    <xsl:value-of select="Description" />

    <xsl:apply-templates select="." mode="rule-text" />

    <xsl:apply-templates select="." mode="steps-text" />


    <xsl:value-of select="ois:markdown-definition-bool('Escalate if no approver found', 
        ApprovalStepProperties/Property[@Field='EscalateIfNoApprover'])" /> 
    <xsl:value-of select="ois:markdown-definition-bool('Additional approvers allowed', 
        ApprovalStepProperties/Property[@Field='IsAdditionalAllowed'])" /> 
    <xsl:value-of select="ois:markdown-definition-bool('Delegation allowed', 
        ApprovalStepProperties/Property[@Field='IsInsteadOfAllowed'])" /> 
    <xsl:value-of select="ois:markdown-definition-bool('No automatic approval', 
        ApprovalStepProperties/Property[@Field='IsNoAutoDecision'])" /> 
    <xsl:value-of select="ois:markdown-definition-bool('Hide decision', 
        ApprovalStepProperties/Property[@Field='IsToHideInHistory'])" /> 
    <xsl:value-of select="ois:markdown-definition-bool('Allow affected identity to approve', 
        ApprovalStepProperties/Property[@Field='IgnoreNoDecideForPerson'])" />


    <xsl:if test="string-length(
                    MailTemplateRemind/@name ||
                    MailTemplateEscalate/@name ||
                    MailTemplateApprove/@name ||
                    MailTemplateDeny/@name ||
                    MailTemplateNew/@name ||
                    MailTemplateToDelegate/@name ||
                    MailTemplateFromDelegate/@name
                ) &gt; 0">
        <xsl:value-of select="ois:markdown-heading-5('Mail Templates')" />

        <xsl:value-of select="ois:markdown-definition('Step approved', MailTemplateApprove/@name)" />
        <xsl:value-of select="ois:markdown-definition('Step denied', MailTemplateDeny/@name)" />
        <xsl:value-of select="ois:markdown-definition('New approval', MailTemplateNew/@name)" />
        <xsl:value-of select="ois:markdown-definition('Reminder', MailTemplateRemind/@name)" />
        <xsl:value-of select="ois:markdown-definition('Escalation', MailTemplateEscalate/@name)" />
        <xsl:value-of select="ois:markdown-definition('Delegate - To', MailTemplateToDelegate/@name)" />
        <xsl:value-of select="ois:markdown-definition('Delegate - From', MailTemplateFromDelegate/@name)" />
    </xsl:if>

</xsl:template>
<xsl:template match="ApprovalStep" mode="rule-text">

    <xsl:value-of select="ois:markdown-definition('Rule', 
                concat(
                    Rule/@name,
                    if (Rule/Description) then concat(' - ', Rule/Description) else ''
                )
        )" /> 

    <xsl:choose>
        <xsl:when test="Rule/@name = 'CD'">
            <xsl:value-of select="ois:markdown-definition-codeblock(
                    'Decision criteria', 
                    ApprovalStepProperties/Property[@Field='WhereClause'],
                    'sql'
            )" />
        </xsl:when>
        <xsl:when test="Rule/@name = 'EX'">
            <xsl:value-of select="ois:markdown-definition('Event name', 
                concat( '_', ApprovalStepProperties/Property[@Field='WhereClause'], '_')
            )" />
        </xsl:when>
        <xsl:when test="Rule/@name = 'OR'">
            <xsl:value-of select="ois:markdown-definition('Assigned role', 
                    concat( AssignedRole/@table, ': ', replace(AssignedRole/@fullPath, '\\', '/') )
                )" />
        </xsl:when>
    </xsl:choose>

</xsl:template>
<xsl:template match="ApprovalStep" mode="steps-text">
    <xsl:if test="ApprovalStepProperties/Property[@Field='PositiveSteps'] != '0'">
        <xsl:value-of select="ois:markdown-definition('Next step on positive/approval', 
                string(ApprovalStepProperties/Property[@Field='PositiveSteps'] + @level)
        )" />
    </xsl:if>
    <xsl:if test="ApprovalStepProperties/Property[@Field='NegativeSteps'] != '0'">
        <xsl:value-of select="ois:markdown-definition('Next step on negative/denial', 
                string(ApprovalStepProperties/Property[@Field='NegativeSteps'] + @level)
        )" />
    </xsl:if>
    <xsl:if test="ApprovalStepProperties/Property[@Field='EscalationSteps'] != '0'">
        <xsl:value-of select="ois:markdown-definition('Next step on escalation', 
                string(ApprovalStepProperties/Property[@Field='EscalationSteps'] + @level)
        )" />
    </xsl:if>
</xsl:template>
<xsl:template match="ApprovalWorkflow" mode="xml">
    <xsl:variable name="steps" select="ApprovalSteps" />
    <workflow>
        <xsl:attribute name="name" select="../@name" />
        <xsl:for-each-group select="ApprovalSteps/ApprovalStep" group-by="@level">
                    <xsl:sort select="@level" order="ascending" data-type="number"/>
            <approval>
                <xsl:variable name="step0" select="current-group()[1]" />
                <xsl:attribute name="index" select="current-grouping-key()" />
                <xsl:attribute name="name" select="$step0/@levelName" />

                <xsl:if test="not($step0/@positiveSteps = '0')">
                    <xsl:attribute name="next-approval-if-approved" select="$step0/@level + $step0/@positiveSteps" />
                </xsl:if>
                <xsl:if test="not($step0/@negativeSteps = '0')">
                    <xsl:attribute name="next-approval-if-denied" select="$step0/@level + $step0/@negativeSteps" />
                </xsl:if>
                <xsl:if test="not($step0/@escalationSteps = '0')">
                    <xsl:attribute name="escalation-approval" select="$step0/@level + $step0/@escalationSteps" />
                </xsl:if>


                <xsl:apply-templates select="current-group()" mode="step-xml" />
            </approval>
        </xsl:for-each-group>
    </workflow>
</xsl:template>
<xsl:template match="ApprovalStep" mode="step-xml">
    <approver>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="type" select="Rule/@name" />
        <xsl:attribute name="typeDescription" select="Rule/Description" />
        <xsl:attribute name="subIndex" select="concat(@level, '.', @subLevel)" />
    </approver>
</xsl:template>
<xsl:template match="ApprovalWorkflow" mode="diagram">
    <xsl:variable name="xml">
        <xsl:apply-templates select="." mode="xml">
                    <xsl:sort select="@index" order="ascending" data-type="number"/>
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:call-template name="ois:generate-plantuml-C4">
        <xsl:with-param name="summary" select="concat('Overview of workflow _', @name, '_')" />
        <xsl:with-param name="id" select="concat('workflow-overview-', @id)" />
        <xsl:with-param name="content">
            <xsl:value-of select="'circle &quot; &quot; as start_box&#xa;'" />
            <xsl:apply-templates select="$xml/workflow/approval" mode="uml-components" />
            <xsl:value-of select="'Rel_D(start_box, index_0, &quot;&quot;, $tags=&quot;OneIM_Approval&quot;)&#xa;'" />
            <xsl:apply-templates select="$xml/workflow/approval" mode="uml-connections" />
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="approval" mode="uml-components">
    <xsl:choose>
        <xsl:when test="count(approver) = 1">
            <xsl:apply-templates select="approver" mode="uml-component">
                <xsl:with-param name="index" select="@index" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat( 
                    '&#xa;',
                    'Container(index_', @index, ', ',
                        '&quot;', ois:clean-for-plantuml(ois:is-null-string(@name, concat('Level ', @index))), '&quot;,',
                        '$tags=&quot;OneIM_Approval&quot;',
                    ') {'
            ) " />
            <xsl:apply-templates select="approver" mode="uml-component" />
            <xsl:value-of select="'&#xa;}&#xa;'" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="approver" mode="uml-component">
    <xsl:param name="index" />
    <xsl:variable name="effective-index">
        <xsl:choose>
            <xsl:when test="$index"><xsl:value-of select="concat('index_', $index)" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat('subIndex_', @subIndex)" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="style">
        <xsl:choose>
            <xsl:when test="@type = 'CD'">OneIM_Approver_CD</xsl:when>
            <xsl:when test="@type = 'EX'">OneIM_Approver_EX</xsl:when>
            <xsl:otherwise>OneIM_Approver</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
                
    <xsl:value-of select="concat( 
                '&#xa; Component(', $effective-index, ', ',
                    '&quot;', ois:clean-for-plantuml(@name), '&quot;,',
                    '&quot;', @type, ' - ', ois:clean-for-plantuml(@typeDescription), '&quot;,',
                    '$tags=&quot;', $style, '&quot;',
                ')&#xa;'
    )" />
</xsl:template>
<xsl:template match="approval" mode="uml-connections">
    <xsl:variable name="verbs">
        <xsl:choose>
            <xsl:when test="approver[1]/@type = 'CD'"><v>true</v><v>false</v></xsl:when>
            <xsl:when test="approver[1]/@type = 'EX'"><v>approved</v><v>no approval</v></xsl:when>
            <xsl:otherwise><v>approved</v><v>denied</v></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="@next-approval-if-approved and not(@next-approval-if-approved = '0')">
        <xsl:value-of select="concat( 
                '&#xa;Rel_D(',
                    'index_', @index, ', ',
                    'index_', @next-approval-if-approved, ', ',
                    '&quot;', $verbs/v[1], '&quot;, ',
                    '$tags=&quot;OneIM_Approval&quot;',
                ')&#xa;'
            )" />
    </xsl:if>
    <xsl:if test="@next-approval-if-denied and not(@next-approval-if-denied = '0')">
        <xsl:value-of select="concat( 
                '&#xa;Rel_R(',
                    'index_', @index, ', ',
                    'index_', @next-approval-if-denied, ', ',
                    '&quot;', $verbs/v[2], '&quot;, ',
                    '$tags=&quot;OneIM_Denial&quot;',
                ')&#xa;'
            )" />
    </xsl:if>
    <xsl:if test="@escalation-approval and not(@escalation-approval = '0')">
        <xsl:value-of select="concat( 
                '&#xa;Rel_D(',
                    'index_', @index, ', ',
                    'index_', @escalation-approval, ', ',
                    '&quot;escalation&quot;, ',
                    '$tags=&quot;OneIM_Escalation&quot;',
                ')&#xa;'
            )" />
    </xsl:if>
</xsl:template>

<xsl:template match="ApprovalDecisionRules">
    <xsl:param name="usage"/>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of approval workflow decision rules.'" />
        <xsl:with-param name="id" select="concat('summary-aproval-workflow-rules-', $usage)" />
        <xsl:with-param name="header"   >| Rule | Description           | Sort Order | Max approvers |</xsl:with-param>
        <xsl:with-param name="separator">|:-----|:----------------------|:--:|:----:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="ApprovalDecisionRule[@usage=$usage]" mode="table-row"> 
                    <xsl:sort select="@name" order="ascending"/>
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="ApprovalDecisionRule" />

</xsl:template>
<xsl:template match="ApprovalDecisionRule" mode="table-row">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="Description"/></xsl:call-template></value>
        <value><xsl:value-of select="@sortOrder"/></value>
        <value><xsl:value-of select="@maxCountApprover"/></value>
    </row>
</xsl:template>
<xsl:template match="ApprovalDecisionRule">
    <xsl:value-of select="ois:markdown-heading-3(replace(@name, '\\', '/'))" />
    <xsl:value-of select="Description" />
    <xsl:apply-templates select="Queries" mode="list" />
</xsl:template>
<xsl:template match="Queries" mode="list">
    <xsl:value-of select="ois:markdown-heading-4('Queries')" />
    <xsl:apply-templates select="Query" mode="list-item" />
</xsl:template>
<xsl:template match="Query" mode="list-item">
    <xsl:value-of select="ois:markdown-definition-codeblock(@name, SQLQuery, 'sql')" />
</xsl:template>




<!-- ===== Service Catalog ======================= -->

<xsl:template match="CatalogGroups">

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Service catalog hierarchy</xsl:with-param>
        <xsl:with-param name="id" select="'summary-service-catalog'" />
        <xsl:with-param name="header" select="'Service Catalog'" />
        <xsl:with-param name="values">
            <xsl:apply-templates select="." mode="tree" />
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of service catalog categories with items.'" />
        <xsl:with-param name="id" select="'summary-service-catalog-groups'" />
        <xsl:with-param name="header"   >| Cateogry              | Description           | Approval Policy | Products | Requests |</xsl:with-param>
        <xsl:with-param name="separator">|:----------------------|:----------------------|:----------------|:------:|:------:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="CatalogGroup[count(CatalogItems/CatalogItem) &gt; 0]" mode="table"> 
                    <xsl:sort select="@fullPath" order="ascending"/>
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

<xsl:apply-templates select="CatalogGroup[count(CatalogItems/CatalogItem) &gt; 0]" />

</xsl:template>
<xsl:template match="CatalogGroup" mode="table">
    <row>
        <value><xsl:value-of select="@fullPath"/></value>
        <value>
            <xsl:if test="Image">![](images/<xsl:value-of select="Image" />){.category-image-small} </xsl:if >
            <xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="Description"/></xsl:call-template>
        </value>
        <value><xsl:value-of select="ApprovalPolicy/@name"/></value>
        <value><xsl:value-of select="count(CatalogItems/CatalogItem)"/></value>
        <value><xsl:value-of select="sum(CatalogItems/CatalogItem/ITShopOrgs/ITShopOrg/Requests)"/></value>
    </row>
</xsl:template>
<xsl:template match="CatalogGroup">

### Category: <xsl:value-of select="replace(@fullPath, '\\', '/')" />
<xsl:text>

</xsl:text>

<xsl:value-of select="ois:markdown-definition('Description', Description)" />
<xsl:value-of select="ois:markdown-definition('Approval Policy',ApprovalPolicy/@name)" />
<xsl:if test="ApprovalPolicy">
    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Approval workflows:'" />
        <xsl:with-param name="values">
            <items> 
                <value><xsl:value-of select="concat('Request: ',    ApprovalPolicy/RequestWorkflow/@name)" /></value>
                <value><xsl:value-of select="concat('Renew: ',      ApprovalPolicy/RenewalWorkflow/@name)" /></value>
                <value><xsl:value-of select="concat('Unsubscribe: ', ApprovalPolicy/UnsubscribeWorkflow/@name)" /></value>
            </items>
        </xsl:with-param>
    </xsl:call-template>
</xsl:if>

<xsl:if test="count(CatalogItems/CatalogItem) &gt; 0">

<xsl:choose>
<xsl:when test="count(CatalogItems/CatalogItem) &lt; 20">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of serivce catalog items'" />
        <xsl:with-param name="id" select="concat('summary-service-catalog-items-', @id)" />
        <xsl:with-param name="header"   >| Product               | Description           | Approval Policy | Requests |</xsl:with-param>
        <xsl:with-param name="separator">|:----------------------|:----------------------|:----------------|:------:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="CatalogItems/CatalogItem" mode="catalog-table"> 
                    <xsl:sort select="@name" order="ascending"/>
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>
</xsl:when>
<xsl:otherwise>
<xsl:text>

</xsl:text>
**Total items in category**: <xsl:value-of select="count(CatalogItems/CatalogItem)" />

**Requests for items in category**: <xsl:value-of select="sum(CatalogItems/CatalogItem/Requests)" />
</xsl:otherwise>
</xsl:choose>

</xsl:if>

</xsl:template>

<xsl:template match="CatalogGroups" mode="tree">
    <tree>
        <xsl:apply-templates select="CatalogGroup" mode="tree">
            <xsl:sort select="@fullPath" order="ascending" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="CatalogGroup" mode="tree">
    <branch>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="path" select="@fullPath" />
        <xsl:attribute name="color" select="$OI_BROWN" />
    </branch>
</xsl:template>

<xsl:template match="CatalogItem" mode="catalog-table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value>
            <xsl:if test="Image">![](images/<xsl:value-of select="Image" />){.category-image-small} </xsl:if >
            <xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="Description"/></xsl:call-template>
        </value>
        <value><xsl:value-of select="ApprovalPolicy/@name"/></value>
        <value><xsl:value-of select="sum(ITShopOrgs/ITShopOrg/Requests)"/></value>
    </row>
</xsl:template>


<!-- ===== Attestation Policies ======================= -->

<xsl:template match="AttestationPolicies">


    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of attestation policies.'" />
        <xsl:with-param name="id" select="'summary-attestation-policies'" />
        <xsl:with-param name="header"   >| Policy            | Procedure       | Approval Policy | Schedule  | Last Modified | Cases |</xsl:with-param>
        <xsl:with-param name="separator">|:------------------|:----------------|:----------------|:----------|:---------|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="AttestationPolicy" mode="table"> 
                    <xsl:sort select="@name" order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="AttestationPolicy[not(Cases='0')]">
        <xsl:sort select="@name" order="ascending" />
    </xsl:apply-templates>

</xsl:template>

<xsl:template match="AttestationPolicy" mode="table">
    <row>
        <value><xsl:value-of select="replace(@name, '\\', '/')" /></value>
        <value><xsl:value-of select="Procedure/@name" /></value>
        <value><xsl:value-of select="ApprovalPolicy/@name" /></value>
        <value><xsl:value-of select="Schedule/@name" /></value>
        <value><xsl:value-of select="ois:last-modified(AttestationPolicyProperties)" /></value>
        <value><xsl:value-of select="Cases" /></value>
    </row>
</xsl:template>

<xsl:template match="AttestationPolicy">
    <xsl:value-of select="ois:markdown-heading-2(concat('Policy: ', @name))" />
    <xsl:value-of select="ois:markdown-definition('Description', Description)" />
    <xsl:value-of select="ois:markdown-definition('Procedure', Procedure/@name)" />

    <xsl:apply-templates select="AttestationCycles" />
</xsl:template>

<xsl:template match="AttestationCycles">
    <xsl:value-of select="ois:markdown-heading-3('Attestation Cycles')" />

    <xsl:choose>
        <xsl:when test="count(AttestationCycle[not(Cases='0')]) &lt; 20">

            <xsl:call-template name="ois:generate-table">
                <xsl:with-param name="summary" select="concat('Summary of attestation cycles for ', ../@name, '.')" />
                <xsl:with-param name="id" select="concat('summary-attestation-cycles-', ../@id)" />
                <xsl:with-param name="header"   >| Date        | Total Cases | Open Cases | Approved | Denied |</xsl:with-param>
                <xsl:with-param name="separator">|:------------|:----:|:----:|:----:|:----:|</xsl:with-param>
                <xsl:with-param name="values">
                    <rows> 
                        <xsl:apply-templates select="AttestationCycle" mode="table"> 
                            <xsl:sort select="@sortableDate" order="ascending" />
                        </xsl:apply-templates>
                    </rows>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="ois:markdown-definition-int('Cycles', count(AttestationCycle))" />
            <xsl:value-of select="ois:markdown-definition-int('Cases', sum(AttestationCycle/Cases))" />
            <xsl:value-of select="ois:markdown-definition-int('Open cases', sum(AttestationCycle/OpenCases))" />
            <xsl:value-of select="ois:markdown-definition-int('Approved cases', sum(AttestationCycle/ApprovedCases))" />
            <xsl:value-of select="ois:markdown-definition-int('Denied cases', sum(AttestationCycle/DeniedCases))" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="AttestationCycle" mode="table">
    <row>
        <value><xsl:value-of select="@date" /></value>
        <value><xsl:value-of select="Cases" /></value>
        <value><xsl:value-of select="OpenCases" /></value>
        <value><xsl:value-of select="ApprovedCases" /></value>
        <value><xsl:value-of select="DeniedCases" /></value>
    </row>
</xsl:template>


<xsl:template match="AttestationProcedureProperties" mode="table-rows">
    <rows>
        <row>
            <value><xsl:value-of select="'Grouping column 1'" /></value>
            <value><xsl:value-of select="Property[@Field='StructureDisplay1']" /></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='StructureDisplayPattern1'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Grouping column 2'" /></value>
            <value><xsl:value-of select="Property[@Field='StructureDisplay2']" /></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='StructureDisplayPattern2'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Grouping column 3'" /></value>
            <value><xsl:value-of select="Property[@Field='StructureDisplay3']" /></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='StructureDisplayPattern3'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Property 1'" /></value>
            <value><xsl:value-of select="Property[@Field='PropertyInfo1']" /></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='PropertyInfoPattern1'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Property 2'" /></value>
            <value><xsl:value-of select="Property[@Field='PropertyInfo2']" /></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='PropertyInfoPattern2'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Property 3'" /></value>
            <value><xsl:value-of select="Property[@Field='PropertyInfo3']" /></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='PropertyInfoPattern3'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Related object 1'" /></value>
            <value></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='ObjectKey1'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Related object 2'" /></value>
            <value></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='ObjectKey2'], 40)" /></value>
        </row>
        <row>
            <value><xsl:value-of select="'Related object 3'" /></value>
            <value></value>
            <value><xsl:value-of select="ois:markdown-inline-code(Property[@Field='ObjectKey3'], 40)" /></value>
        </row>
    </rows>
</xsl:template>

<xsl:template match="AttestationProcedures">
    <xsl:value-of select="ois:markdown-heading-2('Attestation Procedures')" />

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Attestation procedures'" />
        <xsl:with-param name="id" select="'summary-attestation-procedures'" />
        <xsl:with-param name="header"   >| Procedure        | Type | Table | Report |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:-----------|:---------------|:-------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
            <xsl:apply-templates select="AttestationProcedure" mode="table">
                <xsl:sort select="@name" order="ascending" />
            </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="AttestationProcedure">
        <xsl:sort select="@name" order="ascending" />
    </xsl:apply-templates>

</xsl:template>
<xsl:template match="AttestationProcedure" mode="table">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="Type/@name" /></value>
        <value><xsl:value-of select="Table/@name" /></value>
        <value><xsl:value-of select="Report/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="ApprovalPolicies" mode="table-list">
    <items>
        <xsl:apply-templates select="ApprovalPolicy" mode="table-list-item" />
    </items>
</xsl:template>
<xsl:template match="ApprovalPolicy" mode="table-list-item">
    <value><xsl:value-of select="@name" /></value>
</xsl:template>

<xsl:template match="AttestationProcedure">
    <xsl:value-of select="ois:markdown-heading-3(@name)" />

    <xsl:value-of select="ois:markdown-definition('Description', Description)" />
    <xsl:value-of select="ois:markdown-definition('Type', Type/@name)" />
    <xsl:value-of select="ois:markdown-definition('Table', Table/@name)" />
    <xsl:value-of select="ois:markdown-definition('Report', Report/@name)" />

    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Assigned approval policies'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="ApprovalPolicies/ApprovalPolicy" mode="list-item" /> </items>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Procedure templates'" />
        <xsl:with-param name="id" select="concat('attestation-procedure-templates-', @id)" />
        <xsl:with-param name="header"   >| Attribute        | Label | Template |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:-----------|:---------------|</xsl:with-param>
        <xsl:with-param name="values">
            <xsl:apply-templates select="AttestationProcedureProperties" mode="table-rows" />
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="ApprovalPolicy" mode="list-item">
    <value><xsl:value-of select="@name" /></value>
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

<xsl:apply-templates select="AccountDefinition">
    <xsl:sort select="@name" order="ascending" />
</xsl:apply-templates>

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
  />** | <xsl:value-of select="Description" 
    /> | <xsl:value-of select="ois:last-modified(BehaviorProperties)"
    /> |                 
</xsl:for-each>   

<xsl:if test="DataMappings/DataMapping">
    <xsl:variable name="accountDef" select="@id" />
    <xsl:variable name="targetTable" select="TargetSystem/@table" />

### IT Data Mapping

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('IT Data columns for account definition ', @name)" />
        <xsl:with-param name="id" select="concat('account-definition-data-maps-', @id)" />
        <xsl:with-param name="header"   >| Column            | Fixed Value       | Default Value | Notify on Default |</xsl:with-param>
        <xsl:with-param name="separator">|:------------------|:---:|:---------------------------|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="DataMappings/DataMapping" mode="table">
                    <xsl:sort select="Column/@name" order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="DataMappings/DataMapping[count(DataMaps/DataMap) &gt; 0]">
        <xsl:sort select="Column/@name" />
    </xsl:apply-templates>

</xsl:if>


</xsl:template>
<xsl:template match="DataMapping" mode="table">
    <row>
        <value><xsl:value-of select="concat(../../TargetSystem/@table, ': ', Column/@name)" /></value>
        <value><xsl:value-of select="@fixValue" /></value>
        <value><xsl:if test="not(@fixValue)"><xsl:apply-templates select="DefaultValue" mode="text" /></xsl:if></value>
        <value><xsl:value-of select="@notifyDefaultUsed" /></value>
    </row>
</xsl:template>
<xsl:template match="DataMapping">
    <xsl:value-of select="ois:markdown-heading-3( concat( ../../TargetSystem/@table, ': ', Column/@name ) )" />

    <xsl:variable name="dv"> <xsl:apply-templates select="DefaultValue" mode="text" /> </xsl:variable>
    <xsl:value-of select="ois:markdown-definition('Default value', $dv)" />
    <xsl:value-of select="ois:markdown-definition('Always use default', @alwaysUseDefault)" />
    <xsl:value-of select="ois:markdown-definition('Notify when default value used', @notifyDefaultUsed)" />

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat(
            'ITData assignments for column ', ../../TargetSystem/@table, ' - ', Column/@name)" />
        <xsl:with-param name="id" select="concat('account-definition-data-map-values-',../../@id, @UID_DialogColumn )" />
        <xsl:with-param name="header"   >| Structure   | Column Value     |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:-----------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="DataMaps/DataMap" mode="table">
                    <xsl:sort select="Structure/Type/@name" />
                    <xsl:sort select="Structure/@name" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="DataMap" mode="table">
    <row>
        <value><xsl:value-of select="concat(Structure/Type/@name, ': ', Structure/@name)" /></value>
        <value><xsl:apply-templates select="DataMapValue" mode="text" /></value>
    </row>
</xsl:template>

<xsl:template match="DefaultValue|DataMapValue" mode="text">
    <xsl:value-of select="concat( @table, ' - ', longName)" /><xsl:apply-templates select="DefaultValueProperties|DataMapValueProperties" mode="text" />
</xsl:template>
<xsl:template match="DefaultValueProperties|DataMapValueProperties" mode="text">
    <xsl:value-of select="replace(
        concat(
            Property[@Field='FQDN'],
            Property[@Field='CanonicalName']
        ), 
        '&#xa;', ''
     )" />
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

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Target system container hierarchy</xsl:with-param>
        <xsl:with-param name="id" select="concat('target-system-hierarchy-', @id)" />
        <xsl:with-param name="header" select="@name" />
        <xsl:with-param name="values">
            <tree>
                <xsl:apply-templates select="Containers/Container" mode="branch">
                    <xsl:sort select="@canonicalName" />
                </xsl:apply-templates>
            </tree>
        </xsl:with-param>
    </xsl:call-template>


**Containers**: <xsl:value-of select="ois:is-null-string(ObjectCounts/Containers/text(), '0')" />

**Groups**: <xsl:value-of select="ois:is-null-string(ObjectCounts/Groups/text(), '0')" />

**Accounts**: <xsl:value-of select="ois:is-null-string(ObjectCounts/Accounts/text(), '0')" />

<xsl:apply-templates select="Forest|ExchangeForest" />
<xsl:apply-templates select="SPSWebApp" />




<xsl:if test="count(
        /IdentityManager/SyncProjects/SyncProject[
            SystemConnections/SystemConnection/RootObjConnectionInfos/RootObjConnectionInfo/RootObject/@key
            and
            contains(
                concat($objectKey,$spsFarmKey),
                SystemConnections/SystemConnection/RootObjConnectionInfos/RootObjConnectionInfo/RootObject/@key
            )
        ]
    ) &gt; 0">

**Sync projects**:

<xsl:for-each select="
        /IdentityManager/SyncProjects/SyncProject[
            SystemConnections/SystemConnection/RootObjConnectionInfos/RootObjConnectionInfo/RootObject/@key
            and
            contains(
                concat($objectKey,$spsFarmKey),
                SystemConnections/SystemConnection/RootObjConnectionInfos/RootObjConnectionInfo/RootObject/@key
            )
        ]
">
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
                    <xsl:for-each select="SystemConnections/SystemConnection/RootObjConnectionInfos/RootObjConnectionInfo">
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

<xsl:template match="Container" mode="branch">
    <branch>
        <xsl:attribute name="name" select="@cn" />
        <xsl:attribute name="path" select="replace(@canonicalName, '/', '\\')" />
        <xsl:attribute name="color" select="
            if ( ObjectCounts/Groups = '0' and ObjectCounts/Accounts = '0' ) then $OI_GRAY
            else $OI_JAFFA
        " />
    </branch>
</xsl:template>


<!-- ===== Sync Projects ======================= -->

<xsl:template match="SyncProjects">


Table: Summary of synchronization projects {#tbl:summary-synchronization-projects}

| Project        | Description           | Notes                      | Last Modified |
|:--------------|:---------------|:---------------------------|:---------------|
<xsl:for-each select="SyncProject"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@name, '\\', '/')" 
  />** | <xsl:value-of select="ois:encode-breaks-for-markdown-table(Description)"
    /> | <xsl:call-template name="ois:escape-for-markdown-table">
            <xsl:with-param name="s"><xsl:value-of select="SyncProjectProperties/Property[@Field='OriginInfo']"/></xsl:with-param></xsl:call-template
     > | <xsl:value-of select="ois:last-modified(SyncProjectProperties)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="SyncProject">
    <xsl:sort select="@name" order="ascending" />
</xsl:apply-templates>

</xsl:template>

<xsl:template match="SyncProject">
    <xsl:value-of select="ois:markdown-heading-2(@name)" />

    <xsl:apply-templates select="." mode="graphic" />



Table: Startup configurations for <xsl:value-of select="@name" /> {#tbl:synchronization-project-start-<xsl:value-of select="@id"/>}

| Project        | Direction | Revisions | Variable Set  | Workflow           | Schedules   |
|:--------------|:-----:|:-----:|:--------|:---------------|:------------------|
<xsl:for-each select="StartInfos/StartInfo"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="replace(@displayName, '\\', '/')" 
     />** | <xsl:value-of select="@direction"
     /> | <xsl:value-of select="@revisionHandling"
     /> | <xsl:value-of select="if (VariableSet) then VariableSet/@name else 'default'"
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
     />** | <xsl:value-of select="WorkflowProperties/Property[@Field='Description']"
     /> | <xsl:value-of select="@direction"
     /> | <xsl:value-of select="@revisionHandling"
     /> | <xsl:value-of select="@conflictResolution"
     /> | <xsl:value-of select="@exceptionHandling"
     /> |                 
</xsl:for-each>   

<xsl:apply-templates select="Workflows/Workflow" />
<xsl:apply-templates select="SystemMaps" />

</xsl:template>

<xsl:template match="SystemMaps">
    <xsl:value-of select="ois:markdown-heading-3('Mapping')" />

    <xsl:apply-templates select="SystemMap" />
</xsl:template>

<xsl:template match="SystemMap">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Property mapping for ', @name)" />
        <xsl:with-param name="id" select="concat('synchronization-project-map-', @id)" />
        <xsl:with-param name="header" select="concat('| ', LeftSchemaClass/@name, ' | Options | ', RightSchemaClass/@name, ' |')" />
        <xsl:with-param name="separator">|-------------:|:-----------:|:---------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows>
                <xsl:apply-templates select="MappingRules/MappingRule" mode="table-row">
                    <xsl:sort select="@isKeyRule" order="descending" />
                    <xsl:sort select="@name" order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="MappingRule" mode="table-row">
    <row>
        <value><xsl:value-of select="@propertyLeft"/></value>
        <value><xsl:apply-templates select="." mode="table-cell-options" /></value>
        <value><xsl:value-of select="concat('**', @propertyRight, '**')"/></value>
    </row>
</xsl:template>
<xsl:template match="MappingRule" mode="table-cell-options">
    <xsl:choose>
        <xsl:when test="Property[@Field='MappingDirection'] = 'xxDoNotMap'">
            <xsl:value-of select="if ( @isKeyRule='true' ) then 'Key Rule' else 'Not mapped'" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="caption" select="ois:delimit-list(', ',
                if ( @isKeyRule='true' ) then 'Key Column' else '',
                if ( Property[@Field='IgnoreCase']='true' ) then 'Ignore Case' else '',
                if ( Property[@Field='MappingDirection']='Inherite' ) then 'Inherit Direction' else '',
                if ( Property[@Field='IsRogueDetectionEnabled']='true' ) then 'Rogue Detection' else '',
                if ( Property[@Field='IsRogueCorrectionEnabled']='true' ) then 'Rogue Correction' else '',
                if ( Property[@Field='DoNotOverrideLeft']='true' ) then 'No Override Left' else '',
                if ( Property[@Field='DoNotOverrideRight']='true' ) then 'No Override Right' else ''
            )" />
            <xsl:variable name="path-class">
                <xsl:choose>
                    <xsl:when test="Property[@Field='IsKeyRule'] = 'true'">key-column</xsl:when>
                    <xsl:when test="Property[@Field='MappingDirection'] = 'DoNotMap'"      >gray</xsl:when>
                    <xsl:when test="Property[@Field='MappingDirection'] = 'ToTheRight'"    >right-arrow</xsl:when>
                    <xsl:when test="Property[@Field='MappingDirection'] = 'ToTheLeft'"     >left-arrow</xsl:when>
                    <xsl:when test="Property[@Field='MappingDirection'] = 'BothDirections'">arrows</xsl:when>
                    <xsl:when test="Property[@Field='MappingDirection'] = 'Inherite'"      >dashes</xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="ois:generate-SVG-line-h(250, $caption, ois:svg-attr('class', $path-class), '' )" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>



<xsl:template match="VariableSet">

### Variable Set: <xsl:value-of select="@name" />

Table: Values for variable set <xsl:value-of select="@name" /> {#tbl:synchronization-project-variables-<xsl:value-of select="@id"/>}

| Variable        | Value | Secret? | System Variable? |
|:----------------|:-----------------|:-----:|:-----:|
<xsl:for-each select="Variables/Variable"
><xsl:sort select="@name" order="ascending"
     />| **<xsl:value-of select="@name" 
     />** | <xsl:value-of select="if(@isSecret='true') then '[secret]' else ois:markdown-inline-code(@value, 50)"
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
><xsl:sort select="@displayName" order="ascending"
     />| **<xsl:value-of select="@displayName" 
     />** | <xsl:value-of select="Property[@Field='Description']"
     /> | <xsl:value-of select="@direction"
     /> | <xsl:value-of select="@isDeactivated"
     /> | <xsl:value-of select="@isImport"
     /> | <xsl:value-of select="@exceptionHandling"
     /> |                 
</xsl:for-each>   

</xsl:template>


<xsl:template match="SyncProject" mode="graphic">

    <xsl:call-template name="ois:generate-plantuml-C4">
        <xsl:with-param name="summary" select="concat('Schema overview of ', @name)" />
        <xsl:with-param name="id" select="concat('schema-overview-', @id)" />
        <xsl:with-param name="content">
            <xsl:if test="count(SystemMaps/SystemMap) &gt; 0" >
                <xsl:apply-templates select="SystemConnections" mode="plantuml" />
                <xsl:apply-templates select="SystemMaps[count(SystemMap) &gt; 0]" mode="plantuml">
                    <xsl:sort select="@name" />
                </xsl:apply-templates>
                <xsl:apply-templates select="SystemConnections/SystemConnection" mode="plantuml-connection">
                    <xsl:sort select="@name" />
                </xsl:apply-templates>
                <xsl:apply-templates select="SystemMaps" mode="plantuml-connections">
                    <xsl:sort select="@name" />
                </xsl:apply-templates>
            </xsl:if>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="SystemConnections" mode="plantuml">
    <xsl:apply-templates select="SystemConnection" mode="plantuml">
        <xsl:sort select="@name" />
    </xsl:apply-templates>
</xsl:template>
<xsl:template match="SystemConnection" mode="plantuml">
    <xsl:choose>
        <xsl:when test="SystemConnectionProperties/Property[@Field='Name']='MainConnection'">
            <xsl:apply-templates select="/IdentityManager" mode="plantuml-system" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="RootObjConnectionInfos/RootObjConnectionInfo[1]/RootObject" mode="plantuml-system" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="ois:c4-component(
            ois:clean-for-plantuml-name(concat('SC_', @id)), 
            ois:truncate-string(@name, 30, '...'), 
            'SystemConnection', 
            'OneIM_SystemConnection'
        )" />
</xsl:template>
<xsl:template match="IdentityManager" mode="plantuml-system">
    <xsl:value-of select="ois:c4-system('ONEIM', @name, PrimaryDatabase/@DataSource, 'OneIM')" />
</xsl:template>
<xsl:template match="RootObject" mode="plantuml-system">
    <xsl:variable name='root-tag'>
        <xsl:apply-templates select="." mode="c4-tag" />
    </xsl:variable>
    <xsl:variable name='root-name'>
        <xsl:apply-templates select="." mode="text" />
    </xsl:variable>
    <xsl:value-of select="ois:c4-system(
                    'ROOT', 
                    $root-name, 
                    ois:truncate-string(../../../@name, 20, '...'), 
                    $root-tag)" />
</xsl:template>
<xsl:template match="RootObject" mode="text">
    <xsl:choose>
        <xsl:when test="@table='DialogTable' and @id='QER-T-Person'">HR</xsl:when>
        <xsl:otherwise><xsl:value-of select="concat(@table, '-', @name)" /></xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="RootObject" mode="c4-tag">
    <xsl:choose>
        <xsl:when test="@table='ADSDomain'">OneIM_TS_MicrosoftAD</xsl:when>
        <xsl:when test="@table='OLGAPIDomain'">OneLogin</xsl:when>
        <xsl:when test="@table='DialogTable' and @id='QER-T-Person'">OneIM_HR</xsl:when>
        <xsl:otherwise>OneIM_TS_Generic</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="SystemMaps" mode="plantuml">
    <xsl:variable name="content-left">
        <xsl:apply-templates select="SystemMap/LeftSchemaClass" mode="plantuml-component">
            <xsl:sort select="@name" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="content-right">
        <xsl:apply-templates select="SystemMap/RightSchemaClass" mode="plantuml-component">
            <xsl:sort select="@name" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="ois:c4-boundary( 
            'SCHEMA_LEFT', 
            SystemMap[1]/LeftSchemaClass/SchemaType/Schema/@systemDisplay,
            'OI_System', 
            $content-left
        )" />
    <xsl:value-of select="ois:c4-boundary( 
            'SCHEMA_RIGHT', 
            SystemMap[1]/RightSchemaClass/SchemaType/Schema/@systemDisplay,
            'OI_System', 
            $content-right
        )" />
</xsl:template>
<xsl:template match="SchemaClass|LeftSchemaClass|RightSchemaClass" mode="plantuml-component">
    <xsl:value-of select="ois:c4-component(
                    concat('SCLASS_', @id),
                    ois:is-null-string(@displayName, @name), 
                    ois:truncate-string(ois:is-null-string(SchemaType/@displayName, SchemaType/@name), 25, '...'), 
                    'OneIM_SchemaClass')" />
</xsl:template>
<xsl:template match="SystemMap" mode="plantuml-connection">
    <xsl:variable name="rel-type">
        <xsl:choose>
            <xsl:when test="@direction='ToTheLeft'">Rel</xsl:when>
            <xsl:when test="@direction='ToTheRight'">Rel</xsl:when>
            <xsl:when test="@direction='BothDirections'">BiRel</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="ois:c4-rel-common(
                    $rel-type,
                    concat('SCLASS_', LeftSchemaClass/@id),
                    concat('SCLASS_', RightSchemaClass/@id),
                    'mapped', 
                    'light')" />
</xsl:template>
<xsl:template match="SystemConnection" mode="plantuml-connection">
    <xsl:variable name="rel-target">
        <xsl:choose>
            <xsl:when test="SystemConnectionProperties/Property[@Field='Name']='MainConnection'">ONEIM</xsl:when>
            <xsl:otherwise>ROOT</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- map back to system -->
    <xsl:value-of select="ois:c4-rel(
                    $rel-target,
                    concat('SC_', @id),
                    '', 
                    'light')" />
</xsl:template>
<xsl:template match="SystemMaps" mode="plantuml-connections">
    <!-- map left and right maps to system connections -->
    <xsl:variable name="schema-left" select="SystemMap[1]/LeftSchemaClass/SchemaType/Schema/@id" />
    <xsl:variable name="schema-right" select="SystemMap[1]/RightSchemaClass/SchemaType/Schema/@id" />
    <xsl:value-of select="ois:c4-rel(
                    ois:clean-for-plantuml-name(concat('SC_', ../SystemConnections/SystemConnection[Schema/@id=$schema-left]/@id)), 
                    'SCHEMA_LEFT',
                    '', 
                    'light')" />
    <xsl:value-of select="ois:c4-rel(
                    ois:clean-for-plantuml-name(concat('SC_', ../SystemConnections/SystemConnection[Schema/@id=$schema-right]/@id)), 
                    'SCHEMA_RIGHT',
                    '', 
                    'light')" />

    <xsl:apply-templates select="SystemMap" mode="plantuml-connection">
        <xsl:sort select="@name" />
</xsl:apply-templates>
</xsl:template>


<!-- ==== Compliance ====================== -->

<xsl:template match="ComplianceRules">

    <xsl:if test="count(ComplianceRule) &gt; 0">
        <xsl:value-of select="ois:markdown-heading-1('Compliance Rules')" />
    </xsl:if>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of identity compliance rules.'" />
        <xsl:with-param name="id" select="'summary-compliance-rules'" />
        <xsl:with-param name="header"   >| Name     | Description | Version | Violations |  Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:---------|:------------|:---:|:--:|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="ComplianceRule" mode="table"> 
                    <xsl:sort select="@name"  order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="ComplianceRule"> 
        <xsl:sort select="@name"  order="ascending" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="ComplianceRule" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ois:encode-breaks-for-markdown-table(Description)"/></value>
        <value><xsl:value-of select="concat(@versionMajor, '.', @versionMinor, '.', @versionPatch)"/></value>
        <value><xsl:value-of select="count(Violations/Violation)"/></value>
        <value><xsl:value-of select="ois:last-modified(ComplianceRuleProperties)" /></value>
    </row>
</xsl:template>

<xsl:template match="ComplianceRule">
    <xsl:value-of select="ois:markdown-heading-2(replace(concat('Rule: ', @name), '\\', '/'))" />

    <xsl:value-of select="ois:markdown-definition('Version', concat(@versionMajor, '.', @versionMinor, '.', @versionPatch))" />
    <xsl:value-of select="ois:markdown-definition('Description', Description)" />

    <xsl:value-of select="ois:markdown-definition('Rule supervisors', OwnerRole/@fullPath)" />
    <xsl:value-of select="ois:markdown-definition('Attestors', Attestor/@fullPath)" />

    <xsl:value-of select="ois:markdown-definition('Last audit', concat(ComplianceRuleProperties/Property[@Field='DateLastAudit'], ' - ', LastAuditor/@fullName))" />


    <xsl:value-of select="ois:markdown-heading-3('Criteria')" />
    <xsl:value-of select="ois:markdown-definition-codeblock('Identity where clause', WhereClausePerson, 'sql')" />
    <xsl:value-of select="ois:markdown-definition-codeblock('Where clause', WhereClause, 'sql')" />


    <xsl:value-of select="ois:markdown-heading-3('Violations')" />
    <xsl:value-of select="ois:markdown-definition('Exception approvers', ExceptionApproverRole/@fullPath)" />
    <xsl:value-of select="ois:markdown-definition('Approval max duration (days)', ComplianceRuleProperties/Property[@Field='ExceptionMaxValidDays'])" />
    <xsl:value-of select="ois:markdown-definition('Note to exception approver', ExceptionNotes)" />
    <xsl:value-of select="ois:markdown-definition('Approval risk note', RiskDescription)" />
    <xsl:value-of select="ois:markdown-definition('Mail template - new violation', MailTemplateNewViolation/@name)" />
    <xsl:value-of select="ois:markdown-definition-int('Number of violations', count(Violations/Violation))" />
    <xsl:value-of select="ois:markdown-definition-int('Approved violations', count(Violations/Violation[@isExceptionGranted='true']))" />

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of violations.'" />
        <xsl:with-param name="id" select="concat('summary-compliance-violations-', @id)" />
        <xsl:with-param name="header"   >| User     | Date Detected | Approver | Approval Date | Approval Comments |</xsl:with-param>
        <xsl:with-param name="separator">|:---------|:-------|:---------|:-------|:---------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="Violations/Violation" mode="table"> 
                    <xsl:sort select="@XDateInserted"  order="ascending" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:value-of select="ois:markdown-heading-3('Schedules')" />
    <xsl:value-of select="ois:markdown-definition('Check schedule', CheckSchedule/@name)" />
    <xsl:value-of select="ois:markdown-definition('Fill schedule', FillSchedule/@name)" />
</xsl:template>

<xsl:template match="Violation" mode="table">
    <row>
        <value><xsl:value-of select="Violator/@fullName"/></value>
        <value><xsl:value-of select="@XDateInserted"/></value>
        <value><xsl:value-of select="Approver/@fullName"/></value>
        <value><xsl:value-of select="@decisionDate"/></value>
        <value><xsl:value-of select="ois:encode-breaks-for-markdown-table(DecisionReason)"/></value>
    </row>
</xsl:template>


<!-- ===== generic functions ======================= -->



  <!-- Function to extract last modified string -->
  <xsl:function name="ois:last-modified" as="xs:string">
    <xsl:param name="o"/>

    <xsl:variable name="result">
        <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown($o/Property[@Field='XUserUpdated']), 15, '...')" /> - <xsl:value-of select="$o/Property[@Field='XDateUpdated']" />
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
                      <v>dynamic + direct</v>
                      <v>dynamic + inherited</v>
                      <v>dynamic + direct + inherited</v>
                      <v>requested</v>
                      <v>requested + direct</v>
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
