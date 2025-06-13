<?xml version='1.0' encoding="UTF-8"?>
<!--

  Ops related to SSB MIBs

  Author: M Pierson
  Date: Mar 2025
  Version: 0.90

Depends on exported MIB defs in xcb-snmp-mib.xml (e.g. from /opt/ssb/etc/)

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >
  <xsl:output omit-xml-declaration="yes" indent="no" />

  <xsl:variable
    name="MIBs-xcb"
    select="document('xcb-snmp-mib.xml')/smi" />

  <xsl:variable
    name="MIBs-ssb"
    select="document('ssb-snmp-mib.xml')/smi" />


  <xsl:template name="ois:get-notification-info">
      <xsl:param name="oid" />

      <xsl:copy-of select="$MIBs-xcb/notifications/notification[@oid=$oid]" />
      <xsl:copy-of select="$MIBs-ssb/notifications/notification[@oid=$oid]" />
  </xsl:template>

</xsl:stylesheet>
