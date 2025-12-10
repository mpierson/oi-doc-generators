<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SPS config export to Markdown

  Author: M Pierson
  Date: Feb 2025
  Version: 0.91

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

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

  <xsl:output omit-xml-declaration="yes" indent="no" method="text"  />

  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />

  <xsl:param name="ext-project">
      <project/>
  </xsl:param>

 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>

 <xsl:template match="config">

---
title: SPS Configuration <xsl:value-of select="xcb/networking/hostname" /> / <xsl:value-of select="xcb/networking/hostname" /> 
author: SPS As Built Generator v0.91
abstract: |
   Configuration of the <xsl:value-of select="xcb/networking/hostname" /> appliance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Summary

    <xsl:apply-templates select="$ext-project/project" />
    <xsl:call-template name="cluster-summary" />
    <xsl:apply-templates select="$ext-project/project/environments" />

     <!-- <xsl:call-template name="get-cluster-nodes" /> -->

<xsl:apply-templates select="xcb" />
<xsl:apply-templates select="scb" />


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


<!-- ============================================== -->
<!-- ============================================== -->

<!-- software configs -->
<xsl:template match="scb">
    <xsl:apply-templates select="cluster"/>

# Policies
    <xsl:apply-templates select="pol_analytics"/>
    <xsl:apply-templates select="pol_audit"/>
    <xsl:apply-templates select="content_policies"/>
    <xsl:apply-templates select="pol_indexer"/>

    <xsl:apply-templates select="pol_connections"/>

    <xsl:apply-templates select="plugins"/>


</xsl:template>

<xsl:template match="cluster">
# Cluster
    <xsl:apply-templates select="nodes"/>
</xsl:template>
<xsl:template match="nodes">
    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Nodes in SPS cluster'" />
         <xsl:with-param name="id" select="'cluster-nodes'" />
         <xsl:with-param name="header"   >| Node ID        | Address | Roles |</xsl:with-param>
         <xsl:with-param name="separator">|:---------------|:--------|:-----------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="node" mode="table-row" /> </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="node" mode="table-row">
    <row>
        <value><xsl:value-of select="@id" /></value>
        <value><xsl:value-of select="address" /></value>
        <value><xsl:apply-templates select="roles" mode="cluster-node-table-cell" /></value>
    </row>
</xsl:template>
<xsl:template match="roles" mode="cluster-node-table-cell">
    <xsl:value-of select="role/@name" separator=", " />
</xsl:template>

<xsl:template match="pol_analytics">
## Analytics

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of analytics policies'" />
         <xsl:with-param name="id" select="'policy-analytics'" />
         <xsl:with-param name="header"   >| Name       | Keystroke  | Command  | Login time | Host login | FIS | Window title | Mouse   | Script detect   |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:-----------|:---------|:---------|:---------|:--------|:--------|:--------|:--------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="analytics" mode="table-row" /> </rows>
         </xsl:with-param>
     </xsl:call-template>

Notes:

- _Disable_: Select this value if you do not want to use a particular algorithm
- _Use_: Select this value if you want to use a particular algorithm
- _Trust_: Select this value if you want to use a particular algorithm, and wish to
include all scores given by this algorithm in the final aggregated score

</xsl:template>
<xsl:template match="analytics" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <xsl:apply-templates select="scoring" mode="analytics-table-cells" />
        <value><xsl:value-of select="if (scripted_detection/@enabled='yes') then 'enabled' else 'disabled'" /></value>
    </row>
</xsl:template>
<xsl:template match="scoring" mode="analytics-table-cells">
    <value><xsl:value-of select="keystroke/@choice" /></value>
    <value><xsl:value-of select="command/@choice" /></value>
    <value><xsl:value-of select="logintime/@choice" /></value>
    <value><xsl:value-of select="hostlogin/@choice" /></value>
    <value><xsl:value-of select="fis/@choice" /></value>
    <value><xsl:value-of select="windowtitle/@choice" /></value>
    <value><xsl:value-of select="mouse/@choice" /></value>
</xsl:template>


<xsl:template match="pol_audit">

## Audit

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of audit policies'" />
         <xsl:with-param name="id" select="'policy-audit'" />
         <xsl:with-param name="header"   >| Name       | Encryption        | Signing         | Timestamp             |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:------------------|:----------------|:----------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="audit" mode="table-row" /> </rows>
         </xsl:with-param>
     </xsl:call-template>

Notes: 

- Certificates are used as a container and delivery mechanism. For encryption and decryption, only the keys are used. 
- One Identity recommends using 2048-bit RSA keys (or stronger).
</xsl:template>
<xsl:template match="audit" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:apply-templates select="encryption" mode="audit-table-cell" /></value>
        <value>
            <xsl:choose>
                <xsl:when test="signing/@enabled='yes'">enabled, interval = <xsl:value-of select="signing_interval" />sec</xsl:when>
                <xsl:otherwise>disabled</xsl:otherwise>
            </xsl:choose>
        </value>
        <value><xsl:apply-templates select="timestamping" mode="audit-table-cell" /></value>
    </row>
</xsl:template>
<xsl:template match="encryption" mode="audit-table-cell">
    <xsl:choose>
        <xsl:when test="@enabled='yes'">
            <xsl:value-of select="concat(
                'enabled', 
                '&#10;',
                concat(count(certificate_groups/certificate_group), ' cert group(s)'),
                if (upstream_encryption/@enabled='yes') then
                    concat('&#10;', count(upstream_encryption/certificate_groups/certificate_group), ' cert group(s) for upstream') 
                else ''
            )" />
        </xsl:when>
        <xsl:otherwise>disabled</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="timestamping" mode="audit-table-cell">
    <xsl:choose>
        <xsl:when test="@enabled='yes'">enabled, <xsl:apply-templates select="server" mode="audit-timestamping" /></xsl:when>
        <xsl:otherwise>disabled</xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="server" mode="audit-timestamping">
    <xsl:choose>
        <xsl:when test="@choice='remote'">via <xsl:value-of select="url" /><xsl:if test="string-length(timestamp_policy) > 0">, OID=<xsl:value-of select="timestamp_policy" /></xsl:if></xsl:when>
        <xsl:otherwise>local server</xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template match="content_policies">

## Content

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of content policies'" />
         <xsl:with-param name="id" select="'policy-content'" />
         <xsl:with-param name="header"   >| Policy     | Rule                 | Actions         | Groups           |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:---------------------|:----------------|:-----------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="contentpol" mode="table-row" /> </rows>
         </xsl:with-param>
         <xsl:with-param name="empty-message">No content policies defined.</xsl:with-param>
     </xsl:call-template>


Notes:

- Command, credit card and window detection algorithms use heuristics. In certain (rare) situations, they might not match the configured content. In such cases, contact our Support Team to help analyze the problem.
- Real-time content monitoring in graphical protocols is not supported for Arabic and CJK languages.

</xsl:template>
<xsl:template match="contentpol" mode="table-row">
    <xsl:apply-templates select="rules/rule" mode="content-policy-table-row" />
</xsl:template>
<xsl:template match="rule" mode="content-policy-table-row">
    <row>
        <value><xsl:value-of select="../../@name" /></value>
        <value><xsl:apply-templates select="event_type" mode="content-policy-table-cell" /></value>
        <value><xsl:apply-templates select="actions" mode="content-policy-table-cell" /></value>
        <value>
            <xsl:apply-templates select="gateway_groups" mode="content-policy-table-cell" />
            <xsl:apply-templates select="server_groups"  mode="content-policy-table-cell" />
        </value>
    </row>
