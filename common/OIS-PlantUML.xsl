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

  <!-- Replace reserved characters from string -->
  <xsl:function name="ois:clean-for-plantuml" as="xs:string">
    <xsl:param name="s" as="xs:string"/>

    <xsl:variable name="result">
        <!--<xsl:value-of select="replace($s, '\\`\*_\{\}\[\]\(\)#\+-\.!\|', '')" />-->
        <xsl:value-of select="translate($s, '&#34;', ' ')" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>
  <xsl:function name="ois:clean-for-plantuml-name" as="xs:string">
    <xsl:param name="s" as="xs:string"/>

    <xsl:variable name="result">
        <!--<xsl:value-of select="replace($s, '\\`\*_\{\}\[\]\(\)#\+-\.!\|', '')" />-->
        <xsl:value-of select="translate($s, '-&#34;=, ', '_____')" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function>


<!-- generate a hierarchy list -->

  <xsl:template name="ois:generate-plantuml-tree">
      <xsl:param name="summary" />
      <xsl:param name="id" />
      <xsl:param name="header" />
      <xsl:param name="header-color" />
      <xsl:param name="values" /><!-- <tree><branch><branch>xxx</branch><branch>xxy</branch></branch>...</tree> -->

      <xsl:variable name="color-prefix">&lt;color:</xsl:variable>
      <xsl:variable name="block-start">```{.plantuml caption="_CAPTION_"}</xsl:variable>

  <xsl:if test="count($values/tree/branch) &gt; 0">
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
</xsl:if>

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
        <xsl:value-of select="concat(
            $leader, ' ',
            if ( string-length($color) &gt; 0 ) then concat($color-prefix, $color, '&gt;') else '',
            translate(replace($path, '^.+\\', ' '), '{}', '[]'),
            '&#xa;'
        )" />
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function>


<!-- generate a C4 diag -->

<xsl:template name="ois:generate-plantuml-C4">
    <xsl:param name="summary" />
    <xsl:param name="id" />
    <xsl:param name="content" />

    <xsl:if test="string-length($content) &gt; 0">
      <xsl:value-of select="concat('&#xa;&#xa;```{.plantuml caption=&quot;', $summary, '&quot;}')" />
      <xsl:text>&#xa;&#xa;!include_many header.puml&#xa;&#xa;</xsl:text>
      <xsl:copy-of select="$content" />
      <xsl:text>&#xa;&#xa;```&#xa;&#xa;</xsl:text>
      <xsl:value-of select="concat('&#xa;&#xa;![', $summary, '](single.png){#fig:', $id, '}&#xa;&#xa;')" />
  </xsl:if>

</xsl:template>

<xsl:function name="ois:c4-element-internal" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="attributes" as="xs:string?" />
   <xsl:value-of select="concat(
        '&#xa; ', $type, '(', 
            ois:clean-for-plantuml-name($id), 
            if ( string-length($attributes) gt 0 ) then concat(', ', $attributes)
            else '',
        ') '
    )" />
</xsl:function>
<xsl:function name="ois:c4-make-unnamed-attr" as="xs:string">
    <xsl:param name="v" as="xs:string"/>
    <xsl:value-of select="concat(' &quot;', $v, '&quot; ')" />
</xsl:function>
<xsl:function name="ois:c4-make-named-attr" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="v" as="xs:string"/>
    <xsl:value-of select="concat(' $', $n,'=&quot;', $v, '&quot; ')" />
</xsl:function>

<xsl:function name="ois:c4-element" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
    <xsl:value-of select="ois:c4-element-ext($type, $id, $name, $description, '', $tag)" />
</xsl:function>

<xsl:function name="ois:c4-element-ext" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="type-tag" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>

   <xsl:value-of select="concat(
        '&#xa; ', $type, '(', 
            ois:clean-for-plantuml-name($id), ', ',
            '&quot;', $name, '&quot;,',
            if ( string-length($description) &gt; 0 ) then concat('&quot;', $description, '&quot;,') else '',
            if ( string-length($type-tag) &gt; 0 ) then concat('$type=&quot;', $type-tag, '&quot;') else '',
            '$tags=&quot;', $tag, '&quot;',
        ') '
    )" />
