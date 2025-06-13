<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SPP config export to Markdown

  Author: M Pierson
  Date: Jan 2025
  Version: 0.90

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="no" />

  <xsl:variable name="apos">'</xsl:variable>

 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>

 <xsl:template match="SPP">

---
title: SPP Configuration <xsl:value-of select="@name" /> / <xsl:value-of select="@dnsName" />
author: SPP As Built Generator v0.90
abstract: |
   Configuration of the <xsl:value-of select="@name" /> appliance, exported on <xsl:value-of select="format-dateTime(@checkDate, '[Y0001]-[M01]-[D01]')" />.
---


# Summary

<xsl:call-template name="cluster-summary">
    <xsl:with-param name="node" select="." />
</xsl:call-template>

## Policies

<xsl:call-template name="entitlement-summary"><xsl:with-param name="node" select="." /></xsl:call-template>
<xsl:call-template name="user-group-summary"><xsl:with-param name="groups" select="./Groups" /></xsl:call-template>
<xsl:call-template name="asset-group-summary"><xsl:with-param name="groups" select="./Groups" /></xsl:call-template>
<xsl:call-template name="account-group-summary"><xsl:with-param name="groups" select="./Groups" /></xsl:call-template>


## Partitions

<xsl:call-template name="all-partitions-summary"><xsl:with-param name="partitions" select="Partitions" /></xsl:call-template>


# Appliance Information
         <xsl:apply-templates select="Version" />
         <xsl:apply-templates select="Health" />
         <xsl:apply-templates select="AuthProviders" />
         <xsl:apply-templates select="Administrators" />
         <xsl:apply-templates select="ArchiveServers" />

## Settings
             <xsl:apply-templates select="ApplianceSettings | CoreSettings | PurgeSettings" />



     <xsl:apply-templates select="Entitlements | Groups" />

     <xsl:apply-templates select="Partitions" />

     <xsl:apply-templates select="CustomPlatforms" />
 </xsl:template>
<xsl:template name="cluster-summary">
     <xsl:param name="node" />
