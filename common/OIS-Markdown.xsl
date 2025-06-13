<?xml version='1.0' encoding="UTF-8"?>
<!--

  Markdown related utilities

  Author: M Pierson
  Date: April 2025
  Version: 0.90

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >


  <!-- Replace markdown reserved characters from string -->
  <xsl:function name="ois:escape-for-markdown" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    
    <xsl:variable name="result">
        <xsl:value-of select="replace(translate($s, '\', '/'), '_', '\\_')" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>
  <xsl:function name="ois:escape-markdown-id" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    
    <xsl:variable name="result">
        <xsl:value-of select="translate($s, ' -', '__')" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>
  <!-- Replace markdown reserved characters from string -->
  <xsl:function name="ois:clean-for-markdown" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    
    <xsl:variable name="result">
        <!--<xsl:value-of select="replace($s, '\\`\*_\{\}\[\]\(\)#\+-\.!\|', '')" />-->
        <xsl:value-of select="translate($s, '\`*_#|', '/     ')" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>


  <!-- Replace line feeds etc from string, suitable for Markdown table -->
  <xsl:template name="ois:escape-for-markdown-table">
    <xsl:param name="s" as="xs:string"/>
    
    <xsl:variable name="tokens" select="tokenize($s, '&#10;')" />
    <xsl:for-each select="$tokens">
        <xsl:value-of select="." /><br />
    </xsl:for-each>

  </xsl:template>


  <!-- generate a markdown table -->
  <xsl:template name="ois:generate-table">
      <xsl:param name="summary" />
      <xsl:param name="id" />
      <xsl:param name="header" />
      <xsl:param name="separator" />
      <xsl:param name="values" />

      <xsl:if test="count($values/rows/row) &gt; 0">

      <xsl:text>

Table: </xsl:text><xsl:value-of select="$summary"/> {#tbl:<xsl:value-of select="$id"/>} 
<xsl:text>
</xsl:text>
      <xsl:value-of select="normalize-space($header)" /><xsl:text>
</xsl:text><xsl:value-of select="normalize-space($separator)" />
      <xsl:apply-templates select="$values/rows/row" mode="table" />
  </xsl:if>
  </xsl:template>
  <xsl:template match="row" mode="table">
      <xsl:text>
| </xsl:text>
      <xsl:apply-templates select="value" mode="table" />
      <xsl:text> </xsl:text>
  </xsl:template>
  <xsl:template match="value" mode="table">
      <xsl:choose>
          <xsl:when test="position() = 1">
              <xsl:text>**</xsl:text><xsl:value-of select="."/><xsl:text>** | </xsl:text>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="."/><xsl:text> | </xsl:text>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:template>


  <!-- Function to output markdown definition, if value is not null -->
  <xsl:function name="ois:markdown-definition" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:string?"/>

    <xsl:variable name="result">
      <xsl:value-of select="if (string-length($v) &gt; 0) then concat('&#xa;**', $n, '**: ', $v, '&#xa;') else ''" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>
  <!-- Function to output markdown definition, if value is not zero -->
  <xsl:function name="ois:markdown-definition-int" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:integer?"/>

    <xsl:variable name="result">
      <xsl:value-of select="if ($v &gt; 0) then concat('&#xa;**', $n, '**: ', $v, '&#xa;') else ''" />
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>
  <!-- Function to output markdown definition, if value is not 'False' -->
  <xsl:function name="ois:markdown-definition-bool" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:string?"/>

    <xsl:variable name='bv' select="normalize-space(lower-case($v))" />
    <xsl:variable name="result">
      <xsl:value-of select="if ($bv != 'false') then ois:markdown-definition($n, $v) else ''" />
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>
  <!-- Function to output markdown definition, value is code -->
  <xsl:function name="ois:markdown-definition-code" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:string?"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="string-length($v) &gt; 0">
                <xsl:value-of select="ois:markdown-definition($n, concat('`',$v,'`'))" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>
  <!-- Function to create inline code, with max length -->
  <xsl:function name="ois:markdown-inline-code" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:param name="length" as="xs:integer"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="string-length($s) &gt; 0">
                <xsl:value-of select="concat(
                            '`',
                            ois:truncate-string(translate($s, '&#xa;', ' '), $length, '...'),
                            '`')" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>

  <!-- generate a markdown list -->
  <xsl:template name="ois:generate-markdown-list">
      <xsl:param name="header" />
      <xsl:param name="values" /><!-- expect <items><value>xxx</value>...</items> -->

      <xsl:if test="count($values/items/value) &gt; 0">
          <xsl:value-of select="concat('&#xa;&#xa;**', normalize-space($header), '**:&#xa;&#xa;')" />
          <xsl:apply-templates select="$values/items/value" mode="list" />
      </xsl:if>
  </xsl:template>
  <xsl:template match="items" mode="list">
      <xsl:text>&#xa;&#xa;</xsl:text>
      <xsl:apply-templates select="value" mode="list" />
  </xsl:template>
  <xsl:template match="value" mode="list">
      <xsl:value-of select="concat(ois:markdown-list-item(.,0), '&#xa;')" />
  </xsl:template>
  <!-- Function to output literal list item, with given indentation -->
  <xsl:function name="ois:markdown-list-item" as="xs:string">
    <xsl:param name="v" as="xs:string"/>
    <xsl:param name="indent-level" as="xs:integer"/>
    <xsl:variable name="indent-master" select="'                                                                    '"/>
    <xsl:variable name="result">
        <xsl:value-of select="concat(substring($indent-master, 1, $indent-level*2), '- ', $v)" /> 
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>


  <xsl:template name="ois:generate-markdown-code-block">
      <xsl:param name="header" />
      <xsl:param name="code" />
      <xsl:param name="code-type" />

      <xsl:if test="string-length($code) &gt; 0">
          <xsl:value-of select="concat('&#xa;&#xa;', $header, '')" />
          <xsl:value-of select="concat('&#xa;```', $code-type, '&#xa;')"/>
          <!-- <xsl:value-of select="replace(translate($code, '&#xd;', '&#xa;'),'^\s+|\s+$','')" />-->
          <!--<xsl:value-of select="translate($code, '&#xd;', '&#xa;')" />-->
          <!--<xsl:value-of select="$code" />-->
          <xsl:value-of select="replace($code, '  ', '&#xa;')" />
          <xsl:text>&#xa;```&#xa;</xsl:text>
      </xsl:if>  
  </xsl:template>



  <!-- Function to output markdown figure -->
  <xsl:function name="ois:markdown-figure" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:param name="filename" as="xs:string"/>
    <xsl:param name="id" as="xs:string?"/>

    <xsl:variable name='ref' select="if (string-length($id) &gt; 0) then concat('{#fig:', $id, '}') else ''" />
    <xsl:variable name="result">
      <xsl:value-of select="concat('&#xa;&#xa;![', $caption, '](', $filename, ')', $ref, '&#xa;&#xa;')" />
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>

</xsl:stylesheet>
