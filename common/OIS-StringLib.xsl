<?xml version='1.0' encoding="UTF-8"?>
<!--

  String related utilities

  Author: M Pierson
  Date: April 2025
  Version: 0.90

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >


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


  <!-- Function to apply default to empty string -->
  <xsl:function name="ois:is-null-string" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:param name="default" as="xs:string?"/>
    
    <xsl:variable name="result">
        <xsl:value-of select="if (string-length($s) &gt; 0) then $s else $default" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>

  <!-- Function to test for empty string -->
  <xsl:function name="ois:is-empty-string" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:param name="on-empty" as="xs:string?"/>
    <xsl:param name="on-non-empty" as="xs:string?"/>
    
    <xsl:variable name="result">
        <xsl:value-of select="if (string-length($s) &gt; 0) then $on-non-empty else $on-empty" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>

  <!-- Function to concat if first value is non-null -->
  <xsl:function name="ois:concat-nonempty-string" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:param name="suffix" as="xs:string?"/>
    
    <xsl:variable name="result">
        <xsl:value-of select="ois:is-empty-string($s, '', concat($s, $suffix))" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>



  <!-- Return True or False based on boolean -->
  <xsl:function name="ois:true-or-false" as="xs:string">
    <xsl:param name="n"/>
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="boolean($n)">True</xsl:when>
            <xsl:otherwise>False</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>


  <!-- Return string value by index, given list of <s>xxxx</s><s>yyyy</s>, zero-based -->
  <xsl:template name="ois:select-by-index" as="xs:string">
    <xsl:param name="i" as="xs:integer" />
    <xsl:param name="values"/>
    <xsl:value-of select="$values/v[$i]" />
  </xsl:template>


  <!-- Trim leading substring  -->
  <xsl:function name="ois:left-trim" as="xs:string">
    <xsl:param name="s" as="xs:string" />
    <xsl:param name="t" as="xs:string" />
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="string-length($s) &gt; 0 
                                and string-length($t) &gt; 0 
                                and starts-with($s, $t)"
                    ><xsl:value-of select="substring($s,string-length($t)+1)" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$s" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>

  <!-- Render map as string
    Expect map content like:
    <items><value key="...">...</value>...</items> 
  -->
  <xsl:function name="ois:map-to-string" as="xs:string">
    <xsl:param name="m" />
    <xsl:param name="divider" as="xs:string"/>
    <xsl:param name="separator" as="xs:string"/>
    <xsl:variable name="result">
        <xsl:if test="count($m/items/value) &gt; 0">
            <values>
                <xsl:apply-templates select="$m/items/value" mode="map">
                    <xsl:with-param name="divider" select="$divider" />
                </xsl:apply-templates>
            </values>
      </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$result/values/value" separator="{$separator}" />

  </xsl:function>
   <xsl:template match="value" mode="map">
       <xsl:param name="divider" select="':'"/>
       <xsl:if test="string-length(.) &gt; 0">
           <value>
               <xsl:value-of select="concat(@key, $divider, .)" />
           </value>
       </xsl:if>
  </xsl:template>



  <!-- XSLT HASH Fn   https://stackoverflow.com/questions/6753343/using-xsl-to-make-a-hash-of-xml-file -->
  <xsl:function name="ois:checksum" as="xs:integer">
        <xsl:param name="str" as="xs:string"/>
        <xsl:variable name="codepoints" select="string-to-codepoints($str)"/>
        <xsl:value-of select="ois:fletcher16($codepoints, count($codepoints), 1, 0, 0)"/>
    </xsl:function>
    <xsl:function name="ois:fletcher16">
        <xsl:param name="str" as="xs:integer*"/>
        <xsl:param name="len" as="xs:integer" />
        <xsl:param name="index" as="xs:integer" />
        <xsl:param name="sum1" as="xs:integer" />
        <xsl:param name="sum2" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$index gt $len">
                <xsl:sequence select="$sum2 * 256 + $sum1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="newSum1" as="xs:integer"
                    select="($sum1 + $str[$index]) mod 255"/>
                <xsl:sequence select="ois:fletcher16($str, $len, $index + 1, $newSum1,
                        ($sum2 + $newSum1) mod 255)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

  <!-- Return a well-formatted delimited list -->
  <xsl:function name="ois:delimit-list" as="xs:string">
    <xsl:param name="sep" as="xs:string"/>
    <xsl:param name="s1" as="xs:string"/>
    <xsl:param name="s2" as="xs:string"/>
    <xsl:param name="s3" as="xs:string?"/>
    <xsl:param name="s4" as="xs:string?"/>
    <xsl:param name="s5" as="xs:string?"/>
    <xsl:param name="s6" as="xs:string?"/>
    <xsl:param name="s7" as="xs:string?"/>
    <xsl:variable name="values">
        <values>
            <xsl:if test="string-length($s1) &gt; 0"><v><xsl:value-of select="$s1" /></v></xsl:if>
            <xsl:if test="string-length($s2) &gt; 0"><v><xsl:value-of select="$s2" /></v></xsl:if>
            <xsl:if test="string-length($s3) &gt; 0"><v><xsl:value-of select="$s3" /></v></xsl:if>
            <xsl:if test="string-length($s4) &gt; 0"><v><xsl:value-of select="$s4" /></v></xsl:if>
            <xsl:if test="string-length($s5) &gt; 0"><v><xsl:value-of select="$s5" /></v></xsl:if>
            <xsl:if test="string-length($s6) &gt; 0"><v><xsl:value-of select="$s6" /></v></xsl:if>
            <xsl:if test="string-length($s7) &gt; 0"><v><xsl:value-of select="$s7" /></v></xsl:if>
        </values>
    </xsl:variable>
    <xsl:value-of select="string-join($values/values/v, $sep)" />
  </xsl:function>
  <xsl:function name="ois:delimit-list" as="xs:string">
    <xsl:param name="sep" as="xs:string"/>
    <xsl:param name="s1" as="xs:string"/>
    <xsl:param name="s2" as="xs:string"/>
    <xsl:param name="s3" as="xs:string?"/>
    <xsl:param name="s4" as="xs:string?"/>
    <xsl:param name="s5" as="xs:string?"/>
    <xsl:param name="s6" as="xs:string?"/>
    <xsl:value-of select="ois:delimit-list($sep,$s1,$s2,$s3,$s4,$s5,$s6,'')" />
  </xsl:function>
  <xsl:function name="ois:delimit-list" as="xs:string">
    <xsl:param name="sep" as="xs:string"/>
    <xsl:param name="s1" as="xs:string"/>
    <xsl:param name="s2" as="xs:string"/>
    <xsl:param name="s3" as="xs:string?"/>
    <xsl:param name="s4" as="xs:string?"/>
    <xsl:param name="s5" as="xs:string?"/>
    <xsl:value-of select="ois:delimit-list($sep,$s1,$s2,$s3,$s4,$s5,'','')" />
  </xsl:function>
  <xsl:function name="ois:delimit-list" as="xs:string">
    <xsl:param name="sep" as="xs:string"/>
    <xsl:param name="s1" as="xs:string"/>
    <xsl:param name="s2" as="xs:string"/>
    <xsl:param name="s3" as="xs:string?"/>
    <xsl:param name="s4" as="xs:string?"/>
    <xsl:value-of select="ois:delimit-list($sep,$s1,$s2,$s3,$s4,'','','')" />
  </xsl:function>
  <xsl:function name="ois:delimit-list" as="xs:string">
    <xsl:param name="sep" as="xs:string"/>
    <xsl:param name="s1" as="xs:string"/>
    <xsl:param name="s2" as="xs:string"/>
    <xsl:param name="s3" as="xs:string?"/>
    <xsl:value-of select="ois:delimit-list($sep,$s1,$s2,$s3,'','','','')" />
  </xsl:function>

</xsl:stylesheet>
