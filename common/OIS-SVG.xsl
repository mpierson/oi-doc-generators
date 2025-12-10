<?xml version='1.0' encoding="UTF-8"?>
<!--

  SVG related utilities

  Author: M Pierson
  Date: April 2025
  Version: 0.90

 -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >

<xsl:import href="OIS-DateLib.xsl" />

<xsl:key name="timeline-date" match="e" use="date" />

  <xsl:template name="ois:generate-SVG-image">
      <xsl:param name="summary" />
      <xsl:param name="id" />
      <xsl:param name="width" as="xs:integer" />
      <xsl:param name="height" as="xs:integer" />
      <xsl:param name="styles" />
      <xsl:param name="content" />

      <xsl:text><![CDATA[<svg ]]></xsl:text><xsl:value-of select="concat('width=', $width, ' height=', $height)" /><xsl:text><![CDATA[>]]></xsl:text>

      <xsl:if test="string-length($styles) &gt; 0">
          <xsl:text><![CDATA[<style>]]></xsl:text>
          <xsl:copy-of select="$styles" />
          <xsl:text><![CDATA[</style>]]></xsl:text>
      </xsl:if>

      <xsl:copy-of select="$content" />

      <xsl:text><![CDATA[</svg>]]></xsl:text>
      <xsl:if test="string-length($summary) gt 0 and string-length($id) gt 0">
          <xsl:value-of select="concat('![', $summary, '](single.png){#fig:', $id, '}&#xa;&#xa;')" />
      </xsl:if>
    </xsl:template>

    <xsl:function name="ois:generate-SVG-line" as="xs:string">
      <xsl:param name="x" as="xs:integer" />
      <xsl:param name="y" as="xs:integer" />
      <xsl:param name="caption" as="xs:string?" />
      <xsl:param name="path-attrs" as="xs:string?" />
      <xsl:param name="text-attrs" as="xs:string?" />
      <xsl:param name="styles" as="xs:string?" />

      <xsl:variable name="height" select="
                if (string-length($caption) &gt; 0) then ($y+30) 
                else  ($y+20)" as="xs:integer
      " />
      <xsl:variable name="width" select="($x+20)" as="xs:integer" />

      <xsl:variable name="caption-x" select="$width div 2"/>
      <xsl:variable name="caption-y" select="($height div 2) + 3" />

      <xsl:variable name="result">
          <xsl:call-template name="ois:generate-SVG-image">
              <xsl:with-param name="width" select="$width" />
              <xsl:with-param name="height" select="$height" />
              <xsl:with-param name="styles" select="$styles" />
              <xsl:with-param name="content" select="concat(
                      ois:svg-element(
                          'path', 
                          concat(
                              ois:svg-attr('d',  concat('M8,10 l', $x, ',', $y)), 
                              $path-attrs
                          ),
                          ''
                      ),
                      if ( string-length($caption) &gt; 0 ) then
                          ois:svg-element(
                              'text', 
                              concat( 
                                  ois:svg-attr('x', string($caption-x)), 
                                  ois:svg-attr('y', string($caption-y)),
                                  ois:svg-attr('dominant-baseline', 'hanging'),
                                  ois:svg-attr('text-anchor', 'middle'),
                                  $text-attrs
                              ),
                              $caption
                          )
                      else ''
              )" />
          </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="$result" />
    </xsl:function>

    <xsl:function name="ois:generate-SVG-line-h" as="xs:string">
      <xsl:param name="length" as="xs:integer" />
      <xsl:param name="caption" as="xs:string?" />
      <xsl:param name="path-attrs" as="xs:string?" />
      <xsl:param name="text-attrs" as="xs:string?" />
      <xsl:value-of select="ois:generate-SVG-line($length, 0, $caption, $path-attrs, $text-attrs, '')" />
    </xsl:function>


    <xsl:function name="ois:svg-element" as="xs:string">
      <xsl:param name="name" as="xs:string" />
      <xsl:param name="attrs" as="xs:string?" />
      <xsl:param name="value" as="xs:string?" />
      <xsl:value-of select="
              if ( string-length($value) &gt; 0 ) then 
                  concat(ois:svg-start-e($name, $attrs), $value, ois:svg-end-e($name))
              else 
                  concat( '&lt;', $name, ' ', $attrs, '/&gt;')
          " />
    </xsl:function>
    <xsl:function name="ois:svg-start-e" as="xs:string">
      <xsl:param name="name" as="xs:string" />
      <xsl:param name="attrs" as="xs:string?" />
      <xsl:value-of select="concat( '&lt;', $name, ' ', $attrs, '&gt;')" />
    </xsl:function>
    <xsl:function name="ois:svg-end-e" as="xs:string">
      <xsl:param name="name" as="xs:string" />
      <xsl:value-of select="concat( '&lt;/', $name, '&gt;')" />
    </xsl:function>
    <xsl:function name="ois:svg-attr" as="xs:string">
      <xsl:param name="n" as="xs:string" />
      <xsl:param name="v" as="xs:string" />
      <xsl:value-of select="concat( ' ', $n, '=&quot;', $v, '&quot; ')" />
    </xsl:function>

    <xsl:function name="ois:svg-line" as="xs:string">
      <xsl:param name="x1" as="xs:double" />
      <xsl:param name="x2" as="xs:double" />
      <xsl:param name="y1" as="xs:double" />
      <xsl:param name="y2" as="xs:double" />
      <xsl:param name="attrs" as="xs:string?" />
      <xsl:value-of select="
              concat( '&lt;', 'line', ' ', 
                  concat(
                    ois:svg-attr('x1', string($x1)),
                    ois:svg-attr('y1', string($y1)),
                    ois:svg-attr('x2', string($x2)),
                    ois:svg-attr('y2', string($y2)),
                    $attrs
                  ),
              '/&gt;')
      " />
    </xsl:function>
    <xsl:function name="ois:svg-text" as="xs:string">
      <xsl:param name="x" as="xs:double" />
      <xsl:param name="y" as="xs:double" />
      <xsl:param name="t" as="xs:string" />
      <xsl:param name="attrs" as="xs:string?" />
      <xsl:value-of select="concat(
            ois:svg-start-e('text',
                  concat(
                    ois:svg-attr('x', string($x)),
                    ois:svg-attr('y', string($y)),
                    $attrs
                  )
            ),
            $t,
          ois:svg-end-e('text')
      ) " />
    </xsl:function>


    <!-- ===================================================== -->

    <!-- 
        timeline from 
        <events>
            <event date="yyyy-mm-dd">description</event>
            ...
        </events>
    -->
    <xsl:function name="ois:generate-SVG-timeline" as="xs:string">
        <xsl:param name="summary" as="xs:string" />
        <xsl:param name="id" as="xs:string" />
        <xsl:param name="width" as="xs:integer" />
        <xsl:param name="height" as="xs:integer" />
        <xsl:param name="styles" as="xs:string" />
        <xsl:param name="events" />

        <xsl:variable name="y-pad" select="20" />
        <xsl:variable name="x-pad" select="20" />

        <xsl:variable name="events-internal">
            <xsl:apply-templates select="$events/events" mode="events-internal"/>
        </xsl:variable>

        <xsl:variable name="x-axis">
            <xsl:apply-templates select="$events-internal/es" mode="axis">
                <xsl:with-param name="x-pos" select="$x-pad" />
                <xsl:with-param name="y-pos" select="$height - $y-pad" />
                <xsl:with-param name="width" select="$width - 2*$x-pad" />
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="bucket-sizes" as="xs:integer*">
            <xsl:for-each-group select="$events-internal/es/e" group-by="@d">
                <xsl:value-of select="count(current-group())" />
            </xsl:for-each-group>
        </xsl:variable>

        <xsl:variable name="stacks">
            <xsl:for-each-group select="$events-internal/es/e" group-by="@d">
                <xsl:value-of select="ois:svg-event-markers(
                    current-grouping-key(),
                    current-group(),
                    max($bucket-sizes),
                    $x-axis/axis,
                    $height - $x-axis/axis/@height - $y-pad,
                    string(count(current-group()))
                )" />
            </xsl:for-each-group>
        </xsl:variable>

        <xsl:variable name="result">
            <xsl:if test="count(distinct-values($events-internal/es/e/@d)) gt 1">
                <xsl:call-template name="ois:generate-SVG-image">
                    <xsl:with-param name="summary" select="$summary" />
                    <xsl:with-param name="id" select="$id" />
                    <xsl:with-param name="width" select="$width" />
                    <xsl:with-param name="height" select="$height" />
                    <xsl:with-param name="styles" select="$styles" />
                    <xsl:with-param name="content" select="concat(
                        $x-axis,
                        $stacks
                    )"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="concat('&#xa;&#xa;', $result)" />
    </xsl:function>

    <xsl:template match="events" mode="events-internal">
        <es>
            <xsl:attribute name="size" select="count(event)" />
            <xsl:apply-templates select="event" mode="events-internal" />
        </es>
    </xsl:template>
    <xsl:template match="event" mode="events-internal">
        <e>
            <xsl:attribute name="date" select="@date" />
            <xsl:attribute name="d" select="xs:date(@date)" />
            <xsl:attribute name="ndate" select="translate(@date, '-', '')" />
            <xsl:attribute name="label" select="text()" />
        </e>
    </xsl:template>

    <!-- generate timeline axis from collection of events -->
    <xsl:template match="es" mode="axis">
        <xsl:param name="x-pos" as="xs:integer" />
        <xsl:param name="y-pos" as="xs:integer" />
        <xsl:param name="width" as="xs:integer" />

        <!-- padding to reserve on either side of axis, for labels etc. -->
        <xsl:variable name="horiz-pad" as="xs:integer" select="20" />

        <xsl:variable name="marker-length" as="xs:integer" select="8" />

        <xsl:variable name="dates" as="xs:date*" select="e/@d"/>
        <xsl:variable name="start-date" select="min($dates)" />
        <xsl:variable name="end-date" select="max($dates)" />
        <xsl:variable name="duration-days" as="xs:integer" select="days-from-duration($end-date - $start-date)" />

        <xsl:variable name="line-start" as="xs:integer"  select="$x-pos + $horiz-pad" />
        <xsl:variable name="line-length" as="xs:integer"  select="$width - ($horiz-pad * 2)" />
        <xsl:variable name="axis" select="
            if ( $duration-days lt 2 ) then ''
            else ois:svg-line(
                $line-start, $line-start + $line-length, 
                $y-pos, $y-pos, 
                ois:svg-attr('class', 'timeline-line')
            ) " />

        <!-- axis is measured in days, months, years ... -->
        <xsl:variable name="base-unit" select="if ( $duration-days lt 2 ) then 'none'
                                                      else if ( $duration-days lt 20 ) then 'day'
                                                      else if ( $duration-days lt 100 ) then 'week'
                                                      else 'month' " />
        <!-- based on base unit, calculate effective start and end dates -->
        <xsl:variable name="e-start" as="xs:date" select="
            if      ( $base-unit eq 'day' ) then    $start-date
            else if ( $base-unit eq 'week' ) then   $start-date
            else if ( $base-unit eq 'month' ) then  ois:first-of-month($start-date)
            else if ( $base-unit eq 'year' ) then   ois:first-of-year($start-date)
            else current-date()
        " />
        <xsl:variable name="e-end" as="xs:date" select="
            if      ( $base-unit eq 'day' ) then    $end-date
            else if ( $base-unit eq 'week' ) then   $end-date
            else if ( $base-unit eq 'month' ) then  ois:first-of-month($end-date) + xs:yearMonthDuration('P1M')
            else if ( $base-unit eq 'year' ) then   ois:first-of-year($end-date) + xs:yearMonthDuration('P1Y')
            else current-date()
        " />

        <!-- effective date sequence -->
        <xsl:variable name="date-increment" as="xs:duration" select="
            if      ( $base-unit eq 'day' ) then    xs:duration('P1D')
            else if ( $base-unit eq 'week' ) then   xs:duration('P7D')
            else if ( $base-unit eq 'month' ) then  xs:duration('P1M')
            else if ( $base-unit eq 'year' ) then   xs:duration('P1Y')
            else                                    xs:duration('P1D')
        " />
        <xsl:variable name="e-dates" as="xs:date*" select="
            if ( $duration-days lt 2 or $base-unit = 'none' ) then ()
            else ois:date-sequence($e-start, $e-end, $date-increment)
            " />
        <!-- generate ticks for effective date sequence -->
        <xsl:variable name="date-markers">
            <xsl:for-each select="$e-dates">
                <xsl:value-of select="ois:svg-date-tick(
                    $line-start, 
                    $line-start + $line-length - 2, 
                    $y-pos,
                    $marker-length,
                    position(), 
                    count($e-dates) - 1, 
                    format-date(., '[Y]-[M]-[D]') 
                )" />
            </xsl:for-each>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$duration-days lt 2 or $base-unit = 'none'">
                <axis />
            </xsl:when>
            <xsl:otherwise>
                <axis>
                    <xsl:attribute name="xPos" select="$x-pos" />
                    <xsl:attribute name="yPos" select="$y-pos" />
                    <xsl:attribute name="width" select="$width" />
                    <xsl:attribute name="height" select="20" /><!-- marker height + text + gap ?? -->
                    <xsl:attribute name="startPos" select="$line-start" />
                    <xsl:attribute name="endPos" select="$line-start + $line-length" />
                    <xsl:attribute name="startDate" select="$e-start" />
                    <xsl:attribute name="endDate" select="$e-end" />
                    <xsl:attribute name="totalDays" select="days-from-duration($e-end - $e-start)" />
                    <xsl:attribute name="pixelsPerDay" select="$line-length div days-from-duration($e-end - $e-start) " />
                    <!-- graphical content -->
                    <xsl:value-of select="concat($axis, $date-markers)" />
                </axis>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="ois:svg-date-tick" as="xs:string">
        <xsl:param name="x-start" as="xs:double" />
        <xsl:param name="x-end" as="xs:double" />
        <xsl:param name="y-pos" as="xs:double" />
        <xsl:param name="marker-length" as="xs:integer" />
        <xsl:param name="marker-index" as="xs:integer" />
        <xsl:param name="marker-count" as="xs:integer" />
        <xsl:param name="label" as="xs:string?" />

        <xsl:variable name="text-gap" as="xs:integer" select="10" />

        <xsl:variable name="x-pos" as="xs:double" select="$x-start + ($marker-index - 1) * ($x-end - $x-start) div $marker-count + 1" />

        <xsl:value-of select="concat(
                ois:svg-line($x-pos, $x-pos, 
                    $y-pos, $y-pos + $marker-length, 
                    ois:svg-attr('class', 'date-marker')),
                if ( string-length($label) gt 0 ) then 
                    ois:svg-text($x-pos, $y-pos + $marker-length + $text-gap, $label, 
                        concat(
                            ois:svg-attr('style', 'text-anchor: middle;'),
                            ois:svg-attr('class', 'date-label')
                        )
                    )
                else ''
            )" />
    </xsl:function>

    <xsl:function name="ois:svg-event-markers" as="xs:string">
        <xsl:param name="date" as="xs:date" />
        <xsl:param name="events" /><!-- <e>...</e><e>...</e>  -->
        <xsl:param name="max-size" as="xs:integer" /><!-- expected size of largest bucket -->
        <xsl:param name="axis" />
        <xsl:param name="max-height" as="xs:double" />
        <xsl:param name="label" as="xs:string" />

        <xsl:variable name="text-gap" as="xs:integer" select="3" />

        <!-- position of marker, expressed as fraction of total axis length -->
        <xsl:variable name="x" select="
            $axis/@startPos + days-from-duration($date - xs:date($axis/@startDate)) * $axis/@pixelsPerDay
        " />
        <!-- height of marker, relative to max size and height -->
        <xsl:variable name="h" select="count($events) div $max-size * $max-height" />

        <xsl:variable name="line" select="
                ois:svg-line($x, $x, 
                    $axis/@yPos, $axis/@yPos - $h, 
                    ois:svg-attr('class', 'event-marker'))
        " />
        <xsl:variable name="txt" select="
                if ( string-length($label) gt 0 ) then 
                    ois:svg-text($x, $axis/@yPos - $h - $text-gap, $label, 
                        concat(
                            ois:svg-attr('style', 'text-anchor: middle;'),
                            ois:svg-attr('class', 'marker-label')
                        )
                    )
                else ''
        " />

        <xsl:value-of select="concat($line, $txt)" />
    </xsl:function>

    <!-- ===================================================== -->


</xsl:stylesheet>