</xsl:template>
<xsl:template match="event_type" mode="content-policy-table-cell">
    <xsl:value-of select="concat('**', @choice, '**')" />
    <xsl:apply-templates select="match" mode="content-policy-table-cell" />
    <xsl:apply-templates select="ignore" mode="content-policy-table-cell" />
</xsl:template>
<xsl:template match="match|ignore" mode="content-policy-table-cell">
    <xsl:if test="count(command) &gt; 0">
        <xsl:value-of select="concat('&#10;', name(.), ': ')" />
        <xsl:value-of select="command/string" separator=", " />
    </xsl:if>
</xsl:template>
<xsl:template match="actions" mode="content-policy-table-cell">
    <xsl:value-of select="concat(
                if ( log/@enabled='yes'      ) then 'log, ' else '',
                if ( metadb/@enabled='yes'   ) then 'store in db, ' else '',
                if ( notify/@enabled='yes'   ) then 'notify, ' else '',
                if ( terminate/@enabled='yes') then 'terminate' else ''
    )" />
</xsl:template>
<xsl:template match="gateway_groups|server_groups" mode="content-policy-table-cell">
    <xsl:if test="count(group) &gt; 0">
        <xsl:value-of select="concat( '**', replace(name(.), '_', ' ') , '**: ')" />
        <xsl:value-of select="group" separator=", "/>
    </xsl:if>
</xsl:template>


<xsl:template match="pol_indexer">

## Indexing

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of indexing policies'" />
         <xsl:with-param name="id" select="'policy-indexing'" />
         <xsl:with-param name="header"   >| Policy     | Commands | Window titles | Screen content | Pointer biometrics | Typing biometrics | OCR options |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:------:|:------:|:------:|:------:|:------:|:--------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> <xsl:apply-templates select="indexer" mode="table-row" /> </rows>
         </xsl:with-param>
         <xsl:with-param name="empty-message">No index policies defined.</xsl:with-param>
     </xsl:call-template>

Notes:

- Using content policies significantly slows down connections (approximately 5 times slower), and can also cause performance problems when using the indexer service.
- In the case of graphical protocols, the default Optical Character Recognition (OCR) configuration is automatic language detection. This means that the OCR engine will attempt to detect the languages of the indexed audit trails automatically. However, if you know in advance what language(s) will be used, create a new Indexer Policy.

</xsl:template>

<xsl:template match="indexer" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <xsl:apply-templates select="index" mode="indexer-policy-table-cells" />
        <value><xsl:apply-templates select="ocr" mode="indexer-policy-table-cell" /></value>
    </row>
</xsl:template>
<xsl:template match="index" mode="indexer-policy-table-cells">
    <value><xsl:value-of select="command/@enabled" /></value>
    <value><xsl:value-of select="window_title/@enabled" /></value>
    <value><xsl:value-of select="screen_content/@enabled" /></value>
    <value><xsl:value-of select="mouse/@enabled" /></value>
    <value><xsl:value-of select="keyboard/@enabled" /></value>
</xsl:template>
<xsl:template match="ocr" mode="indexer-policy-table-cell">
    <xsl:value-of select="concat(
        accuracy,
        if ( manual_languages/@enabled='yes' ) then '&#10;manual languages: ' else ''
        )" />
    <xsl:value-of select="manual_languages/languages/language"  separator=", " />
</xsl:template>


<xsl:template match="pol_connections">

# Proxies

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of connection policies'" />
         <xsl:with-param name="id" select="'policy-connections'" />
         <xsl:with-param name="header"   >| Policy    | Network             | Indexing | Audit | Analytics | Archive |</xsl:with-param>
         <xsl:with-param name="separator">|:----------|:--------------------|:-------|:-------|:-------|:-------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="connections/connection" mode="table-row"> 
                     <xsl:sort select="../@proto" order="ascending"/>
                     <xsl:sort select="@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
     </xsl:call-template>

     <xsl:apply-templates select="connections[count(connection) &gt; 0]">
         <xsl:sort select="@proto" order="ascending"/>
     </xsl:apply-templates>

</xsl:template>

<xsl:template match="connection" mode="table-row">
    <xsl:variable name='from'  ><xsl:apply-templates select="from"   mode="connection-summary" /></xsl:variable>
    <xsl:variable name='to'    ><xsl:apply-templates select="to"     mode="connection-summary" /></xsl:variable>
    <xsl:variable name='ports' ><xsl:apply-templates select="ports"  mode="connection-summary" /></xsl:variable>
    <xsl:variable name='target'><xsl:apply-templates select="target" mode="connection-summary" /></xsl:variable>
    <row>
        <value><xsl:value-of select="concat(
                        @name,
                        ' [', ../@proto, ']',
                        if ( @enabled='no' ) then ' (disabled)' else ''
        )" /></value>
        <value><xsl:value-of select="concat(
                        '**From**: ', $from,
                        '&#10;',
                        '**To**: ', $to,
                        '&#10;',
                        '**Ports**: ', $ports,
                        '&#10;',
                        '**Target**: ', $target
        )" /></value>
        <value><xsl:apply-templates select="indexing" mode="connection-policy-table-cell" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, audit/@idref)" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, analytics_policy/@idref)" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, archive/@idref)" /></value>
    </row>
</xsl:template>
<xsl:template match="from|to" mode="connection-summary">
    <xsl:apply-templates select="network" mode="connection-summary" />
</xsl:template>
<xsl:template match="network" mode="connection-summary">
    <xsl:value-of select="concat( addr, '/', prefix, if (position() != last()) then ', ' else '')" />
</xsl:template>
<xsl:template match="ports" mode="connection-summary">
    <xsl:value-of select="port" separator=", " />
</xsl:template>

<xsl:template match="target" mode="connection-summary">
    <xsl:variable name='domains'><xsl:apply-templates select="domains" mode="connection-summary" /></xsl:variable>
    <xsl:variable name='exception-domains'><xsl:apply-templates select="exception_domains" mode="connection-summary" /></xsl:variable>
    <xsl:variable name="type-specific-content">
        <xsl:choose>
            <xsl:when test="@choice = 'transparent'"></xsl:when><!-- no extra config required -->
            <xsl:when test="@choice = 'nat'"        ><xsl:value-of select="concat(
                    '```', network/addr, '/', network/prefix, '```'
            )" /></xsl:when>
            <xsl:when test="@choice = 'direct'"     ><xsl:value-of select="concat(
                    '```', ip, ':', port, '```'
            )" /></xsl:when>
            <xsl:when test="@choice = 'inband'"     ><xsl:value-of select="concat(
                    '[', $domains, ']',
                    if ( string-length($exception-domains) &gt; 0 ) then 
                        concat('&#10;exceptions [', $exception-domains, ']')
                    else ''
            )" /></xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat(ois:connection-target-description(@choice), ' ', $type-specific-content)" />
</xsl:template>
<xsl:function name="ois:connection-target-description" as="xs:string">
    <xsl:param name="name" as="xs:string" />
    <xsl:variable name="content">
        <xsl:choose>
            <xsl:when test="$name = 'transparent'">Use original target address of the client</xsl:when>
            <xsl:when test="$name = 'nat'"        >NAT destination address</xsl:when>
            <xsl:when test="$name = 'direct'"     >Use fixed address</xsl:when>
            <xsl:when test="$name = 'inband'"     >Inband destination selection</xsl:when>
            <xsl:otherwise>{$selectName}</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$content" />
</xsl:function>
<xsl:template match="domains|exception_domains" mode="connection-summary">
    <xsl:apply-templates select="domain"  mode="connection-summary" />
</xsl:template>
<xsl:template match="domain" mode="connection-summary">
    <xsl:value-of select="concat(
        @port, ':```', text(), '```',
        if (position()!=last()) then ', ' else ''
    )" />
</xsl:template>

