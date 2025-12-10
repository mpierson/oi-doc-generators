<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SPP config export to Markdown

  Author: M Pierson
  Date: Jan 2025
  Version: 0.91

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

  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />

  <xsl:variable name="apos">'</xsl:variable>


  <xsl:param name="ext-project">
      <project/>
  </xsl:param>

 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>

 <xsl:template match="SPP">

---
title: SPP Configuration <xsl:value-of select="@name" /> / <xsl:value-of select="@dnsName" />
author: SPP As Built Generator v0.91
abstract: |
   Configuration of the <xsl:value-of select="@name" /> appliance, exported on <xsl:value-of select="format-dateTime(@checkDate, '[Y0001]-[M01]-[D01]')" />.
---


# Summary

    <xsl:apply-templates select="$ext-project/project" />
    <xsl:apply-templates select="." mode="graphic" />
    <xsl:apply-templates select="$ext-project/project/environments" />

## Cluster

<xsl:apply-templates select="Cluster" />


## Policies

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of entitlements'" />
        <xsl:with-param name="id" select="'entitlements-summary'" />
        <xsl:with-param name="header"   >| Name           | Description                   | Priority | Policies | Users | Assets | Accounts | Created By    |</xsl:with-param>
        <xsl:with-param name="separator">|:---------------|:------------------------------|:--------:|:--------:|:-----:|:------:|:--------:|---------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="Entitlements/Entitlement" mode="table">
                    <xsl:sort select="@name" order="ascending"/>
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

<xsl:call-template name="user-group-summary"><xsl:with-param name="groups" select="./Groups" /></xsl:call-template>

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="'Summary of asset groups'" />
            <xsl:with-param name="id" select="'policies-asset-groups'" />
            <xsl:with-param name="header"   >| Name           | Description              | Matching rule            | Assets | Created By    |</xsl:with-param>
            <xsl:with-param name="separator">|:---------------|:-------------------------|:-------------------------|:------:|:--------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> 
                    <xsl:apply-templates select="Groups/AssetGroups/AssetGroup" mode="table">
                        <xsl:sort select="@name" order="descending"/>
                    </xsl:apply-templates> 
                </rows>
            </xsl:with-param>
        </xsl:call-template>

<xsl:call-template name="account-group-summary"><xsl:with-param name="groups" select="./Groups" /></xsl:call-template>


## Partitions

<xsl:call-template name="all-partitions-summary"><xsl:with-param name="partitions" select="Partitions" /></xsl:call-template>


# Appliance Information
         <xsl:apply-templates select="Version" />
         <xsl:apply-templates select="Health" />
         <xsl:apply-templates select="Licenses" />
         <xsl:apply-templates select="Certificates" />
         <xsl:apply-templates select="IdentityProviders" />
         <xsl:apply-templates select="AuthProviders" />
         <xsl:apply-templates select="Administrators" />
         <xsl:apply-templates select="ArchiveServers" />
         <xsl:apply-templates select="SyslogServers" />

## Settings
             <xsl:apply-templates select="ApplianceSettings | CoreSettings | PurgeSettings" />

     <xsl:apply-templates select="Entitlements | Groups" />
     <xsl:apply-templates select="LinkedAccounts" />
     <xsl:apply-templates select="Partitions" />
     <xsl:apply-templates select="CustomPlatforms" />
 </xsl:template>

<!-- ===== project ============================== -->

<xsl:template match="project">
    <xsl:value-of select="ois:markdown-definition('Name', @name)" />
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





 <!-- SPP summary graphic -->

 <xsl:template match="SPP" mode="graphic">

```{.plantuml caption="Safeguard environment overview"}

!include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

top to bottom direction

together {

    <xsl:if test="count(Cluster/SessionAppliances/SessionNode) > 0">
        Boundary(sps, "SPS cluster") {
         <xsl:apply-templates select="Cluster/SessionAppliances/SessionNode" mode="graphic" />
        }
     </xsl:if>

        Boundary(spp, "SPP cluster") {
         <xsl:apply-templates select="Cluster/Members/Member" mode="graphic-spp-node" />
        }
     }

     together {
        Boundary(admins, "Safeguard administrators") {
             <xsl:apply-templates select="Administrators/Administrator[ois:spp-user-is-administrator(.)]" mode="graphic" />
        }

        Boundary(auditors, "Safeguard auditors") {
             <xsl:apply-templates select="Administrators/Administrator[ois:spp-user-is-auditor(.) and not(ois:spp-user-is-administrator(.))]" mode="graphic" />
        }
    }

    together {
        Boundary(idp, "Identity providers") {
          <xsl:apply-templates select="IdentityProviders/IdentityProvider[ois:spp-idp-has-users(/SPP/Users, .)]" mode="graphic" />
        }
        Boundary(auth, "Authentication providers") {
          <xsl:apply-templates select="AuthProviders/AuthProvider[ois:spp-idp-has-users-auth(/SPP/Users, .)]" mode="graphic" />
        }
    }

    Boundary(int, "Integrated systems") {

         Component(Starling1, "Starling Cloud-based services", <xsl:value-of select="if (count(StarlingSubscription/Property) &gt; 0) then '' else ''" />, $tags="<xsl:value-of select="if (count(StarlingSubscription/Property) &gt; 0) then 'SG_Starling' else 'SG_Starling_Disabled'" />")

         <xsl:if test="count(EmailClient/Property) &gt; 0">
             Component(Mail1, "<xsl:value-of select="EmailClient/Property[@Name='ServerAddress']" />", "Mail transport", $tags="INTEGRATION", $sprite="email_service,scale=0.7,color=white")
         </xsl:if>

         <xsl:apply-templates select="ArchiveServers/ArchiveServer" mode="graphic" />
         <xsl:apply-templates select="SyslogServers/SyslogServer" mode="graphic" />
    }

```
![Safeguard logical view](single.png){#fig:spp-overview}

 </xsl:template>

 <xsl:template match="SessionNode" mode="graphic">
     Component(SPS<xsl:value-of select="ois:clean-for-plantuml-name(Property[@Name='Id'])" />, "<xsl:value-of select="Property[@Name='SpsHostName']" /> (<xsl:value-of select="Property[@Name='SpsNetworkAddress']" />)", "session proxy", $tags="SG_SPS")
 </xsl:template>
 <xsl:template match="Member" mode="graphic-spp-node">
     Component(<xsl:value-of select="ois:clean-for-plantuml-name(Property[@Name='Name'])" />, "<xsl:value-of select="Property[@Name='Name']" /> (<xsl:value-of select="Property[@Name='Ipv4Address']" />)", "<xsl:value-of select="if(Property[@Name='IsLeader']='True') then 'primary node' else 'replica node'" />", $tags="SG_SPP")
 </xsl:template>
 <xsl:template match="Administrator" mode="graphic">
     <xsl:variable name="type" select="if (ois:spp-user-is-administrator(.)) then 'Admin' else 'Auditor'" />
     Person(<xsl:value-of select="@name"/>, "<xsl:value-of select="@name"/>", "<xsl:value-of select="ois:clean-for-plantuml(Property[@Name='Description'])"/>", $tags="SG_<xsl:value-of select="$type" />")
 </xsl:template>
 <xsl:template match="IdentityProvider" mode="graphic">
     Component(Ident<xsl:value-of select="replace(@id, '-', '_')" />, "<xsl:value-of select="@name" />", "<xsl:value-of select="@type" /> identity provider", $tags="IDP_<xsl:value-of select="@type" />")
 </xsl:template>
 <xsl:template match="AuthProvider" mode="graphic">
     Component(Auth<xsl:value-of select="replace(@id, '-', '_')" />, "<xsl:value-of select="@name" />", "<xsl:value-of select="@type" /> auth provider", $tags="AUTH_<xsl:value-of select="@type" />")
 </xsl:template>
 <xsl:template match="ArchiveServer" mode="graphic">
     Component(ARC<xsl:value-of select="@id" />, "<xsl:value-of select="@name" /> (<xsl:value-of select="@networkAddress" />)", "<xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" /> archive server", $tags="ARCH_<xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" />")
 </xsl:template>
 <xsl:template match="SyslogServer" mode="graphic">
     Component(Syslog_<xsl:value-of select="@id" />, "Syslog: <xsl:value-of select="@name" />", "<xsl:value-of select="@host" /> - <xsl:value-of select="@protocol" />", $tags="SG_Syslog")
 </xsl:template>

<xsl:function name="ois:spp-idp-num-users" as="xs:integer">
    <xsl:param name="users"/>                                                                         
    <xsl:param name="idp"/>                                                                         
    <xsl:sequence select="count($users/User[UserObject/Property[@Name='IdentityProvider']/Property[@Name='Id'] = $idp/@id])" />
</xsl:function>

<xsl:function name="ois:spp-idp-has-users" as="xs:boolean">
    <xsl:param name="users"/>                                                                         
    <xsl:param name="idp"/>                                                                         
    <xsl:sequence select="ois:spp-idp-num-users($users, $idp) &gt; 0" />
</xsl:function>

<xsl:function name="ois:spp-idp-num-users-primary-auth" as="xs:integer">
    <xsl:param name="users"/>                                                                         
    <xsl:param name="idp"/>                                                                         
    <xsl:sequence select="count($users/User[UserObject/Property[@Name='PrimaryAuthenticationProvider']/Property[@Name='Id'] = $idp/@id])" />
</xsl:function>
<xsl:function name="ois:spp-idp-num-users-secondary-auth" as="xs:integer">
    <xsl:param name="users"/>                                                                         
    <xsl:param name="idp"/>                                                                         
    <xsl:sequence select="count($users/User[UserObject/Property[@Name='SecondaryAuthenticationProvider']/Property[@Name='Id'] = $idp/@id])" />
</xsl:function>


<xsl:function name="ois:spp-idp-has-users-auth" as="xs:boolean">
    <xsl:param name="users"/>                                                                         
    <xsl:param name="idp"/>                                                                         
    <xsl:sequence select="ois:spp-idp-num-users-primary-auth($users, $idp) &gt; 0 
                          or
                          ois:spp-idp-num-users-secondary-auth($users, $idp) &gt; 0" />
</xsl:function>


<xsl:template match="Cluster">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Nodes in SPP cluster'" />
        <xsl:with-param name="id" select="'summary-cluster-nodes'" />
        <xsl:with-param name="header"   >| Name    | Node ID    | IP | Enrolled Since |</xsl:with-param>
        <xsl:with-param name="separator">|:--------|:-----------|:---|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Members/Member" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>

<xsl:template match="Member" mode="table">
    <row>
        <value><xsl:value-of select="@name"/><xsl:if test="@IsLeader='True'"> (primary)</xsl:if></value>
        <value><xsl:value-of select="@id"/></value>
        <value><xsl:value-of select="Property[@Name='Ipv4Address']" /></value>
        <value><xsl:value-of select="Property[@Name='EnrolledSince']" /></value>
    </row>
</xsl:template>

<xsl:template match="Entitlement" mode="table">
    <row>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='Name']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='Priority']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='PolicyCount']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='UserCount']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='AssetCount']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='AccountCount']"/></value>
        <value><xsl:value-of select="EntitlementObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(EntitlementObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"/></value>
    </row>
</xsl:template>

<xsl:template name="user-group-summary">
     <xsl:param name="groups" />

