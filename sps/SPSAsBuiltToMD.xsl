<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SPS config export to Markdown

  Author: M Pierson
  Date: Feb 2025
  Version: 0.90

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:output omit-xml-declaration="yes" indent="no" />

  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />


 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>

 <xsl:template match="config">

---
title: SPS Configuration <xsl:value-of select="xcb/networking/hostname" /> / <xsl:value-of select="xcb/networking/hostname" /> 
author: SPS As Built Generator v0.90
abstract: |
   Configuration of the <xsl:value-of select="xcb/networking/hostname" /> appliance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Summary

<xsl:call-template name="cluster-summary" />

<xsl:call-template name="get-cluster-nodes" />

# Appliance

Host name
: <xsl:value-of select="xcb/networking/hostname" /> <xsl:if test="xcb/networking/domainname">[<xsl:value-of select="xcb/networking/domainname" />]</xsl:if>

Version
: <xsl:value-of select="xcb/@major_version" />-<xsl:value-of select="xcb/@minor_version" />-<xsl:value-of select="xcb/@revision" />

DNS servers
: <xsl:value-of select="xcb/networking/dns/primary" /> <xsl:if test="xcb/networking/dns/secondary">, <xsl:value-of select="xcb/networking/dns/secondary" /></xsl:if><xsl:text>

</xsl:text>

<xsl:value-of select="xcb/networking/nics/nic[1]/@name" />
: <xsl:call-template name="nic-summary"><xsl:with-param name="nic" select="xcb/networking/nics/nic[1]" /></xsl:call-template><xsl:text>

</xsl:text>


<xsl:value-of select="xcb/networking/nics/nic[2]/@name" />
: <xsl:call-template name="nic-summary"><xsl:with-param name="nic" select="xcb/networking/nics/nic[2]" /></xsl:call-template><xsl:text>

</xsl:text>

<xsl:value-of select="xcb/networking/nics/nic[3]/@name" />
: <xsl:call-template name="nic-summary"><xsl:with-param name="nic" select="xcb/networking/nics/nic[3]" /></xsl:call-template><xsl:text>

</xsl:text>

<xsl:value-of select="xcb/networking/nics/nic[4]/@name" />
: <xsl:call-template name="nic-summary"><xsl:with-param name="nic" select="xcb/networking/nics/nic[4]" /></xsl:call-template><xsl:text>

</xsl:text>

<xsl:value-of select="xcb/networking/nics/nic[5]/@name" />
: <xsl:call-template name="nic-summary"><xsl:with-param name="nic" select="xcb/networking/nics/nic[5]" /></xsl:call-template><xsl:text>

</xsl:text>



# License

version
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">product_version</xsl:with-param></xsl:call-template>

serial number
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">serial</xsl:with-param></xsl:call-template>

expiry
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">valid_not_after</xsl:with-param></xsl:call-template>

type
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">limit_type</xsl:with-param></xsl:call-template>

proxies
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">basic_proxies</xsl:with-param></xsl:call-template>

sudo iolog
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">sudo_iolog</xsl:with-param></xsl:call-template>

includes analytics
: <xsl:call-template name="get-json-value"><xsl:with-param name="json"><xsl:value-of select="xcb/license/info" /></xsl:with-param><xsl:with-param name="key">analytics</xsl:with-param></xsl:call-template>


# Services