<xsl:template match="indexing" mode="connection-policy-table-cell">
        <xsl:value-of select=" if (@enabled='yes') then 
                                concat(ois:sps-policy-name(/config, policy/@idref), 
                                       '&#10;priority ', level)
                           else 'disabled' " />
</xsl:template>


<xsl:template match="connections">
    <xsl:value-of select="concat('&#10;## ', upper-case(@proto), ' Proxies')" />
    <xsl:choose>
        <xsl:when test="@proto='rdp'">
            <xsl:apply-templates select="." mode="connection-policy-section-rdp" />
        </xsl:when>
        <xsl:when test="@proto='ssh'">
            <xsl:apply-templates select="." mode="connection-policy-section-ssh" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="connections" mode="connection-policy-section-ssh">

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SSH connection policies'" />
         <xsl:with-param name="id" select="'policy-connections-ssh'" />
         <xsl:with-param name="header"   >| Policy    | SSH Settings | Channel | Host Key Check | Gateway Auth | SPP Capabilities |</xsl:with-param>
         <xsl:with-param name="separator">|:----------|:---------|:---------|:------------|:-------------|:----------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="connection" mode="table-row-ssh"> 
                     <xsl:sort select="@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
         <xsl:with-param name="empty-message">No SSH connection policies defined.</xsl:with-param>
     </xsl:call-template>

Notes:

- When your deployment consists of two or more instances of SPS organized into a cluster, the SSH keys recorded on the Managed Host nodes before they were joined to the cluster are overwritten by the keys on the Central Management node.
- Disabling SSH host key verification makes it impossible for SPS to verify the identity of the server and prevent man-in-the-middle (MITM) attacks.


### SSH Settings Policies

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SSH protocol setting policies'" />
         <xsl:with-param name="id" select="'policy-connections-ssh-settings'" />
         <xsl:with-param name="header"   >| Policy    | Timeout (s) | Strict Mode | Client Algorithms | Server Algorithms |</xsl:with-param>
         <xsl:with-param name="separator">|:-------|:----:|:-----:|:----------------------------|:--------------------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="/config/scb/pol_settings/settings[@proto='ssh']/setting" mode="table-row-ssh"> 
                     <xsl:sort select="@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
     </xsl:call-template>

Notes:

- Determining if a connection is idle is based on the network traffic generated by the connection, not the activity of the user. 
- Do not use the CBC block cipher mode, or the diffie-hellman-group1-sha1 key exchange algorithm.
- Strict mode can interfere with certain client or server applications.   Strict mode is not working with the Windows internal Bash/WSL feature, because it uses a very large terminal window size. Using Windows internal Bash/WSL is not supported.



### SSH Channel Policies

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SSH channel policies'" />
         <xsl:with-param name="id" select="'policy-connections-ssh-channel'" />
         <xsl:with-param name="header"   >| Policy    | Channel | Network     | Time Policy | Group Restrictions | Options |</xsl:with-param>
         <xsl:with-param name="separator">|:---------|:---:|:----------|:----:|:-------------|:--------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="/config/scb/pol_channels/channels[@proto='ssh']/channel/rules/rule" mode="table-row-channel-rule"> 
                     <xsl:sort select="../../@name" order="ascending"/>
                     <xsl:sort select="details/@choice" order="ascending"/>
                 </xsl:apply-templates>
                 <xsl:apply-templates select="/config/scb/pol_channels/channels[@proto='ssh']/channel/rules[count(rule) = 0]" mode="table-row-channel-rule-empty"> 
                     <xsl:sort select="../../@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
         <xsl:with-param name="empty-message">No channel policies defined.</xsl:with-param>
     </xsl:call-template>

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


     <xsl:apply-templates select="connection"> 
         <xsl:sort select="@name" order="ascending"/>
     </xsl:apply-templates>

</xsl:template>


<xsl:template match="connection">
    <xsl:variable name='from'  ><xsl:apply-templates select="from"   mode="connection-summary" /></xsl:variable>
    <xsl:variable name='to'    ><xsl:apply-templates select="to"     mode="connection-summary" /></xsl:variable>
    <xsl:variable name='ports' ><xsl:apply-templates select="ports"  mode="connection-summary" /></xsl:variable>
    <xsl:variable name='target'><xsl:apply-templates select="target" mode="connection-summary" /></xsl:variable>
    <xsl:variable name='index' ><xsl:apply-templates select="indexing" mode="connection-policy-table-cell" /></xsl:variable>
    <xsl:variable name='gwauth'><xsl:apply-templates select="gwauth" mode="connection-policy-table-cell" /></xsl:variable>
    <xsl:variable name='spp'   ><xsl:apply-templates select="spp_capabilities" mode="connection-policy-table-cell" /></xsl:variable>
    <xsl:variable name='server-key'><xsl:apply-templates select="server_host_key_plain" mode="connection-policy-table-cell" /></xsl:variable>
    <xsl:variable name='log-level'><xsl:apply-templates select="override_verbosity_level" mode="connection-summary" /></xsl:variable>


### <xsl:value-of select="upper-case(../@proto)" /> Proxy: <xsl:value-of select="@name" />

    <xsl:apply-templates select="." mode="graphic" />

    <xsl:value-of select="ois:markdown-definition('Status', if (@enabled='yes') then 'active' else 'disabled' )" />
    <xsl:value-of select="ois:markdown-definition('From', $from)" />
    <xsl:value-of select="ois:markdown-definition('To', $to)" />
    <xsl:value-of select="ois:markdown-definition('Ports', $ports)" />
    <xsl:value-of select="ois:markdown-definition('Address translation', snat/@choice)" />
    <xsl:value-of select="ois:markdown-definition('Target', $target)" />
    <xsl:value-of select="ois:markdown-definition('Indexing', $index)" />
    <xsl:value-of select="ois:markdown-definition('Gateway authentication', $gwauth)" />
    <xsl:value-of select="ois:markdown-definition('Act as RDS gateway', act_as_ts_gw/@choice)" />
    <xsl:value-of select="ois:markdown-definition('Host key check', $server-key)" />
    <xsl:value-of select="ois:markdown-definition('Rate limit', concat(rate_limit, ' connections/minute/client'))" />
    <xsl:value-of select="ois:markdown-definition('Log level override', $log-level)" />
    <xsl:value-of select="ois:markdown-definition('SPP capabilities', $spp)" />

    <xsl:apply-templates select="transport_security" />

#### Assigned Policies
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Audit',      audit/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Analytics',  analytics_policy/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Archive',    archive/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Authentication', authentication/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Backup',     backup/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Channel',    channel/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Credential store', credstore/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'Settings',   settings/@idref)" />
    <xsl:value-of select="ois:sps-markdown-definition-policy(/config, 'User mapping', usermapping/@idref)" />


</xsl:template>

<xsl:function name="ois:sps-markdown-definition-policy" as="xs:string">
     <xsl:param name="config" />
     <xsl:param name="term" as="xs:string?" />
     <xsl:param name="policy-id" as="xs:string?" />
     <xsl:variable name='policy-name'>
         <xsl:value-of select="ois:sps-policy-name($config, $policy-id)" />
     </xsl:variable>
     <xsl:value-of select="ois:markdown-definition(
                                $term, 
                                if ( string-length($policy-id) &gt; 0 ) then
                                    $policy-name
                                else 'n/a'
         )" />
</xsl:function>


<xsl:template match="transport_security">

