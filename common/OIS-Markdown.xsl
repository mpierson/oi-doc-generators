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
        <xsl:value-of select="translate($s, ' -/', '___')" />
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
    <xsl:param name="s" as="xs:string?"/>
    
    <xsl:variable name="tokens" select="tokenize($s, '&#10;')" />
    <xsl:for-each select="$tokens">
        <xsl:value-of select="concat(., '&lt;br /&gt;')" />
    </xsl:for-each>

  </xsl:template>
  <xsl:function name="ois:encode-breaks-for-markdown-table" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="tokens" select="tokenize($s, '&#10;')" />
    <xsl:variable name="result">
        <xsl:for-each select="$tokens">
            <xsl:value-of select="concat(., '&lt;br /&gt;')" />
        </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>


  <!-- generate a markdown table -->
  <xsl:template name="ois:generate-table">
      <xsl:param name="summary" />
      <xsl:param name="id" />
      <xsl:param name="header" />
      <xsl:param name="separator" />
      <xsl:param name="values" />
      <xsl:param name="empty-message" />
      <xsl:param name="max-size" as="xs:integer?" select="-1" />
      <xsl:variable name="size-limit" select="if ( $max-size &gt; 0 ) then $max-size else  count($values/rows/row)" />

      <xsl:if test="count($values/rows/row) &gt; 0">

      <xsl:text>

Table: </xsl:text><xsl:value-of select="$summary"/> {#tbl:<xsl:value-of select="$id"/>} 
<xsl:text>
</xsl:text>
      <xsl:value-of select="normalize-space($header)" /><xsl:text>
</xsl:text><xsl:value-of select="normalize-space($separator)" />
<xsl:apply-templates select="$values/rows/row[position() &lt;= $size-limit]" mode="table" />
  </xsl:if>
  <xsl:if test="count($values/rows/row) = 0">
      <xsl:text>
</xsl:text><xsl:value-of select="$empty-message" />
</xsl:if>
  </xsl:template>
  <xsl:template match="row" mode="table">
      <xsl:text>
| </xsl:text>
      <xsl:apply-templates select="value" mode="table" />
      <xsl:text> </xsl:text>
  </xsl:template>
  <xsl:template match="value" mode="table">
      <xsl:variable name="escaped-nodes">
          <xsl:call-template name="ois:escape-for-markdown-table">
              <xsl:with-param name="s" select="." />
          </xsl:call-template>
      </xsl:variable>
      <xsl:choose>
          <xsl:when test="position() = 1">
              <xsl:text>**</xsl:text>
              <xsl:value-of select="$escaped-nodes" disable-output-escaping="yes" />
              <xsl:text>** | </xsl:text>
          </xsl:when>
          <xsl:otherwise>
              <xsl:copy-of select="$escaped-nodes" />
              <xsl:text> | </xsl:text>
          </xsl:otherwise>
      </xsl:choose>
  </xsl:template>


  <!-- Function to output markdown definition, if value is not null -->
  <xsl:function name="ois:markdown-definition" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:string?"/>

    <xsl:variable name="result">
      <xsl:value-of select="if (string-length($v) &gt; 0) then concat('&#xa;&#xa;**', $n, '**: ', $v, '&#xa;') else ''" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>
  <!-- Function to output markdown definition, if value is not zero -->
  <xsl:function name="ois:markdown-definition-int" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:double?"/>

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
  <!-- Function to output markdown definition with block of code, value is code -->
  <xsl:function name="ois:markdown-definition-codeblock" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:string?"/>
    <xsl:param name="language" as="xs:string?"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="string-length($v) &gt; 0">
                <xsl:value-of select="ois:markdown-definition($n, 
                            concat('&#xa;```',$language,'&#xa;',$v,'&#xa;```&#xa;'))" />
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
      <xsl:param name="max-size" as="xs:integer?" select="-1" />
      <xsl:variable name="size" select="count($values/items/value)" />

      <xsl:choose>
          <xsl:when test="
                    $size &gt; 0
                    and (
                      not($max-size &gt; 0) 
                      or 
                      $size &lt; $max-size
                    ) 
              ">
              <xsl:value-of select="concat('&#xa;&#xa;**', normalize-space($header), '**:&#xa;&#xa;')" />
              <xsl:apply-templates select="$values/items/value" mode="list" />
          </xsl:when>
          <xsl:when test="($max-size &gt; 0) and ($size &gt; $max-size)">
              <xsl:value-of select="ois:markdown-definition-int($header, count($values/items/value))" />
          </xsl:when>
      </xsl:choose>
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
          <xsl:value-of select="$code" />
          <!--<xsl:value-of select="replace($code, '  ', '&#xa;')" />-->
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

  <!-- Function to output markdown heading -->
  <xsl:function name="ois:markdown-heading" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:param name="level" as="xs:integer"/>

    <xsl:variable name="big-leader">############</xsl:variable>                      
    <xsl:variable name="leader" select="substring($big-leader, 0, $level + 1)" />

    <xsl:variable name="result">
      <xsl:value-of select="concat('&#xa;&#xa;', $leader, ' ', ois:escape-for-markdown($caption), '&#xa;&#xa;')" />
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>
  <xsl:function name="ois:markdown-heading-1" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:value-of select="ois:markdown-heading($caption, 1)" />
  </xsl:function>
  <xsl:function name="ois:markdown-heading-2" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:value-of select="ois:markdown-heading($caption, 2)" />
  </xsl:function>
  <xsl:function name="ois:markdown-heading-3" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:value-of select="ois:markdown-heading($caption, 3)" />
  </xsl:function>
  <xsl:function name="ois:markdown-heading-4" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:value-of select="ois:markdown-heading($caption, 4)" />
  </xsl:function>
  <xsl:function name="ois:markdown-heading-5" as="xs:string">
    <xsl:param name="caption" as="xs:string"/>
    <xsl:value-of select="ois:markdown-heading($caption, 5)" />
  </xsl:function>

  <!-- generate a markdown list, suitable for table cell -->
  <xsl:template name="ois:generate-markdown-table-list">
      <xsl:param name="values" /><!-- expect <items><value>xxx</value>...</items> -->
      <xsl:if test="count($values/items/value) &gt; 0">
          <xsl:apply-templates select="$values/items/value" mode="table-list" />
      </xsl:if>
  </xsl:template>
  <xsl:template match="items" mode="table-list">
      <xsl:apply-templates select="value" mode="table-list" />
  </xsl:template>
  <xsl:template match="value" mode="table-list">
      <xsl:value-of select="ois:encode-breaks-for-markdown-table(concat('- ', ois:escape-for-markdown(.), ' '))" />
  </xsl:template>


</xsl:stylesheet>