```{.plantuml caption="Safeguard environment overview"}

!include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

top to bottom direction

together {

    <xsl:if test="count($node/Cluster/SessionAppliances/SessionNode) > 0">
        Boundary(sps, "SPS cluster") {
            <xsl:for-each select="$node/Cluster/SessionAppliances/SessionNode">
                Component(SPS<xsl:value-of select="Property[@Name='Id']" />, "<xsl:value-of select="Property[@Name='SpsHostName']" /> (<xsl:value-of select="Property[@Name='SpsNetworkAddress']" />)", "session proxy", $tags="SG_SPS")
            </xsl:for-each>
         }
    </xsl:if>

    Boundary(spp, "SPP cluster") {
        <xsl:for-each select="$node/Cluster/Members/Member">
          <xsl:choose>
              <xsl:when test="Property[@Name='IsLeader'] = 'True'"
        >
        Component(<xsl:value-of select="Property[@Name='Name']" />, "<xsl:value-of select="Property[@Name='Name']" /> (<xsl:value-of select="Property[@Name='Ipv4Address']" />)", "primary node", $tags="SG_SPP")
              </xsl:when>
              <xsl:otherwise
        >
        Component(<xsl:value-of select="Property[@Name='Name']" />, "<xsl:value-of select="Property[@Name='Name']" />", "replica node", $tags="SG_SPP")
              </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    }

}

Boundary(admins, "Safeguard administrators") {
  <xsl:for-each select="$node/Administrators/Administrator">
      Person(<xsl:value-of select="@name"/>, "<xsl:value-of select="@name"/>", "<xsl:value-of select="Property[@Name='Description']"/>", $tags="SG_Admin")
  </xsl:for-each>
}


Boundary(int, "Integrated systems") {
    <xsl:for-each select="$node/AuthProviders/AuthProvider[@type != 'Local' and @type != 'Certificate']">
        Component(Auth<xsl:value-of select="@id" />, "<xsl:value-of select="@name" />", "<xsl:value-of select="@type" /> auth provider", $tags="AUTH_<xsl:value-of select="@type" />")
    </xsl:for-each>

    Component(Starling1, "Starling", "Cloud-based services", $tags="SG_Starling")
    Component(Mail1, "oneidentity.demo", "Mail transport", $tags="INTEGRATION", $sprite="email_service,scale=0.7,color=white")
    Component(Syslog, "log.demo", "Syslog destination", $tags="SG_Syslog")

    <xsl:for-each select="$node/ArchiveServers/ArchiveServer">
        Component(ARC<xsl:value-of select="@id" />, "<xsl:value-of select="@name" /> (<xsl:value-of select="@networkAddress" />)", "<xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" /> archive server", $tags="ARCH_<xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" />")
    </xsl:for-each>
}

admins -[hidden]- spp
admins -[hidden]- sps
spp -[hidden]l- sps
spp -[hidden]- int

```
![Safeguard environment overview](single.png){#fig:overview}


</xsl:template>

<xsl:template name="entitlement-summary">
     <xsl:param name="node" />

Table: Summary of entitlements {#tbl:summary-entitlements}

| Name           | Description                   | Priority | Policies | Users | Assets | Accounts | Created By    |
|:---------------|:------------------------------|:--------:|:--------:|:-----:|:------:|:--------:|---------------|
<xsl:for-each select="$node/Entitlements/Entitlement"
      >| **<xsl:value-of select="EntitlementObject/Property[@Name='Name']" 
  />** | <xsl:value-of select="EntitlementObject/Property[@Name='Description']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='Priority']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='PolicyCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='UserCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='AssetCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='AccountCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(EntitlementObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
    /> |
</xsl:for-each>

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

<xsl:template name="asset-group-summary">
     <xsl:param name="groups" />

Table: Summary of asset groups {#tbl:summary-asset-groups-<xsl:value-of select="generate-id()" />}

| Name           | Description              | Matching rule            | Assets | Created By    |
|:---------------|:-------------------------|:-------------------------|:------:|:--------------|
<xsl:for-each select="$groups/AssetGroups/AssetGroup"
    >| **<xsl:value-of select="@name" 
/>** | <xsl:value-of select="AssetGroupObject/Property[@Name='Description']"
  /> | <xsl:choose>
        <xsl:when test="@isDynamic='True'"><xsl:value-of select="GroupingRule/Property[@Name='AssetGroupingRule']" /></xsl:when>
        <xsl:otherwise>[static]</xsl:otherwise>
       </xsl:choose
   > | <xsl:value-of select="count(Assets/Asset)" 
  /> | <xsl:value-of select="AssetGroupObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(AssetGroupObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
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

 <xsl:template match="AuthProviders">

Table: Authentication Providers {#tbl:authentication-providers}

| Name           | Type                                      |
|----------------|-------------------------------------------|
<xsl:apply-templates select="AuthProvider" />
<xsl:text>

</xsl:text>
 </xsl:template>
<xsl:template match="AuthProvider">
     <xsl:text>| </xsl:text> <xsl:value-of select="Property[@Name='Name']" /> <xsl:text> | </xsl:text> <xsl:value-of select="Property[@Name='TypeReferenceName']" /> <xsl:text> |
</xsl:text>
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

<!-- Administrators -->
<xsl:template match="Administrators">

## Administrators


Table: Appliance administrators {#tbl:administrators}

| User name  | Full name                 | Roles            | Identity source | Auth provider | Created | Last login | Disabled |
|:-----------|:--------------------------|:-----------------|------------|-----------|:---------|:--------|:-----:|
<xsl:apply-templates select="Administrator" />
 </xsl:template>
<xsl:template match="Administrator">| **<xsl:value-of select="@name" 
    />** | <xsl:value-of select="Property[@Name='FirstName']"/><xsl:text> </xsl:text><xsl:value-of select="Property[@Name='LastName']" 
      /> | <xsl:value-of select="replace(@adminRoles, ',', ' ')" 
      /> | <xsl:value-of select="Property[@Name='IdentityProvider']/Property[@Name='Name']" 
      /> | <xsl:value-of select="Property[@Name='PrimaryAuthenticationProvider']/Property[@Name='Name']" /><xsl:if test="Property[@Name='SecondaryAuthenticationProvider']/Property[@Name='Name']"> / <xsl:value-of select="Property[@Name='SecondaryAuthenticationProvider']/Property[@Name='Name']"/></xsl:if
       > | <xsl:value-of select="Property[@Name='CreatedByUserDisplayName']" /> (<xsl:value-of select="format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')" /><xsl:text>)</xsl:text
       > | <xsl:if test="string-length(Property[@Name='LastLoginDate']) > 0"><xsl:value-of select="format-dateTime(Property[@Name='LastLoginDate'], '[Y0001]-[M01]-[D01]')" /></xsl:if 
       > | <xsl:value-of select="Property[@Name='Disabled']" 
      /> |
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

    <xsl:call-template name="asset-discovery-summary">
        <xsl:with-param name="partition" select=".." />
    </xsl:call-template>

    <xsl:apply-templates select="Job" />
 </xsl:if>
</xsl:template>
 <!-- account discovery -->
<xsl:template match="AccountDiscoveryJobs">
  <xsl:if test="count(AccountDiscoveryJob) > 0">
### Account Discovery

    <xsl:call-template name="account-discovery-summary">
        <xsl:with-param name="partition" select=".." />
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
    Component(PROFILE<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="@name"/>", "Password profile", $tags="SG_PasswordProfile")
</xsl:for-each>
 }

together {
<xsl:for-each select="$partition/CheckRules/CheckRule">
    Component(CHECK<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="@name"/>", "Password check schedule", $tags="SG_PasswordCheck")
</xsl:for-each>
 }

together {
<xsl:for-each select="$partition/ChangeRules/ChangeRule">
    Component(CHANGE<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="@name"/>", "Password change schedule", $tags="SG_PasswordChange")
</xsl:for-each>
 }

together {
<xsl:for-each select="$partition/PasswordRules/PasswordRule">
    Component(PASSRULE<xsl:value-of select="replace(@id, '-', '_')"/>, "<xsl:value-of select="@name"/>", "Password complexity rule", $tags="SG_PasswordRule")
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
<xsl:template name="asset-discovery-summary">
     <xsl:param name="partition" />

Table: Asset discovery jobs for <xsl:value-of select="$partition/@name" /> {#tbl:asset-discovery-<xsl:value-of select="$partition/@id" />}

| Name              | Type          | Rules             | Description                  |
|-------------------|---------------|-------------------|------------------------------|
<xsl:for-each select="$partition/AssetDiscoveryJobs/Job"
>| <xsl:value-of select="@name" /> | <xsl:value-of select="@type" /> | <xsl:for-each select="Rules/Rule"><xsl:value-of select="@name" /><br /></xsl:for-each> | <xsl:value-of select="JobObject/Property[@Name='Description']" /> | 
</xsl:for-each>
<xsl:text>
</xsl:text>
</xsl:template>
<xsl:template name="account-discovery-summary">
     <xsl:param name="partition" />

Table: Account discovery jobs for <xsl:value-of select="$partition/@name" /> {#tbl:account-discovery-<xsl:value-of select="$partition/@id" />}

| Name              | Description                  |
|:------------------|:-----------------------------|
<xsl:for-each select="$partition/AccountDiscoveryJobs/AccountDiscoveryJob"
>| <xsl:value-of select="@name"
/> | <xsl:value-of select="AccountDiscoveryJobObject/Property[@Name='Description']" 
/> |
</xsl:for-each>
<xsl:text>
</xsl:text>
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

Table: Summary of accounts in partition <xsl:value-of select="$partition/@name"/> {#tbl:all-accounts-<xsl:value-of select="$partition/@id" />}

| Name           | Asset                 | Password profile | Is service account? | Last password change |
|:---------------|:----------------------|:-----------------|:--------:|-----|
<xsl:for-each select="$partition/Assets/Asset/Accounts/Account"
>| <xsl:value-of select="@name"
/> | <xsl:value-of select="../../@name"
/> | <xsl:value-of select="Property[@Name='PasswordProfile']/Property[@Name='EffectiveName']"
/> | <xsl:value-of select="Property[@Name='IsServiceAccount']"
/> | <xsl:choose><xsl:when test="string-length(Property[@Name='TaskProperties']/Property[@Name='LastSuccessPasswordChangeDate']) > 0"><xsl:value-of select="format-dateTime(Property[@Name='TaskProperties']/Property[@Name='LastSuccessPasswordChangeDate'], '[Y0001]-[M01]-[D01]')" /></xsl:when><xsl:otherwise> never </xsl:otherwise></xsl:choose>
<xsl:text>
</xsl:text>
</xsl:for-each>
<xsl:text>

</xsl:text>
 </xsl:template>


 <!-- Asset -->
 <xsl:template match="Asset">
     <xsl:text>#### Asset: </xsl:text> <xsl:value-of select="@name" /> <xsl:text>
</xsl:text>

<xsl:text>

Table: Properties - </xsl:text><xsl:value-of select="@name" /><xsl:text> {#tbl:asset-</xsl:text><xsl:value-of select="@id" /><xsl:text>}

| Name                       | Value                                               |
|----------------------------|-----------------------------------------------------|
</xsl:text>

<!-- all non-empty Property elements without children, i.e. exclude complex props -->
<xsl:apply-templates select="AssetObject/Property[not(./Property) and .!='']" />

<xsl:text>

</xsl:text>


<xsl:if test="count(Owners/Owner) &gt; 0">
Table: Owners of asset <xsl:value-of select="@name" /> {#tbl:asset-owners-<xsl:value-of select="@id" />}

| Name       | Full name                 | Identity source | Type         |
|:-----------|:--------------------------|:----------------|:-------------|
<xsl:apply-templates select="Owners/Owner" />
<xsl:text>

</xsl:text>
</xsl:if>



<xsl:if test="count(Accounts/Account) &gt; 0">
    <xsl:call-template name="asset-account-summary">
        <xsl:with-param name="asset" select="." />
    </xsl:call-template>
</xsl:if>
<xsl:if test="count(Accounts/Account) &lt; 2">
    <xsl:apply-templates select="Accounts/Account" />
</xsl:if>
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

 <xsl:apply-templates select="$rule/Property[@Name != 'Name' and .!='']" />
<xsl:text>

</xsl:text>
 </xsl:template>


 <xsl:template match="Property">
     <xsl:text>| </xsl:text> <xsl:value-of select="@Name" /> <xsl:text> | </xsl:text> <xsl:value-of select="translate(current(), '&#10;&#13;', '')" /> <xsl:text> |
</xsl:text>  
 </xsl:template>



 <!-- ===== Entitlements ========================================== -->

 <xsl:template match="Entitlements">
# Entitlements

Table: Summary of entitlements {#tbl:entitlements}

| Name           | Description                                | Priority | Policies | Users | Assets | Accounts | Created By |
|----------------|--------------------------------------------|:--------:|:--------:|:-----:|:------:|:--------:|--------|
<xsl:for-each select="Entitlement"
    >| <xsl:value-of select="EntitlementObject/Property[@Name='Name']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='Description']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='Priority']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='PolicyCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='UserCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='AssetCount']" 
    /> | <xsl:value-of select="EntitlementObject/Property[@Name='AccountCount']" 
    />| <xsl:value-of select="EntitlementObject/Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(EntitlementObject/Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
    /> |
</xsl:for-each>

<xsl:apply-templates select="Entitlement" />

<xsl:text>

</xsl:text>
</xsl:template>


<xsl:template match="Entitlement">

## <xsl:value-of select="@name" />

 <xsl:call-template name="entitlement-graphic">
  <xsl:with-param name="entitlement" select="." />
 </xsl:call-template>

<xsl:apply-templates select="Members" />
<xsl:apply-templates select="RequestPolicies" />

</xsl:template>

<xsl:template name="entitlement-graphic">
  <xsl:param name="entitlement" />

```plantuml

!include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

 together {
<xsl:for-each select="$entitlement/Members/Member">
 <xsl:call-template name="member-graphic"><xsl:with-param name="member" select="." /></xsl:call-template>
</xsl:for-each>
}

Component(Ent1, "<xsl:value-of select="$entitlement/@name" />", "Entitlement", $tags="SG_Entitlement")

 together {
<xsl:for-each select="$entitlement/RequestPolicies/RequestPolicy">
<xsl:call-template name="policy-graphic"><xsl:with-param name="policy" select="." /></xsl:call-template>
</xsl:for-each>
}

 together {
<xsl:for-each select="$entitlement/RequestPolicies/RequestPolicy/ScopeItems/ScopeItem">
<xsl:call-template name="scope-graphic"><xsl:with-param name="item" select="." /></xsl:call-template>
</xsl:for-each>
}


<xsl:for-each select="$entitlement/Members/Member">
    Rel(Member<xsl:value-of select="@id" />, Ent1, "")
</xsl:for-each>
<xsl:for-each select="$entitlement/RequestPolicies/RequestPolicy">
    Rel(Ent1, ARP<xsl:value-of select="@id"/>, "")
    <xsl:for-each select="ScopeItems/ScopeItem">
        Rel(ARP<xsl:value-of select="../../@id"/>, ITM<xsl:value-of select="@id"/>, "")
    </xsl:for-each>
</xsl:for-each>


```
![Overview of entitlement <xsl:value-of select="$entitlement/@name" />](single.png){#fig:overview-entitlement-<xsl:value-of select="$entitlement/@id"/>}
</xsl:template>
<xsl:template name="member-graphic">
  <xsl:param name="member" />

  <xsl:choose>
      <xsl:when test="$member/@kind = 'Group'"
>

Person(Member<xsl:value-of select="$member/@id"/>, "<xsl:value-of select="$member/@name" />", "User group assigned entitlement", $tags="SG_UserGroup")
</xsl:when>
      <xsl:otherwise
>
Person(Member<xsl:value-of select="$member/@id"/>, "<xsl:value-of select="$member/@name" />", "User assigned to entitlement", $tags="SG_User")
</xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="policy-graphic">
  <xsl:param name="policy" />
  <xsl:choose>
      <xsl:when test="$policy/@type = 'Password'"
>

Component(ARP<xsl:value-of select="$policy/@id"/>, "<xsl:value-of select="$policy/@name" />", "request policy - passwords", $tags="SG_RequestPolicy") 
</xsl:when>
      <xsl:when test="$policy/@type = 'Session'"
>

Component(ARP<xsl:value-of select="$policy/@id"/>, "<xsl:value-of select="$policy/@name" />", "request policy - session", $tags="SG_RequestPolicy") 
</xsl:when>
      <xsl:when test="$policy/@type = 'RemoteDesktop'"
>

Component(ARP<xsl:value-of select="$policy/@id"/>, "<xsl:value-of select="$policy/@name" />", "request policy - remote desktop", $tags="SG_RequestPolicy") 
</xsl:when>
      <xsl:when test="$policy/@type = 'RemoteDesktopApplication'"
>

Component(ARP<xsl:value-of select="$policy/@id"/>, "<xsl:value-of select="$policy/@name" />", "request policy - remote desktop application", $tags="SG_RequestPolicy") 
</xsl:when>
      <xsl:otherwise
>
          MISSING
      <xsl:value-of select="$policy/@type" />
</xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="scope-graphic">
  <xsl:param name="item" />
  <xsl:choose>
      <xsl:when test="$item/@type = 'Account'"
>
Component(ITM<xsl:value-of select="$item/@id"/>, "<xsl:value-of select="$item/@name" />", "account", $tags="SG_Account") 
</xsl:when>
      <xsl:when test="$item/@type = 'AccountGroup'"
>
Component(ITM<xsl:value-of select="$item/@id"/>, "<xsl:value-of select="$item/@name" />", "account group", $tags="SG_AccountGroup") 
</xsl:when>
      <xsl:when test="$item/@type = 'Asset'"
>
Component(ITM<xsl:value-of select="$item/@id"/>, "<xsl:value-of select="$item/@name" />", "asset", $tags="SG_Asset") 
</xsl:when>
      <xsl:when test="$item/@type = 'AssetGroup'"
>
Component(ITM<xsl:value-of select="$item/@id"/>, "<xsl:value-of select="$item/@name" />", "asset group", $tags="SG_AssetGroup") 
</xsl:when>
      <xsl:otherwise
>
          MISSING
      <xsl:value-of select="$item/@type" />
</xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template match="Members">

**Users** in scope:
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


<xsl:if test="count(RequestPolicy) > 0">
Table: Access request policies for entitlement <xsl:value-of select="../@name" /> {#tbl:request-policies-<xsl:value-of select="../@id" />}

| Name          | Description              | Type   | Priority | Accounts | Assets | Account Groups | Asset Groups | Created By |
|:--------------|:-------------------------|--------|:-----:|:-----:|:-----:|:-----:|:----:|---------|
<xsl:for-each select="RequestPolicy"
    >| <xsl:value-of select="Property[@Name='Name']" 
    />| <xsl:value-of select="Property[@Name='Description']" 
    />| <xsl:value-of select="@type" 
    />| <xsl:value-of select="Property[@Name='Priority']" 
    />| <xsl:value-of select="Property[@Name='AccountCount']" 
    />| <xsl:value-of select="Property[@Name='AssetCount']" 
    />| <xsl:value-of select="Property[@Name='AccountGroupCount']" 
    />| <xsl:value-of select="Property[@Name='AssetGroupCount']" 
    />| <xsl:value-of select="Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')"
    /> |
</xsl:for-each>
</xsl:if>


<xsl:if test="count(RequestPolicy/ScopeItems/ScopeItem) > 0">

Table: Scope items for access request policies in <xsl:value-of select="../@name" /> {#tbl:request-policies-scope-<xsl:value-of select="../@id" />}

| Name          | Scope                                     |
|:--------------|:----------------------------------|
<xsl:for-each select="RequestPolicy"
     >| <xsl:value-of select="Property[@Name='Name']" 
    />| <xsl:for-each select="ScopeItems/ScopeItem[@type = 'Account']">**Account**: <xsl:value-of select="@name"/><br /></xsl:for-each
     > <xsl:for-each select="ScopeItems/ScopeItem[@type = 'Asset']">**Asset**: <xsl:value-of select="@name"/><br /></xsl:for-each
     > <xsl:for-each select="ScopeItems/ScopeItem[@type = 'AccountGroup']">**Account group**: <xsl:value-of select="@name"/><br /></xsl:for-each
     > <xsl:for-each select="ScopeItems/ScopeItem[@type = 'AssetGroup']">**Asset group**: <xsl:value-of select="@name"/><br /></xsl:for-each
    > |
</xsl:for-each>
</xsl:if>


    <!-- <xsl:apply-templates select="RequestPolicy" /> -->

<xsl:text>

</xsl:text>
 </xsl:template>


 <xsl:template match="RequestPolicy">

##### Request Policy: <xsl:value-of select="@name" />

**Name**: <xsl:value-of select="@name" />

**Type**: <xsl:value-of select="@type" />

**Description**: <xsl:value-of select="Property[@Name='Description']" />

**Priority**: <xsl:value-of select="Property[@Name='Priority']" />

**Created by**: <xsl:value-of select="Property[@Name='CreatedByUserDisplayName']" /> - <xsl:value-of select="format-dateTime(Property[@Name='CreatedDate'], '[Y0001]-[M01]-[D01]')" />

 <xsl:apply-templates select="ScopeItems" />
</xsl:template>

<xsl:template match="ScopeItems">

<xsl:if test="count(ScopeItem) > 0">

**Accounts and assets** in scope:
    <xsl:for-each select="ScopeItem">
      <xsl:choose>
          <xsl:when test="@type = 'Account'"
>
- <xsl:value-of select="@name" /> (Account)
          </xsl:when>
          <xsl:when test="@type = 'AccountGroup'"
>
- <xsl:value-of select="@name" /> (Account group)
          </xsl:when>
          <xsl:when test="@type = 'Asset'"
>
- <xsl:value-of select="@name" /> (Asset)
          </xsl:when>
          <xsl:when test="@type = 'AssetGroup'"
>
- <xsl:value-of select="@name" /> (Asset group)
          </xsl:when>
          <xsl:otherwise
>
- <xsl:value-of select="@name" />
          </xsl:otherwise>
      </xsl:choose>
     </xsl:for-each>
 </xsl:if>

 </xsl:template>



 <!-- ====== GROUPS ========================= -->
<xsl:template match="Groups">

    <xsl:apply-templates select="UserGroups" />
    <xsl:apply-templates select="AssetGroups" />
    <xsl:apply-templates select="AccountGroups" />

</xsl:template>

<xsl:template match="UserGroups">
<xsl:if test="count(UserGroup) &gt; 0">
# User Groups

<xsl:call-template name="user-group-summary"><xsl:with-param name="groups" select=".." /></xsl:call-template>


Table: Summary of directory-based user groups {#tbl:summary-user-groups-directory}

| Name           | Directory         | Group         | Link Managed Accounts | Authentication Provider | Require Cert Auth |
|:---------------|:------------------|:--------------|:------:|:----------------|:------:|
<xsl:for-each select="UserGroup[@type = 'ActiveDirectory']"
      >| **<xsl:value-of select="@name" 
  />** | <xsl:value-of select="UserGroupObject/Property[@Name='DirectoryProperties']/Property[@Name='DomainName']" 
    /> | <xsl:value-of select="UserGroupObject/Property[@Name='DirectoryProperties']/Property[@Name='DistinguishedName']" 
    /> | <xsl:value-of select="UserGroupObject/Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='LinkDirectoryAccounts']" 
    /> | <xsl:value-of select="UserGroupObject/Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='PrimaryAuthenticationProviderName']" 
    /> | <xsl:value-of select="UserGroupObject/Property[@Name='DirectoryGroupSyncProperties']/Property[@Name='RequireCertificateAuthentication']" 
    /> |
</xsl:for-each>

</xsl:if>

</xsl:template>

<xsl:template match="AssetGroups">
<xsl:if test="count(AssetGroup) &gt; 0">
# Asset Groups

<xsl:call-template name="asset-group-summary"><xsl:with-param name="groups" select=".." /></xsl:call-template>

    <xsl:if test="count(AssetGroup/Assets/Asset) > 0">

Table: Asset group membership {#tbl:asset-groups-members}

| Name                  | Scope                             |
|:----------------------|:----------------------------------|
<xsl:for-each select="AssetGroup[count(Assets/Asset) > 0]"
      >| **<xsl:value-of select="@name" 
  />** | <xsl:for-each select="Assets/Asset"
          ><xsl:value-of select="Property[@Name='AssetPartitionName']"
          /> / <xsl:value-of select="@name"
          /><br /></xsl:for-each
     > |
</xsl:for-each>

    </xsl:if>

</xsl:if>

</xsl:template>

<xsl:template match="AccountGroups">
<xsl:if test="count(AccountGroup) &gt; 0">
# Account Groups

<xsl:call-template name="account-group-summary"><xsl:with-param name="groups" select=".." /></xsl:call-template>

    <xsl:if test="count(AccountGroup/Accounts/Account) > 0">

Table: Account group membership {#tbl:account-groups-members}

| Name                  | Scope                             |
|:----------------------|:----------------------------------|
<xsl:for-each select="AccountGroup[count(Accounts/Account) > 0]"
      >| **<xsl:value-of select="@name" 
      />** | <xsl:for-each select="Accounts/Account"
          ><xsl:value-of select="Property[@Name='Asset']/Property[@Name='AssetPartitionName']"
          /> / <xsl:value-of select="Property[@Name='Asset']/Property[@Name='Name']"
          /> / <xsl:value-of select="@name"
      /><br /></xsl:for-each
     > |
</xsl:for-each>

    </xsl:if>

</xsl:if>

</xsl:template>



 <!-- ===== platforms ===================================== -->

 <xsl:template match="CustomPlatforms">
# Appendix: Custom Platforms

   <xsl:apply-templates select="Platform" />
 </xsl:template>
 <xsl:template match="Platform">
## <xsl:value-of select="@name" />
<xsl:text>

</xsl:text>

   <xsl:apply-templates select="Script" />
 </xsl:template>


 <xsl:template match="Script">
``` <xsl:value-of select="@type" />
<xsl:value-of select="current()" />
```
 </xsl:template>




</xsl:stylesheet>