#### Transport Security

    <xsl:value-of select="ois:markdown-definition('Type', @choice)" />
    <xsl:if test="@choice='tls'">
        <xsl:variable name='cert-summary'><xsl:apply-templates select="certificate" mode="tls-summary" /></xsl:variable>
        <xsl:variable name='cert-check'><xsl:apply-templates select="server_certificate_check" mode="tls-summary" /></xsl:variable>
        <xsl:value-of select="ois:markdown-definition('Certificate',        $cert-summary)" />
        <xsl:value-of select="ois:markdown-definition('Server validation',  $cert-check)" />
        <xsl:value-of select="ois:markdown-definition('Legacy fallback',    legacy_fallback/@enabled)" />
    </xsl:if>
</xsl:template>


<xsl:template match="connection" mode="table-row-ssh">
    <row>
        <value><xsl:value-of select="concat(
                        @name,
                        if ( @enabled='no' ) then ' (disabled)' else ''
        )" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, settings/@idref)" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, channel/@idref)" /></value>
        <value><xsl:apply-templates select="server_host_key_plain" mode="connection-policy-table-cell" /></value>
        <value><xsl:apply-templates select="gwauth" mode="connection-policy-table-cell" /></value>
        <value><xsl:apply-templates select="spp_capabilities" mode="connection-policy-table-cell" /></value>
    </row>
</xsl:template>
<xsl:template match="server_host_key_plain" mode="connection-policy-table-cell">
    <xsl:value-of select="server_key_check" />
</xsl:template>

<xsl:template match="setting" mode="table-row-ssh">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="ois:sps-connection-timeout(.)" /></value>
        <value><xsl:value-of select="strict_mode/@enabled" /></value>
        <value><xsl:value-of select="ois:sps-ssh-algorithm-summary(., 'client')" /></value>
        <value><xsl:value-of select="ois:sps-ssh-algorithm-summary(., 'server')" /></value>
    </row>
</xsl:template>

<xsl:function name="ois:sps-connection-timeout" as="xs:string">
     <xsl:param name="config" />
     <xsl:value-of select="concat(
         $config/timeout,
         if ( $config/inactivity_timeout/enabled='yes' ) then 
             concat('&#10;User idle timeout: ', $config/inactivity_timeout/value)
         else ''
     )" />
</xsl:function>




<xsl:template match="connections" mode="connection-policy-section-rdp">

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of RDP connection policies'" />
         <xsl:with-param name="id" select="'policy-connections-rdp'" />
         <xsl:with-param name="header"   >| Policy    | RDP Settings | Channel | TLS                   | Gateway Auth | SPP Capabilities |</xsl:with-param>
         <xsl:with-param name="separator">|:----------|:---------|:---------|:-------------------------|:-------------|:----------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="connection" mode="table-row-rdp"> 
                     <xsl:sort select="@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
         <xsl:with-param name="empty-message">No RDP connection policies defined.</xsl:with-param>
     </xsl:call-template>

### RDP Settings Policies

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of RDP protocol setting policies'" />
         <xsl:with-param name="id" select="'policy-connections-rdp-settings'" />
         <xsl:with-param name="header"   >| Policy    | Timeout (s) | Max. Display size (HxWxBpp) | Authentication | TLS |</xsl:with-param>
         <xsl:with-param name="separator">|:----------|:--------:|:---------:|:-------------------|:-------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="/config/scb/pol_settings/settings[@proto='rdp']/setting" mode="table-row-rdp"> 
                     <xsl:sort select="@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
     </xsl:call-template>


Notes:

- Determining if a connection is idle is based on the network traffic generated by the connection, not the activity of the user. 
- The Maximum display width and Maximum display height options should be high enough to cover the combined resolution of the client monitor setup. Connections that exceed these limits will automatically fail.
- Using 32-bit color depth is currently not supported: client connections requesting 32-bit color depth automatically revert to 24-bit



### RDP Channel Policies


    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of RDP channel policies'" />
         <xsl:with-param name="id" select="'policy-connections-rdp-channel'" />
         <xsl:with-param name="header"   >| Policy    | Channel | Network     | Time Policy | Group Restrictions | Options |</xsl:with-param>
         <xsl:with-param name="separator">|:---------|:---:|:----------|:----:|:-------------|:--------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="/config/scb/pol_channels/channels[@proto='rdp']/channel/rules/rule" mode="table-row-channel-rule"> 
                     <xsl:sort select="../../@name" order="ascending"/>
                     <xsl:sort select="details/@choice" order="ascending"/>
                 </xsl:apply-templates>
                 <xsl:apply-templates select="/config/scb/pol_channels/channels[@proto='rdp']/channel/rules[count(rule) = 0]" mode="table-row-channel-rule-empty"> 
                     <xsl:sort select="../../@name" order="ascending"/>
                 </xsl:apply-templates>
             </rows>
         </xsl:with-param>
         <xsl:with-param name="empty-message">No channel policies defined.</xsl:with-param>
     </xsl:call-template>


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

     <xsl:apply-templates select="connection"> 
         <xsl:sort select="@name" order="ascending"/>
     </xsl:apply-templates>

</xsl:template>

<xsl:template match="rules" mode="table-row-channel-rule-empty">
    <row>
        <value><xsl:value-of select="../@name" /></value>
        <value>_none_</value>
        <value>*</value>
        <value></value>
        <value></value>
        <value></value>
        <value></value>
    </row>
</xsl:template>
<xsl:template match="rule" mode="table-row-channel-rule">
    <xsl:variable name='from'><xsl:apply-templates select="from" mode="channel-summary" /></xsl:variable>
    <xsl:variable name='to'><xsl:apply-templates select="to" mode="channel-summary" /></xsl:variable>
    <row>
        <value><xsl:value-of select="../../@name" /></value>
        <value><xsl:value-of select="details/@choice" /></value>
        <value><xsl:value-of select="concat(
            '**From**: ', $from,
            '&#10;',
            '**Target**: ', $to

        )" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, time/@idref)" /></value>
        <value>
            <xsl:apply-templates select="remote_groups" mode="channel-summary" />
            <xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="gateway_groups" mode="channel-summary" />
        </value>
        <value>
            <xsl:apply-templates select="." mode="channel-options-summary" />
            <xsl:apply-templates select="details" mode="channel-options-summary" />
        </value>


    </row>
</xsl:template>
<xsl:template match="from|to" mode="channel-summary">
    <xsl:variable name='networks'><xsl:value-of select="network" separator=", " /></xsl:variable>
    <xsl:value-of select="
                if ( count(network) = 0 ) then
                    '```*```'
                else
                    concat('```', $networks, '```')
    " />
</xsl:template>
<xsl:template match="remote_groups|gateway_groups" mode="channel-summary">
    <xsl:variable name='groups'><xsl:value-of select="group" separator=", " /></xsl:variable>
    <xsl:value-of select="
                if ( string-length($groups) &gt; 0 ) then
                    concat('**', replace(name(.), '_', ' '), '**: ', $groups)
                else ''
    " />
</xsl:template>
<xsl:template match="rule" mode="channel-options-summary">
    <xsl:variable name="options">
        <items>
            <value><xsl:value-of select="ois:enabled-node-label(four_eyes, 'four-eyes authorization')" /></value>
            <value><xsl:value-of select="ois:enabled-node-label(audit, 'record audit trail')" /></value>
        </items>
    </xsl:variable>
    <xsl:value-of select="ois:list-to-string($options, ', ')" />
