<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SSB config export to Markdown

  Author: M Pierson
  Date: Mar 2025
  Version: 0.90

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" 
                              exclude-result-prefixes="ois xs">
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:import href="OIS-JSONLib.xsl" />
  <xsl:import href="OIS-SSBMIBsLib.xsl" />
  <xsl:output omit-xml-declaration="yes" indent="no" />

  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />


 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>

 <xsl:template match="config">

---
title: syslog-ng Store Box Configuration <xsl:value-of select="xcb/networking/hostname" /> / <xsl:value-of select="xcb/networking/domainname" /> 
author: SSB As Built Generator v0.90
abstract: |
   Configuration of the <xsl:value-of select="xcb/networking/hostname" /> appliance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Summary

<xsl:call-template name="component-summary" />

# Appliance

Host name
: <xsl:value-of select="xcb/networking/hostname" /> <xsl:if test="xcb/networking/domainname">[<xsl:value-of select="xcb/networking/domainname" />]</xsl:if>

Version
: <xsl:value-of select="ssb/@major_version" />-<xsl:value-of select="ssb/@minor_version" />

DNS servers
: <xsl:value-of select="xcb/networking/dns/primary" /> <xsl:if test="xcb/networking/dns/secondary">, <xsl:value-of select="xcb/networking/dns/secondary" /></xsl:if><xsl:text>

</xsl:text>

Network interface
: <xsl:call-template name="nic-summary"><xsl:with-param name="nic" select="xcb/networking" /></xsl:call-template><xsl:text>

</xsl:text>




# License

<xsl:variable name="license" select="xcb/license" />
product
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Product</xsl:with-param></xsl:call-template>

version
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Version</xsl:with-param></xsl:call-template>

serial number
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Serial</xsl:with-param></xsl:call-template>

expiry
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Valid-Not-After</xsl:with-param></xsl:call-template>

edition
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Edition</xsl:with-param></xsl:call-template>

type
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">License-Type</xsl:with-param></xsl:call-template>

limit
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Limit</xsl:with-param></xsl:call-template>

options
: <xsl:call-template name="get-license-value"><xsl:with-param name="content" select="$license" /><xsl:with-param name="key">Licensed-Options</xsl:with-param></xsl:call-template>


# Authentication

<xsl:variable name="aaa-configs" select="xcb/aaa/settings" />

auth method
: <xsl:value-of select="$aaa-configs/method/@choice" />

backend
: <xsl:value-of select="$aaa-configs/backend/@choice" /> 
<xsl:call-template name="server-summary"><xsl:with-param name="servers" select="$aaa-configs/backend/servers" /></xsl:call-template>




# Administrators