Table: Summary of user groups {#tbl:summary-user-groups-<xsl:value-of select="generate-id()" />}

| Name           | Description                   | Type | Personal Vault | Roles      | Users  | Created By    |
|:---------------|:------------------------------|:----:|:------:|:------------|:------:|:--------------|
<xsl:for-each select="$groups/UserGroups/UserGroup"
      >| **<xsl:value-of select="@name" 
  />** | <xsl:choose>
          <xsl:when test="@type='ActiveDirectory'"><xsl:value-of select="UserGroupObject/Property[@Name='DirectoryProperties']/Property[@Name='DistinguishedName']" /></xsl:when>
          <xsl:otherwise><xsl:value-of select="UserGroupObject/Property[@Name='Description']" /></xsl:otherwise>
        </xsl:choose
   > | <xsl:value-of select="@type" 
  /> | <xsl:value-of select="UserGroupObject/Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='AllowPersonalAccounts']" 
  /> | <xsl:value-of select="string-join(UserGroupObject/Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='AdminRoles']/Property, ' ')" 
  /> | <xsl:value-of select="count(Users/User)" 
  /> | <xsl:value-of select="UserGroupObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(UserGroupObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
  /> |
</xsl:for-each>

</xsl:template>

<xsl:template name="account-group-summary">
     <xsl:param name="groups" />

Table: Summary of account groups {#tbl:summary-account-groups-<xsl:value-of select="generate-id()" />}

| Name           | Description              | Matching rule            | Accounts | Created By    |
|:---------------|:-------------------------|:-------------------------|:------:|:--------------|
<xsl:for-each select="$groups/AccountGroups/AccountGroup"
    >| **<xsl:value-of select="@name" 
/>** | <xsl:value-of select="AccountGroupObject/Property[@Name='Description']"
  /> | <xsl:choose>
        <xsl:when test="@isDynamic='True'"><xsl:value-of select="GroupingRule/Property[@Name='GroupingRule']" /></xsl:when>
        <xsl:otherwise>[static]</xsl:otherwise>
       </xsl:choose
   > | <xsl:value-of select="count(Accounts/Account)" 
  /> | <xsl:value-of select="AccountGroupObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(AccountGroupObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
  /> |
</xsl:for-each>

</xsl:template>



<xsl:template name="all-partitions-summary">
     <xsl:param name="partitions" />

<!-- add random ID to tag, so the template can be called multiple times -->
Table: Summary of partitions {#tbl:summary-partitions-<xsl:value-of select="generate-id()" />}

| Name           | Description                  | Assets | Accounts | Owners        | Created By     |
|:---------------|:-----------------------------|:------:|:--------:|:--------------|----------------|
<xsl:for-each select="$partitions/Partition"
    >| <xsl:value-of select="PartitionObject/Property[@Name='Name']" 
    /> | <xsl:value-of select="PartitionObject/Property[@Name='Description']" 
    /> | <xsl:value-of select="count(Assets/Asset)" 
    /> | <xsl:value-of select="count(Assets/Asset/Accounts/Account)" 
    /> | <xsl:for-each select="Owners/Owner"
>**<xsl:value-of select="@kind"/>**:<xsl:value-of select="@name" /><br /></xsl:for-each
    >| <xsl:value-of select="PartitionObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(PartitionObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
    /> |
</xsl:for-each>



<!-- add random ID to tag, so the template can be called multiple times -->
Table: Summary of assets by platform, all partitions {#tbl:assets-by-platform-all-partitions-<xsl:value-of select="generate-id()" />}

| Platform                      | Platform family               | Count  |
|:------------------------------|:------------------------------|:------:|
<xsl:for-each-group select="$partitions/Partition/Assets/Asset" group-by="@platform"
    >| <xsl:value-of select="@platform"
    /> | <xsl:value-of select="@platformFamily"
    /> | <xsl:value-of select="count(current-group())"
    /> |
</xsl:for-each-group>


</xsl:template>




 <!-- ===== Appliance ===================================================== -->

<xsl:template match="Version">

Table: SPP version details {#tbl:appliance-version}

| Name           | Value                                      |
|----------------|--------------------------------------------|
<xsl:for-each select="Property">| <xsl:value-of select="@Name" /> | <xsl:value-of select="current()" /> |
</xsl:for-each>
<xsl:text>

</xsl:text>
 </xsl:template>

<xsl:template match="Health">

Table: Appliance health {#tbl:appliance-health}

| Name           | Value                                      |
|----------------|--------------------------------------------|
| Uptime | <xsl:value-of select="Property[@Name='UpTime']/Property[@Name='Days']" /> days  <xsl:value-of select="Property[@Name='UpTime']/Property[@Name='Hours']" /> hours |
| Disk usage | <xsl:value-of select="Property[@Name='ResourceUsage']/Property[@Name='NodeResourceHealth']/Property[@Name='DiskPercentFree']" /> percent free |
| Memory usage | <xsl:value-of select="format-number(Property[@Name='ResourceUsage']/Property[@Name='NodeResourceHealth']/Property[@Name='MemoryPercentFree'], '#.00')" /> percent free |
| Processor usage | <xsl:value-of select="Property[@Name='ResourceUsage']/Property[@Name='NodeResourceHealth']/Property[@Name='ProcessorPercentUsed']" /> percent |
<xsl:for-each select="Property[./Property[@Name='Status']]">| <xsl:value-of select="@Name" /> | <xsl:value-of select="Property[@Name='Status']" /> |
</xsl:for-each>
<xsl:text>

</xsl:text>
 </xsl:template>


<xsl:template match="Licenses">

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SPP licenses'" />
         <xsl:with-param name="id" select="'licenses'" />
         <xsl:with-param name="header"   >| Key  | Module | Valid? | Type  | Expiry | Standard License | Enterprise Password Vault | Disconnected Assets | Changed By |</xsl:with-param>
         <xsl:with-param name="separator">|:--------|:----|:----:|:----:|:-------|:-----------|:-----------|:---------|:--------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="License" mode="table-row"><xsl:sort select="@key" order="descending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="License" mode="table-row">
    <row>
        <value><xsl:value-of select="@key" /></value>
        <value><xsl:value-of select="@module" /></value>
        <value><xsl:value-of select="@isValid" /></value>
        <value><xsl:value-of select="@type" /></value>
        <value><xsl:value-of select="@expires" /></value>
        <value><xsl:apply-templates select="Property[@Name='PasswordManagementLicense']" mode="table-cell-PasswordManagementLicense" /></value>
        <value><xsl:apply-templates select="Property[@Name='EnterpriseAccountsLicense']" mode="table-cell-EnterpriseAccountsLicense" /></value>
        <value><xsl:apply-templates select="Property[@Name='DisconnectedAssetsLicense']" mode="table-cell-EnterpriseAccountsLicense" /></value>
        <value><xsl:value-of select="concat(Property[@Name='ChangedByUserDisplayName'],' (',format-dateTime(Property[@Name='ChangedByDate'], '[Y0001]-[M01]-[D01]'),')')" /></value>
    </row>
</xsl:template>
<xsl:template match="Property" mode="table-cell-PasswordManagementLicense">
    <xsl:choose>
        <xsl:when test="Property[@Name='Model']='User'">
            <xsl:value-of select="concat('Users: ', Property[@Name='UsersUsed'], ' of ', Property[@Name='MaxUsers'])" />
        </xsl:when>
        <xsl:when test="Property[@Name='Model']='System'">
            <xsl:value-of select="concat('System: ', Property[@Name='SystemsUsed'], ' of ', Property[@Name='MaxSystems'])" />
        </xsl:when>
        <xsl:otherwise>n/a</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="Property" mode="table-cell-EnterpriseAccountsLicense">
    <xsl:choose>
        <xsl:when test="Property[@Name='Model']='User'">
            <xsl:value-of select="concat('Users: ', Property[@Name='UsersUsed'], ' of ', Property[@Name='MaxUsers'])" />
        </xsl:when>
        <xsl:otherwise>n/a</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="Property" mode="table-cell-DisconnectedAssetsLicense">
    <xsl:choose>
        <xsl:when test="Property[@Name='Model']='System'">
            <xsl:value-of select="concat('Systems: ', Property[@Name='SystemsUsed'], ' of ', Property[@Name='MaxSystems'])" />
        </xsl:when>
        <xsl:otherwise>n/a</xsl:otherwise>
    </xsl:choose>
</xsl:template>



<xsl:template match="Certificates">

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of trusted certificates'" />
         <xsl:with-param name="id" select="'certificates-trusted'" />
         <xsl:with-param name="header"   >| Subject | Issuer | Thumbprint | Is CA? | Validity |</xsl:with-param>
         <xsl:with-param name="separator">|:--------|:---------|:------------|:--:|:----------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="Certificate" mode="table-row"><xsl:sort select="@subject" order="descending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="Certificate" mode="table-row">
    <row>
        <value><xsl:value-of select="@subject" /></value>
        <value><xsl:value-of select="@issuedBy" /></value>
        <value><xsl:value-of select="@thumbprint" /></value>
        <value><xsl:value-of select="Property[@Name='IsCertificateAuthority']" /></value>
        <value><xsl:value-of select="concat(@notBefore, ' - ', @notAfter)" /></value>
    </row>
</xsl:template>


<xsl:template match="IdentityProviders">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Identity Providers'" />
        <xsl:with-param name="id" select="'identity-providers'" />
        <xsl:with-param name="header"   >| Name | Type | Description | # Users | Properties |</xsl:with-param>
        <xsl:with-param name="separator">|:--------|:-------|:--------|:--:|:-----------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="IdentityProvider" mode="table-row"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="IdentityProvider" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="@type" /></value>
        <value><xsl:value-of select="Property[@Name='Description']" /></value>
        <value><xsl:value-of select="ois:spp-idp-num-users(/SPP/Users, .)" /></value>
        <value>
            <xsl:apply-templates select="Property[@Name='DirectoryProperties']" mode="table-cell-idp-dir-props" />
            <xsl:apply-templates select="Property[@Name='ExternalFederationProperties']" mode="table-cell-idp-fed-props" />
        </value>
    </row>
</xsl:template>
<xsl:template match="Property" mode="table-cell-idp-dir-props">
    <xsl:choose>
        <xsl:when test="Property[@Name='ForestRootDomain']">
            <xsl:value-of select="concat('**Forest**: ', Property[@Name='ForestRootDomain'])" />
            <xsl:text>&#10;</xsl:text>
            <xsl:value-of select="concat(' **Sync interval**: ', Property[@Name='SynchronizationIntervalMinutes'], 'min')" />
            <xsl:text>&#10;</xsl:text>
            <xsl:value-of select="concat(' **Delete sync interval**: ', Property[@Name='DeleteSyncIntervalMinutes'], 'min')" />
            <xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="Property[@Name='Domains']" mode="table-cell-idp-domains" />
            <xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="Property[@Name='DomainControllers']" mode="table-cell-idp-domain-controllers" />
            <xsl:text>&#10;</xsl:text>
            <xsl:value-of select="concat(' **Port**: ', Property[@Name='ConnectionProperties']/Property[@Name='Port'], ' ')" />
            <xsl:text>&#10;</xsl:text>
            <xsl:value-of select="concat(' **SSL**: ', if (Property[@Name='ConnectionProperties']/Property[@Name='UseSslEncryption'] = 'True') then 'Use SSL' else 'No SSL')" />
            <xsl:text>&#10;</xsl:text>
            <xsl:value-of select="concat(' **Service account**: ', Property[@Name='ConnectionProperties']/Property[@Name='EffectiveServiceAccountName'], ' ')" />
        </xsl:when>
    </xsl:choose>
</xsl:template>
<xsl:template match="Property" mode="table-cell-idp-domains">
    <xsl:choose>
        <xsl:when test="count(Property) &gt; 0">
            <xsl:text> **Domains**: </xsl:text>
            <xsl:apply-templates select="Property" mode="table-cell-idp-domain" />
        </xsl:when>
        <xsl:otherwise>n/a</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="Property" mode="table-cell-idp-domain">
    <xsl:value-of select="concat(Property[@Name='DomainName'], ' (', Property[@Name='NetBiosName'], ') ')" />
</xsl:template>
<xsl:template match="Property" mode="table-cell-idp-domain-controllers">
    <xsl:choose>
        <xsl:when test="count(Property) &gt; 0">
            <xsl:text> **Domain controllers**: </xsl:text>
            <xsl:apply-templates select="Property" mode="table-cell-idp-domain-controller" />
        </xsl:when>
        <xsl:otherwise>n/a</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="Property" mode="table-cell-idp-domain-controller">
    <xsl:value-of select="concat(Property[@Name='NetworkAddress'], ' (', Property[@Name='ServerType'], ') ')" />
</xsl:template>

<xsl:template match="Property" mode="table-cell-idp-fed-props">
    <xsl:choose>
        <xsl:when test="Property[@Name='Realm']">
            <xsl:value-of select="concat('**Realm**: ', Property[@Name='Realm'])" />
        </xsl:when>
    </xsl:choose>
</xsl:template>



<xsl:template match="AuthProviders">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Authentication Providers'" />
        <xsl:with-param name="id" select="'authentication-providers'" />
        <xsl:with-param name="header"   >| Name | Type | # Users - Primary Authentication | # Users - Secondary Authentication  |</xsl:with-param>
        <xsl:with-param name="separator">|:--------|:------|:--:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="AuthProvider" mode="table-row"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="AuthProvider">
     <xsl:text>| </xsl:text> <xsl:value-of select="Property[@Name='Name']" /> <xsl:text> | </xsl:text> <xsl:value-of select="Property[@Name='TypeReferenceName']" /> <xsl:text> |
</xsl:text>
 </xsl:template>
<xsl:template match="AuthProvider" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="@type" /></value>
        <value><xsl:value-of select="ois:spp-idp-num-users-primary-auth(/SPP/Users, .)" /></value>
        <value><xsl:value-of select="ois:spp-idp-num-users-secondary-auth(/SPP/Users, .)" /></value>
    </row>
</xsl:template>


<xsl:template match="ArchiveServers">

## Archive Servers

<xsl:apply-templates select="ArchiveServer" />
 </xsl:template>
<xsl:template match="ArchiveServer">

### <xsl:value-of select="@name" />

Description
: <xsl:value-of select="Property[@Name='Description']" />

Network address
: <xsl:value-of select="Property[@Name='NetworkAddress']" />

Transfer protocol
: <xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" /><xsl:text> </xsl:text><xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Description']" />

Path
: <xsl:value-of select="Property[@Name='StoragePath']" />

</xsl:template>


<xsl:template match="SyslogServers">

## Syslog Servers

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Syslog Servers'" />
         <xsl:with-param name="id" select="'syslog-servers'" />
         <xsl:with-param name="header"   >| Name              | Host              | Port | Protocol  | Created |</xsl:with-param>
         <xsl:with-param name="separator">|:------------------|:--------------|:-:|:-:|:-------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="SyslogServer" mode="table"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="SyslogServer" mode="table">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="@host" /></value>
        <value><xsl:value-of select="Property[@Name='Port']" /></value>
        <value><xsl:value-of select="@protocol" /></value>
        <value><xsl:value-of select="concat(Property[@Name='CreatedByUserDisplayName'],' (',format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]'),')')" /></value>
    </row>
</xsl:template>



<!-- Administrators -->
<xsl:template match="Administrators">

## Administrators

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Appliance administrators'" />
         <xsl:with-param name="id" select="'administrators'" />
         <xsl:with-param name="header"   >| User name  | Full name                 | Roles            | Identity source | Auth provider | Created | Last login | Disabled |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:--------------------------|:-----------------|------------|-----------|:---------|:--------|:-----:|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="Administrator[ois:spp-user-is-administrator(.)]" mode="table-row"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Privileged access auditors (excluding administrators)'" />
         <xsl:with-param name="id" select="'auditors'" />
         <xsl:with-param name="header"   >| User name  | Full name                 | Roles            | Identity source | Auth provider | Created | Last login | Disabled |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:--------------------------|:-----------------|------------|-----------|:---------|:--------|:-----:|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="Administrator[ois:spp-user-is-auditor(.) and not(ois:spp-user-is-administrator(.))]" mode="table-row"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>

<xsl:function name="ois:spp-user-is-administrator" as="xs:boolean">
    <xsl:param name="user"/>                                                                         
    <xsl:sequence select="contains($user/@adminRoles, 'Admin')" />
</xsl:function>
<xsl:function name="ois:spp-user-is-auditor" as="xs:boolean">
    <xsl:param name="user"/>                                                                         
    <xsl:sequence select="contains($user/@adminRoles, 'Auditor')" />
</xsl:function>

<xsl:template match="Administrator" mode="table-row">
  <row>
    <value><xsl:value-of select="@name" /></value>
    <value><xsl:value-of select="concat(Property[@Name='FirstName'], ' ', Property[@Name='FirstName'])" /></value>
    <value><xsl:value-of select="replace(@adminRoles, ',', '&#10;')" /></value>
    <value><xsl:value-of select="Property[@Name='IdentityProvider']/Property[@Name='Name']" /></value>
    <value><xsl:value-of select="concat(
            Property[@Name='PrimaryAuthenticationProvider']/Property[@Name='Name'],
            if (Property[@Name='SecondaryAuthenticationProvider']/Property[@Name='Name']) then ' / ' else '',
            Property[@Name='SecondaryAuthenticationProvider']/Property[@Name='Name']
        )" />
    </value>
    <value><xsl:value-of select="Property[@Name='CreatedByUserDisplayName']" /> (<xsl:value-of select="format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')" /><xsl:text>)</xsl:text></value>
    <value><xsl:if test="string-length(Property[@Name='LastLoginDate']) > 0"><xsl:value-of select="format-dateTime(Property[@Name='LastLoginDate'], '[Y0001]-[M01]-[D01]')" /></xsl:if></value>
    <value><xsl:value-of select="Property[@Name='Disabled']" /></value>
  </row>
    
</xsl:template>



 <!-- Settings -->
 <xsl:template match="CoreSettings">

Table: Base settings {#tbl:base-settings}

| Name           | Value                    |
|----------------|--------------------------|
<xsl:apply-templates select="Setting" />

<xsl:text>

</xsl:text>
 </xsl:template>
 <xsl:template match="Setting">
     <xsl:if test="Property[@Name='Value'] != ''">
         <xsl:text>| </xsl:text> <xsl:value-of select="Property[@Name='Name']" /> <xsl:text> | </xsl:text> <xsl:value-of select="Property[@Name='Value']" /> <xsl:text> |
</xsl:text>  
     </xsl:if>
 </xsl:template>

<xsl:template match="ApplianceSettings">

Table: Appliance settings {#tbl:appliance-settings}

| Name           | Value                                      |
|----------------|--------------------------------------------|
<xsl:apply-templates select="Setting" />

<xsl:text>

</xsl:text>
 </xsl:template>

<xsl:template match="PurgeSettings">

Table: Purge settings {#tbl:purge-settings}

| Name           | Value                                      |
|----------------|--------------------------------------------|
<xsl:for-each select="Property">| <xsl:value-of select="@Name" /> | <xsl:value-of select="current()" /> |
</xsl:for-each>
<xsl:text>

</xsl:text>
 </xsl:template>

<!-- auth providers -->




 <!-- ===== partitions =============================== -->

 <xsl:template match="Partitions">

# Partitions 

   <xsl:call-template name="all-partitions-summary"><xsl:with-param name="partitions" select="." /></xsl:call-template>

   <xsl:apply-templates select="Partition" />
 </xsl:template>
 <xsl:template match="Partition">

## Partition: <xsl:value-of select="PartitionObject/Property[@Name='Name']" />

<xsl:call-template name="partition-summary">
    <xsl:with-param name="partition" select="." />
</xsl:call-template>

<xsl:if test="count(Owners/Owner) &gt; 0">
Table: Partition owners {#tbl:partition-owners-<xsl:value-of select="@id" />}

| Name       | Full name                 | Identity source | Type         |
|:-----------|:--------------------------|:----------------|:-------------|
<xsl:apply-templates select="Owners/Owner" />
</xsl:if>

<xsl:if test="count(Tags/Tag) &gt; 0">
Table: Partition tags {#tbl:tags-<xsl:value-of select="@id" />}

| Name  | Description               | Owners        |
|:------|:--------------------------|:--------------|
<xsl:apply-templates select="Tags/Tag" />
</xsl:if>

<xsl:apply-templates select="PasswordProfiles | CheckRules | ChangeRules | PasswordRules" />
<xsl:apply-templates select="AssetDiscoveryJobs" />
<xsl:apply-templates select="AccountDiscoveryJobs" />
<xsl:apply-templates select="Assets" />
</xsl:template>

<xsl:template match="Owner">| **<xsl:value-of select="@name" 
/>** | <xsl:value-of select="@displayName"
/> | <xsl:value-of select="@identityProvider" 
/> | <xsl:value-of select="@kind"
/> |
</xsl:template>
<xsl:template match="Tag">| **<xsl:value-of select="@name" 
/>** | <xsl:value-of select="TagObject/Property[@Name='Description']"
/> |<xsl:for-each select="Owners/Owner"
>**<xsl:value-of select="@kind"/>**:<xsl:value-of select="@name" /><br /></xsl:for-each> | 
</xsl:template>

 <!-- asset discovery -->
<xsl:template match="AssetDiscoveryJobs">
  <xsl:if test="count(Job) > 0">
### Asset Discovery

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Asset discovery jobs for ', ../@name)" />
         <xsl:with-param name="id" select="concat('asset-discovery-', ../@id)" />
         <xsl:with-param name="header"   >| Name              | Type          | Rules             | Description                  |</xsl:with-param>
         <xsl:with-param name="separator">|-------------------|---------------|-------------------|------------------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="Job" mode="table"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

    <xsl:apply-templates select="Job" />
 </xsl:if>
</xsl:template>
 <!-- account discovery -->
<xsl:template match="AccountDiscoveryJobs">
  <xsl:if test="count(AccountDiscoveryJob) > 0">
### Account Discovery

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Account discovery jobs for ', ../@name)" />
         <xsl:with-param name="id" select="concat('account-discovery-', ../@id)" />
         <xsl:with-param name="header"   >| Name              | Rules             | Description                  |</xsl:with-param>
         <xsl:with-param name="separator">|-------------------|-------------------|------------------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="AccountDiscoveryJob" mode="table"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

    <xsl:apply-templates select="AccountDiscoveryJob" />
 </xsl:if>
</xsl:template>


<xsl:template name="partition-summary">
     <xsl:param name="partition" />
```plantuml

!include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

top to bottom direction

Boundary(PARTITION, "<xsl:value-of select="$partition/@name" />", "") {

<xsl:if test="count($partition/Owners/Owner) &gt; 0">
    Boundary(OWNERS, "Owners", "") {
    <xsl:for-each select="$partition/Owners/Owner">
       Person(OWNER<xsl:value-of select="@id"/>, "<xsl:value-of select="@displayName"/>", "<xsl:value-of select="@identityProvider"/> user", $tags="SG_Admin")
    </xsl:for-each>
    }
</xsl:if>


<xsl:if test="count($partition/Tags/Tag) &gt; 0">
    Boundary(TAGS, "Tags", "") {
    <xsl:for-each select="$partition/Tags/Tag">
       Component(TAG<xsl:value-of select="@id"/>, "<xsl:value-of select="@name"/>", "", $tags="SG_Tag")
    </xsl:for-each>
    }
</xsl:if>


Boundary(ASSETS, "Assets", "") {
<xsl:for-each-group select="$partition/Assets/Asset" group-by="@platform">
        Component(ASSET<xsl:value-of select="replace(../../@id, '-', '_')"/><xsl:value-of select="@platformId" />, "<xsl:value-of select="@platform" />", "<xsl:value-of select="count(current-group())" /><xsl:text> </xsl:text><xsl:value-of select="@platform" /> assets", $tags="PF_<xsl:value-of select="@platformFamily" />")
</xsl:for-each-group>
}


Boundary(PROFILES, "Password Profiles", "") {
together {
<xsl:for-each select="$partition/PasswordProfiles/Profile">
    Component(PROFILE<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="ois:clean-for-plantuml-name(@name)"/>", "Password profile", $tags="SG_PasswordProfile")
</xsl:for-each>
 }

together {
<xsl:for-each select="$partition/CheckRules/CheckRule">
    Component(CHECK<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="ois:clean-for-plantuml-name(@name)"/>", "Password check schedule", $tags="SG_PasswordCheck")
</xsl:for-each>
 }

together {
<xsl:for-each select="$partition/ChangeRules/ChangeRule">
    Component(CHANGE<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="ois:clean-for-plantuml-name(@name)"/>", "Password change schedule", $tags="SG_PasswordChange")
</xsl:for-each>
 }

together {
<xsl:for-each select="$partition/PasswordRules/PasswordRule">
    Component(PASSRULE<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="ois:clean-for-plantuml-name(@name)"/>", "Password complexity rule", $tags="SG_PasswordRule")
</xsl:for-each>
 }

}


<xsl:if test="count($partition/AssetDiscoveryJobs/Job) &gt; 0 or count($partition/AccountDiscoveryJobs/AccountDiscoveryJob) &gt; 0">
Boundary(DISCOVERY, "Discovery Rules", "") {

<xsl:for-each select="$partition/AssetDiscoveryJobs/Job">
Component(ASSETDISC<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="@name"/>", "asset discovery job", $tags="SG_AssetDiscoveryJob")
</xsl:for-each>

<xsl:for-each select="$partition/AssetDiscoveryJobs/Job/Rules/Rule">
Component(ASSETDISCRULE_<xsl:value-of select="replace(../../@id, '-', '_')"/>_<xsl:value-of select="position()"/>, "<xsl:value-of select="@name"/>", "asset discovery rule", $tags="SG_AssetDiscoveryRule")
</xsl:for-each>

<xsl:for-each select="$partition/AccountDiscoveryJobs/AccountDiscoveryJob">
Component(ACCDISC<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="@name"/>", "account discovery job", $tags="SG_AccountDiscoveryRule")
</xsl:for-each>

}
</xsl:if>


}

<xsl:for-each select="$partition/PasswordProfiles/Profile">
PROFILE<xsl:value-of select="replace(@id, '-', '_')"/><xsl:text disable-output-escaping="yes"><![CDATA[ --> CHECK]]></xsl:text><xsl:value-of select="replace(Property[@Name='CheckScheduleId'], '-', '_')"/>
PROFILE<xsl:value-of select="replace(@id, '-', '_')"/><xsl:text disable-output-escaping="yes"><![CDATA[ -->]]></xsl:text> CHANGE<xsl:value-of select="replace(Property[@Name='ChangeScheduleId'], '-', '_')"/>
PROFILE<xsl:value-of select="replace(@id, '-', '_')"/><xsl:text disable-output-escaping="yes"><![CDATA[ -->]]></xsl:text> PASSRULE<xsl:value-of select="replace(Property[@Name='AccountPasswordRuleId'], '-', '_')"/>
</xsl:for-each>


<xsl:for-each select="$partition/AssetDiscoveryJobs/Job/Rules/Rule">
    <!-- asset discovery job to asset discovery rule -->
ASSETDISC<xsl:value-of select="replace(../../@id, '-', '_')"/><xsl:text disable-output-escaping="yes"><![CDATA[ -->]]></xsl:text>ASSETDISCRULE_<xsl:value-of select="replace(../../@id, '-', '_')"/>_<xsl:value-of select="position()"/>

    <!-- asset discovery rule to account discovery rule -->
    <xsl:if test="string-length(RuleObject/Property[@Name='AssetTemplate']/Property[@Name='AccountDiscoveryScheduleId']) &gt; 0">
ASSETDISCRULE_<xsl:value-of select="replace(../../@id, '-', '_')"/>_<xsl:value-of select="position()"/><xsl:text disable-output-escaping="yes"><![CDATA[ -->]]></xsl:text> ACCDISC<xsl:value-of select="replace(RuleObject/Property[@Name='AssetTemplate']/Property[@Name='AccountDiscoveryScheduleId'], '-', '_')"/>
    </xsl:if>

</xsl:for-each>

<xsl:for-each select="$partition/Tags/Tag">
    <xsl:if test="position() &gt; 1">
        <xsl:variable name="index" select="position() -1" />
        TAG<xsl:value-of select="$partition/Tags/Tag[$index]/@id"/><xsl:text disable-output-escaping="yes"><![CDATA[ -[hidden]r-> ]]></xsl:text> TAG<xsl:value-of select="@id"/>
    </xsl:if>
</xsl:for-each>
<xsl:if test="(count($partition/Tags/Tag) &gt; 0) and (count($partition/Owners/Owner) &gt; 0)">
    OWNERS<xsl:text disable-output-escaping="yes"><![CDATA[ -[hidden]d-> ]]></xsl:text>TAGS
</xsl:if>

```
![Overview of partition <xsl:value-of select="$partition/@name" />](single.png){#fig:overview-partition-<xsl:value-of select="$partition/@id"/>}
</xsl:template>

<xsl:template match="Job" mode="table">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="@type" /></value>
        <value><xsl:value-of select="Rules/Rule/@name" separator=", " /></value>
        <value><xsl:value-of select="JobObject/Property[@Name='Description']" /></value>
    </row>
</xsl:template>
<xsl:template match="AccountDiscoveryJob" mode="table">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="Rules/Rule/@name" separator=", " /></value>
        <value><xsl:value-of select="JobObject/Property[@Name='Description']" /></value>
    </row>
</xsl:template>


<xsl:template match="Job">

#### Job: <xsl:value-of select="@name" />

Type
: <xsl:value-of select="@type" />

Description
: <xsl:value-of select="JobObject/Property[@Name='Description']" />

Schedule type
: <xsl:value-of select="JobObject/Property[@Name='ScheduleType']" />

Created by
: <xsl:value-of select="JobObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(JobObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')" />


Table: Asset discovery rules for &quot;<xsl:value-of select="@name" />&quot; {#tbl:asset-discovery-rules-<xsl:value-of select="@id" />}

| Name         | Password profile | SSH key profile  | Account discovery rule | Allow session requests | Conditions                |
|:-------------|:-----------------|:-----------------|:-----------------|:------:|:--------------------------------|
<xsl:apply-templates select="Rules/Rule" />

</xsl:template>

<xsl:template match="Rule">

    <xsl:if test="name(../../..) = 'AssetDiscoveryJobs'"
>| <xsl:value-of select="@name" 
/> | <xsl:value-of select="RuleObject/Property[@Name='AssetTemplate']/Property[@Name='PasswordProfile']/Property[@Name='EffectiveName']" 
/> | <xsl:value-of select="RuleObject/Property[@Name='AssetTemplate']/Property[@Name='SshKeyProfile']/Property[@Name='EffectiveName']"
/> | <xsl:value-of select="RuleObject/Property[@Name='AssetTemplate']/Property[@Name='AccountDiscoveryScheduleName']" 
/> | <xsl:value-of select="RuleObject/Property[@Name='AssetTemplate']/Property[@Name='SessionAccessProperties']/Property[@Name='AllowSessionRequests']"
/> | <xsl:apply-templates select="Conditions/Condition" /> | 
    </xsl:if>

    <xsl:if test="name(../../..) = 'AccountDiscoveryJobs'"
>| <xsl:value-of select="@name" 
/> | <xsl:value-of select="Property[@Name='AutoManageDiscoveredAccounts']" 
/> | <xsl:value-of select="Property[@Name='AccountTemplate']/Property[@Name='ProfileName']" 
/> | <xsl:value-of select="Property[@Name='AccountTemplate']/Property[@Name='SshKeyProfileName']"
/> | <xsl:value-of select="Property[@Name='AccountTemplate']/Property[@Name='AllowPasswordRelease']" 
/> | <!-- extract criteria from populated discovery props element
--><xsl:for-each select="Property[ends-with(@Name, 'AccountDiscoveryProperties') and string-length(Property[@Name='RuleType']) &gt; 0]"
><xsl:call-template name='account-discovery-rule-condition'><xsl:with-param name='property' select="." /></xsl:call-template> </xsl:for-each> | 
    </xsl:if>

</xsl:template>

<xsl:template match="Condition">**<xsl:value-of select="@type" />** : <xsl:value-of select="normalize-space(replace(Property[@Name='PropertyConstraints'], '\n', ''))" /><br /></xsl:template>

<xsl:template match="AccountDiscoveryJob">

#### Job: <xsl:value-of select="@name" />

Description
: <xsl:value-of select="AccountDiscoveryJobObject/Property[@Name='Description']" />

Schedule type
: <xsl:value-of select="AccountDiscoveryJobObject/Property[@Name='ScheduleType']" />

Created by
: <xsl:value-of select="AccountDiscoveryJobObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(AccountDiscoveryJobObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')" />


Table: Account discovery rules for &quot;<xsl:value-of select="@name" />&quot; {#tbl:account-discovery-rules-<xsl:value-of select="@id" />}

| Name         | Auto-manage accounts | Password profile | SSH key profile  | Allow password release | Conditions                |
|:-------------|:----------:|:-----------------|:-----------------|:------:|:--------------------------------|
<xsl:apply-templates select="Rules/Rule" />

</xsl:template>

<!--
    <Property Name="UnixAccountDiscoveryProperties">
      <Property Name="RuleType">PropertyConstraint</Property>
      <Property Name="PropertyConstraintProperties">
        <Property Name="GidFilter" />
        <Property Name="GroupFilter" />
        <Property Name="NameFilter">root</Property>
        <Property Name="UidFilter" />
      </Property>
  </Property>
-->
<xsl:template name="account-discovery-rule-condition">
     <xsl:param name="property" />

     <xsl:choose>
         <xsl:when test="$property/@Name = 'DirectoryAccountDiscoveryProperties'"
>**<xsl:value-of select="$property/Property[@Name='RuleType']" /> search [<xsl:value-of select="$property/Property[@Name='SearchBase']" />/<xsl:value-of select="$property/Property[@Name='SearchScope']" />]**: <xsl:value-of select="$property/Property[@Name='SearchNameType']" /> &quot;<xsl:value-of select="$property/Property[@Name='SearchName']" />&quot; </xsl:when>
         <xsl:when test="$property/@Name = 'xAccountDiscoveryProperties'">
         </xsl:when>
         <xsl:otherwise
>**<xsl:value-of select="$property/Property[@Name='RuleType']" />**: <xsl:for-each select="$property/Property[@Name='PropertyConstraintProperties']/Property[.!='']"
                 ><xsl:value-of select="@Name" /> = <xsl:value-of select="." /><br />
             </xsl:for-each>
         </xsl:otherwise>
     </xsl:choose>
</xsl:template>





<!-- assets -->
 <xsl:template match="Assets">
 <xsl:if test="count(Asset) &gt; 0">

### Assets

      <xsl:call-template name="asset-summary">
          <xsl:with-param name="partition" select=".." />
      </xsl:call-template>


  <xsl:choose>
   <xsl:when test="count(Asset) &gt; 10 and count(Asset/Accounts/Account) > 0">
      <xsl:call-template name="account-summary-all">
          <xsl:with-param name="partition" select=".." />
      </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
     <xsl:apply-templates select="Asset" />
   </xsl:otherwise>
  </xsl:choose>
  </xsl:if>
 </xsl:template>

 <xsl:template name="asset-summary">
     <xsl:param name="partition" />

            <xsl:call-template name="asset-platform-summary">
                <xsl:with-param name="partition" select="$partition" />
            </xsl:call-template>

            <xsl:call-template name="asset-platform-list">
                <xsl:with-param name="partition" select="$partition" />
            </xsl:call-template>

 </xsl:template>

 <xsl:template name="asset-platform-summary">
     <xsl:param name="partition" />

Table: Assets by platform in partition <xsl:value-of select="$partition/@name" /> {#tbl:assets-by-platform-<xsl:value-of select="$partition/@id" />}

| Platform                      | Platform family               | Count  |
|:------------------------------|:------------------------------|:------:|
<xsl:for-each-group select="$partition/Assets/Asset" group-by="@platform">
         <xsl:text>| </xsl:text>
         <xsl:value-of select="@platform" />
         <xsl:text> | </xsl:text>
         <xsl:value-of select="@platformFamily" />
         <xsl:text> | </xsl:text>
         <xsl:value-of select="count(current-group())" />
         <xsl:text> |
</xsl:text>
     </xsl:for-each-group>
     <xsl:text>
</xsl:text>
 </xsl:template>


 <xsl:template name="asset-platform-list">
     <xsl:param name="partition" />

Table: Assets in partition <xsl:value-of select="$partition/@name" /> {#tbl:assets-<xsl:value-of select="$partition/@id" />}

| Name            | Address          | Platform              | Owners               | Description                       |
|:----------------|:-----------------|:----------------------|:---------------------|:----------------------------------|
<xsl:for-each select="$partition/Assets/Asset"
>| <xsl:value-of select="@name"
/> | <xsl:value-of select="AssetObject/Property[@Name='NetworkAddress']"
/> | <xsl:value-of select="@platformFamily" /> / <xsl:value-of select="@platform"
/> | <xsl:for-each select="Owners/Owner">**<xsl:value-of select="@kind"/>**:<xsl:value-of select="@name"/><br /></xsl:for-each
 > | <xsl:value-of select="AssetObject/Property[@Name='Description']"
/> |
</xsl:for-each>
<xsl:text>

</xsl:text>
 </xsl:template>

 <!-- table of all accounts in partition -->
 <xsl:template name="account-summary-all">
     <xsl:param name="partition" />


     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Summary of accounts in partition ', $partition/@name)" />
         <xsl:with-param name="id" select="concat('all-accounts-', $partition/@id)" />
         <xsl:with-param name="header"   >| Name           | Asset                 | Platform | Password profile | Service account? | Password requests? | Session requests? | Last password change |</xsl:with-param>
         <xsl:with-param name="separator">|:---------------|:----------------------|:---------|:-----------------|:----:|:----:|:----:|:----|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="$partition/Assets/Asset/Accounts/Account" mode="table"><xsl:sort select="Property[@Name='Asset']/Property[@Name='Name']" order="ascending"/><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

 </xsl:template>

<xsl:template match="Account" mode="table">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="../../@name" /></value>
        <value><xsl:value-of select="Property[@Name='Platform']/Property[@Name='PlatformType']" /></value>
        <value><xsl:value-of select="Property[@Name='PasswordProfile']/Property[@Name='EffectiveName']" /></value>
        <value><xsl:value-of select="Property[@Name='IsServiceAccount']" /></value>
        <value><xsl:value-of select="Property[@Name='RequestProperties']/Property[@Name='AllowPasswordRequest']" /></value>
        <value><xsl:value-of select="Property[@Name='RequestProperties']/Property[@Name='AllowSessionRequest']" /></value>
        <value><xsl:choose><xsl:when test="string-length(Property[@Name='TaskProperties']/Property[@Name='LastSuccessPasswordChangeDate']) > 0"><xsl:value-of select="format-dateTime(Property[@Name='TaskProperties']/Property[@Name='LastSuccessPasswordChangeDate'], '[Y0001]-[M01]-[D01]')" /></xsl:when><xsl:otherwise> never </xsl:otherwise></xsl:choose></value>
    </row>
</xsl:template>

 <!-- Asset -->
 <xsl:template match="Asset">
     <xsl:value-of select="ois:markdown-heading-4(concat('Asset: ', @name))" />

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Summary of asset properties for ', @name)" />
         <xsl:with-param name="id" select="concat('asset-properties-', @id)" />
         <xsl:with-param name="header"   >| Name             | Value                          |</xsl:with-param>
         <xsl:with-param name="separator">|------------------|------------------------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="AssetObject/Property[not(./Property) and .!='']" mode="asset-property-table">
                     <xsl:sort select="@Name" order="ascending"/>
                 </xsl:apply-templates> 
             </rows>
         </xsl:with-param>
     </xsl:call-template>


     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Owners of asset ', @name)" />
         <xsl:with-param name="id" select="concat('asset-owners-', @id)" />
         <xsl:with-param name="header"   >| Name       | Full name                 | Identity source | Type         |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:--------------------------|:----------------|:-------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="Owners/Owner" mode="asset-owner-table">
                     <xsl:sort select="@name" order="ascending"/>
                 </xsl:apply-templates> 
             </rows>
         </xsl:with-param>
     </xsl:call-template>


<xsl:if test="count(Accounts/Account) &gt; 0">
    <xsl:call-template name="asset-account-summary">
        <xsl:with-param name="asset" select="." />
    </xsl:call-template>
</xsl:if>
<xsl:if test="count(Accounts/Account) &lt; 2">
    <xsl:apply-templates select="Accounts/Account" />
</xsl:if>
</xsl:template>

 <xsl:template match="Property" mode="asset-property-table">
    <row>
        <value><xsl:value-of select="@Name"/></value>
        <value><xsl:value-of select="." /></value>
    </row>
</xsl:template>
<xsl:template match="Owner" mode="asset-property-table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="@displayName" /></value>
        <value><xsl:value-of select="@identityProvider" /></value>
        <value><xsl:value-of select="@kind" /></value>
    </row>
</xsl:template>

 <xsl:template match="Account">

Table: Properties for account <xsl:value-of select="../../@name" />/<xsl:value-of select="@name" /> {#tbl:account-<xsl:value-of select="@id" />}

<!-- all non-empty Property elements without children, i.e. exclude complex props -->
| Name                       | Value                                               |
|----------------------------|-----------------------------------------------------|
<xsl:apply-templates select="Property[not(./Property) and .!='']" />

 </xsl:template>

 <!-- table of accounts in asset -->
 <xsl:template name="asset-account-summary">
     <xsl:param name="asset" />

Table: Summary of accounts in asset <xsl:value-of select="$asset/@name"/> {#tbl:asset-accounts-<xsl:value-of select="$asset/@id" />}

| Name           | Description      | Password profile | Is service account? | Last password change |
|:---------------|:-----------------|:-----------------|:--------:|-----|
<xsl:for-each select="$asset/Accounts/Account"
>| <xsl:value-of select="@name"
/> | <xsl:value-of select="Property[@Name='Description']"
/> | <xsl:value-of select="Property[@Name='PasswordProfile']/Property[@Name='EffectiveName']"
/> | <xsl:value-of select="Property[@Name='IsServiceAccount']"
/> | <xsl:choose><xsl:when test="string-length(Property[@Name='TaskProperties']/Property[@Name='LastSuccessPasswordChangeDate']) > 0"><xsl:value-of select="format-dateTime(Property[@Name='TaskProperties']/Property[@Name='LastSuccessPasswordChangeDate'], '[Y0001]-[M01]-[D01]')" /></xsl:when><xsl:otherwise> never </xsl:otherwise></xsl:choose>
<xsl:text>
</xsl:text>
</xsl:for-each>
<xsl:text>

</xsl:text>
</xsl:template>




<xsl:template match="PasswordProfiles">

### Password Profiles

Table: Password Profiles {#tbl:password-profiles-<xsl:value-of select="../@id" />}

| Name            | Description             | Check Rule          | Change Rule          | Password Rule    |
|-----------------|-------------------------|---------------------|----------------------|------------------|
<xsl:apply-templates select="Profile" />

<xsl:text>

</xsl:text>
</xsl:template>

<xsl:template match="Profile">
    <xsl:text>| </xsl:text> 
      <xsl:value-of select="@name" /> 
      <xsl:text> | </xsl:text> 
      <xsl:value-of select="Property[@Name='Description']" /> 
      <xsl:text> | </xsl:text> 
      <xsl:value-of select="Property[@Name='CheckScheduleName']" /> 
      <xsl:text> | </xsl:text> 
      <xsl:value-of select="Property[@Name='ChangeScheduleName']" /> 
      <xsl:text> | </xsl:text> 
      <xsl:value-of select="Property[@Name='AccountPasswordRuleName']" /> 
      <xsl:text> |
</xsl:text>
 </xsl:template>


<xsl:template match="CheckRules">
      <xsl:call-template name="profile-rules">
          <xsl:with-param name="node" select="." />
          <xsl:with-param name="name">Password Check Rules</xsl:with-param>
          <xsl:with-param name="type">Password Check Rule</xsl:with-param>
          <xsl:with-param name="idPrefix">check-rule-</xsl:with-param>
      </xsl:call-template>
</xsl:template>
<xsl:template match="ChangeRules">
      <xsl:call-template name="profile-rules">
          <xsl:with-param name="node" select="." />
          <xsl:with-param name="name">Password Change Rules</xsl:with-param>
          <xsl:with-param name="type">Password Change Rule</xsl:with-param>
          <xsl:with-param name="idPrefix">change-rule-</xsl:with-param>
      </xsl:call-template>
</xsl:template>
<xsl:template match="PasswordRules">
      <xsl:call-template name="profile-rules">
          <xsl:with-param name="node" select="." />
          <xsl:with-param name="name">Password Complexity Rules</xsl:with-param>
          <xsl:with-param name="type">Password Complexity Rule</xsl:with-param>
          <xsl:with-param name="idPrefix">password-rule-</xsl:with-param>
      </xsl:call-template>
</xsl:template>




<xsl:template name="profile-rules">
  <xsl:param name="node" />
  <xsl:param name="name" />
  <xsl:param name="type" />
  <xsl:param name="idPrefix" />

  <xsl:text>### </xsl:text><xsl:value-of select="$name" /><xsl:text>

</xsl:text>

<xsl:for-each select="$node/*">
      <xsl:call-template name="profile-rule">
          <xsl:with-param name="rule" select="." />
          <xsl:with-param name="type"><xsl:value-of select="$type" /></xsl:with-param>
          <xsl:with-param name="idPrefix"><xsl:value-of select="$idPrefix" /></xsl:with-param>
      </xsl:call-template>
</xsl:for-each>
    

<xsl:text>

</xsl:text>
</xsl:template>

 <xsl:template name="profile-rule">
  <xsl:param name="rule" />
  <xsl:param name="type" />
  <xsl:param name="idPrefix" />

<xsl:text>

Table: </xsl:text><xsl:value-of select="$type" /><xsl:text> - </xsl:text><xsl:value-of select="$rule/@name" /><xsl:text> {#tbl:</xsl:text><xsl:value-of select="$idPrefix" /><xsl:value-of select="$rule/@id"/><xsl:text>}

| Name                       | Value                                               |
|----------------------------|-----------------------------------------------------|
</xsl:text>

 <xsl:apply-templates select="$rule/Property[@Name != 'Name' and .!='']" mode="table-profile" />
<xsl:text>

</xsl:text>
 </xsl:template>


 <xsl:template match="Property" mode="table-profile">
     <xsl:text>| </xsl:text> <xsl:value-of select="@Name" /> <xsl:text> | </xsl:text> <xsl:value-of select="translate(current(), '&#10;&#13;', '')" /> <xsl:text> |
</xsl:text>  
 </xsl:template>



 <!-- ===== Entitlements ========================================== -->

 <xsl:template match="Entitlements">
# Entitlements

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of entitlements'" />
         <xsl:with-param name="id" select="'entitlements'" />
         <xsl:with-param name="header"   >| Name           | Description                                | Priority | Policies | Users | Assets | Accounts | Created By |</xsl:with-param>
         <xsl:with-param name="separator">|----------------|--------------------------------------------|:--------:|:--------:|:-----:|:------:|:--------:|--------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="Entitlement/EntitlementObject" mode="table"><xsl:sort select="Property[@Name='Name']" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

     <xsl:apply-templates select="Entitlement">
         <xsl:sort select="@name" order="ascending"/>
     </xsl:apply-templates>

<xsl:text>

</xsl:text>
</xsl:template>
<xsl:template match="EntitlementObject" mode="table">
    <row>
    <value><xsl:value-of select="Property[@Name='Name']" /></value>
    <value><xsl:value-of select="Property[@Name='Description']" /></value>
    <value><xsl:value-of select="Property[@Name='Priority']" /></value>
    <value><xsl:value-of select="Property[@Name='PolicyCount']" /></value>
    <value><xsl:value-of select="Property[@Name='UserCount']" /></value>
    <value><xsl:value-of select="Property[@Name='AssetCount']" /></value>
    <value><xsl:value-of select="Property[@Name='AccountCount']" /></value>
    <value><xsl:value-of select="Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"/></value>
    </row>
</xsl:template>


<xsl:template match="Entitlement">

## <xsl:value-of select="@name" />

<xsl:apply-templates select="." mode="graphic" />

### Hourly Restrictions
<xsl:apply-templates select="EntitlementObject/Property[@Name='HourlyRestrictionProperties']" mode="hourly-restrictions" />

### Users in scope
<xsl:apply-templates select="Members" />


<xsl:apply-templates select="RequestPolicies" />

</xsl:template>


<xsl:template match="Entitlement" mode="graphic">


```plantuml

    !include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

    Component(Ent1, "<xsl:value-of select="@name" />", "Entitlement", $tags="SG_Entitlement")

    <xsl:apply-templates select="Members" mode="graphic" />
    <xsl:apply-templates select="RequestPolicies" mode="graphic" />

    <xsl:apply-templates select="Members/Member" mode="graphic-rel" />
    <xsl:apply-templates select="RequestPolicies/RequestPolicy" mode="graphic-rel" />

```
![Overview of entitlement <xsl:value-of select="@name" />](single.png){#fig:ng-overview-entitlement-<xsl:value-of select="@id"/>}

</xsl:template>

<xsl:template match="Members" mode="graphic">
    together {
    <xsl:apply-templates select="Member" mode="graphic"/>
    }
</xsl:template>
<xsl:template match="Member" mode="graphic">
    <xsl:variable name="description">
        <xsl:choose>
            <xsl:when test="@kind = 'Group'" >User group assigned entitlement</xsl:when>
            <xsl:otherwise>User assigned entitlement</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="tag">
        <xsl:choose>
            <xsl:when test="@kind = 'Group'" >SG_UserGroup</xsl:when>
            <xsl:otherwise>SG_User</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    Person(Member<xsl:value-of select="@id"/>, "<xsl:value-of select="@name" />", "<xsl:value-of select="$description" />", $tags="<xsl:value-of select="$tag" />")
</xsl:template>
<xsl:template match="Member" mode="graphic-rel">
    Rel(Member<xsl:value-of select="@id" />, Ent1, "")
</xsl:template>




<xsl:template match="RequestPolicies" mode="graphic">

    <xsl:variable name="all-approvers">
        <approvers>
            <xsl:apply-templates select="RequestPolicy/Property[@Name='ApproverSets']" mode="node-ent-approver-sets" />
        </approvers>
    </xsl:variable>

    together {
    <xsl:for-each select="distinct-values($all-approvers/approvers/approver-set/@id)">
        <xsl:variable name="set-id" select="." />
        <xsl:apply-templates select="$all-approvers/approvers/approver-set[@id=$set-id][1]" mode="graphic" />
    </xsl:for-each>
    }

    together {
    <xsl:apply-templates select="RequestPolicy" mode="graphic"/>
    }
</xsl:template>

<xsl:template match="Property" mode="node-ent-approver-sets">  
    <xsl:apply-templates select="Property" mode="approver-set-map" />
</xsl:template>
<xsl:template match="Property" mode="approver-set-map">  
    <xsl:variable name="approvers"><xsl:apply-templates select="Property[@Name='Approvers']" mode="line-arp-approvers" /></xsl:variable>
    <approver-set>
        <xsl:attribute name="id" select="ois:checksum($approvers)" />
        <xsl:attribute name="requestPolicyId" select="../../@id" />
        <xsl:value-of select="$approvers" />
    </approver-set>
</xsl:template>
<xsl:template match="approver-set" mode="graphic">  
    Component(AS_<xsl:value-of select="@id"  />, "<xsl:value-of select="." />", "Approver Set", $tags="SG_Approver") 
</xsl:template>


<xsl:template match="RequestPolicy" mode="graphic">
    <xsl:variable name="description">
        <xsl:choose>
            <xsl:when test="@type = 'Password'">passwords</xsl:when>
            <xsl:when test="@type = 'Session'" >session</xsl:when>
            <xsl:when test="@type = 'RemoteDesktop'" >remote desktop</xsl:when>
            <xsl:when test="@type = 'RemoteDesktopApplication'" >remote desktop application</xsl:when>
            <xsl:when test="@type = 'Ssh'">SSH</xsl:when>
            <xsl:otherwise >MISSING</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    Component(ARP<xsl:value-of select="@id"/>, "<xsl:value-of select="@name" />", "request policy - <xsl:value-of select="$description" />", $tags="SG_RequestPolicy") 

    <xsl:apply-templates select="ScopeItems" mode="graphic" />
</xsl:template>

<xsl:template match="Property" mode="line-arp-approvers">  
    <xsl:apply-templates select="Property" mode="line-arp-approver" />
</xsl:template>
<xsl:template match="Property" mode="line-arp-approver">  
    <xsl:value-of select="concat(Property[@Name='DisplayName'], '\n')"  disable-output-escaping="yes" />
</xsl:template>


<xsl:template match="ScopeItems" mode="graphic">
    together {
    <xsl:apply-templates select="ScopeItem" mode="graphic"/>
    }
</xsl:template>
<xsl:template match="ScopeItem" mode="graphic">
    <xsl:variable name="name">
        <xsl:choose>
            <xsl:when test="@type = 'Account'" >
                <xsl:value-of select="concat(Property[@Name='Account']/Property[@Name='Asset']/Property[@Name='Name'],':', @name)" />
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="@name" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="description">
        <xsl:choose>
            <xsl:when test="@type = 'Account'" >account</xsl:when>
            <xsl:when test="@type = 'AccountGroup'" >account group</xsl:when>
            <xsl:when test="@type = 'Asset'" >asset</xsl:when>
            <xsl:when test="@type = 'AssetGroup'" >asset group</xsl:when>
            <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="tag">
        <xsl:choose>
            <xsl:when test="@type = 'Account'" >SG_Account</xsl:when>
            <xsl:when test="@type = 'AccountGroup'" >SG_AccountGroup</xsl:when>
            <xsl:when test="@type = 'Asset'" >SG_Asset</xsl:when>
            <xsl:when test="@type = 'AssetGroup'" >SG_AssetGroup</xsl:when>
            <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    Component(ITM<xsl:value-of select="@id"/>, "<xsl:value-of select="$name" />", "<xsl:value-of select="$description" />", $tags="<xsl:value-of select="$tag" />") 
</xsl:template>
<xsl:template match="RequestPolicy" mode="graphic-rel">
    Rel(Ent1, ARP<xsl:value-of select="@id"/>, "")
    <xsl:apply-templates select="Property[@Name='ApproverSets']" mode="graphic-approver-sets-rel" />
    <xsl:apply-templates select="ScopeItems/ScopeItem" mode="graphic-rel" />
</xsl:template>
<xsl:template match="Property" mode="graphic-approver-sets-rel">  
    <xsl:apply-templates select="Property" mode="graphic-approver-set-rel" />
</xsl:template>
<xsl:template match="Property" mode="graphic-approver-set-rel">  
    <xsl:variable name="approvers"><xsl:apply-templates select="Property[@Name='Approvers']" mode="line-arp-approvers" /></xsl:variable>
  Rel(ARP<xsl:value-of select="../../@id"/>, AS_<xsl:value-of select="ois:checksum($approvers)"/>, "")
</xsl:template>
<xsl:template match="ScopeItem" mode="graphic-rel">
        Rel(ARP<xsl:value-of select="../../@id"/>, ITM<xsl:value-of select="@id"/>, "")
</xsl:template>



<xsl:template match="Members">

<xsl:for-each select="Member">
  <xsl:choose>
      <xsl:when test="@kind = 'Group'"
>
- <xsl:value-of select="@name" /> (User Group)
</xsl:when>
      <xsl:otherwise
>
- <xsl:value-of select="@name" /> (<xsl:value-of select="Property[@Name='IdentityProviderTypeReferenceName']" /> User)
</xsl:otherwise>
  </xsl:choose>
 </xsl:for-each>

</xsl:template>

<xsl:template match="RequestPolicies">

### Access Request Policy Summary

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Access request policies for entitlement ', ../@name)" />
         <xsl:with-param name="id" select="concat('request-policies-', ../@id)" />
         <xsl:with-param name="header"   >| Name          | Description              | Type   | Priority | Accounts | Assets | Account Groups | Asset Groups | Created By |</xsl:with-param>
         <xsl:with-param name="separator">|:--------------|:-------------------------|--------|:-----:|:-----:|:-----:|:-----:|:----:|---------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="RequestPolicy" mode="table"><xsl:sort select="Property[@Name='Priority']" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Security properties of access request policies in entitlement ', ../@name)" />
         <xsl:with-param name="id" select="concat('request-policies-secuirty-', ../@id)" />
         <xsl:with-param name="header"   >| Name          | Simultaneous access | Rotate Password | Rotate SSH Key | Terminate Expired Sessions | Filter Linked Accounts | Hourly Restrictions |</xsl:with-param>
         <xsl:with-param name="separator">|:--------------|:---------:|:---:|:---:|:---:|:---:|:---:|:----|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="RequestPolicy" mode="table-security-properties"><xsl:sort select="Property[@Name='Priority']" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Requester properties of access request policies in entitlement ', ../@name)" />
         <xsl:with-param name="id" select="concat('request-policies-requester-', ../@id)" />
         <xsl:with-param name="header"   >| Name          | Require Ticket | Require Comment | Require Reason Code | Emergency Allowed | Duration |</xsl:with-param>
         <xsl:with-param name="separator">|:--------------|:----:|:----:|:----:|:----:|:-----------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="RequestPolicy" mode="table-requester-properties"><xsl:sort select="Property[@Name='Priority']" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>

     <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="concat('Scope items for access request policies in ', ../@name)" />
         <xsl:with-param name="id" select="concat('request-policies-scope-', ../@id)" />
         <xsl:with-param name="header"   >| Name        | Account | Account Group | Asset | Asset Group    |</xsl:with-param>

         <xsl:with-param name="separator">|:----|:------|:------|:------|:------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="RequestPolicy" mode="table-scope-items"><xsl:sort select="Property[@Name='Priority']" order="ascending"/></xsl:apply-templates> </rows>
         </xsl:with-param>
     </xsl:call-template>


    <xsl:apply-templates select="RequestPolicy"><xsl:sort select="Property[@Name='Priority']" order="ascending"/></xsl:apply-templates>

<xsl:text>

</xsl:text>
 </xsl:template>

<xsl:template match="RequestPolicy" mode="table">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="Property[@Name='Description']" /></value>
        <value><xsl:value-of select="@type" /></value>
        <value><xsl:value-of select="Property[@Name='Priority']" /></value>
        <value><xsl:value-of select="Property[@Name='AccountCount']" /></value>
        <value><xsl:value-of select="Property[@Name='AssetCount']" /></value>
        <value><xsl:value-of select="Property[@Name='AccountGroupCount']" /></value>
        <value><xsl:value-of select="Property[@Name='AssetGroupCount']" /></value>
        <value><xsl:value-of select="Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')" /></value>
    </row>
 </xsl:template>
<xsl:template match="RequestPolicy" mode="table-security-properties">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select=" ois:spp-get-simultaneous-sessions-text(Property[@Name='AccessRequestProperties'])" /></value>
        <value><xsl:value-of select="Property[@Name='AccessRequestProperties']/Property[@Name='ChangePasswordAfterCheckin']" /></value>
        <value><xsl:value-of select="Property[@Name='AccessRequestProperties']/Property[@Name='ChangeSshKeyAfterCheckin']" /></value>
        <value><xsl:value-of select="Property[@Name='AccessRequestProperties']/Property[@Name='TerminateExpiredSessions']" /></value>
        <value><xsl:value-of select="Property[@Name='AccessRequestProperties']/Property[@Name='LinkedAccountScopeFiltering']" /></value>
        <value><xsl:value-of select="if (Property[@Name='HourlyRestrictionProperties']/Property[@Name='EnableHourlyRestrictions'] = 'True') then 'Enabled' else 'No restrictions'" /></value>
    </row>
 </xsl:template>
<xsl:template match="RequestPolicy" mode="table-requester-properties">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="Property[@Name='RequesterProperties']/Property[@Name='RequireServiceTicket']" /></value>
        <value><xsl:value-of select="Property[@Name='RequesterProperties']/Property[@Name='RequireReasonComment']" /></value>
        <value><xsl:value-of select="Property[@Name='RequesterProperties']/Property[@Name='RequireReasonCode']" /></value>
        <value><xsl:value-of select="Property[@Name='EmergencyAccessProperties']/Property[@Name='AllowEmergencyAccess']" /></value>
        <value>
            <xsl:choose>
                <xsl:when test="Property[@Name='RequesterProperties']/Property[@Name='AllowCustomDuration']='True'">
                    <xsl:value-of select="concat('Max: ', ois:spp-get-request-duration(Property[@Name='RequesterProperties'], 'MaximumRelease'))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="ois:spp-get-request-duration(Property[@Name='RequesterProperties'], 'DefaultRelease')" />
                </xsl:otherwise>
            </xsl:choose>
        </value>
    </row>
 </xsl:template>
<xsl:template match="RequestPolicy" mode="table-scope-items">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:apply-templates select="ScopeItems/ScopeItem[@type='Account']" mode="table-cell-account" /></value>
        <value><xsl:value-of select="ScopeItems/ScopeItem[@type='AccountGroup'  ]/@name" separator=", " /></value>
        <value><xsl:value-of select="ScopeItems/ScopeItem[@type='Asset'       ]/@name" separator=", " /></value>
        <value><xsl:value-of select="ScopeItems/ScopeItem[@type='AssetGroup'  ]/@name" separator=", " /></value>
    </row>
 </xsl:template>
 <xsl:template match="ScopeItem" mode="table-cell-account">
     <xsl:value-of select="concat('**', Property[@Name='Account']/Property[@Name='Asset']/Property[@Name='Name'],'**:', @name, '&#10;')" />
 </xsl:template>


<xsl:template match="RequestPolicy">

### Request Policy: <xsl:value-of select="@name" />

    <xsl:apply-templates select="." mode="graphic-overview" />

    <xsl:value-of select="ois:markdown-definition('Name', @name)" />
    <xsl:value-of select="ois:markdown-definition('Type', @type)" />
    <xsl:value-of select="ois:markdown-definition('Priority', Property[@Name='Priority'])" />
    <xsl:value-of select="ois:markdown-definition('Description', Property[@Name='Description'])" />

    <xsl:apply-templates select="Property[@Name='AccessRequestProperties']" mode="def-request-security" />

#### Hourly Restrictions
<xsl:apply-templates select="Property[@Name='HourlyRestrictionProperties']" mode="hourly-restrictions" />

#### Emergency Access
    <xsl:value-of select="ois:markdown-definition('Emergency Access', if (Property[@Name='EmergencyAccessProperties']/Property[@Name='AllowEmergencyAccess'] = 'True') then 'Allowed' else 'Not Allowed')" />

    <xsl:apply-templates select="Property[@Name='RequesterProperties']" mode="def-request-requester" />

    <xsl:apply-templates select="Property[@Name='ApproverSets']" mode="list-approver-sets" />

    <xsl:apply-templates select="ScopeItems" />
</xsl:template>

<xsl:template match="RequestPolicy" mode="graphic-overview">


```plantuml

    !include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

    Component(Ent1, "<xsl:value-of select="../../@name" />", "Entitlement", $tags="SG_Entitlement")

    <xsl:apply-templates select="." mode="graphic" />
    <xsl:variable name="all-approvers">
        <approvers>
            <xsl:apply-templates select="Property[@Name='ApproverSets']" mode="node-ent-approver-sets" />
        </approvers>
    </xsl:variable>

    together {
    <xsl:for-each select="distinct-values($all-approvers/approvers/approver-set/@id)">
        <xsl:variable name="set-id" select="." />
        <xsl:apply-templates select="$all-approvers/approvers/approver-set[@id=$set-id][1]" mode="graphic" />
    </xsl:for-each>
    }


    <xsl:apply-templates select="." mode="graphic-rel" />
```
![Overview of ARP <xsl:value-of select="@name" />](single.png){#fig:ng-overview-request-policy-<xsl:value-of select="@id"/>}
</xsl:template>


<xsl:template match="Property" mode="def-request-security">
#### Security
    <xsl:value-of select="ois:markdown-definition('Simultaneous access', ois:spp-get-simultaneous-sessions-text(.))" />
    <xsl:value-of select="ois:markdown-definition('Change password after check-in', Property[@Name='ChangePasswordAfterCheckin'] )" />
    <xsl:value-of select="ois:markdown-definition('Change SSH key after check-in', Property[@Name='ChangeSshKeyAfterCheckin'] )" />
    <xsl:value-of select="ois:markdown-definition('Terminate expired sessions', Property[@Name='TerminateExpiredSessions'] )" />
    <xsl:value-of select="ois:markdown-definition('Linked accounts are filtered', Property[@Name='LinkedAccountScopeFiltering'] )" />
</xsl:template>
<xsl:function name="ois:spp-get-simultaneous-sessions-text" as="xs:string">
    <xsl:param name="parent"/>                                                                         
    <xsl:value-of select="
        if($parent/Property[@Name='AllowSimultaneousAccess']='True') 
        then concat('Maximum ', $parent/Property[@Name='MaximumSimultaneousReleases'], ' releases')
        else 'Not allowed'" />
</xsl:function>

<xsl:template match="Property" mode="hourly-restrictions">

    <xsl:choose>
        <xsl:when test="Property[@Name='EnableHourlyRestrictions'] = 'True'">

            <xsl:variable name="base" select="." />
            <xsl:variable name="days">
                <day display="Mon">Monday</day>
                <day display="Tue">Tuesday</day>
                <day display="Wed">Wednesday</day>
                <day display="Thu">Thursday</day>
                <day display="Fri">Friday</day>
                <day display="Sat">Saturday</day>
                <day display="Sun">Sunday</day>
            </xsl:variable>

            <xsl:variable name="restrictions">
                <xsl:for-each select="$days/day">
                    <d>
                        <xsl:attribute name="name" select="." />
                        <xsl:attribute name="displayName" select="./@display" />
                        <xsl:variable name="day-prop" select="concat(., 'ValidHours')" />
                        <xsl:for-each select="0 to 23">
                            <xsl:variable name="hour-display" select="
                                    if (number(.) = 0) 
                                    then '12am' 
                                    else 
                                        if (number(.) &lt; 12) 
                                        then concat(., 'am') 
                                        else 
                                            if (number(.) = 12)
                                            then '12pm'
                                            else concat(number(.) - 12, 'pm') " />
                            <h>
                                <xsl:attribute name="hour" select="." />
                                <xsl:attribute name="display" select="$hour-display" />
                                <!-- Allowed vs Restricted -->
                                <xsl:value-of select="if ($base/Property[@Name=$day-prop]/Property/text() = .) then 'A' else 'R'" />
                            </h>
                        </xsl:for-each>
                    </d>
                </xsl:for-each>
            </xsl:variable>
<xsl:text>
</xsl:text>
<svg width="955" height="200">
 <style>
  text {
   font-size: 7pt;
   font-family: Verdana, sans-serif
  }

  rect {
   stroke: black;
   stroke-width: 1px;
  }
 </style>

<xsl:apply-templates select="$restrictions/d" mode="svg-restriction-day" />
<xsl:apply-templates select="$restrictions/d[@name='Monday']" mode="svg-restriction-hour-names" />

</svg>

**Note**: times shown are UTC.
      </xsl:when>
      <xsl:otherwise>No restrictions.</xsl:otherwise>
  </xsl:choose>

 </xsl:template>

 <xsl:template match="d" mode="svg-restriction-day">
     <xsl:variable name="y" as="xs:integer" select="position()*22 + 1" />
     <text x="28" fill="black" style="dominant-baseline: central; text-anchor: end">
         <xsl:attribute name="y" select="$y" />
         <xsl:value-of select="@displayName" />
     </text>
    <xsl:apply-templates select="h" mode="svg-restriction-hour">
        <xsl:with-param name="y" select="$y - 10 " />
    </xsl:apply-templates>
 </xsl:template>
 <xsl:template match="h" mode="svg-restriction-hour">
     <xsl:param name="y" as="xs:integer" />
    <rect width="30" height="20" stroke="black" stroke-width="1">
         <xsl:attribute name="x" select="position()*32" />
         <xsl:attribute name="y" select="$y" />
         <xsl:attribute name="fill" select="if (text() = 'A') then '#77c8b3' else '#40535d'" />
    </rect>
 </xsl:template>

 <xsl:template match="d" mode="svg-restriction-hour-names">
     <xsl:variable name="y" as="xs:integer" select="8*22 + 1" />
    <xsl:apply-templates select="h" mode="svg-restriction-hour-names">
        <xsl:with-param name="y" select="$y + 5 " />
    </xsl:apply-templates>
 </xsl:template>
 <xsl:template match="h" mode="svg-restriction-hour-names">
     <xsl:param name="y" as="xs:integer" />
     <xsl:variable name="x" select="position()*32 + 15" />
    <text fill="black" style="dominant-baseline: bottom; text-anchor: middle">
         <xsl:attribute name="x" select="$x" />
         <xsl:attribute name="y" select="$y" />
         <xsl:value-of select="@display" />
    </text>
 </xsl:template>


<xsl:template match="Property" mode="def-request-requester">
#### Requester 
    <xsl:value-of select="ois:markdown-definition('Requires ticket', Property[@Name='RequireServiceTicket'])" />
    <xsl:value-of select="ois:markdown-definition('Requires comment', Property[@Name='RequireReasonComment'])" />
    <xsl:value-of select="ois:markdown-definition('Requires reason code', Property[@Name='RequireReasonCode'])" />
    <xsl:apply-templates select="." mode="def-request-duration" />
</xsl:template>
<xsl:template match="Property" mode="def-request-duration">
    <xsl:variable name="default-duration" select="ois:spp-get-request-duration(., 'DefaultRelease')" />
    <xsl:variable name="max-duration"     select="ois:spp-get-request-duration(., 'MaximumRelease')" />
    <xsl:choose>
        <xsl:when test="Property[@Name='AllowCustomDuration']='True'">
            <xsl:value-of select="ois:markdown-definition('Default duration', $default-duration)" />
            <xsl:value-of select="ois:markdown-definition('Maximum duration', $max-duration)" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="ois:markdown-definition('Duration', $default-duration)" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:function name="ois:spp-get-request-duration" as="xs:string">
    <xsl:param name="parent"/>                                                                         
    <xsl:param name="prefix" as="xs:string"/> 
    <xsl:variable name="days"    
        select="ois:spp-get-duration-text($parent, concat($prefix,'DurationDays'), 'days')" />
    <xsl:variable name="hours"   
        select="ois:spp-get-duration-text($parent, concat($prefix,'DurationHours'), 'hours')" />
    <xsl:variable name="minutes" 
        select="ois:spp-get-duration-text($parent, concat($prefix,'DurationMinutes'), 'minutes')" />
    <xsl:value-of select="concat($days, ', ', $hours, ', ', $minutes)" />
</xsl:function>
<xsl:function name="ois:spp-get-duration-text" as="xs:string">
    <xsl:param name="parent"/>                                                                         
    <xsl:param name="name" as="xs:string"/> 
    <xsl:param name="label" as="xs:string"/> 
    <xsl:value-of select="concat($parent/Property[@Name=$name], ' ', $label)" />
</xsl:function>


<xsl:template match="Property" mode="list-approver-sets">
    <xsl:if test="count(*) &gt; 0">
#### Approvals
      <xsl:apply-templates select="Property" mode="list-approver-set" />
    </xsl:if>
</xsl:template>
<xsl:template match="Property" mode="list-approver-set">  
   <xsl:apply-templates select="Property[@Name='Approvers']" mode="list-approvers" />
</xsl:template>
<xsl:template match="Property" mode="list-approvers">  
   <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header" select="'Approver set'" />
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="Property" mode="list-item-approver" /> </items>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>
    <xsl:template match="Property" mode="list-item-approver">  
        <value><xsl:value-of select="Property[@Name='DisplayName']" /></value>
    </xsl:template>


    <xsl:template match="ScopeItems">

        <xsl:if test="count(ScopeItem) > 0">
            <xsl:value-of select="ois:markdown-heading-4('Scope')" />

            <xsl:call-template name="ois:generate-markdown-list">
                <xsl:with-param name="header" select="'Objects in scope'" />
                <xsl:with-param name="values">
                    <items> <xsl:apply-templates select="ScopeItem" mode="list-item" /> </items>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>
    <xsl:template match="ScopeItem" mode="list-item">  
      <xsl:choose>
          <xsl:when test="@type = 'Account'">
              <value><xsl:value-of select="concat(
                  '**', Property[@Name='Account']/Property[@Name='Asset']/Property[@Name='Name'],'**:', 
                  @name, 
                  ' (account on ', 
                      Property[@Name='Account']/Property[@Name='Platform']/Property[@Name='DisplayName'], 
                  ')'
              )" /></value>
          </xsl:when>
          <xsl:when test="@type = 'AccountGroup'">
              <value><xsl:value-of select="concat( @name, ' (account group)')" /></value>
          </xsl:when>
          <xsl:when test="@type = 'Asset'" >
              <value><xsl:value-of select="concat(
                  @name, 
                  ' (',  
                      Property[@Name='Asset']/Property[@Name='Platform']/Property[@Name='DisplayName'], 
                  ')'
              )" /></value>
          </xsl:when>
          <xsl:when test="@type = 'AssetGroup'" >
              <value><xsl:value-of select="concat(@name, ' (asset group)')" /></value>
          </xsl:when>
          <xsl:otherwise><value><xsl:value-of select="@name" /></value></xsl:otherwise>
      </xsl:choose>
    </xsl:template>

     <!-- ====== GROUPS ========================= -->
    <xsl:template match="Groups">

        <xsl:apply-templates select="UserGroups" />
        <xsl:apply-templates select="AssetGroups" />
        <xsl:apply-templates select="AccountGroups" />

    </xsl:template>

    <xsl:template match="UserGroups">
        <xsl:if test="count(UserGroup) &gt; 0">
            <xsl:value-of select="ois:markdown-heading-1('User Groups')" />
        </xsl:if>

        <xsl:call-template name="user-group-summary"><xsl:with-param name="groups" select=".." /></xsl:call-template>

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="'Summary of directory-based user groups'" />
            <xsl:with-param name="id" select="'directory-based-user-groups'" />
            <xsl:with-param name="header"   >| Name           | Directory         | Group         | Link Managed Accounts | Authentication Provider | Require Cert Auth |</xsl:with-param>

            <xsl:with-param name="separator">|:---------------|:------------------|:--------------|:------:|:-------------:|:------:|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> 
                    <xsl:apply-templates select="UserGroup[@type = 'ActiveDirectory']" mode="table">
                        <xsl:sort select="@name" order="ascending"/>
                    </xsl:apply-templates> 
                </rows>
            </xsl:with-param>
        </xsl:call-template>


    </xsl:template>
    <xsl:template match="UserGroup" mode="table">
        <row>
            <value><xsl:value-of select="@name" /></value>
            <xsl:apply-templates select="UserGroupObject" mode="table-cells" />
        </row>
    </xsl:template>
    <xsl:template match="UserGroupObject" mode="table-cells">
            <value><xsl:value-of select="Property[@Name='DirectoryProperties']/Property[@Name='DomainName']" /></value>
            <value><xsl:value-of select="Property[@Name='DirectoryProperties']/Property[@Name='DistinguishedName']" /></value>
            <value><xsl:value-of select="Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='LinkDirectoryAccounts']" /></value>
            <value><xsl:value-of select="Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='PrimaryAuthenticationProviderName']" /></value>
            <value><xsl:value-of select="Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='RequireCertificateAuthentication']" /></value>
    </xsl:template>

    <xsl:template match="AssetGroups">
        <xsl:if test="count(AssetGroup) &gt; 0">
            <xsl:value-of select="ois:markdown-heading-1('Asset Groups')" />
        </xsl:if>
        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="'Summary of asset groups'" />
            <xsl:with-param name="id" select="'asset-groups'" />
            <xsl:with-param name="header"   >| Name           | Description              | Matching rule            | Assets | Created By    |</xsl:with-param>
            <xsl:with-param name="separator">|:---------------|:-------------------------|:-------------------------|:------:|:--------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> 
                    <xsl:apply-templates select="AssetGroups/AssetGroup" mode="table">
                        <xsl:sort select="@name" order="descending"/>
                    </xsl:apply-templates> 
                </rows>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="'Asset group memberships'" />
            <xsl:with-param name="id" select="'asset-group-memberships'" />
            <xsl:with-param name="header"   >| Name       | Scope             |</xsl:with-param>
            <xsl:with-param name="separator">|:-----------|:------------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> 
                    <xsl:apply-templates select="AssetGroup[count(Assets/Asset) > 0]" mode="table-group-members">
                        <xsl:sort select="@name" order="ascending"/>
                    </xsl:apply-templates> 
                </rows>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="AssetGroup" mode="table">
        <row>
            <value><xsl:value-of select="@name" /></value>
            <value><xsl:value-of select="AssetGroupObject/Property[@Name='Description']" /></value>
            <value>
                <xsl:choose>
                    <xsl:when test="@isDynamic='True'">
                        <xsl:value-of select="GroupingRule/Property[@Name='AssetGroupingRule']" />
                    </xsl:when>
                    <xsl:otherwise>[static]</xsl:otherwise>
                </xsl:choose>
            </value>
            <value><xsl:value-of select="count(Assets/Asset)" /></value>
            <value><xsl:value-of select="ois:last-modified(AssetGroupObject)" /></value>
        </row>
    </xsl:template>
    <xsl:template match="AssetGroup|AccountGroup" mode="table-group-members">
        <row>
            <value><xsl:value-of select="@name" /></value>
            <value> <xsl:apply-templates select="Assets|Accounts" mode="table-list-with-partition" /> </value>
        </row>
    </xsl:template>
    <xsl:template match="Assets|Accounts" mode="table-list-with-partition">
        <xsl:call-template name="ois:generate-markdown-table-list">
            <xsl:with-param name="values">
                <items>
                    <xsl:apply-templates select="Asset|Account" mode="list-item-with-partition">
                        <xsl:sort select="@name" order="ascending" />
                    </xsl:apply-templates>
                </items>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="Asset" mode="list-item-with-partition">
        <value><xsl:value-of select="concat(Property[@Name='AssetPartitionName'], ' / ', @name)"/></value>
    </xsl:template>

    <xsl:template match="AccountGroups">
        <xsl:if test="count(AccountGroup) &gt; 0">
            <xsl:value-of select="ois:markdown-heading-1('Account Groups')" />
        </xsl:if>

        <xsl:call-template name="account-group-summary"><xsl:with-param name="groups" select=".." /></xsl:call-template>

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="'Account group memberships'" />
            <xsl:with-param name="id" select="'account-group-memberships'" />
            <xsl:with-param name="header"   >| Name       | Scope             |</xsl:with-param>
            <xsl:with-param name="separator">|:-----------|:------------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> 
                    <xsl:apply-templates select="AccountGroup[count(Accounts/Account) > 0]" mode="table-group-members">
                        <xsl:sort select="@name" order="ascending"/>
                    </xsl:apply-templates> 
                </rows>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="Account" mode="list-item-with-partition">
        <value><xsl:value-of select="concat(
            Property[@Name='Asset']/Property[@Name='AssetPartitionName'], 
            ' / ', 
            Property[@Name='Asset']/Property[@Name='Name'], 
            ' / ', 
            @name
        )"/></value>
    </xsl:template>



    <xsl:template match="LinkedAccounts">
        <xsl:if test="count(LinkedAccount) &gt; 0">
            <xsl:value-of select="ois:markdown-heading-1('Linked Accounts')" />
        </xsl:if>

         <xsl:call-template name="ois:generate-table">
             <xsl:with-param name="summary" select="'Summary of directory accounts linked to users'" />
             <xsl:with-param name="id" select="'linked-accounts'" />
             <xsl:with-param name="header"   >| Owner | Account Name | Description | Asset | Password requests? | Session requests? | Last password change |</xsl:with-param>

             <xsl:with-param name="separator">|:-------|:--------|:-----------|:-------|:---:|:---:|</xsl:with-param>
             <xsl:with-param name="values">
                 <rows> 
                     <xsl:apply-templates select="LinkedAccount" mode="table-row">
                         <xsl:sort select="owner" order="ascending"/>
                         <xsl:sort select="accountName" order="ascending"/>
                     </xsl:apply-templates> 
                 </rows>
             </xsl:with-param>
         </xsl:call-template>

    </xsl:template>
    <xsl:template match="LinkedAccount" mode="table-row">
        <row>
            <value><xsl:value-of select="@ownerName" /></value>
            <value><xsl:value-of select="@name" /></value>
            <value><xsl:value-of select="Property[@Name='Description']" /></value>
            <value><xsl:value-of select="@assetName" /></value>
            <value><xsl:value-of select="Property[@Name='RequestProperties']/Property[@Name='AllowPasswordRequest']" /></value>
            <value><xsl:value-of select="Property[@Name='RequestProperties']/Property[@Name='AllowSessionRequest']" /></value>
        </row>
     </xsl:template>


     <!-- ===== platforms ===================================== -->

     <xsl:template match="CustomPlatforms">
         <xsl:if test="Platform">
             <xsl:value-of select="ois:markdown-heading-1('Appendix: Custom Platforms')" />
         </xsl:if>

       <xsl:apply-templates select="Platform" />
     </xsl:template>
     <xsl:template match="Platform">
         <xsl:value-of select="ois:markdown-heading-2(@name)" />
         <xsl:apply-templates select="Script" />
     </xsl:template>


     <xsl:template match="Script">
    ``` <xsl:value-of select="@type" />
    <xsl:value-of select="current()" />
    ```
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


</xsl:stylesheet>