</xsl:template>
<xsl:template match="details" mode="channel-options-summary">
    <xsl:variable name="options">
        <items>
            <value><xsl:value-of select="ois:enabled-node-label(log_transfer_details/log_transfer_to_syslog, 'log transfers to syslog')" /></value>
            <value><xsl:value-of select="ois:enabled-node-label(log_transfer_details/log_transfer_to_db, 'log transfers to db')" /></value>
        </items>
    </xsl:variable>
    <xsl:variable name="other-categories">
        <items>
            <value key="clients"><xsl:value-of select="x11/network" separator=", " /></value>
            <value key="direct"><xsl:apply-templates select="directs/direct" mode="channel-summary" /></value>
            <value key="forward"><xsl:apply-templates select="forwardeds/forwarded" mode="channel-summary" /></value>
            <value key="custom"><xsl:apply-templates select="customs" mode="channel-summary" /></value>
        </items>
    </xsl:variable>
    <xsl:value-of select="concat(
                ois:list-to-string($options, ', '),
                ois:map-to-string($other-categories, '&#10;', ', ')
        )" />
</xsl:template>
<xsl:template match="direct" mode="channel-summary">
    <xsl:value-of select="concat(originator_addr, '&#8594;', host_addr, ': ', host_port)" />
</xsl:template>
<xsl:template match="forwarded" mode="channel-summary">
    <xsl:value-of select="concat(originator_addr, '&#8594;', connected_addr, ': ', connected_port)" />
</xsl:template>
<xsl:template match="customs" mode="channel-summary">
    <xsl:value-of select="custom" separator=", " />
</xsl:template>
<xsl:template match="override_verbosity_level" mode="channel-summary">
    <xsl:if test="@enabled='yes'">
        <xsl:value-of select=" concat('level ', verbosity_level) " />
    </xsl:if>
</xsl:template>

<xsl:template match="connection" mode="table-row-rdp">
    <row>
        <value><xsl:value-of select="concat(
                        @name,
                        if ( @enabled='no' ) then ' (disabled)' else ''
        )" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, settings/@idref)" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, channel/@idref)" /></value>
        <value><xsl:apply-templates select="transport_security" mode="connection-policy-table-cell" /></value>
        <value><xsl:apply-templates select="gwauth" mode="connection-policy-table-cell" /></value>
        <value><xsl:apply-templates select="spp_capabilities" mode="connection-policy-table-cell" /></value>
    </row>
</xsl:template>
<xsl:template match="transport_security" mode="connection-policy-table-cell">
    <xsl:variable name='cert-summary'><xsl:apply-templates select="certificate" mode="tls-summary" /></xsl:variable>
    <xsl:variable name='cert-check'><xsl:apply-templates select="server_certificate_check" mode="tls-summary" /></xsl:variable>
    <xsl:value-of select="concat(
        '**Type**: ', @choice,
        '&#10;',
        if ( @choice='tls' ) then
            concat(
                '**Certificate**: ', $cert-summary,
                '&#10;',
                '**Server validation**: ', $cert-check,
                '&#10;',
                '**Legacy fallback**: ', legacy_fallback/@enabled
            )
        else ''
     )" />
</xsl:template>
<xsl:template match="certificate" mode="tls-summary">
    <xsl:value-of>
        <xsl:choose>
            <xsl:when test="@choice = 'generate'"><xsl:value-of select="concat(
            'Generate on the fly with ', ois:sps-certificate-name(/config, signing-ca/@idref) )" /></xsl:when>
            <xsl:when test="@choice = 'self_signed'">Self-signed</xsl:when>
            <xsl:when test="@choice = 'fix'">Same certificate for each connection</xsl:when>
        </xsl:choose>
    </xsl:value-of>
</xsl:template>
<xsl:template match="server_certificate_check" mode="tls-summary">
    <xsl:value-of select="
        if (@choice='yes') then
            concat('via ', ois:sps-certificate-name(/config, trusted_ca/@idref))
        else 'none'" />
</xsl:template>

<xsl:template match="gwauth" mode="connection-policy-table-cell">
    <xsl:variable name='groups'><xsl:value-of select="groups/group" separator=", "/></xsl:variable>
    <xsl:value-of select="
        if ( @enabled='yes' ) then
            concat(
                'enabled',
                if ( @sameip='yes' ) then ' (same IP address)' else '',
                if ( string-length($groups) &gt; 0 ) then
                    concat( '&#10;', '**Groups**: ', $groups)
                else ''
            )
        else 'disabled'
     " />
</xsl:template>

<xsl:template match="spp_capabilities" mode="connection-policy-table-cell">
    <xsl:value-of select="concat(
        if ( spp_init/@enabled='yes' ) then 'SPP initiated sessions' else '',
        if ( sps_init/@enabled='yes' ) then '&#10;SPS initiated sessions' else '',
        if ( cred_inj/@enabled='yes' ) then '&#10;Credential injection' else ''
     )" />
</xsl:template>

<xsl:template match="setting" mode="table-row-rdp">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="ois:sps-connection-timeout(.)" /></value>
        <value><xsl:value-of select="concat( max_width, 'x', max_height, 'x', max_bpp )" /></value>
        <value><xsl:apply-templates select="authentication_mode" mode="connection-policy-table-cell" /></value>
        <value>
            <xsl:apply-templates select="client_tls_security_settings" mode="rdp-settings-summary">
                <xsl:with-param name="type" select="'Client'" />
            </xsl:apply-templates>
        </value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, settings/@idref)" /></value>
        <value><xsl:value-of select="ois:sps-policy-name(/config, channel/@idref)" /></value>
        <value><xsl:apply-templates select="transport_security" mode="connection-policy-table-cell" /></value>
        <value><xsl:apply-templates select="gwauth" mode="connection-policy-table-cell" /></value>
        <value><xsl:apply-templates select="spp_capabilities" mode="connection-policy-table-cell" /></value>
    </row>
</xsl:template>
<xsl:template match="authentication_mode" mode="connection-policy-table-cell">
    <xsl:variable name='groups'><xsl:value-of select="groups/group" separator=", "/></xsl:variable>
    <xsl:value-of select="concat(
        '**Logon screen**: ', server_screen/@enabled,
        '&#10;',
        '**NLA**: ', nla/@enabled,
        if ( nla/@enabled='yes' and require_domain/enabled='yes' ) then ' (domain membership required)' else ''
     )" />
</xsl:template>

<xsl:template match="client_tls_security_settings|server_tls_security_settings" mode="rdp-settings-summary">
    <xsl:param name='type' />
    <xsl:variable name='cipher'>
        <xsl:apply-templates select="cipher_strength" mode="rdp-settings-summary">
            <xsl:with-param name='type' select="$type" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="concat(
        $cipher,
        '&#10;',
        '**', $type, ' version**: ', minimum_tls_version/@choice
    )" />
</xsl:template>
<xsl:template match="cipher_strength" mode="rdp-settings-summary">
    <xsl:param name='type' />
    <xsl:value-of select="concat(
        '**', $type, ' cipher**: ',
            if ( @choice='custom' ) then
                concat('```', custom_cipher, '```')
            else 'SPS recommended'
    )" />
</xsl:template>

<!-- proxy graphic -->
<xsl:template match="connection" mode="graphic">
    <xsl:variable name='proxy-icon'><xsl:value-of select="concat(
            'SPS_Proxy',
            if ( @enabled='no' ) then '_DISABLED' else ''
    ) "/></xsl:variable>