Table: Summary of SSB local users {#tbl:summary-local-users}

| Username       | Groups      | ACLs                                   |
|:---------------|:------------|:---------------------------------------|
<xsl:variable name="users" select="xcb/aaa/usersgroups/users" />
<xsl:variable name="groups" select="xcb/aaa/usersgroups/groups" />
<xsl:variable name="acls" select="xcb/aaa/acls" />
<xsl:for-each select="$users/user"
      ><xsl:variable name="userId" select="@id"
     />| **<xsl:value-of select="@name" 
  />** | <xsl:value-of select="$groups/group[members/member/@idref=$userId]/@name" separator=", "
     />| <xsl:for-each select="$groups/group[members/member/@idref=$userId]">
         <xsl:variable name="groupName"><xsl:value-of select="@name"/></xsl:variable
         ><xsl:if test="count($acls/acl[@group=$groupName]) > 0"
           >**<xsl:value-of select="$acls/acl[@group=$groupName]/@type" />**: <xsl:for-each select="$acls/acl[@group=$groupName]/objects/object">
             <xsl:value-of select="." /><br 
           /></xsl:for-each
          ></xsl:if
        ></xsl:for-each>|
</xsl:for-each>


# Alerts


## E-mail

<xsl:choose>
    <xsl:when test="xcb/management/mail_hub">

SMTP server
: <xsl:value-of select="xcb/management/mail_hub" />

Send as
: <xsl:value-of select="xcb/management/box_email_address" />

Administrator's address
: <xsl:value-of select="xcb/management/root_email" />

Alerts sent to
: <xsl:value-of select="xcb/management/alert_email" />

Reports sent to
: <xsl:value-of select="xcb/management/report_email" />

    </xsl:when>
    <xsl:otherwise>

E-mail alerts not configured.

    </xsl:otherwise>
</xsl:choose>


## SNMP


## Alert Levels

Table: Summary of monitor alert levels {#tbl:summary-alert-levels}

| Metric       | Alert Level        |
|:-------------|:-------------------|
| Disk utilization | <xsl:value-of select="xcb/alerting/monitoring/monitor[@name='disk']/@percent" />% |
| One minute load | <xsl:value-of select="xcb/alerting/monitoring/monitor[@name='load1']/@maximum" /> |
| Five minute load | <xsl:value-of select="xcb/alerting/monitoring/monitor[@name='load5']/@maximum" /> |
| Fifteen minute load | <xsl:value-of select="xcb/alerting/monitoring/monitor[@name='load15']/@maximum" /> |
| Swap utilization | <xsl:value-of select="xcb/alerting/monitoring/monitor[@name='swap']/@percent" />% |


**Note**:

- The alert message includes the actual disk usage, not the limit set on the web interface.


## Messages

Table: SSB Alerts {#tbl:summary-alerts}

| Alert       | OID     | Description                | Email  | SNMP |
|:------------|:--------|:---------------------------|:---:|:---:|
<xsl:for-each select="xcb/alerting/alerts/alert"
  ><xsl:variable name="notification">
    <xsl:call-template name="ois:get-notification-info">
        <xsl:with-param name="oid" select="@oid" />
    </xsl:call-template>
  </xsl:variable
   >| <xsl:value-of select="$notification/notification/@name"
 /> | <xsl:value-of select="@oid"
 /> | <xsl:value-of select="normalize-space($notification/notification/description)"
 /> | <xsl:value-of select="@email"
 /> | <xsl:value-of select="@snmp"
 /> |
</xsl:for-each>




## SNMP Monitoring

<xsl:choose>
  <xsl:when test="string-length(xcb/monitoring/agent/client_address) = 0">SNMP service disabled
</xsl:when>
<xsl:otherwise>

client
: <xsl:value-of select="xcb/monitoring/agent/client_address" />

<xsl:if test="xcb/monitoring/agent/v2c/@choice='yes'">

V2 options
: community=<xsl:value-of select="xcb/monitoring/agent/v2c/community" />
</xsl:if>
<xsl:if test="xcb/monitoring/agent/v3/@choice='yes'">

V3 options
: user(s)=<xsl:value-of select="xcb/monitoring/agent/v3/users/user/username" separator=", " />
</xsl:if>


</xsl:otherwise>
</xsl:choose>

**Note**:

To have your central monitoring system recognize the SNMP alerts sent by SSB, select **Basic Settings > Monitoring > Download MIBs** to download the SSB-specific Management Information Base (MIB), then import it into your monitoring system.





# Backup and Archive

Table: Summary of backup policies {#tbl:summary-policies-backup}

| Policy        | Times   | Target          | Options                 |
|:--------------|:--------|:----------------|:------------------------|
<xsl:for-each select="xcb/backup_archive/backups/backup"
       >| **<xsl:value-of select="@name" 
   />** | <xsl:value-of select="start_times/start_time" separator=", "
     /> | **<xsl:value-of select="target/@choice" />**<xsl:if test="target/anonymous/@enabled='yes'"> [anonymous]</xsl:if><xsl:choose>
           <xsl:when test="target/@choice='smb'"
              ><br />server: <xsl:value-of select="target/smb_server"
              /><xsl:if test="target/anonymous/@enabled='no'"><br />username: <xsl:value-of select="target/smb_username"/></xsl:if
              ><br />share: <xsl:value-of select="target/share"
          /></xsl:when>
          <xsl:when test="target/@choice='nfs'"
              ><br />server: <xsl:value-of select="target/nfs_server"
              /><br />path: <xsl:value-of select="target/nfs_path"
          /></xsl:when>
        </xsl:choose
      > | notifications: <xsl:value-of select="@notification"
     /> |
</xsl:for-each>

Notes:

- Backup and archive policies only work with existing shares and subdirectories.  If a server has a share at, for example, archive and that directory is empty, when the user configures archive/ssb1 (or similar) as a backup/archive share, it will fail.
- Notifications are sent to the administrator e-mail address set on the Management tab, and include the list of the files that were backed up.


Table: Summary of archive policies {#tbl:summary-policies-archive}

| Policy        | Retention Time | Archive Times   | Target          | Options                 |
|:--------------|:--------:|:-------:|:----------------|:------------------------|
<xsl:for-each select="xcb/backup_archive/archives/archive"
       >| **<xsl:value-of select="@name" 
   />** | <xsl:value-of select="archive_days" separator=", " /><xsl:text> days</xsl:text
      > | <xsl:value-of select="start_times/start_time" separator=", "
     /> | **<xsl:value-of select="target/@choice" />**<xsl:if test="target/anonymous/@enabled='yes'"> [anonymous]</xsl:if><xsl:choose>
           <xsl:when test="target/@choice='smb'"
              ><br />server: <xsl:value-of select="target/smb_server"
              /><xsl:if test="target/anonymous/@enabled='no'"><br />username: <xsl:value-of select="target/smb_username"/></xsl:if
              ><br />share: <xsl:value-of select="target/share"
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

Note:

- Cleanup permanently deletes all log files and data that is older than Retention time in days without creating a backup copy or an archive. Such data is irrecoverably lost. Use this option with care.
- Notifications are sent to the administrator e-mail address set on the Management tab, and include the list of the files that were backed up.


# Sources

Table: Summary of log message sources {#tbl:summary-sources}

| Source        | Type   | Rate Alerts            | Options                     |
|:--------------|:------:|:-----------------------|:----------------------------|
<xsl:for-each select="ssb/sources/source"
        ><xsl:sort select="@enabled" order="descending"
       /><xsl:sort select="@name"    order="ascending"
  />| **<xsl:value-of select="@name" />**<xsl:if test="@enabled='no'"> _[disabled]_</xsl:if
  > | <xsl:value-of select="type/@choice" 
 /> | <xsl:choose>
         <xsl:when test="type/message_rate_alerting/@choice='yes'"
             ><xsl:apply-templates select="type/message_rate_alerting/absolute_limits/limit"
         /></xsl:when>
         <xsl:otherwise>disabled</xsl:otherwise>
       </xsl:choose
  > | <xsl:call-template name="source-options"><xsl:with-param name="source" select="."/></xsl:call-template
  > |
</xsl:for-each>


Notes:

- UDP is a highly unreliable protocol, when using UDP, a large number of messages may be lost without any warning. Use TCP, TLS or ALTP whenever possible.
- If you want to receive messages using the ALTP or ALTP TLS protocol, make sure that you have configured your syslog-ng PE clients to transfer the messages to SSB using ALTP or ALTP TPS protocol. 



# Spaces

Table: Summary of log storage spaces {#tbl:summary-spaces}

| Source           | Storage Options       | Policies       | Alerts         |
|:-----------------|:----------------------|:---------------|:---------------|
<xsl:for-each select="ssb/spaces/space"
       ><xsl:sort select="@name"    order="ascending"
  />| **<xsl:value-of select="@name" />**<xsl:if test="@enabled='no'"> _[disabled]_</xsl:if
       ><br />Template: <xsl:call-template name="file-template-name"><xsl:with-param name="template" select="filename_template/@choice"/></xsl:call-template
       ><br />Disk: <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="disk/@idref"/></xsl:call-template
  > | <xsl:choose>
      <xsl:when test="type/@choice='logstore'"><xsl:call-template name="space-log-store-options"><xsl:with-param name="type" select="type" /></xsl:call-template></xsl:when>
        <xsl:when test="type/@choice='file'"><xsl:call-template name="space-text-file-options"><xsl:with-param name="type" select="type" /></xsl:call-template></xsl:when>
      </xsl:choose
  > | <xsl:call-template name="space-policy-summary"><xsl:with-param name="space" select="."/></xsl:call-template
  > | <xsl:if test="warning_size">**Warning size**:<xsl:value-of select="warning_size"/> GiB</xsl:if
      ><xsl:if test="message_rate_alerting/@choice='yes'"
          ><br/>**Rate**: <xsl:apply-templates select="message_rate_alerting/absolute_limits/limit"
      /></xsl:if
  > |
</xsl:for-each>

<!--  > | <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="disk/@idref"/></xsl:call-template -->

Notes:

- To view encrypted log messages, you will need the private key of this certificate. Encrypted log files can be displayed using the logcat command-line tool as well.
- Use archiving and cleanup policies to remove older logfiles from SSB, otherwise the hard disk of SSB may become full.
- Make sure that the Logspace exceeded warning size alert is enabled in **Basic Settings > Alerting > syslog-ng traps**, and that the mail settings of **Basic Settings > Management**, and the SNMP settings of **Basic Settings > Alerting** are correct. 


# Destinations


Table: Summary of log message destinations {#tbl:summary-destinations}

| Destination  | Type                        | Options           |
|:-------------|:----------------------------|:------------------|
<xsl:for-each select="ssb/destinations/destination"
       ><xsl:sort select="@name"    order="ascending"
  />| **<xsl:value-of select="@name" /><xsl:text>**</xsl:text
  > | <xsl:call-template name="destination-type-options"><xsl:with-param name="destination" select="."/></xsl:call-template
  > | <xsl:if test="message_rate_alerting/@choice='yes'"
             >**Rate alert** <xsl:apply-templates select="message_rate_alerting/absolute_limits/limit"
     /></xsl:if
     ><xsl:if test="frac_digits > 0"
         ><br />**Timestamp sub-second digits**: <xsl:apply-templates select="frac_digits"
     /></xsl:if
     ><xsl:if test="disk_buffer > 0"
     ><br />**Disk buffer size**: <xsl:apply-templates select="disk_buffer"/><xsl:text>MiB</xsl:text
     ></xsl:if
  > |
</xsl:for-each>

<xsl:if test="count(ssb/destinations/destination[string-length(type/log-proto/template) &gt; 0]) &gt; 0">

Table: Log message templates  {#tbl:summary-destinations-templates}

| Destination  | Template                  |
|:-------|:--------------------------------|
<xsl:for-each select="ssb/destinations/destination[string-length(type/log-proto/template) &gt; 0]"
       ><xsl:sort select="@name"    order="ascending"
 />| **<xsl:value-of select="@name" /><xsl:text>**</xsl:text
  >| `<xsl:value-of select="type/log-proto/template" /><xsl:text>`</xsl:text
  >|
</xsl:for-each>

</xsl:if>
<xsl:if test="count(ssb/destinations/destination[type/@choice='sentinel']) &gt; 0">

Table: Sentinel message body scripts  {#tbl:summary-destinations-sentinel-body}

| Destination  | Body Script                   |
|:-------|:------------------------------------|
<xsl:for-each select="ssb/destinations/destination[type/@choice='sentinel']"
       ><xsl:sort select="@name"    order="ascending"
 />| **<xsl:value-of select="@name" /><xsl:text>**</xsl:text
  >| `<xsl:value-of select="type/body" /><xsl:text>`</xsl:text
  >|
</xsl:for-each>

</xsl:if>


Notes:

- Consult the documentation of the remote server application to determine which protocols are supported.  UDP is a highly unreliable protocol and a high amount of messages may be lost without notice during the transfer. Use TCP or TLS instead whenever possible.
- The size of the disk buffer you need depends on the rate of the incoming messages, the size of the messages, and the length of the network outage that you want to cover.
- _Splunk destinations_: If you use more than one workers together with the disk buffer option, syslog-ng PE creates a separate disk buffer file for each worker. As a result, decreasing the number of workers can result in losing data currently stored in the disk buffer files. Do not decrease the number of workers when the disk buffer files are in use. 
- _SQL destinations_: _Flush lines_ is in connection with the _Output memory buffer_ value. (To set the Output memory buffer value, navigate to **Log > Destinations**). The value of _Output memory buffer_ has to be greater than or equal to the value of _Flush lines_.
_ _Sentinel destinations_ Make sure that the customized message format is accepted by Azure Sentinel. For invalid messages, SSB will receive an HTTP 400 response code and messages with such a response code will be dropped.




# Paths

<xsl:call-template name="path-summary" />




<!-- collection of filters, for bookmarking -->
<xsl:variable name="custom-filters">
    <filters>
        <xsl:for-each select="ssb/paths/path/filter">
            <xsl:sort select="../@enabled"    order="ascending" />
            <filter>
                <xsl:attribute name="id"><xsl:value-of select="position()"/></xsl:attribute>
                <xsl:attribute name="pathId"><xsl:value-of select="../@id"/></xsl:attribute>
                <xsl:value-of select="." />
            </filter>
        </xsl:for-each>
    </filters>
</xsl:variable>

Table: Log message paths {#tbl:summary-paths}

| Sources | Filters | Rewrites       | Options  | Destinations |
|:------|:----------|:---------------|:--------|:------|
<xsl:for-each select="ssb/paths/path"
       ><xsl:sort select="@enabled"    order="descending"
       /><xsl:variable name="path-id" select="@id" 
       /><xsl:variable name="path-enabled" select="@enabled" 
   />| **<xsl:if test="count(sources/source) = 0">[none]</xsl:if><xsl:call-template name="get-policy-list"><xsl:with-param name="policies" select="sources"/></xsl:call-template>**<xsl:if test="$path-enabled='no'"> _[disabled]_</xsl:if
   > | <xsl:call-template name="get-path-filters"><xsl:with-param name="path" select="."/></xsl:call-template
   ><xsl:if test="filter"><br />_see custom filter <xsl:value-of select="$custom-filters/filters/filter[@pathId=$path-id]/@id"/> below_</xsl:if
   > | <xsl:call-template name="get-path-rewrites"><xsl:with-param name="path" select="."/></xsl:call-template
   > | <xsl:if test="final/@enabled='yes'">Path is _final_<br/></xsl:if
          ><xsl:if test="flow-control/@enabled='yes'">Flow control enabled<br/></xsl:if
          ><xsl:if test="parser">Message parser: <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="parser/@idref"/></xsl:call-template></xsl:if
   > | **<xsl:if test="count(destinations/destination) = 0">[none]</xsl:if><xsl:call-template name="get-policy-list"><xsl:with-param name="policies" select="destinations"/></xsl:call-template
 >** |
</xsl:for-each>

Notes:

- Note that both default log paths are marked as Final: if you create a new log path that collects logs from the default sources, make sure to adjust the order of the log paths, or disable the Final option for the default log path.
- The _none_ destination discards messages — messages sent only to this destination will be lost irrevocably.
- As a result of toggling the flow-control status of the logpath, the output buffer size of the logpath's destination(s) will change. For the changes to take effect, navigate to **Basic Settings > System > Service control** and click _Restart syslog-ng_.
- The effect of the sender and the host filters is the same if every client sends the logs directly to SSB. But if SSB receives messages from relays, then the host filter applies to the address of the clients, while the sender applies to the address of the relays.
- If multiple filters are set for a log path, only messages complying to every filter are sent to the destinations. (In other words, filters are added using the logical AND operation.)

<xsl:if test="count(ssb/paths/path[filter]) &gt; 0">

Table: Custom path filters  {#tbl:summary-path-custom-filters}

| Filter  | Script                   |
|:---:|:------------------------------------|
<xsl:for-each select="$custom-filters/filters/filter"
        ><xsl:sort select="@id"  data-type="number"   order="ascending"
  />| **<xsl:value-of select="@id" /><xsl:text>**</xsl:text
  > | `<xsl:value-of select="."  disable-output-escaping="yes"
/>` |
</xsl:for-each>

Notes:

- The contents of the Custom filter field are pasted into the filter() parameter of the syslog-ng log path definition.
- By default, custom filters use POSIX-style (extended) regular expressions.
 
</xsl:if>

Table: Key-value parsers  {#tbl:parsers}

| Parser       | Value Separator | Pair Separator | Namespace        |
|:-------------|:--:|:--:|---------|
<xsl:for-each select="ssb/parsers/parser"
       ><xsl:sort select="@name"    order="ascending"
    />| **<xsl:value-of select="@name" /><xsl:text>**</xsl:text
    > | `<xsl:value-of select="type/value_separator"
  />` | `<xsl:value-of select="type/pair_separator"
  />` | <xsl:value-of select="type/namespace"
  /> |
</xsl:for-each>






 </xsl:template>

<!-- ======================================================= -->

 <!-- plantuml of path components -->
 <xsl:template name='path-summary'>
```{.plantuml caption="log message paths"}

!include_many /home/mpierson/projects/quest/SSB/tools/header.puml

'top to bottom direction

Boundary(sources, "Sources") {
     <xsl:for-each select="ssb/sources/source">
         Component(source_<xsl:value-of select="@id" />, "<xsl:value-of select="@name"/>", "<xsl:value-of select="type/@choice"/>", $tags="SSB_Source")
     </xsl:for-each>
     <xsl:for-each select="builtin_objects/source">
         Component(source_<xsl:value-of select="@id" />, "<xsl:value-of select="@name"/>", "built-in", $tags="SSB_Source")
     </xsl:for-each>
}

Boundary(paths, "Paths") {
     <xsl:for-each select="ssb/paths/path[@enabled='yes']">
         <xsl:if test="ois:is-path-active(/config, .)" >
             Component(path_<xsl:value-of select="@id" />, "<xsl:value-of select="substring(@id, 1, 6)"/>", "", $tags="SSB_Path")
         </xsl:if>
     </xsl:for-each>
}

Boundary(spaces, "Local Storage") {
     <xsl:for-each select="ssb/spaces/space">
         Component(dest_<xsl:value-of select="@id" />, "<xsl:value-of select="@name"/>", "filtered", $tags="SSB_Space")
     </xsl:for-each>
}

Boundary(destinations, "Log Destinations") {
     <xsl:for-each select="ssb/destinations/destination">
         Component(dest_<xsl:value-of select="@id" />, "<xsl:value-of select="@name"/>", "filtered", $tags="SSB_Destination")
     </xsl:for-each>
}



 <xsl:for-each select="ssb/paths/path[@enabled='yes']">
     <xsl:if test="ois:is-path-active(/config, .)" >
         <xsl:variable name="path-id">path_<xsl:value-of select="@id"/></xsl:variable>
         <!--  paths from sources -->
         <xsl:for-each select="sources/source">
            <xsl:if test="ois:is-source-active(/config, @idref)">
                 Rel(source_<xsl:value-of select="@idref"/>, <xsl:value-of select="$path-id"/>, "")
              </xsl:if>
         </xsl:for-each>
         <!--  paths to destinations -->
         <xsl:for-each select="destinations/destination">
             <xsl:variable name="dest-id" select="@idref" />
            <xsl:choose>
                <xsl:when test="count(/config/ssb/spaces/space[@id=$dest-id]) > 0">
                    Rel(<xsl:value-of select="$path-id"/>, dest_<xsl:value-of select="$dest-id"/>, "")
                </xsl:when>
                <xsl:when test="count(/config/ssb/destinations/destination[@id=$dest-id]) > 0">
                    Rel(<xsl:value-of select="$path-id"/>, dest_<xsl:value-of select="$dest-id"/>, "")
                </xsl:when>
            </xsl:choose>
         </xsl:for-each>
     </xsl:if>
 </xsl:for-each>



```
![Overview of configured log message paths](single.png){#fig:path-overview}


</xsl:template>

  <!-- Function to check if given path has at least one active source, or none (none == all) -->
  <xsl:function name="ois:is-path-active" as="xs:boolean">
    <xsl:param name="config"/>
    <xsl:param name="path" />
    <xsl:variable name="results">
        <xsl:choose>
            <!-- empty sources indicates ALL sources are connected to path -->
            <xsl:when test="count($path/sources/source) = 0"><result><xsl:value-of select="true()" /></result></xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$path/sources/source">
                    <result><xsl:value-of select="ois:is-source-active($config, @idref)" /></result>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="count($results/result[text()=true()]) > 0" />
  </xsl:function>

  <!-- Function to check if given source, or built-in source is active -->
  <xsl:function name="ois:is-source-active" as="xs:boolean">
    <xsl:param name="config"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:choose>
        <xsl:when test="count($config/builtin_objects/source[@id=$id]) > 0"><xsl:value-of select="true()" /></xsl:when>
        <xsl:when test="count($config/ssb/sources/source[@id=$id and @enabled='yes']) > 0"><xsl:value-of select="true()" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="false()" /></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

 <!-- summarize rewrites assigned to path -->
 <xsl:template name="get-path-rewrites">
   <xsl:param name="path" />
   <xsl:if test="count($path/rewrite_before/rule) > 0">
       <xsl:text>**Before**: </xsl:text><br /><xsl:call-template name="get-path-one-rewrite"><xsl:with-param name="rewrite" select="$path/rewrite_before" /></xsl:call-template><br />
   </xsl:if>
   <xsl:if test="count($path/rewrite_after/rule) > 0">
       <xsl:text>**After**: </xsl:text><br /><xsl:call-template name="get-path-one-rewrite"><xsl:with-param name="rewrite" select="$path/rewrite_after" /></xsl:call-template><br />
   </xsl:if>
 </xsl:template>
 <xsl:template name="get-path-one-rewrite">
   <xsl:param name="rewrite" />
   <xsl:for-each select="$rewrite/rule">
       <xsl:apply-templates select="." /><br/>
   </xsl:for-each>
 </xsl:template>
 <xsl:template match="rule">
     <xsl:if test="message_part and replacement_value">
         <xsl:text>- </xsl:text><xsl:value-of select="message_part" /> `<xsl:value-of select="replacement_value" /><xsl:text>`</xsl:text>
         <xsl:if test="match_case/@enabled='yes'">i</xsl:if>
         <xsl:if test="global/@enabled='yes'">g</xsl:if>
     </xsl:if>
 </xsl:template>



 <!-- summarize filters assigned to path -->
 <xsl:template name="get-path-filters">
   <xsl:param name="path" />
   <xsl:variable name="names">
       <names>
           <n>priority</n>
           <n>facility</n>
           <n>sender</n>
           <n>host</n>
           <n>program</n>
           <n>message</n>
           <n>classifier_class</n>
           <n>classifier_rule_id</n>
       </names>
   </xsl:variable>
   <xsl:variable name="filters">
       <filters>
           <xsl:for-each select="$names/names/n">
               <xsl:call-template name="get-one-filter">
                   <xsl:with-param name="path" select="$path"/>
                   <xsl:with-param name="name" select="."/>
               </xsl:call-template>
           </xsl:for-each>
       </filters>
   </xsl:variable>
   <xsl:for-each select="$filters/filters/filter"
       ><xsl:if test="position() > 1"><br /></xsl:if><xsl:value-of select="."
   /></xsl:for-each>
 </xsl:template>
 <xsl:template name="get-one-filter">
   <xsl:param name="path" />
   <xsl:param name="name" />
   <xsl:variable name="filter"><xsl:value-of select="$path/*[name()=$name]"/></xsl:variable>
   <xsl:if test="string-length($filter) > 0">
       <filter><xsl:value-of select="$name" />: `<xsl:value-of select="$filter" />`</filter>
   </xsl:if>
 </xsl:template>


 <!-- summarize list of policy names -->
 <xsl:template name="get-policy-list">
   <xsl:param name="policies" />
   <xsl:variable name="names">
       <xsl:for-each select="$policies/*">
           <name><xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="@idref"/></xsl:call-template></name>
       </xsl:for-each>
   </xsl:variable>
   <xsl:value-of select="$names/name" separator=",  " />
 </xsl:template>


 <!-- options for destinations -->
 <xsl:template name="destination-type-options">
   <xsl:param name="destination" />
   <xsl:choose>
       <xsl:when test="$destination/type/@choice='remote'"
           ><xsl:call-template name="destination-type-options-remote">
               <xsl:with-param name="type" select="$destination/type"/>
           </xsl:call-template
       ></xsl:when>
       <xsl:when test="$destination/type/@choice='splunk'"
           ><xsl:call-template name="destination-type-options-splunk">
               <xsl:with-param name="type" select="$destination/type"/>
           </xsl:call-template
       ></xsl:when>
       <xsl:when test="$destination/type/@choice='sentinel'"
           ><xsl:call-template name="destination-type-options-sentinel">
               <xsl:with-param name="type" select="$destination/type"/>
           </xsl:call-template
       ></xsl:when>
       <xsl:when test="$destination/type/@choice='sql'"
           ><xsl:call-template name="destination-type-options-sql">
               <xsl:with-param name="type" select="$destination/type"/>
           </xsl:call-template
       ></xsl:when>
       <xsl:when test="$destination/type/@choice='x'"
           ><xsl:call-template name="destination-type-options-remote">
               <xsl:with-param name="type" select="$destination/type"/>
           </xsl:call-template
       ></xsl:when>
   <xsl:otherwise><xsl:value-of select="$destination/type/@choice"/></xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <!-- options for remote destintations -->
 <xsl:template name="destination-type-options-remote">
     <xsl:param name="type" />
     <xsl:text>**Remote host**</xsl:text><br
     /><xsl:value-of select="$type/proto/@choice"/>: <xsl:value-of select="$type/host"/>:<xsl:value-of select="$type/port"/><br 
     /><xsl:text>Message protocol: </xsl:text><xsl:value-of select="$type/log-proto/@choice"
     /><xsl:if test="$type/log-proto/template">, _see template below_</xsl:if
 ></xsl:template>

 <!-- options for splunk destintations -->
 <xsl:template name="destination-type-options-splunk">
     <xsl:param name="type" />
     <xsl:text>**Splunk**</xsl:text><br
     />URL(s): <xsl:value-of select="$type/connection/https_urls/url" separator=", "/><br 
     /><xsl:text>Performance: </xsl:text><xsl:value-of select="$type/workers"/> worker(s), <xsl:value-of select="$type/timeout"/>s timeout, <xsl:value-of select="$type/batch-lines"/><xsl:text> batch lines</xsl:text
 ></xsl:template>

 <!-- options for sentinel destintations -->
 <xsl:template name="destination-type-options-sentinel">
     <xsl:param name="type" />
     <xsl:text>**Sentinel**</xsl:text><br
     />Domain: <xsl:value-of select="$type/domain"/><br 
     />Body def: _see script below_<br 
     /><xsl:text>Performance: </xsl:text><xsl:value-of select="$type/workers"/> worker(s), <xsl:value-of select="$type/timeout"/>s timeout, <xsl:value-of select="$type/batch-lines"/><xsl:text> batch lines</xsl:text
 ></xsl:template>

 <!-- options for sql destintations -->
 <xsl:template name="destination-type-options-sql">
     <xsl:param name="type" />
     <xsl:text>**SQL**</xsl:text><br
     />Connection: <xsl:value-of select="$type/database_type"/>, <xsl:value-of select="$type/host"/>:<xsl:value-of select="$type/port"/>/<xsl:value-of select="$type/database"/><br 
     /><xsl:text>Schema: </xsl:text><xsl:value-of select="$type/schema/@choice"/><br
     /><xsl:text>Data handling: </xsl:text><xsl:value-of select="$type/flush_lines"/> flush lines, <xsl:value-of select="$type/retention"/> days retention, <xsl:value-of select="$type/table/@choice"/><xsl:text> table rotation</xsl:text
 ></xsl:template>













 <!-- summary of policies assigned to log space -->
 <xsl:template name="space-policy-summary">
   <xsl:param name="space" />
   <xsl:variable name="policies">
       <policies>
           <xsl:if test="$space/archive">
               <policy>**Archive**: <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="$space/archive/@idref" /></xsl:call-template></policy>
           </xsl:if>
           <xsl:if test="$space/backup">
               <policy>**Backup**: <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="$space/backup/@idref" /></xsl:call-template></policy>
           </xsl:if>
           <xsl:if test="$space/share">
               <policy>**Sharing**: <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="$space/share/@idref" /></xsl:call-template></policy>
           </xsl:if>
       </policies>
   </xsl:variable>
   <xsl:for-each select="$policies/policies/policy">
       <xsl:if test="position() &gt; 1"><br /></xsl:if>
       <xsl:value-of select="." />
   </xsl:for-each>
 </xsl:template>


 <!-- options for logstore spaces -->
 <xsl:template name="space-log-store-options">
   <xsl:param name="type" />
   <xsl:text>**LogStore**</xsl:text>
   <xsl:if test="$type/compress/@enabled='yes'"> compressed</xsl:if>
   <xsl:if test="$type/encrypt_certificate">  encrypted</xsl:if>
   <br/>**Timestamping frequency**: <xsl:value-of select="$type/timestamp_freq" /><xsl:text> seconds</xsl:text>
   <xsl:if test="$type/indexer/@choice='yes'"><br
       />**Indexer**: <xsl:value-of select="$type/indexer/max_search_results"/> max results, <xsl:value-of select="$type/indexer/memory_limit" /><xsl:text> MiB max. memory</xsl:text
   ></xsl:if>
 </xsl:template>

 <!-- options for text file spaces -->
 <xsl:template name="space-text-file-options">
   <xsl:param name="type" />
   <xsl:text>**Text file**</xsl:text>
 </xsl:template>

 <!-- map of file template names -->
 <xsl:template name="file-template-name">
   <xsl:param name="template" />
   <xsl:choose>
       <xsl:when test="$template = 'onefile'">All messages in one file</xsl:when>
       <xsl:when test="$template = 'host'"   >Per host</xsl:when>
       <xsl:when test="$template = 'application'" >Per application</xsl:when>
       <xsl:otherwise><xsl:value-of select="$template" /></xsl:otherwise>
   </xsl:choose>  
 </xsl:template>






 <!-- format options for sources -->
 <xsl:template name="source-options">
   <xsl:param name="source" />
   <xsl:choose>
       <xsl:when test="$source/type/@choice='syslog'"
           ><xsl:call-template name="source-options-syslog">
               <xsl:with-param name="source" select="$source"/>
           </xsl:call-template
       ></xsl:when>
      <xsl:when test="$source/type/@choice='sql'"
          ><xsl:call-template name="source-options-sql">
              <xsl:with-param name="source" select="$source"/>
          </xsl:call-template
      ></xsl:when>
  </xsl:choose>
 </xsl:template>

 <!-- format options for syslog sources -->
 <xsl:template name="source-options-syslog">
     <xsl:param name="source" />
     <xsl:text>**Listen on**: </xsl:text><xsl:call-template name="get-nic-address"><xsl:with-param name="nicId" select="$source/type/address/@idref"/></xsl:call-template>:<xsl:value-of select="$source/type/port" /><br 
    /><xsl:if test="$source/type/time_zone">**Time zone**: <xsl:value-of select="$source/type/time_zone"/><br /></xsl:if 
     ><xsl:if test="$source/type/hostlist/@idref">**Host list**: <xsl:call-template name="get-policy-name"><xsl:with-param name="policyId" select="$source/type/hostlist/@idref"/></xsl:call-template><br /></xsl:if 
     ><xsl:if test="$source/type/trusted/@enabled='yes'">**Hostnames and timestamps are trusted**<br /></xsl:if 
     ><xsl:choose>
         <xsl:when test="$source/type/type/@choice='udp'" ><xsl:call-template name="source-options-syslog-std"><xsl:with-param name="source-type" select="$source/type/type" /></xsl:call-template></xsl:when>
         <xsl:when test="$source/type/type/@choice='tcp'" ><xsl:call-template name="source-options-syslog-std"><xsl:with-param name="source-type" select="$source/type/type" /></xsl:call-template></xsl:when>
         <xsl:when test="$source/type/type/@choice='tls'" ><xsl:call-template name="source-options-syslog-std"><xsl:with-param name="source-type" select="$source/type/type" /></xsl:call-template></xsl:when>
         <xsl:when test="$source/type/type/@choice='altp'"><xsl:call-template name="source-options-syslog-altp"><xsl:with-param name="source-type" select="$source/type/type" /></xsl:call-template></xsl:when>
         <xsl:otherwise>other</xsl:otherwise>
     </xsl:choose
 ></xsl:template>

<xsl:template name="source-options-syslog-std">
     <xsl:param name="source-type" />
     <xsl:text>**Protocol**: </xsl:text><xsl:value-of select="$source-type/@choice"
     />, <xsl:value-of select="$source-type/log_protocol/@choice" /><xsl:text>format</xsl:text
         ><xsl:if test="$source-type/log_protocol/no_parse = 'yes'"> (no parsing)</xsl:if
     ><xsl:text>, </xsl:text
     >max. <xsl:value-of select="$source-type/max_connections"/><xsl:text> parallel connections</xsl:text
></xsl:template>

<xsl:template name="source-options-syslog-altp">
     <xsl:param name="source-type" />
     <xsl:text>**Protocol**: </xsl:text><xsl:value-of select="$source-type/@choice"
     />, max. <xsl:value-of select="$source-type/max_connections"/><xsl:text> parallel connections</xsl:text
     > <xsl:if test="$source-type/allow_compression/@enabled='yes'">, compressed</xsl:if 
></xsl:template>

 <!-- format options for sql sources -->
 <xsl:template name="source-options-sql">
     <xsl:param name="source" />
     <xsl:text>**</xsl:text><xsl:value-of select="$source/type/database_type"/>**: <xsl:value-of select="$source/type/host" />:<xsl:value-of select="$source/type/port"/>/<xsl:value-of select="$source/type/database" /><br 
     />**query**: `<xsl:value-of select="$source/type/fetch_query"/>`<br
     />**facility**: <xsl:value-of select="$source/type/facility"/><br
     />**severity**: <xsl:value-of select="$source/type/severity"/><br
     />**frequency**: <xsl:value-of select="$source/type/fetch_data_seconds"/><xsl:text> seconds</xsl:text
> </xsl:template>



 <!-- rate monitoring for incoming messages -->
 <xsl:template match="limit"
    >**<xsl:value-of select="counter/@choice"
    />**: <xsl:value-of select="period/@choice" /><xsl:text> minutes, less than </xsl:text
         ><xsl:value-of select="minimum"/> / more than <xsl:value-of select="maximum"
         /><xsl:text>, frequency=</xsl:text><xsl:value-of select="alert/@choice"
         /><xsl:if test="master_alert/@enabled='yes'"> [_master_]</xsl:if
 ></xsl:template>

<xsl:template name="component-summary">

```{.plantuml caption="SSB environment overview"}

!include_many /home/mpierson/projects/quest/SSB/tools/header.puml

top to bottom direction

    Component(ssb, "<xsl:value-of select="xcb/networking/hostname" />", "Syslog appliance", $tags="SG_SSB")

    <xsl:if test="xcb/aaa/settings/backend[@choice='ldap']">
        <xsl:for-each select="xcb/aaa/settings/backend/servers/server">
            Component(ldap_<xsl:value-of select="position()"/>, "<xsl:value-of select="address" />", "Auth directory", $tags="AUTH_ActiveDirectory")
        </xsl:for-each>
    </xsl:if>
    <xsl:if test="xcb/management/mail_hub">
        Component(Mail, "<xsl:value-of select="xcb/management/mail_hub" />", "Mail server", $tags="INTEGRATION",  $sprite="email_service,scale=0.7,color=white")
    </xsl:if>

    Component(ARC, "10.0.0.205", "CIFS archive server", $tags="ARCH_CIFS")


Boundary(admins, "SSB users") {
    <xsl:for-each select="xcb/aaa/usersgroups/users/user">
      Person(<xsl:value-of select="@name"/>, "<xsl:value-of select="@name"/>", "SSB user", $tags="SG_Admin")
  </xsl:for-each>
}

Boundary(destinations, "Log Destinations") {
  <xsl:for-each select="ssb/destinations/destination">
      Component(<xsl:value-of select="@name"/>, "<xsl:value-of select="@name"/>", "<xsl:value-of select="type/@choice"/>", $tags="SSB_Destination")
  </xsl:for-each>
}




admins -[hidden]- ssb
ssb -[hidden]- ARC
ssb -[hidden]- destinations

    <xsl:if test="xcb/management/mail_hub">
        ssb -[hidden]- Mail
    </xsl:if>
    <xsl:if test="xcb/aaa/settings/backend[@choice='ldap']">
        <xsl:for-each select="xcb/aaa/settings/backend/servers/server">
            ssb -[hidden]- ldap_<xsl:value-of select="position()"/>
        </xsl:for-each>
    </xsl:if>

```
![syslog-ng Store Box environment overview](single.png){#fig:overview}


</xsl:template>




<xsl:template name="server-summary">
    <xsl:param name="servers" />
    <xsl:if test="count($servers/server) > 0"
        > [<xsl:for-each select="$servers/server"><xsl:apply-templates select="." />, </xsl:for-each
     >]</xsl:if>
</xsl:template>
<xsl:template match="server">
    <xsl:value-of select="address" />/<xsl:value-of select="port" />
</xsl:template>

<xsl:template name="nic-summary">
    <xsl:param name="nic" />
    <xsl:if test="count($nic/interfaces/interface) = 0">[unused]</xsl:if
     ><xsl:for-each select="$nic/interfaces/interface"><xsl:apply-templates select="." /><br/></xsl:for-each>
</xsl:template>

<xsl:template match="interface">
 <xsl:value-of select="@type"
 />: <xsl:choose>
         <xsl:when test="@enabled='yes'"><xsl:value-of select="addresses/address" separator=", " /></xsl:when>
         <xsl:otherwise>_disabled_</xsl:otherwise>
     </xsl:choose>
 </xsl:template>

<xsl:template match="address">
    <xsl:value-of select="addr" />/<xsl:value-of select="prefix" />
</xsl:template>


<!-- generate network information for this appliance's NICs -->
<xsl:template name="get-SSB-networks">
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



<xsl:template name="get-nic-address">
     <xsl:param name="nicId" />
     <xsl:value-of select="//config/xcb/networking/interfaces/interface/addresses/address[@id = $nicId]/addr" />
</xsl:template>

<xsl:template name="get-license-value">
     <xsl:param name="content" />
     <xsl:param name="key" />
     <!-- look for "key": value, where value may be quoted, and may be followed by delimiters '}' or ',' -->
     <xsl:variable name="regex"><xsl:value-of select="$key" />: (.*?)\n</xsl:variable>
<xsl:analyze-string select="$content" regex="{$regex}">
  <xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
</xsl:analyze-string>
</xsl:template>

<xsl:template name="get-policy-name">
     <xsl:param name="policyId" />
   <xsl:value-of select="//config/xcb/backup_archive/archives/archive[@id = $policyId]/@name"
   /><xsl:value-of select="//config/xcb/backup_archive/backups/backup[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/pol_hostlists/hostlist[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/pol_shares/shares/share[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/disks/disk[@id = $policyId]/@name"
   /><xsl:value-of select="//config/builtin_objects/source[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/sources/source[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/destinations/destination[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/spaces/space[@id = $policyId]/@name"
   /><xsl:value-of select="//config/ssb/parsers/parser[@id = $policyId]/@name"
     />
</xsl:template>

</xsl:stylesheet>
