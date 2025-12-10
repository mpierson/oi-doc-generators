<?xml version='1.0' encoding="UTF-8"?>
<!--

  JSON-related utilities

  Author: M Pierson
  Date: Mar 2025
  Version: 0.90

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >



<xsl:template name="get-json-value">
     <xsl:param name="json" />
     <xsl:param name="key" />
     <!-- look for "key": value, where value may be quoted, and may be followed by delimiters '}' or ',' -->
     <xsl:variable name="regex"><xsl:value-of select="$key" />&quot;: &quot;?([^&quot;}]*?)[&quot;,\}]</xsl:variable>
<xsl:analyze-string select="$json" regex="{$regex}">
  <xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
</xsl:analyze-string>
</xsl:template>

<xsl:function name="ois:json-get-value" as="xs:string">                                                          
     <xsl:param name="json" />
     <xsl:param name="key" />

     <!-- look for "key": value, where value may be quoted, and may be followed by delimiters '}' or ',' -->
     <xsl:variable name="regex"><xsl:value-of select="$key" />&quot;: &quot;?([^&quot;}]*?)[&quot;,\}]</xsl:variable>
    <xsl:variable name="content">
        <xsl:analyze-string select="$json" regex="{$regex}">
            <xsl:matching-substring><xsl:value-of select="regex-group(1)" /></xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    <xsl:value-of select="$content" />
</xsl:function>


</xsl:stylesheet>