```{.plantuml caption="Proxy overview"}
!include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

top to bottom direction

    <xsl:value-of select="ois:puml-component(
                            'CONNECTION', 
                            @name, 
                            concat(upper-case(../@proto), ' proxy'),
                            $proxy-icon
    )"/>


    together {
        <xsl:apply-templates select="audit"             mode="graphic" />
        <xsl:apply-templates select="analytics_policy"  mode="graphic" />
        <xsl:apply-templates select="archive"           mode="graphic" />
        <xsl:apply-templates select="authentication"    mode="graphic" />
        <xsl:apply-templates select="backup"            mode="graphic" />
        <xsl:apply-templates select="channel"           mode="graphic" />
        <xsl:apply-templates select="credstore"         mode="graphic" />
        <xsl:apply-templates select="settings"          mode="graphic" />
        <xsl:apply-templates select="usermapping"       mode="graphic" />
    }
    <xsl:apply-templates select="indexing"   mode="graphic" />


    <xsl:apply-templates select="audit"             mode="graphic-proxy-connection" />
    <xsl:apply-templates select="analytics_policy"  mode="graphic-proxy-connection" />
    <xsl:apply-templates select="archive"           mode="graphic-proxy-connection" />
    <xsl:apply-templates select="authentication"    mode="graphic-proxy-connection" />
    <xsl:apply-templates select="backup"            mode="graphic-proxy-connection" />
    <xsl:apply-templates select="channel"           mode="graphic-proxy-connection" />
    <xsl:apply-templates select="credstore"         mode="graphic-proxy-connection" />
    <xsl:apply-templates select="settings"          mode="graphic-proxy-connection" />
    <xsl:apply-templates select="usermapping"       mode="graphic-proxy-connection" />

    <xsl:apply-templates select="indexing" mode="graphic-proxy-connection" />

```

    <xsl:value-of select="ois:markdown-figure(
                            concat('Proxy overview - ', @name),
                            'single.png',
                            concat('proxy-overview-', @id) )" />
</xsl:template>

<xsl:template match="audit|analytics_policy|archive|authentication|backup|channel|credstore|settings|usermapping" mode="graphic">
    <xsl:variable name="policy">
        <xsl:choose>
            <xsl:when test="name(.) = 'analytics_policy'">analytics</xsl:when>
            <xsl:when test="name(.) = 'credstore'">credential store</xsl:when>
            <xsl:when test="name(.) = 'usermapping'">user mapping</xsl:when>
            <xsl:when test="name(.) = 'policy'"><xsl:value-of select="name(..)" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="name(.)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="ois:puml-component(
                            upper-case(name(.)), 
                            ois:sps-policy-name(/config, @idref), 
                            concat($policy, ' policy'),
                            'SPS_Policy'
    )"/>
</xsl:template>
<xsl:template match="audit|analytics_policy|archive|authentication|backup|channel|credstore|settings|usermapping" mode="graphic-proxy-connection">
    <xsl:value-of select="concat(
        '&#10;CONNECTION', '--', upper-case(name(.))
    )" />
</xsl:template>
<xsl:template match="indexing" mode="graphic">
    <xsl:if test="@enabled='yes'">
        <xsl:value-of select="ois:puml-component(
                                'INDEXING', 
                                ois:sps-policy-name(/config, policy/@idref), 
                                'indexing policy',
                                'SPS_Indexing'
        )"/>
    </xsl:if>
</xsl:template>
<xsl:template match="indexing" mode="graphic-proxy-connection">
    <xsl:if test="@enabled='yes'">
    <xsl:value-of select="concat(
        '&#10;CONNECTION', '--', upper-case(name(.))
    )" />
    </xsl:if>
</xsl:template>






<xsl:template match="plugins">

<xsl:if test="count(*/plugin) &gt; 0">

# Plugins

To download the official plugins for your product version, navigate to the [product page](https://support.oneidentity.com/one-identity-safeguard-for-privileged-sessions/7.4.0/download-new-releases) on the Support Portal. The official plugins are also available on [GitHub](https://github.com/search?q=topic%3Aoi-sps-plugin+org%3AOneIdentity&amp;type=Repositories). To write your own custom plugin, use our [Plugin SDK](https://oneidentity.github.io/safeguard-sessions-plugin-sdk/latest/).

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SPS plugins'" />
         <xsl:with-param name="id" select="'plugins'" />
         <xsl:with-param name="header"   >| Name  | Type  | Version | Description | Path |</xsl:with-param>
         <xsl:with-param name="separator">|:------|:----:|:---:|:---------------|:--------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="*/plugin" mode="table-row" />
             </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:if>
</xsl:template>
<xsl:template match="plugin" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="../name()" /></value>
        <value><xsl:value-of select="version" /></value>
        <value><xsl:value-of select="description" /></value>
        <value><xsl:value-of select="path" /></value>
    </row>
</xsl:template>





<!-- appliance docs -->
<xsl:template match="xcb">
# Appliance

    <xsl:value-of select="ois:markdown-definition('Version', concat(@major_version, '-', @minor_version, '-', @revision) )" />

    <xsl:apply-templates select="networking" />
    <xsl:apply-templates select="license" />
    <xsl:apply-templates select="services" />
    <xsl:apply-templates select="aaa" />
    <xsl:apply-templates select="backup_archive" />

</xsl:template>

<xsl:template match="networking">
## Network

    <xsl:value-of select="ois:markdown-definition('Host name', concat(hostname, if (domainname) then concat(' [', domainname, ']') else '' ) )" />

    <xsl:value-of select="ois:markdown-definition('DNS servers', concat(dns/primary, if (dns/secondary) then concat(', ', dns/secondary) else '' ) )" />

    <xsl:apply-templates select="nics" />

</xsl:template>
<xsl:template match="nics">
### Interfaces
    <xsl:apply-templates select="nic" />
</xsl:template>
<xsl:template match="nic">
    <xsl:value-of select="ois:markdown-definition(@name, ois:sps-nic-summary(.))" />
</xsl:template>


<xsl:template match="license">
## License

    <xsl:value-of select="ois:markdown-definition('Version',    ois:json-get-value(info, 'product_version') )" />
    <xsl:value-of select="ois:markdown-definition('Serial number', ois:json-get-value(info, 'serial') )" />
    <xsl:value-of select="ois:markdown-definition('Type',       
            concat( if (ois:json-get-value(info, 'enterprise')='true') 
                        then 'enterprise' else ois:json-get-value(info, 'limt_type'),
                    '/',
                    ois:json-get-value(info, 'license_type')) )" />
    <xsl:value-of select="ois:markdown-definition('Expiry',     ois:json-get-value(info, 'valid_not_after') )" />
    <xsl:value-of select="ois:markdown-definition('Proxies',    ois:json-get-value(info, 'basic_proxies') )" />
    <xsl:value-of select="ois:markdown-definition('Sudo iolog', ois:json-get-value(info, 'sudo_iolog') )" />
    <xsl:value-of select="ois:markdown-definition('Analytics',  ois:json-get-value(info, 'analytics') )" />

</xsl:template>

<xsl:template match="services">
## Services

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SPS services'" />
         <xsl:with-param name="id" select="'services-summary'" />
         <xsl:with-param name="header"   >| Service | Enabled? | Notes   |</xsl:with-param>
         <xsl:with-param name="separator">|:----|:--:|:------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="ssh"          mode="service-table-row" />
                 <xsl:apply-templates select="admin_web"    mode="service-table-row" />
                 <xsl:apply-templates select="user_web"     mode="service-table-row" />
                 <xsl:apply-templates select="snmp"         mode="service-table-row" />
                 <xsl:apply-templates select="indexer"      mode="service-table-row" />
                 <xsl:apply-templates select="analytics"    mode="service-table-row" />
                 <xsl:apply-templates select="cluster"      mode="service-table-row" />
             </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="ssh" mode="service-table-row">
    <row>
        <value>Local SSH</value>
        <xsl:choose>
            <xsl:when test="@enabled = 'yes'">
                <value>enabled</value>
                <value><xsl:value-of select="concat(
                    concat('Brute force protection: ', @bruteforce_protection),
                    '&#10;',
                    concat('Password auth enabled: ', password_auth), 
                    if (@restricted ='yes') then 
                        concat('Restricted to: ', allowed_from, '&#10;') 
                    else '',
                    '&#10;',
                    concat('Network: ', 
                        ois:nic-address-name(/config/xcb/networking/nics, listen/address/addr/@idref), 
                        ', port ', 
                        listen/address/port) 
                )" /></value>
            </xsl:when>
            <xsl:otherwise>
                <value>disabled</value>
                <value></value>
            </xsl:otherwise>
        </xsl:choose>
    </row>