Table: Summary of SPS services {#tbl:summary-services}

| Service        | Enabled?     | Notes                                   |
|:---------------|:------------:|:----------------------------------------|
| **Local SSH** | <xsl:choose><xsl:when test="xcb/services/ssh/@enabled='yes'">enabled</xsl:when><xsl:otherwise>disabled</xsl:otherwise></xsl:choose> | <xsl:if test="xcb/services/ssh/@enabled = 'yes'"
                        >Brute force protection: <xsl:value-of select="xcb/services/ssh/@bruteforce_protection" /><br
                        />Password auth enabled: <xsl:value-of select="xcb/services/ssh/password_auth" /><br
                        /><xsl:if test="xcb/services/ssh/@restricted ='yes'">restricted to <xsl:value-of select="xcb/services/ssh/allowed_from" /><br /></xsl:if
                         >Network: <xsl:call-template name="get-nic-address-name"><xsl:with-param name="nicId" select="xcb/services/ssh/listen/address/addr/@idref"/></xsl:call-template 
                        >, port <xsl:value-of select="xcb/services/ssh/listen/address/port"
                        /></xsl:if> |
| **Admin HTTPs** | enabled | <xsl:if test="xcb/services/admin_web/@restricted ='yes'">restricted to <xsl:value-of select="xcb/services/admin_web/allowed_from" /><br /></xsl:if
                    >Network: <xsl:call-template name="get-nic-address-name"><xsl:with-param name="nicId" select="xcb/services/admin_web/listen/address/addr/@idref"/></xsl:call-template 
                        >, ports <xsl:value-of select="xcb/services/admin_web/listen/address/http_port"
                    />/<xsl:value-of select="xcb/services/admin_web/listen/address/https_port" /> |
| **User HTTPs** | enabled | <xsl:if test="xcb/services/user_web/@restricted ='yes'">restricted to <xsl:value-of select="xcb/services/user_web/allowed_from" /><br /></xsl:if
                    >Network: <xsl:call-template name="get-nic-address-name"><xsl:with-param name="nicId" select="xcb/services/user_web/listen/address/addr/@idref"/></xsl:call-template 
                        >, ports <xsl:value-of select="xcb/services/user_web/listen/address/http_port"
                        />/<xsl:value-of select="xcb/services/user_web/listen/address/https_port" /> |
| **SNMP server** | <xsl:choose>
    <xsl:when test="xcb/services/snmp/@enabled = 'yes'">enabled | <xsl:if test="xcb/services/snmp/@restricted ='yes'">restricted to <xsl:value-of select="xcb/services/snmp/allowed_from" /><br /></xsl:if
                    >Network: <xsl:call-template name="get-nic-address-name"><xsl:with-param name="nicId" select="xcb/services/snmp/listen/address/addr/@idref"/></xsl:call-template 
                        >, port <xsl:value-of select="xcb/services/snmp/listen/address/port"
                    /></xsl:when>
                <xsl:otherwise>disabled | </xsl:otherwise>
              </xsl:choose> |
| **Indexer** | <xsl:choose>
                    <xsl:when test="xcb/services/indexer/@choice = 'integrated'"
                    >integrated | Workers: <xsl:value-of select="xcb/services/indexer/number_of_workers" /><br 
                    />Near realtime workers: <xsl:value-of select="xcb/services/indexer/number_of_near_realtime_workers"/><br
                    />Remote indexer: <xsl:choose>
                        <xsl:when test="xcb/services/indexer/remote_access/@enabled='yes'"
                        ><xsl:call-template name="get-nic-address-name"><xsl:with-param name="nicId" select="xcb/services/indexer/remote_access/listen/address/addr/@idref"/></xsl:call-template 
                        >, port <xsl:value-of select="xcb/services/indexer/remote_access/listen/address/port"
                       /></xsl:when>
                       <xsl:otherwise>disabled</xsl:otherwise>
                     </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>n/a | n/a</xsl:otherwise>
                </xsl:choose> |
| **Analytics** | <xsl:choose>
                    <xsl:when test="xcb/services/analytics/@enabled='yes'">enabled | </xsl:when>
                    <xsl:otherwise>disabled | </xsl:otherwise
                  ></xsl:choose> |
| **Cluster** | <xsl:choose>
                    <xsl:when test="xcb/services/cluster/@enabled='yes'">enabled | <xsl:call-template name="get-nic-address-name"><xsl:with-param name="nicId" select="xcb/services/cluster/listen/address/addr/@idref"/></xsl:call-template 
                        > | </xsl:when>
                    <xsl:otherwise>disabled | </xsl:otherwise
                  ></xsl:choose> |


# Cluster

Table: Nodes in SPS cluster {#tbl:summary-cluster-nodes}

| Node ID        | Cluster IP Address | Roles |
|:---------------|:--------|:-----------------|
<xsl:for-each select="scb/cluster/nodes/node"
    >| **<xsl:value-of select="@id"
/>** | <xsl:value-of select="address"
  /> | <xsl:value-of select="roles/role/@name" separator=", "
  /> |
</xsl:for-each>


# Administrators

Table: Summary of SPS local users {#tbl:summary-local-users}

| Username       | Groups      | ACLs                                   |
|:---------------|:------------|:---------------------------------------|
<xsl:for-each select="xcb/aaa/usersgroups/users/user"
      ><xsl:variable name="userId"><xsl:value-of select="@id" /></xsl:variable
      >| **<xsl:value-of select="@name" 
      />** | <xsl:value-of select="//config/xcb/aaa/usersgroups/groups/group[members/member/@idref=$userId]/@name" separator=", "
      />| <xsl:for-each select="//config/xcb/aaa/usersgroups/groups/group[members/member/@idref=$userId]">
         <xsl:variable name="groupName"><xsl:value-of select="@name"/></xsl:variable
         ><xsl:if test="count(//config/xcb/aaa/acls/acl[@group=$groupName]/@type) > 0"
           >**<xsl:value-of select="//config/xcb/aaa/acls/acl[@group=$groupName]/@type" />**: <xsl:for-each select="//config/xcb/aaa/acls/acl[@group=$groupName]/objects/object">
             <xsl:value-of select="." /><br 
           /></xsl:for-each
          ></xsl:if
        ></xsl:for-each>|
</xsl:for-each>


# Policies

## Analytics

Table: Summary of analytics policies {#tbl:summary-policies-analytics}

| Name       | Keystroke  | Command  | Login time | Host login | FIS | Window title | Mouse   | Script detect   |
|:-----------|:-----------|:---------|:---------|:---------|:--------|:--------|:--------|:--------|
<xsl:for-each select="scb/pol_analytics/analytics"
    >| **<xsl:value-of select="@name" 
/>** | <xsl:value-of select="scoring/keystroke/@choice"
  /> | <xsl:value-of select="scoring/command/@choice"
  /> | <xsl:value-of select="scoring/logintime/@choice"
  /> | <xsl:value-of select="scoring/hostlogin/@choice"
  /> | <xsl:value-of select="scoring/fis/@choice"
  /> | <xsl:value-of select="scoring/windowtitle/@choice"
  /> | <xsl:value-of select="scoring/mouse/@choice"
  /> | <xsl:choose><xsl:when test="scripted_detection/@enabled='yes'">enabled</xsl:when
        ><xsl:otherwise>disabled</xsl:otherwise></xsl:choose
   > |
</xsl:for-each>

Notes:

- _Disable_: Select this value if you do not want to use a particular algorithm
- _Use_: Select this value if you want to use a particular algorithm
- _Trust_: Select this value if you want to use a particular algorithm, and wish to
include all scores given by this algorithm in the final aggregated score


## Audit

Table: Summary of audit policies {#tbl:summary-policies-audit}

| Name       | Encryption        | Signing         | Timestamp             |
|:-----------|:------------------|:----------------|:----------------------|
<xsl:for-each select="scb/pol_audit/audit"
      >| **<xsl:value-of select="@name" 
  />** | <xsl:choose>
    <xsl:when test="encryption/@enabled='yes'">enabled, <xsl:value-of select="count(encryption/certificate_groups/certificate_group)" /> cert group(s)<xsl:if test="encryption/upstream_encryption/@enabled='yes'"
    ><br /><xsl:value-of select="count(encryption/upstream_encryption/certificate_groups/certificate_group)" /> cert group(s) for upstream</xsl:if></xsl:when>
            <xsl:otherwise>disabled</xsl:otherwise>
        </xsl:choose
     > | <xsl:choose>
            <xsl:when test="signing/@enabled='yes'">enabled, interval = <xsl:value-of select="signing_interval" />sec</xsl:when>
            <xsl:otherwise>disabled</xsl:otherwise>
        </xsl:choose
    >  | <xsl:choose>
            <xsl:when test="timestamping/@enabled='yes'">enabled, <xsl:choose>
                    <xsl:when test="timestamping/server/@choice='remote'">via <xsl:value-of select="timestamping/server/url" /><xsl:if test="string-length(timestamping/server/timestamp_policy) > 0">, OID=<xsl:value-of select="timestamping/server/timestamp_policy" /></xsl:if></xsl:when>
                <xsl:otherwise>local server</xsl:otherwise>
            </xsl:choose></xsl:when>
            <xsl:otherwise>disabled</xsl:otherwise>
        </xsl:choose
     > |
</xsl:for-each>


Notes: 

- Certificates are used as a container and delivery mechanism. For encryption and decryption, only the keys are used. 
- One Identity recommends using 2048-bit RSA keys (or stronger).


## Content

Table: Summary of content policies {#tbl:summary-policies-content}

| Policy     | Rule                 | Actions         | Groups           |
|:-----------|:---------------------|:----------------|:-----------------|
<xsl:for-each select="scb/content_policies/contentpol">
    <xsl:variable name="policy" select="@name" />
    <xsl:for-each select="rules/rule"
    >| **<xsl:value-of select="$policy"
/>** | **<xsl:value-of select="event_type/@choice"
        />** <xsl:if test="count(event_type/match/command) > 0"><br />match: <xsl:value-of select="event_type/match/command/string" separator=", " /></xsl:if
           > <xsl:if test="count(event_type/ignore/command) > 0"><br />ignore: <xsl:value-of select="event_type/ignore/command/string" separator=", "/></xsl:if
   > | <xsl:if test="actions/log/@enabled='yes'">log, </xsl:if
            ><xsl:if test="actions/metadb/@enabled='yes'">store in db, </xsl:if
            ><xsl:if test="actions/notify/@enabled='yes'">notify, </xsl:if
            ><xsl:if test="actions/terminate/@enabled='yes'">terminate</xsl:if
   > | <xsl:if test="count(gateway_groups/group) > 0">**Gateway groups**: <xsl:value-of select="gateway_groups/group" separator=", "/></xsl:if
      ><xsl:if test="count(server_groups/group) > 0"><br/>**Remote groups**: <xsl:value-of select="server_groups/group" separator=", "/></xsl:if
   > |
  </xsl:for-each></xsl:for-each>


Notes:

- Command, credit card and window detection algorithms use heuristics. In certain (rare) situations, they might not match the configured content. In such cases, contact our Support Team to help analyze the problem.
- Real-time content monitoring in graphical protocols is not supported for Arabic and CJK languages.


## Indexing

Table: Summary of indexing policies {#tbl:summary-policies-index}

| Policy     | Commands | Window titles | Screen content | Pointer biometrics | Typing biometrics | OCR options |
|:-----------|:------:|:------:|:------:|:------:|:------:|:--------------|
<xsl:for-each select="scb/pol_indexer/indexer"
       >| **<xsl:value-of select="@name" 
   />** | <xsl:value-of select="index/command/@enabled"
     /> | <xsl:value-of select="index/window_title/@enabled"
     /> | <xsl:value-of select="index/screen_content/@enabled"
     /> | <xsl:value-of select="index/mouse/@enabled"
     /> | <xsl:value-of select="index/keyboard/@enabled"
     /> | <xsl:value-of select="ocr/accuracy"
          /><xsl:if test="ocr/manual_languages/@enabled='yes'"
          ><br />manual languages: <xsl:value-of select="ocr/manual_languages/languages/language" separator=", "/></xsl:if
      > |
</xsl:for-each>

Notes:

- Using content policies significantly slows down connections (approximately 5 times slower), and can also cause performance problems when using the indexer service.
- In the case of graphical protocols, the default Optical Character Recognition (OCR) configuration is automatic language detection. This means that the OCR engine will attempt to detect the languages of the indexed audit trails automatically. However, if you know in advance what language(s) will be used, create a new Indexer Policy.


## Backup and Archive

Table: Summary of backup policies {#tbl:summary-policies-backup}

| Policy     | Times   | Target          | Options                 |
|:-----------|:--------|:----------------|:------------------------|
<xsl:for-each select="xcb/backup_archive/backups/backup"
       >| **<xsl:value-of select="@name" 
   />** | <xsl:value-of select="start_times/start_time" separator=", "
     /> | **<xsl:value-of select="target/@choice" />**<xsl:if test="target/anonymous/@enabled='yes'"> [anonymous]</xsl:if><xsl:choose>
           <xsl:when test="target/@choice='smb'"
              ><br />server: <xsl:value-of select="target/smb_server"
              /><xsl:if test="target/anonymous/@enabled='no'"><br />username: <xsl:value-of select="target/smb_username"/></xsl:if
              ><br />share: <xsl:value-of select="target/share"
              /><br />smb version: <xsl:value-of select="target/protocol_version"
          /></xsl:when>
          <xsl:when test="target/@choice='nfs'"
              ><br />server: <xsl:value-of select="target/nfs_server"
              /><br />path: <xsl:value-of select="target/nfs_path"
          /></xsl:when>
        </xsl:choose
      > | notifications: <xsl:value-of select="@notification"
            /><xsl:if test="include_node_id_in_path/@enabled='yes'"><br />node ID included in path</xsl:if
      > |
</xsl:for-each>


Table: Summary of archive policies {#tbl:summary-policies-archive}

| Policy   | Archive age | Times    | Target        | Options                     |
|:---------|:-----------:|:---------|:--------------|:----------------------------|
<xsl:for-each select="xcb/backup_archive/archives/archive"
      >| **<xsl:value-of select="@name" 
  />** | <xsl:value-of select="archive_days" /><xsl:text> days</xsl:text
   >   | <xsl:value-of select="start_times/start_time" separator=", "
    /> | **<xsl:value-of select="target/@choice" />**<xsl:if test="target/anonymous/@enabled='yes'"> [anonymous]</xsl:if><xsl:choose>
           <xsl:when test="target/@choice='smb'"
              ><br />server: <xsl:value-of select="target/smb_server"
              /><xsl:if test="target/anonymous/@enabled='no'"><br />username: <xsl:value-of select="target/smb_username"/></xsl:if
              ><br />share: <xsl:value-of select="target/share"
              /><br />smb version: <xsl:value-of select="target/protocol_version"
          /></xsl:when>
          <xsl:when test="target/@choice='nfs'"
              ><br />server: <xsl:value-of select="target/nfs_server"
              /><br />path: <xsl:value-of select="target/nfs_path"
          /></xsl:when>
        </xsl:choose
    > | notifications: <xsl:value-of select="@notification"/><xsl:if test="notification_send_filelist='yes'"> (with file list)</xsl:if
        ><br />file template: <xsl:call-template name="backup-file-template-name"><xsl:with-param name="templateId"><xsl:value-of select="template" /></xsl:with-param></xsl:call-template
        ><xsl:if test="include_node_id_in_path/@enabled='yes'"><br />node ID included in path</xsl:if
    > |
</xsl:for-each>



# Proxies

Table: Summary of connection policies {#tbl:summary-policies-connection}

| Policy    | Network             | Indexing | Audit | Analytics | Archive |
|:----------|:--------------------|:-------|:-------|:-------|:-------|
<xsl:for-each select="scb/pol_connections/connections/connection"
     >| **<xsl:value-of select="@name" />** [<xsl:value-of select="../@proto" />]<xsl:if test="@enabled='no'"> (disabled)</xsl:if
    > | **From**: <xsl:for-each select="from/network"><xsl:value-of select="addr" />/<xsl:value-of select="prefix"/>, </xsl:for-each
          ><br />**To**: <xsl:for-each select="to/network"><xsl:value-of select="addr" />/<xsl:value-of select="prefix"/>, </xsl:for-each
          ><br />**Ports**: <xsl:value-of select="ports/port" separator=", "
         /><br />**Target**: <xsl:call-template name="connection-target-summary"><xsl:with-param name="target" select="target"/></xsl:call-template
          ><xsl:if test="target/custom_dns/@enabled='yes'"><br />**Custom DNS**: <xsl:value-of select="target/custom_dns/server"/></xsl:if
    > | <xsl:choose>
          <xsl:when test="indexing/@enabled = 'yes'"
              ><xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="indexing/policy/@idref"/></xsl:call-template><br />priority <xsl:value-of select="indexing/level" 
          /></xsl:when>
          <xsl:otherwise>disabled</xsl:otherwise>
        </xsl:choose
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="audit/@idref"/></xsl:call-template
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="analytics_policy/@idref"/></xsl:call-template
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="archive/@idref"/></xsl:call-template
    > |
</xsl:for-each>

## SSH Proxies

Table: Summary of SSH connection policies {#tbl:summary-policies-connection-secure-shell}

| Policy    | SSH Settings | Channel | Server Host Keys      | Gateway Auth | SPP Capabilities |
|:----------|:---------|:---------|:-------------------------|:-------------|:-------------|
<xsl:for-each select="scb/pol_connections/connections[@proto='ssh']/connection"
     >| **<xsl:value-of select="@name" />** <xsl:if test="@enabled='no'"> (disabled)</xsl:if
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="settings/@idref"/></xsl:call-template
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="channel/@idref"/></xsl:call-template
    > | <xsl:value-of select="server_host_key_plain/server_key_check"
   /> | <xsl:choose>
        <xsl:when test="gwauth/@enabled='yes'">enabled<xsl:if test="gwauth/@sameip='yes'"> (same IP address)</xsl:if
            ><xsl:if test="count(gwauth/groups/group)>0"><br/>**Groups**: <xsl:value-of select="gwauth/groups/group" separator=", "/></xsl:if
        ></xsl:when>
        <xsl:otherwise>disabled</xsl:otherwise>
    </xsl:choose
    > | <xsl:call-template name="spp-options-summary"><xsl:with-param name="capabilities" select="spp_capabilities"/></xsl:call-template
    > |
</xsl:for-each>

Notes:

- When your deployment consists of two or more instances of SPS organized into a cluster, the SSH keys recorded on the Managed Host nodes before they were joined to the cluster are overwritten by the keys on the Central Management node.
- Disabling SSH host key verification makes it impossible for SPS to verify the identity of the server and prevent man-in-the-middle (MITM) attacks.



Table: Summary of SSH settings policies {#tbl:summary-policies-connection-secure-shell-settings}

| Policy | Timeout (s) | Strict Mode | Client Algorithms | Server Algorithms |
|:-------|:----:|:-----:|:----------------------------|:--------------------------------|
<xsl:for-each select="scb/pol_settings/settings[@proto='ssh']/setting"
     >| **<xsl:value-of select="@name" 
 />** | <xsl:value-of select="timeout"/><xsl:if test="inactivity_timeout/@enabled='yes'"
         ><br />User idle timeout: <xsl:value-of select="inactivity_timeout/value"
        /></xsl:if
    > | <xsl:value-of select="strict_mode/@enabled"
   /> | <xsl:call-template name="ssh-algorithm-summary">
            <xsl:with-param name="policy" select="." />
            <xsl:with-param name="type">client</xsl:with-param>
        </xsl:call-template
    > | <xsl:call-template name="ssh-algorithm-summary">
            <xsl:with-param name="policy" select="." />
            <xsl:with-param name="type">server</xsl:with-param>
        </xsl:call-template
    > |
</xsl:for-each>

Notes:

- Determining if a connection is idle is based on the network traffic generated by the connection, not the activity of the user. 
- Do not use the CBC block cipher mode, or the diffie-hellman-group1-sha1 key exchange algorithm.
- Strict mode can interfere with certain client or server applications.   Strict mode is not working with the Windows internal Bash/WSL feature, because it uses a very large terminal window size. Using Windows internal Bash/WSL is not supported.

### Channel Policies

Notes:

- The order of the rules matters. The first matching rule will be applied to the connection. Also, note that you can add the same channel type more than once, to fine-tune the policy.
- Adding more than approximately 1000 remote groups to a channel policy may cause configuration, performance, and authentication issues when connecting to LDAP servers.
- If you list multiple groups, members of any of the groups can access the channel.
- If you do not list any groups, anyone can access the channel.
- If a local user list and an LDAP group has the same name and the LDAP server is configured in the connection that uses this channel policy, both the members of the LDAP group and the members of the local user list can access the channel.
- User lists and LDAP support is currently available only for the SSH and ssh protocols.
- To perform agent-based authentication on the target server, it is not required to enable the Agent-forwarding channel in the Channel Policy used by the connection. The Agent-forwarding channel is needed only to establish connections from the target server to other devices and authenticate using the agent running on the client.
- Certain client applications send the Target address as a hostname, while others as an IP address. If you are using a mix of different client applications, you might have to duplicate the channel rules and create IP-address and hostname versions of the same rule.
- Port forwarding across One Identity Safeguard for Privileged Sessions (SPS) may fail for certain SSH client-server combinations. This happens if within the protocol, the address of the remote host is specified as a hostname during the port-forwarding request (SSH_MSG_GLOBAL_REQUEST), but the hostname is resolved to IP address in the channel opening request (SSH_MSG_CHANNEL_OPEN.  By default, SPS rejects such connections.
- Restricting the commands available in Session Exec channels does not guarantee that no other commands can be executed. Commands can be renamed, or executed from shell scripts to circumvent such restrictions.


<xsl:for-each select="scb/pol_channels/channels[@proto='ssh']/channel">

#### Policy: <xsl:value-of select="@name" />

Table: Summary of rules for channel policy <xsl:value-of select="@name"/> {#tbl:summary-policies-connection-secure-shell-channel-<xsl:value-of select="@name"/>}

| Channel  | Network     | Time Policy | Content Policy | Group Restrictions | Options |
|:---------|:------------|:-------|:--------|:----------|:----------------|
<xsl:if test="count(rules/rule)=0">| _none_ | * |</xsl:if
><xsl:for-each select="rules/rule"
     >| **<xsl:value-of select="details/@choice"
 />** | **From**: <xsl:if test="count(from/network)=0"> * </xsl:if
        ><xsl:value-of select="from/network" separator=", "
        /><br />**Target**: <xsl:if test="count(to/network)=0"> * </xsl:if
        ><xsl:value-of select="to/network" separator=", "
   /> | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="time/@idref"/></xsl:call-template
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="content_policies/@idref"/></xsl:call-template
    > | <xsl:if test="count(remote_groups/group)>0">**Groups**: <xsl:value-of select="remote_groups/group" separator=", " /></xsl:if
    ><xsl:if test="count(gateway_groups/group)>0"><br />**Gateway Groups**: <xsl:value-of select="gateway_groups/group" separator=", " /></xsl:if
    > | <xsl:variable name="options"
            ><xsl:if test="four_eyes/@enabled='yes'"><string>four-eyes authorization</string></xsl:if
            ><xsl:if test="audit/@enabled='yes'"><string>record audit trail</string></xsl:if
            ><xsl:if test="details/log_transfer_details/log_transfer_to_syslog/@enabled='yes'"><string>log transfers to syslog</string></xsl:if
            ><xsl:if test="details/log_transfer_details/log_transfer_to_db/@enabled='yes'"><string>log transfers to db</string></xsl:if
        ></xsl:variable><xsl:value-of select="$options/string" separator=", "
        /><xsl:if test="count(details/x11/network)>0"
            ><br />clients: <xsl:value-of select="details/x11/network" separator=", "
        /></xsl:if
        ><xsl:if test="count(details/directs/direct)>0"
            ><br />forwards: <xsl:for-each select="details/directs/direct"
                ><xsl:value-of select="originator_addr"/> &#8594; <xsl:value-of select="host_addr"/>:<xsl:value-of select="host_port"/><br
            /></xsl:for-each
        ></xsl:if
        ><xsl:if test="count(details/forwardeds/forwarded)>0"
            ><br />forwards: <xsl:for-each select="details/forwardeds/forwarded"
                ><xsl:value-of select="originator_addr"/> &#8594; <xsl:value-of select="connected_addr"/>:<xsl:value-of select="connected_port"/><br
            /></xsl:for-each
        ></xsl:if
   > |
</xsl:for-each>


</xsl:for-each>


## RDP Proxies

Table: Summary of RDP connection policies {#tbl:summary-policies-connection-remote-desktop}

| Policy    | RDP Settings | Channel | TLS                   | Gateway Auth | SPP Capabilities |
|:----------|:---------|:---------|:-------------------------|:-------------|:----------|
<xsl:for-each select="scb/pol_connections/connections[@proto='rdp']/connection"
     >| **<xsl:value-of select="@name" />** <xsl:if test="@enabled='no'"> (disabled)</xsl:if
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="settings/@idref"/></xsl:call-template
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="channel/@idref"/></xsl:call-template
    > | <xsl:call-template name="tls-summary"><xsl:with-param name="tlsNode" select="transport_security"/></xsl:call-template
    > | <xsl:choose>
        <xsl:when test="gwauth/@enabled='yes'">enabled<xsl:if test="gwauth/@sameip='yes'"> (same IP address)</xsl:if
            ><xsl:if test="count(gwauth/groups/group)>0"><br/>**Groups**: <xsl:value-of select="gwauth/groups/group" separator=", "/></xsl:if
        ></xsl:when>
        <xsl:otherwise>disabled</xsl:otherwise>
    </xsl:choose
    > | <xsl:call-template name="spp-options-summary"><xsl:with-param name="capabilities" select="spp_capabilities"/></xsl:call-template
    > |
</xsl:for-each>


Table: Summary of RDP settings policies {#tbl:summary-policies-connection-remote-desktop-settings}

| Policy    | Timeout (s) | Max. Display size (HxWxBpp) | Authentication | TLS |
|:----------|:--------:|:---------:|:-------------------|:-------------------|
<xsl:for-each select="scb/pol_settings/settings[@proto='rdp']/setting"
     >| **<xsl:value-of select="@name" 
 />** | <xsl:value-of select="timeout"/><xsl:if test="inactivity_timeout/@enabled='yes'"
         ><br />User idle timeout: <xsl:value-of select="inactivity_timeout/value"
        /></xsl:if
    > | <xsl:value-of select="max_height"/>x<xsl:value-of select="max_width"/>x<xsl:value-of select="max_bpp"
   /> | **Logon screen**: <xsl:value-of select="authentication_mode/server_screen/@enabled"
        /><br />**NLA**: <xsl:value-of select="authentication_mode/nla/@enabled" /><xsl:if test="authentication_mode/nla/@enabled='yes' and authentication_mode/nla/require_domain/@enabled='yes'"> (domain membership required)</xsl:if
    > | **Client cipher**: <xsl:choose>
        <xsl:when test="client_tls_security_settings/cipher_strength/@choice='custom'">```<xsl:value-of select="client_tls_security_settings/cipher_strength/custom_cipher" />```</xsl:when>
              <xsl:otherwise>SPS recommended</xsl:otherwise>
            </xsl:choose
        ><br />**Client version**: <xsl:value-of select="client_tls_security_settings/minimum_tls_version/@choice"
       /><br />**Server cipher**: <xsl:choose>
        <xsl:when test="server_tls_security_settings/cipher_strength/@choice='custom'">```<xsl:value-of select="server_tls_security_settings/cipher_strength/custom_cipher" />```</xsl:when>
              <xsl:otherwise>SPS recommended</xsl:otherwise>
            </xsl:choose
        ><br />**Server version**: <xsl:value-of select="server_tls_security_settings/minimum_tls_version/@choice"
   /> |
</xsl:for-each>

Notes:

- Determining if a connection is idle is based on the network traffic generated by the connection, not the activity of the user. 
- The Maximum display width and Maximum display height options should be high enough to cover the combined resolution of the client monitor setup. Connections that exceed these limits will automatically fail.
- Using 32-bit color depth is currently not supported: client connections requesting 32-bit color depth automatically revert to 24-bit


### Channel Policies

Notes:

- The order of the rules matters. The first matching rule will be applied to the connection. Also, note that you can add the same channel type more than once, to fine-tune the policy.
- Adding more than approximately 1000 remote groups to a channel policy may cause configuration, performance, and authentication issues when connecting to LDAP servers.
- If you list multiple groups, members of any of the groups can access the channel.
- If you do not list any groups, anyone can access the channel.
- If a local user list and an LDAP group has the same name and the LDAP server is configured in the connection that uses this channel policy, both the members of the LDAP group and the members of the local user list can access the channel.
- User lists and LDAP support is currently available only for the SSH and RDP protocols.


<xsl:for-each select="scb/pol_channels/channels[@proto='rdp']/channel">

#### Policy: <xsl:value-of select="@name" />

Table: Summary of rules for channel policy <xsl:value-of select="@name"/> {#tbl:summary-policies-connection-remote-desktop-channel-<xsl:value-of select="@name"/>}

| Channel | Network    | Time Policy | Content Policy | Group Restrictions | Options |
|:--------|:-----------|:------------|:------------|:------------|:----------|
<xsl:if test="count(rules/rule)=0">| _none_ | * |</xsl:if
><xsl:for-each select="rules/rule"
     >| **<xsl:value-of select="details/@choice"/>**<xsl:if test="details/@choice='custom'"
            ><br /><xsl:value-of select="details/customs/custom" separator=", "
        /></xsl:if
        ><xsl:if test="count(details/rdpdr_devices_with_logging/devices/device)>0"
            ><br /><xsl:value-of select="details/rdpdr_devices_with_logging/devices/device" separator=", "
        /></xsl:if
    > | **From**: <xsl:if test="count(from/network)=0"> * </xsl:if
        ><xsl:value-of select="from/network" separator=", "
        /><br />**Target**: <xsl:if test="count(to/network)=0"> * </xsl:if
        ><xsl:value-of select="to/network" separator=", "
   /> | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="time/@idref"/></xsl:call-template
    > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="content_policies/@idref"/></xsl:call-template
    > | <xsl:if test="count(remote_groups/group)>0">**Groups**: <xsl:value-of select="remote_groups/group" separator=", " /></xsl:if
    ><xsl:if test="count(gateway_groups/group)>0"><br />**Gateway Groups**: <xsl:value-of select="gateway_groups/group" separator=", " /></xsl:if
    > | <xsl:variable name="options"
            ><xsl:if test="four_eyes/@enabled='yes'"><string>four-eyes authorization</string></xsl:if
            ><xsl:if test="audit/@enabled='yes'"><string>record audit trail</string></xsl:if
            ><xsl:if test="details/log_transfer_details/log_transfer_to_syslog/@enabled='yes'"><string>log transfers to syslog</string></xsl:if
            ><xsl:if test="details/log_transfer_details/log_transfer_to_db/@enabled='yes'"><string>log transfers to db</string></xsl:if
            ><xsl:if test="details/rdpdr_devices_with_logging/log_transfer_details/log_transfer_to_syslog/@enabled='yes'"><string>log transfers to syslog</string></xsl:if
            ><xsl:if test="details/rdpdr_devices_with_logging/log_transfer_details/log_transfer_to_db/@enabled='yes'"><string>log transfers to db</string></xsl:if
        ></xsl:variable><xsl:value-of select="$options/string" separator=", "
   /> |
</xsl:for-each>


</xsl:for-each>



<xsl:if test="count(scb/plugins/*/plugin)>0">

# Plugins

To download the official plugins for your product version, navigate to the [product page](https://support.oneidentity.com/one-identity-safeguard-for-privileged-sessions/7.4.0/download-new-releases) on the Support Portal. The official plugins are also available on [GitHub](https://github.com/search?q=topic%3Aoi-sps-plugin+org%3AOneIdentity&amp;type=Repositories). To write your own custom plugin, use our [Plugin SDK](https://oneidentity.github.io/safeguard-sessions-plugin-sdk/latest/).

Table: Summary of SPS plugins {#tbl:summary-plugins}

| Name  | Type  | Version | Description     | Path          |
|:------|:----:|:---:|:---------------|:--------------|
<xsl:for-each select="scb/plugins/*/plugin"
     >| **<xsl:value-of select="@name"
 />** | <xsl:value-of select="../name()"
   /> | <xsl:value-of select="version"
   /> | <xsl:value-of select="description"
   /> | <xsl:value-of select="path"
   /> |
</xsl:for-each>


</xsl:if>

# Appendix A: Generating audit encryption key

```bash

# generate RSA key
openssl genrsa -out sps_audit_enc.key 2048

# generate cert
openssl req -key sps_audit_enc.key -new -x509 -sha256 -out sps_audit_enc.cert

# view generated cert details
openssl x509 -noout -text -in sps_audit_enc.cert


```

# Appendix B: Manage SPS IP address via console



To configure SPS to listen for connections on a custom IP address, complete the following steps:

1. Access SPS from the local console, and log in with username root and password default.
2. Select Shells > Core shell in the Console Menu.
3. Change the IP address of SPS:

    ``` bash
    ifconfig eth0 [IP-address] netmask 255.255.255.0
    ```
    Replace [IP-address] with an IPv4 address suitable for your environment.

4. Set the default gateway using the following command:

    ```bash
    route add default gw [IP-of-default-gateway]
    ```
    Replace [IP-of-default-gateway] with the IP address of the default gateway.

6. Type exit, then select Logout from the Console Menu.


To update the IP address of a configured system, e.g. when moving an appliance to a new network:

1. Find ```/opt/scb/var/db/scb.xml``` via the console, and update the IP address, netmask, and gateway in the _networking_ section.
2. Run ```makeworld -a```.
3. Access the admin portal via the new address and confirm configuration.


 </xsl:template>

 <xsl:template name="ssh-algorithm-summary">
     <xsl:param name="policy" />
     <xsl:param name="type" />
     <xsl:variable name="algos">
         <algo>
             <name>KEX algorithms</name>
             <value><xsl:value-of select="$policy/*[name()=concat($type,'_','kex_algos')]"/></value>
         </algo>
         <algo>
             <name>Cipher algorithms</name>
             <value><xsl:value-of select="$policy/*[name()=concat($type,'_','cipher_algos')]"/></value>
         </algo>
         <algo>
             <name>MAC algorithms</name>
             <value><xsl:value-of select="$policy/*[name()=concat($type,'_','mac_algos')]"/></value>
         </algo>
         <algo>
             <name>Compression algorithms</name>
             <value><xsl:value-of select="$policy/*[name()=concat($type,'_','comp_algos')]"/></value>
         </algo>
         <algo>
             <name>Host key algorithms</name>
             <value><xsl:value-of select="$policy/*[name()=concat($type,'_','hostkey_algos')]"/></value>
         </algo>
     </xsl:variable>
     <xsl:for-each select="$algos/algo">**<xsl:value-of select="name" />**: <xsl:value-of select="value" /><br /></xsl:for-each>
 </xsl:template>

 <xsl:template name="spp-options-summary">
     <xsl:param name="capabilities" />
     <xsl:variable name="options"
         ><xsl:if test="$capabilities/spp_init/@enabled='yes'"><string>**SPP** initiated sessions</string></xsl:if
         ><xsl:if test="$capabilities/sps_init/@enabled='yes'"><string>**SPS** initiated sessions</string></xsl:if
     ></xsl:variable>
     <xsl:value-of select="$options/string" separator=", " />
 </xsl:template>

<xsl:template name="tls-summary">
    <xsl:param name="tlsNode" />
    <xsl:text>**Type**: </xsl:text><xsl:value-of select="$tlsNode/@choice"
    /><xsl:if test="$tlsNode/@choice='tls'"
        ><br/>**Certificate**: <xsl:choose>
            <xsl:when test="$tlsNode/certificate/@choice = 'generate'">Generate on the fly with <xsl:call-template name="get-certificate-name"><xsl:with-param name="id" select="$tlsNode/certificate/signing_ca/@idref" /></xsl:call-template></xsl:when>
            <xsl:when test="$tlsNode/certificate/@choice = 'self_signed'">Self-signed</xsl:when>
            <xsl:when test="$tlsNode/certificate/@choice = 'fix'">Same certificate for each connection</xsl:when>
        </xsl:choose
        ><br/>**Server validation**: <xsl:choose>
            <xsl:when test="$tlsNode/server_certificate_check/@choice = 'no'">none</xsl:when>
            <xsl:when test="$tlsNode/server_certificate_check/@choice = 'yes'">via <xsl:call-template name="get-ca-certificate-name"><xsl:with-param name="id" select="$tlsNode/server_certificate_check/trusted_ca/@idref" /></xsl:call-template></xsl:when>
        </xsl:choose
        ><br/>**Allow fallback to legacy RDP**: <xsl:value-of select="$tlsNode/legacy_fallback/@enabled"
      /></xsl:if>
</xsl:template>

<xsl:template name="nic-summary">
    <xsl:param name="nic" />
    <xsl:if test="count($nic/interfaces/interface) = 0">[unused]</xsl:if
     ><xsl:for-each select="$nic/interfaces/interface"><xsl:apply-templates select="." /><br/></xsl:for-each>
</xsl:template>

<xsl:template name="backup-file-template-name">
    <xsl:param name="templateId" />
    <xsl:choose>
        <xsl:when test="$templateId = 1">PROTOCOL / CONNECTION / ARCHIVE DATE /</xsl:when>
        <xsl:when test="$templateId = 2">ARCHIVE DATE / PROTOCOL / CONNECTION /</xsl:when>
        <xsl:when test="$templateId = 3">CONNECTION DATE / PROTOCOL / CONNECTION /</xsl:when>
        <xsl:when test="$templateId = 4">ARCHIVE DATE /</xsl:when>
        <xsl:when test="$templateId = 5">CONNECTION DATE /</xsl:when>
        <xsl:otherwise>{$templateId}</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="connection-target-summary">
    <xsl:param name="target" />
    <xsl:call-template name="connection-target-select-description"><xsl:with-param name="name" select="$target/@choice" /></xsl:call-template
    ><xsl:choose>
        <xsl:when test="$target/@choice = 'transparent'"></xsl:when><!-- no extra config required -->
        <xsl:when test="$target/@choice = 'nat'"        > <xsl:value-of select="$target/network/addr" />/<xsl:value-of select="$target/network/prefix"/></xsl:when>
        <xsl:when test="$target/@choice = 'direct'"     > <xsl:value-of select="$target/ip" />:<xsl:value-of select="$target/port"/></xsl:when>
        <xsl:when test="$target/@choice = 'inband'"     > [<xsl:for-each select="$target/domains/domain"
            ><xsl:value-of select="@port"/>:```<xsl:value-of select="." />```, </xsl:for-each
            >]<xsl:if test="count($target/exception_domains/domain)"><br />  exceptions [<xsl:for-each select="$target/exception_domains/domain"
                    ><xsl:value-of select="@port"/>:```<xsl:value-of select="." />```, </xsl:for-each
            >]</xsl:if
        ></xsl:when>
    </xsl:choose>
</xsl:template>
<xsl:template name="connection-target-select-description">
    <xsl:param name="name" />
    <xsl:choose>
        <xsl:when test="$name = 'transparent'">Use original target address of the client</xsl:when>
        <xsl:when test="$name = 'nat'"        >NAT destination address</xsl:when>
        <xsl:when test="$name = 'direct'"     >Use fixed address</xsl:when>
        <xsl:when test="$name = 'inband'"     >Inband destination selection</xsl:when>
        <xsl:otherwise>{$selectName}</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="interface">
 <xsl:if test="string-length(vlantag) > 0">[vlan:<xsl:value-of select="vlantag"/>] </xsl:if><xsl:value-of select="@name"
 />: <xsl:value-of select="addresses/address" separator=", " />
 </xsl:template>

<xsl:template match="address">
    <xsl:value-of select="addr" />/<xsl:value-of select="prefix" />
</xsl:template>


<!-- generate network information for this appliance's NICs -->
<xsl:template name="get-sps-networks">
    <networks>
        <xsl:for-each select="/config/xcb/networking/nics/nic/interfaces/interface/addresses/address[@family='ipv4']">

            <!-- convert net cidr to binary mask -->
            <xsl:variable name="mask-int" select="ois:cidr-to-mask-int(xs:integer(prefix))" as="xs:integer" />
            <xsl:variable name="network-mask" select="ois:pad-left(ois:integer-to-binary($mask-int), 16)" />
            <xsl:variable name="ip-bits" select="ois:pad-left(ois:integer-to-binary(ois:ip-to-int(addr)), 32)" />
            <xsl:variable name="net-def" select="ois:binary-and($ip-bits, $network-mask)" />

            <network family="{@family}" ip="{addr}" raw-mask="{prefix}" netmask="{$network-mask}" pattern="{$net-def}">
                <ip raw="{addr}" binary="{$ip-bits}">
                    <xsl:for-each select="tokenize(addr, '\.')">
                        <octet id="{position()}">
                            <xsl:attribute name="decimal" select="."/>
                            <xsl:value-of select="ois:pad-left(ois:integer-to-binary(xs:integer(.)), 8)" />
                        </octet>
                    </xsl:for-each>
                </ip>
            </network>
        </xsl:for-each>
    </networks>
</xsl:template>

<!-- reduce to unique networks -->
<xsl:template name="reduce-networks">
    <xsl:param name="networks" />
    <networks>
        <xsl:for-each-group select="$networks/networks/network[@family='ipv4']" group-by="@pattern">
            <xsl:variable name="first" select="current-group()[1]" />
            <network family="{$first/@family}" ip="{$first/@ip}" raw-mask="{$first/@raw-mask}" netmask="{$first/@netmask}" pattern="{@pattern}" count="{count(current-group())}" />
        </xsl:for-each-group>
    </networks>
</xsl:template>


<!-- generate cluster information -->
<xsl:template name="get-cluster-nodes">
    <xsl:variable name="cluster-interface" select="/config/xcb/services/cluster/listen/address/addr/@idref" />
    <xsl:variable name="current-appliance-ip" select="/config/xcb/networking/nics/nic/interfaces/interface/addresses/address[@id=$cluster-interface]/addr" />
    <nodes>
        <xsl:for-each select="/config/scb/cluster/nodes/node">
            <node>
                <xsl:attribute name="isCurrentAppliance" select="address = $current-appliance-ip" />
                <xsl:attribute name="id" select="@id" />
                <xsl:attribute name="ip" select="address" />
                <xsl:attribute name="ip-bits" select="ois:pad-left(ois:integer-to-binary(ois:ip-to-int(address)), 32)" />
                <xsl:copy-of select="roles" />
            </node>
        </xsl:for-each>
    </nodes>
</xsl:template>


<xsl:template name="cluster-summary">
    <xsl:variable name="spp-ips"> <xsl:call-template name="get-sps-networks" /> </xsl:variable>
    <xsl:variable name="networks">
        <xsl:call-template name="reduce-networks"> <xsl:with-param name="networks" select="$spp-ips"/> </xsl:call-template>
    </xsl:variable>
    <xsl:variable name='sps-name' select="/config/xcb/networking/hostname" />
    <xsl:variable name='sps-full-name' select="concat($sps-name, '.', /config/xcb/networking/domainname)" />
    <xsl:variable name="cluster-ips"> <xsl:call-template name="get-cluster-nodes" /> </xsl:variable>
    <xsl:variable name='sps-roles' select="$cluster-ips/nodes/node[@isCurrentAppliance='true']/roles/role" />

    <xsl:variable name="spp-node" select="/config/scb/spp" />

    <xsl:variable name="icon-sps"><![CDATA[ <$ICON_SPS*0.5> ]]></xsl:variable>

```{.plantuml caption="Safeguard environment overview"}
<xsl:text disable-output-escaping="yes"><![CDATA[<style file=/home/mpierson/.config/plantuml/PlantUML-Network.css>]]></xsl:text>
!include /home/mpierson/.config/plantuml/ICON_SPP.sprite
!include /home/mpierson/.config/plantuml/ICON_SPS.sprite

nwdiag {

    <xsl:for-each select="$networks/networks/network[@family='ipv4']">
        <xsl:variable name='net-pattern' select="@pattern"/>

network Network_<xsl:value-of select="position()"/> {
address = "<xsl:value-of select="@ip" />/<xsl:value-of select="@raw-mask" />"

    <!-- network info for this appliance -->
    <xsl:for-each select="$spp-ips/networks/network[@pattern=$net-pattern]">
        <xsl:value-of select="$sps-name"/> [address="<xsl:value-of select="@ip" />", shape = label, description = "<xsl:text disable-output-escaping="yes"><![CDATA[<$ICON_SPS*0.4>]]></xsl:text>\n\ncurrent node"];
    </xsl:for-each>
    <!-- network info for other SPS nodes -->
    <xsl:for-each select="$cluster-ips/nodes/node[@isCurrentAppliance='false']">
        <xsl:if test="ois:is-ip-in-network(@ip, $net-pattern)">
            OtherSPS_<xsl:value-of select="position()"/> [address="<xsl:value-of select="@ip" />", shape = label, description = "<xsl:text disable-output-escaping="yes"><![CDATA[<$ICON_SPS*0.4>]]></xsl:text>\n\n   SPS node"];
        </xsl:if>
    </xsl:for-each>
    <!-- network info for SPP cluster -->
    <xsl:for-each select="$spp-node">
        <xsl:if test="ois:is-ip-in-network(ip_address, $net-pattern)">
            SPP_Cluster_<xsl:value-of select="position()"/> [address="<xsl:value-of select="ip_address" />", shape = label, description = "<xsl:text disable-output-escaping="yes"><![CDATA[<$ICON_SPP*0.4>]]></xsl:text>\n\n   SPP cluster"];
        </xsl:if>
    </xsl:for-each>
  }

</xsl:for-each>
}


```
![Safeguard network environment overview](single.png){#fig:network-overview}


</xsl:template>


<xsl:template name="get-nic-address-name">
     <xsl:param name="nicId" />
     <xsl:value-of select="//config/xcb/networking/nics/nic/interfaces/interface[addresses/address/@id = $nicId]/@name" 
     />/<xsl:value-of select="//config/xcb/networking/nics/nic/interfaces/interface/addresses/address[@id = $nicId]/addr" />
</xsl:template>

<xsl:template name="get-policy-name">
     <xsl:param name="policyId" />
     <xsl:value-of select="//config/scb/pol_indexer/indexer[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_audit/audit[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_analytics/analytics[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/xcb/backup_archive/archives/archive[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/xcb/backup_archive/backups/backup[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_settings/settings/setting[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_channels/channels/channel[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_signingca/ca[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_trustedca/ca_list[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/pol_times/time[@id = $policyId]/@name" 
   /><xsl:value-of select="//config/scb/content_policies/contentpol[@id = $policyId]/@name" 
     />
</xsl:template>

<xsl:template name="get-certificate-name">
     <xsl:param name="id" />
     <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="$id"/></xsl:call-template>
</xsl:template>

<xsl:template name="get-ca-certificate-name">
     <xsl:param name="id" />
     <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="$id"/></xsl:call-template>
</xsl:template>

<xsl:template name="get-json-value">
     <xsl:param name="json" />
     <xsl:param name="key" />
     <!-- look for "key": value, where value may be quoted, and may be followed by delimiters '}' or ',' -->
     <xsl:variable name="regex"><xsl:value-of select="$key" />&quot;: &quot;?([^&quot;}]*?)[&quot;,\}]</xsl:variable>
<xsl:analyze-string select="$json" regex="{$regex}">
  <xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
</xsl:analyze-string>
</xsl:template>



</xsl:stylesheet>
