<?xml version='1.0' encoding="UTF-8"?>
<!--

  Date related utilities

  Author: M Pierson
  Date: Dec 2025
  Version: 0.90

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >


    <!-- returns sequence of date objects for given start/end -->
    <xsl:function name="ois:date-sequence" as="xs:date*">
        <xsl:param name="start" as="xs:date"/>
        <xsl:param name="end" as="xs:date"/>
        <xsl:param name="increment" as="xs:duration" />
        <xsl:variable name="incr-ym" as="xs:yearMonthDuration" select="$increment cast as xs:yearMonthDuration" />
        <xsl:variable name="incr-dt" as="xs:dayTimeDuration" select="$increment cast as xs:dayTimeDuration" />
        <xsl:iterate select="1 to 999">
            <xsl:param name="d" select="$start" as="xs:date"/>
            <xsl:variable name="new-date" select="$d + $incr-ym + $incr-dt"/>
            <xsl:value-of select="$d" />
            <xsl:choose>
                <xsl:when test="$new-date gt $end">
                    <xsl:break />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:next-iteration>
                        <xsl:with-param name="d" select="$new-date"/>
                    </xsl:next-iteration>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:iterate> 
    </xsl:function>

    <!-- returns date representing first of month for given date -->
    <xsl:function name="ois:first-of-month" as="xs:date">
        <xsl:param name="d" as="xs:date"/>
        <xsl:variable name="offset" as="xs:dayTimeDuration" select="xs:dayTimeDuration(concat('-P', day-from-date($d) - 1, 'D'))" />
        <xsl:sequence select="$d + $offset" />
    </xsl:function>

    <!-- returns date representing Jan 1st, same year as given date -->
    <xsl:function name="ois:first-of-year" as="xs:date">
        <xsl:param name="d" as="xs:date"/>
        <xsl:sequence select="xs:date( '{year-from-date($d)}-01-01' )" />
    </xsl:function>





  <!-- Function to convert IP string to integer -->
  <xsl:function name="ois:truncate-string" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:param name="length" as="xs:integer"/>
    <xsl:param name="indicator" as="xs:string"/>
    
    <xsl:variable name="result">
    <xsl:choose>
        <xsl:when test="string-length($s) &gt; $length">
            <xsl:value-of select="substring($s, 1, $length)" /><xsl:if test="string-length($indicator) &gt; 0"><xsl:value-of select="$indicator" /></xsl:if>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$s" /></xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>



</xsl:stylesheet>