</xsl:template>
<xsl:template match="admin_web|user_web" mode="service-table-row">
    <row>
        <value><xsl:value-of select="if (name(.) = 'admin_web') then 'Admin HTTPs' else 'User HTTPs'" /></value>
        <xsl:choose>
            <xsl:when test="listen/address">
            <value>enabled</value>
            <value><xsl:value-of select="concat(
                if (@restricted ='yes') then 
                    concat('Restricted to: ', allowed_from, '&#10;') 
                else '',
                concat('Network: ', 
                    ois:nic-address-name(/config/xcb/networking/nics, listen/address/addr/@idref), 
                    ', ports ', 
                    listen/address/http_port, '/', listen/address/https_port) 
            )" /></value>
            </xsl:when>
            <xsl:otherwise>
                <value>disabled</value>
                <value></value>
            </xsl:otherwise>
        </xsl:choose>
    </row>
</xsl:template>
<xsl:template match="snmp" mode="service-table-row">
    <row>
        <value>SNMP</value>
        <xsl:choose>
            <xsl:when test="@enabled = 'yes'">
                <value>enabled</value>
                <value><xsl:value-of select="concat(
                    if (@restricted ='yes') then 
                        concat('Restricted to: ', allowed_from, '&#10;') 
                    else '',
                    '&#10;',
                    concat('Network: ', 
                        ois:nic-address-name(/config/xcb/networking/nics, listen/address/addr/@idref), 
                        ', port ', 
                        listen/address/port) 
                )" /></value>
            </xsl:when>
            <xsl:otherwise>
                <value>disabled</value>
                <value></value>
            </xsl:otherwise>
        </xsl:choose>
    </row>
</xsl:template>
<xsl:template match="indexer" mode="service-table-row">
    <row>
        <value>Indexer</value>
        <xsl:choose>
            <xsl:when test="@choice = 'integrated'">
                <value>integrated</value>
                <value><xsl:value-of select="concat(
                    concat('Workers: ', number_of_workers),
                    '&#10;',
                    concat('Real time workers: ', number_of_near_realtime_workers),
                    '&#10;',
                    concat( 'Remote indexer: ',
                        if (remote_access/@enabled='yes') then
                            concat(ois:nic-address-name(/config/xcb/networking/nics, listen/address/addr/@idref),
                                ', port ',
                                listen/address/port)
                        else 'disabled' )
                )" /></value>
            </xsl:when>
            <xsl:otherwise>
                <value>n/a</value>
                <value></value>
            </xsl:otherwise>
        </xsl:choose>
    </row>
</xsl:template>
<xsl:template match="analytics" mode="service-table-row">
    <row>
        <value>Analytics</value>
        <value><xsl:value-of select="if ( @enabled='yes' ) then 'enabled' else 'disabled' " /></value>
        <value></value>
    </row>
</xsl:template>
<xsl:template match="cluster" mode="service-table-row">
    <row>
        <value>Cluster</value>
        <value><xsl:value-of select="if ( @enabled='yes' ) then 'enabled' else 'disabled' " /></value>
        <value><xsl:value-of select="
                if ( @enabled='yes' ) then 
                    ois:nic-address-name(/config/xcb/networking/nics, listen/address/addr/@idref) 
                else ''
        " /></value>
    </row>
</xsl:template>


<xsl:template match="aaa">
    <xsl:apply-templates select="usersgroups" />
</xsl:template>
<xsl:template match="usersgroups">
    <xsl:apply-templates select="users" />
</xsl:template>
<xsl:template match="users">

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of SPS local users'" />
         <xsl:with-param name="id" select="'local-users'" />
         <xsl:with-param name="header"   >| Name | Groups | ACLs  |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------------|:------------|:-----------------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="user" mode="table-row" />
             </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="user" mode="table-row">
    <xsl:variable name="userId" select="@id" />
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="../../groups/group[members/member[@idref=$userId]]/@name" separator="&#10;" /></value>
        <value><xsl:apply-templates select="../../groups/group[members/member[@idref=$userId]]" mode="table-cell-acl" /></value>
    </row>

</xsl:template>
<xsl:template match="group" mode="table-cell-acl">
    <xsl:variable name="groupName" select="@name" />
    <xsl:apply-templates select="../../../acls/acl[@group=$groupName]"  mode="acl-summary" />
    <xsl:value-of select="if (position() != last()) then '&#10;' else ''" />
</xsl:template>
<xsl:template match="acl" mode="acl-summary">
    <xsl:variable name='acl-objects'>
        <xsl:apply-templates select="objects/object" mode="acl-summary" />
    </xsl:variable>
    <xsl:value-of select="concat(' **', @type, '**: ', $acl-objects)" />
</xsl:template>
<xsl:template match="object" mode="acl-summary">
    <xsl:value-of select="concat( text(), if (position() != last()) then ', ' else '')" /> 
</xsl:template>


<xsl:template match="backup_archive">
## Backup and Archive

    <xsl:apply-templates select="backups" />
    <xsl:apply-templates select="archives" />
</xsl:template>

<xsl:template match="backups">

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of backup policies'" />
         <xsl:with-param name="id" select="'backup'" />
         <xsl:with-param name="header"   >| Policy     | Times   | Target          | Options    |</xsl:with-param>
         <xsl:with-param name="separator">|:-----------|:--------|:-----------------------|:-------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="backup" mode="table-row" />
             </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="backup" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:apply-templates select="start_times" mode="table-cell" /></value>
        <value><xsl:apply-templates select="target" mode="table-cell" /></value>
        <value><xsl:value-of select="concat(
                        'notifications: ', @notification,
                        if (include_node_id_in_path/@enabled='yes') then '&#10;node ID included in path' else '' 
        )" /></value>
    </row>
</xsl:template>
<xsl:template match="start_times" mode="table-cell">
    <xsl:value-of select="start_time" separator=", " />
</xsl:template>
<xsl:template match="target" mode="table-cell">
    <xsl:value-of select="concat('**', @choice, '** ', if (anonymous/@enabled='yes') then '[anonymous] ' else '', '&#10;')" />
    <xsl:choose>
        <xsl:when test="@choice='smb'">
            <xsl:value-of select="concat(
                    'server: ', smb_server, 
                    if (anonymous/@enabled='no') then concat('&#10;username: ', smb_username) else '',
                    '&#10;',
                    'share: ', share, 
                    '&#10;',
                    'smb version: ', protocol_version
            )" />
        </xsl:when>
        <xsl:when test="target/@choice='nfs'">
            <xsl:value-of select="concat(
                    'server: ', nfs_server, 
                    'path: ', nfs_path 
            )" />
        </xsl:when>
    </xsl:choose>
</xsl:template>


<xsl:template match="archives">

    <xsl:call-template name="ois:generate-table">
         <xsl:with-param name="summary" select="'Summary of archive policies'" />
         <xsl:with-param name="id" select="'archive'" />
         <xsl:with-param name="header"   >| Policy   | Archive age | Times    | Target        | Options    |</xsl:with-param>
         <xsl:with-param name="separator">|:---------|:-----------:|:---------|:--------------------|:-------------------|</xsl:with-param>
         <xsl:with-param name="values">
             <rows> 
                 <xsl:apply-templates select="archive" mode="table-row" />
             </rows>
         </xsl:with-param>
     </xsl:call-template>

