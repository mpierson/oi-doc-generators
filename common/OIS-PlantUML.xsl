<?xml version='1.0' encoding="UTF-8"?>
<!--

  PlantUML related utilities

  Author: M Pierson
  Date: April 2025
  Version: 0.90

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >



<!-- generate a hierarchy list -->

  <xsl:template name="ois:generate-plantuml-tree">
      <xsl:param name="summary" />
      <xsl:param name="id" />
      <xsl:param name="header" />
      <xsl:param name="header-color" />
      <xsl:param name="values" /><!-- <tree><branch><branch>xxx</branch><branch>xxy</branch></branch>...</tree> -->


      <xsl:variable name="color-prefix">&lt;color:</xsl:variable>
      <xsl:variable name="block-start">```{.plantuml caption="_CAPTION_"}</xsl:variable>
      <xsl:text>&#xa;&#xa;</xsl:text>
      <xsl:value-of select="replace($block-start,'_CAPTION_', $summary)" />
      <xsl:text>

@startsalt
scale 1.5
{   
{T 

</xsl:text> 
<xsl:if test="string-length($header) &gt; 0">
    <xsl:if test="string-length($header-color) &gt; 0">
        <xsl:value-of disable-output-escaping="yes" select="concat($color-prefix, $header-color)"/><xsl:text disable-output-escaping="yes">></xsl:text>
    </xsl:if>
    <xsl:value-of select="concat($header, '&#xa;')" />
</xsl:if>
<xsl:apply-templates select="$values/tree" mode="tree"/>

<xsl:text>

}                                                                                                                         
}
@endsalt


```
</xsl:text>
<xsl:value-of select="concat('![', $summary, '](single.png){#fig:', $id, '}&#xa;&#xa;')" />

</xsl:template>
<xsl:template match="tree" mode="tree">
    <xsl:variable name="color" select="if (@color='') then 'black' else @color" />
    <xsl:if test="string-length(@name) &gt; 0">
        <xsl:value-of select="if (@name='') then '' else ois:get-puml-tree-string(@name, '\\', $color)" />
    </xsl:if>
    <xsl:apply-templates select="branch" mode="tree" />
</xsl:template>
<xsl:template match="branch" mode="tree">
    <xsl:variable name="color" select="if (@color='') then 'blue' else @color" />
    <xsl:value-of select="ois:get-puml-tree-string(@path, '\\', $color)" />
    <xsl:apply-templates select="branch" mode="tree" />
</xsl:template>

<xsl:function name="ois:get-puml-tree-string" as="xs:string">
    <xsl:param name="path" as="xs:string"/>
    <xsl:param name="separator" as="xs:string"/>
    <xsl:param name="color" as="xs:string"/>

    <xsl:variable name="color-prefix">&lt;color:</xsl:variable>

    <!-- TODO: check incoming path for too many levels -->
    <xsl:variable name="big-leader"> ++++++++++++++++++++++++++++++++++++++++</xsl:variable>
    <xsl:variable name="depth" select="string-length($path) - string-length(translate($path, $separator, ''))" />
    <xsl:variable name="leader" select="substring($big-leader, 0, $depth+3)" />

    <xsl:variable name="result">
<xsl:value-of select="$leader" /><xsl:text> </xsl:text
><xsl:if test="string-length($color) &gt; 0"><xsl:value-of  disable-output-escaping="yes" select="concat($color-prefix, $color)"/><xsl:text disable-output-escaping="yes">></xsl:text></xsl:if
    ><xsl:value-of select="replace($path, '^.+\\', ' ')" /><xsl:text>
</xsl:text>
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function>

</xsl:stylesheet>