</xsl:function>
<xsl:function name="ois:c4-component" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
   <xsl:value-of select="ois:c4-element('Component', $id, $name, $description, $tag)" />
</xsl:function>
<xsl:function name="ois:c4-container" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="tech" as="xs:string"/>
    <xsl:param name="descr" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
    <xsl:variable name="attrs" select="concat(
        ois:c4-make-unnamed-attr($name), ', ',
        ois:c4-make-unnamed-attr($tech), ', ',
        ois:c4-make-unnamed-attr($descr),
        if ( string-length($tag) ) then concat( ', ', ois:c4-make-named-attr('tags', $tag))
        else ''
    )" />
   <xsl:value-of select="ois:c4-element-internal('Container', $id, $attrs)" />
</xsl:function>
<xsl:function name="ois:c4-system" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
   <xsl:value-of select="ois:c4-element('System', $id, $name, $description, $tag)" />
</xsl:function>
<xsl:function name="ois:c4-boundary-ext" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="tag" as="xs:string"/>
    <xsl:param name="content" as="xs:string"/>
    <xsl:value-of select="concat('&#xa; ', 
                ois:c4-element-ext('Boundary', $id, $name, '', $type, $tag),
                ' {&#xa;',
                    $content,
                '&#xa;}&#xa;'
        )" />
</xsl:function>
<xsl:function name="ois:c4-boundary" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="tag" as="xs:string"/>
    <xsl:param name="content" as="xs:string"/>
    <xsl:value-of select="concat('&#xa; ', 
                ois:c4-element('Boundary', $id, $name, '', $tag),
                ' {&#xa;',
                    $content,
                '&#xa;}&#xa;'
        )" />
</xsl:function>
<xsl:function name="ois:c4-node" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string"/>
    <xsl:param name="content" as="xs:string"/>
    <xsl:value-of select="concat('&#xa; ', 
                ois:c4-element('Node', $id, $name, $description, $tag),
                ' {&#xa;',
                    $content,
                '&#xa;}&#xa;'
        )" />
</xsl:function>
<xsl:function name="ois:c4-rel-common" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="id-left" as="xs:string"/>
    <xsl:param name="id-right" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
   <xsl:value-of select="concat(
        '&#xa; ', $type, '(', 
            ois:clean-for-plantuml-name($id-left), ', ',
            ois:clean-for-plantuml-name($id-right), ', ',
            concat('&quot;', $description, '&quot;,'),
            '$tags=&quot;', $tag, '&quot;',
        ') '
    )" />
</xsl:function>
<xsl:function name="ois:c4-rel" as="xs:string">
    <xsl:param name="id-left" as="xs:string"/>
    <xsl:param name="id-right" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
   <xsl:value-of select="ois:c4-rel-common('Rel', $id-left, $id-right, $description, $tag)" />
</xsl:function>
<xsl:function name="ois:c4-birel" as="xs:string">
    <xsl:param name="id-left" as="xs:string"/>
    <xsl:param name="id-right" as="xs:string"/>
    <xsl:param name="description" as="xs:string?"/>
    <xsl:param name="tag" as="xs:string?"/>
   <xsl:value-of select="ois:c4-rel-common('BiRel', $id-left, $id-right, $description, $tag)" />
</xsl:function>

<xsl:function name="ois:puml-component" as="xs:string">
    <xsl:param name="id"            as="xs:string"/>
    <xsl:param name="label"         as="xs:string"/>
    <xsl:param name="description"   as="xs:string"/>
    <xsl:param name="tags"          as="xs:string"/>
    <xsl:value-of select="concat(
            '&#10;Component(', 
                $id, ', ',
                '&quot;', $label, '&quot;, ', 
                '&quot;', $description, '&quot;, ', 
                '$tags=&quot;', $tags, '&quot;', 
            ')'
    )" />
</xsl:function>

</xsl:stylesheet>