</xsl:template>
<xsl:template match="archive" mode="table-row">
    <row>
        <value><xsl:value-of select="@name" /></value>
        <value><xsl:value-of select="concat(archive_days, ' days')" /></value>
        <value><xsl:apply-templates select="start_times" mode="table-cell" /></value>
        <value><xsl:apply-templates select="target" mode="table-cell" /></value>
        <value><xsl:value-of select="concat(
                        'notifications: ', @notification,
                          if (notification_send_filelist='yes') then ' (with file list)' else '',
                        if (include_node_id_in_path/@enabled='yes') then '&#10;node ID included in path' else '' 
        )" /></value>
    </row>
</xsl:template>



<!-- =============================================== -->
<!-- =============================================== -->

<xsl:function name="ois:sps-ssh-algorithm-summary" as="xs:string">
     <xsl:param name="policy" />
     <xsl:param name="type" as="xs:string" />
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
     <xsl:variable name="result">
         <xsl:for-each select="$algos/algo">
             <xsl:value-of select="concat( '**', name, '**: ', value, '&#10;')" />
         </xsl:for-each>
     </xsl:variable>
     <xsl:value-of select="$result" />
</xsl:function>

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


<xsl:template name="nic-summary">
    <xsl:param name="nic" />
    <xsl:if test="count($nic/interfaces/interface) = 0">[unused]</xsl:if
     ><xsl:for-each select="$nic/interfaces/interface"><xsl:apply-templates select="." /><br/></xsl:for-each>
</xsl:template>
<xsl:function name="ois:sps-nic-summary" as="xs:string">
    <xsl:param name="nic" />
    <xsl:variable name="content">
        <xsl:if test="count($nic/interfaces/interface) = 0">[unused]</xsl:if
        ><xsl:apply-templates select="$nic/interfaces/interface" mode="inline-summary" />
    </xsl:variable>
    <xsl:value-of select="$content" />
</xsl:function>
<xsl:template match="interface" mode="inline-summary">
    <xsl:apply-templates select="addresses" mode="inline-summary" />
</xsl:template>
<xsl:template match="addresses" mode="inline-summary">
    <xsl:apply-templates select="address"  mode="inline-summary"/>
</xsl:template>
<xsl:template match="address" mode="inline-summary">
    <xsl:value-of select="concat(@family, ': ', addr, '/', prefix, if (position() &lt; last()) then '; ' else '')" />
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
        <!-- networks for this node -->
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
    <xsl:variable name="sps-nodes"> <xsl:call-template name="get-cluster-nodes" /> </xsl:variable>
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
!include_many /home/mpierson/projects/quest/Safeguard/tools/header.puml

top to bottom direction

together {

        Boundary(spp, "SPP cluster") {
    <xsl:for-each select="$spp-node">
        Component(SPP_<xsl:value-of select="position()"/>, "<xsl:value-of select="ip_address" />", "SPP cluster", $tags="SG_SPP")
    </xsl:for-each>
    }

    Boundary(sps, "SPS cluster") {
    <xsl:for-each select="/config/scb/cluster/nodes/node">
        Component(SPS_<xsl:value-of select="position()" />, "<xsl:value-of select="address" />", "<xsl:value-of select="roles/role/@name" separator=", "/>", $tags="SG_SPS")
        </xsl:for-each>
    }

}

Boundary(admins, "Safeguard administrators") {
  <xsl:for-each select="/config/xcb/aaa/usersgroups/users/user">
      Person(<xsl:value-of select="@id"/>, "<xsl:value-of select="@name"/>", "<xsl:value-of select="@id"/>", $tags="SG_Admin")
  </xsl:for-each>
}


Boundary(int, "Integrated systems") {
    <xsl:for-each select="/AuthProviders/AuthProvider[@type != 'Local' and @type != 'Certificate']">
        Component(Auth<xsl:value-of select="@id" />, "<xsl:value-of select="@name" />", "<xsl:value-of select="@type" /> auth provider", $tags="AUTH_<xsl:value-of select="@type" />")
    </xsl:for-each>

    Component(Starling1, "Starling", "Cloud-based services", <xsl:value-of select="if (/config/scb/starling_join/remote_access/@enabled='yes') then '' else ''" />, $tags="<xsl:value-of select="if (/config/scb/starling_join/remote_access/@enabled='yes') then 'SG_Starling' else 'SG_Starling_Disabled'" />")

    <xsl:if test="/config/xcb/management/smtp_server/text()">
         Component(Mail1, "<xsl:value-of select="/config/xcb/management/smtp_server" />", "Mail transport", $tags="INTEGRATION", $sprite="email_service,scale=0.7,color=white")
     </xsl:if>

     <xsl:if test="/config/xcb/management/syslog/target/server/text()">
       Component(Syslog, "Syslog: <xsl:value-of select="/config/xcb/management/syslog/target/server" />", "<xsl:value-of select="/config/xcb/management/syslog/target/proto" /> - <xsl:value-of select="/config/xcb/management/syslog/target/port" />", $tags="SG_Syslog")
     </xsl:if>

    <xsl:for-each select="/ArchiveServers/ArchiveServer">
        Component(ARC<xsl:value-of select="@id" />, "<xsl:value-of select="@name" /> (<xsl:value-of select="@networkAddress" />)", "<xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" /> archive server", $tags="ARCH_<xsl:value-of select="Property[@Name='TransferProtocol']/Property[@Name='Name']" />")
    </xsl:for-each>
}

admins -[hidden]- spp
admins -[hidden]- sps
spp -[hidden]l- sps
spp -[hidden]- int

```

![SPS environment overview](single.png){#fig:environment-overview}



```{.plantuml caption="SPS node local network"}
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
![Local network environment for current node](single.png){#fig:current-node-network}


</xsl:template>


<xsl:function name="ois:nic-address-name">
     <xsl:param name="nics" />
     <xsl:param name="nicId" />
     <xsl:value-of select="concat(
         $nics/nic/interfaces/interface[addresses/address/@id = $nicId]/@name,
         '/',
         $nics/nic/interfaces/interface/addresses/address[@id = $nicId]/addr
     )" />
</xsl:function>

<xsl:function name="ois:sps-policy-name" as="xs:string">
     <xsl:param name="config" />
     <xsl:param name="policyId" as="xs:string?" />
     <xsl:value-of select="concat(
        $config/scb/pol_indexer/indexer[@id = $policyId]/@name,
        $config/scb/pol_audit/audit[@id = $policyId]/@name,
        $config/scb/pol_analytics/analytics[@id = $policyId]/@name,
        $config/xcb/backup_archive/archives/archive[@id = $policyId]/@name,
        $config/xcb/backup_archive/backups/backup[@id = $policyId]/@name,
        $config/scb/pol_settings/settings/setting[@id = $policyId]/@name,
        $config/scb/pol_channels/channels/channel[@id = $policyId]/@name,
        $config/scb/pol_signingca/ca[@id = $policyId]/@name,
        $config/scb/pol_trustedca/ca_list[@id = $policyId]/@name,
        $config/scb/pol_times/time[@id = $policyId]/@name,
        $config/scb/pol_usermappings/mappings[@id = $policyId]/@name,
        $config/scb/content_policies/contentpol[@id = $policyId]/@name,
        $config/scb/credentialstores/credentialstore[@id = $policyId]/@name,
        $config/scb/authentication_policies/*/authentication[@id = $policyId]/@name
      )" />
</xsl:function>
<xsl:function name="ois:sps-certificate-name" as="xs:string">
     <xsl:param name="config" />
     <xsl:param name="certId" as="xs:string?" />
     <xsl:value-of select="ois:sps-policy-name($config, $certId)" />
</xsl:function>

</xsl:stylesheet>
