<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SSB config export to Markdown

  Author: M Pierson
  Date: Mar 2025
  Version: 0.91

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

 -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" 
                              exclude-result-prefixes="ois xs">
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:import href="OIS-JSONLib.xsl" />
  <xsl:import href="OIS-StringLib.xsl" />
  <xsl:import href="OIS-Markdown.xsl" />
  <xsl:import href="OIS-PlantUML.xsl" />
  <xsl:import href="OIS-SVG.xsl" />
  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />

  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />


 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>


   <!-- Function to format lines for a table cell -->
  <xsl:template name="format-table-lines">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="newline">\n</xsl:variable>
    <xsl:for-each select="tokenize($s, $newline)"><xsl:text>` </xsl:text><xsl:sequence select="."/><xsl:text> ` </xsl:text><br /></xsl:for-each>
  </xsl:template>

<xsl:template match="IdentityManager">

---
title: One Identity Manager Customization Report for <xsl:value-of select="@name" /> 
author: OneIM As Built Generator v0.91
abstract: |
    Schema customizations of the <xsl:value-of select="@name" /> instance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Schedules
<xsl:apply-templates select="Schedules"/> 

# Schema
<xsl:apply-templates select="Tables"/> 

<xsl:apply-templates select="Processes"/> 


<xsl:apply-templates select="Scripts" />

# Mail Templates
<xsl:apply-templates select="MailTemplates" />

# Predefined SQL
<xsl:apply-templates select="LimitedSQLScripts" />

<xsl:apply-templates select="ChangeLabels" />

</xsl:template>


<!-- ===== Schedules ======================= -->

<xsl:template match="Schedules">

    <xsl:value-of select="ois:markdown-heading-2('Annual View')" />

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and (
                        @frequencyType = 'Year' or (@frequencyType = 'Month' and @frequency &gt; 4))]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24*365; yday(range_start)&lt;-1; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + years(4)'" />
        <xsl:with-param name="units" select="'year'" />
        <xsl:with-param name="date-format" select="'%Y'" />
        <xsl:with-param name="tick-units" select="'month'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 4 year view'" />
        <xsl:with-param name="figure-id" select="'schedule-4-year'" />
    </xsl:call-template>


    <xsl:call-template name="schedule-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Yearly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-yearly'" />
        <xsl:with-param name="unit" select="'Year'" />
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Year']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:value-of select="ois:markdown-heading-2('Monthly View')" />

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
                                    (contains('Year Month', @frequencyType)
                                        or @frequencyType='Week' and @frequency > 2)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24*28; mday(range_start)&lt;-1; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + months(6)'" />
        <xsl:with-param name="units" select="'month'" />
        <xsl:with-param name="date-format" select="'%B'" />
        <xsl:with-param name="tick-units" select="'month'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 6 month view'" />
        <xsl:with-param name="figure-id" select="'schedule-6-month'" />
    </xsl:call-template>

    <xsl:call-template name="schedule-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Monthly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-monthly'" />
        <xsl:with-param name="unit" select="'Month'" />
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Month']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:value-of select="ois:markdown-heading-2('Weekly View')" />


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
                                    (contains('Year Month Week', @frequencyType)
                                        or @frequencyType='Day' and @frequency > 2)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24*7; wday(range_start)&lt;-1; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + weeks(4)'" />
        <xsl:with-param name="units" select="'week'" />
        <xsl:with-param name="date-format" select="'%B %d'" />
        <xsl:with-param name="tick-units" select="'day'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 1 month view'" />
        <xsl:with-param name="figure-id" select="'schedule-1-month'" />
    </xsl:call-template>

    <xsl:call-template name="schedule-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Weekly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-weekly'" />
        <xsl:with-param name="unit" select="'Week'" />
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Week']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:value-of select="ois:markdown-heading-2('Daily View')" />

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
                                    (contains('Year Month Week Day', @frequencyType)
                                        or @frequencyType='Hour' and @frequency > 18)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + days(7)'" />
        <xsl:with-param name="units" select="'day'" />
        <xsl:with-param name="date-format" select="'%B %d'" />
        <xsl:with-param name="tick-units" select="'day'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 1 week view'" />
        <xsl:with-param name="figure-id" select="'schedule-1-week'" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Daily_.'" />
        <xsl:with-param name="id" select="'summary-schedules-daily'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Run Every n Days | Start Time | Time Zone |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:----|:---:|:--:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Day']" mode="table-day" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:value-of select="ois:markdown-heading-2('Hourly View')" />

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
                                    (contains('Year Month Week Day', @frequencyType)
                                        or @frequencyType='Hour' and @frequency > 1)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now()+3600*24; minute(range_start)&lt;-0; hour(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + hours(48)'" />
        <xsl:with-param name="units" select="'2 hours'" />
        <xsl:with-param name="date-format" select="'%H'" />
        <xsl:with-param name="tick-units" select="'hour'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 48 hour view'" />
        <xsl:with-param name="figure-id" select="'schedule-2-day'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Hourly_.'" />
        <xsl:with-param name="id" select="'summary-schedules-hour'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Run Every n Hours | Time Zone |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:----|:---:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Hour']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
                                    (contains('Year Month Week Day Hour', @frequencyType)
                                        or @frequencyType='Min' and @frequency > 30)]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now() + 3600; minute(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + hours(12)'" />
        <xsl:with-param name="units" select="'hour'" />
        <xsl:with-param name="date-format" select="'%H'" />
        <xsl:with-param name="tick-units" select="'hour'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 12 hour view'" />
        <xsl:with-param name="figure-id" select="'schedule-12-hour'" />
    </xsl:call-template>


    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of schedules of type _Minute_.'" />
        <xsl:with-param name="id" select="'summary-schedules-minute'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Run Every n Minutes | Time Zone |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:----|:---:|:--:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and @frequencyType = 'Min']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[lower-case(@enabled)='true' and 
                                    (contains('Year Month Week Day Hour Min', @frequencyType))]" mode="data.frame" />
        </xsl:with-param>
        <xsl:with-param name="start-date" select="'now() + 3600; minute(range_start)&lt;-0'" />
        <xsl:with-param name="end-date" select="'range_start + hours(2)'" />
        <xsl:with-param name="units" select="'15 mins'" />
        <xsl:with-param name="date-format" select="'%M'" />
        <xsl:with-param name="tick-units" select="'5 mins'" />
        <xsl:with-param name="figure-description" select="'Timeline of schedules - 2 hour view'" />
        <xsl:with-param name="figure-id" select="'schedule-2-hour'" />
    </xsl:call-template>



</xsl:template>
<xsl:template name="schedule-table">
    <xsl:param name="summary" />
    <xsl:param name="id" />
    <xsl:param name="unit" />
    <xsl:param name="values" />
    <xsl:variable name="header">| Name     | Description | Type | Run Every n Weeks | Run on nth Day of Week | Start Time | Time Zone |</xsl:variable>
    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="$summary" />
        <xsl:with-param name="id" select="$id" />
        <xsl:with-param name="header" select="replace($header, 'Week', $unit)" />
        <xsl:with-param name="separator">|:---------|:----------|:----|:----:|:----:|:--:|:-:|</xsl:with-param>
        <xsl:with-param name="values" select="$values" />
    </xsl:call-template>
</xsl:template>


<xsl:template match="Schedule" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="ScheduleProperties/Property[@Field='Description']"/></xsl:call-template></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="SubTypes/Type" separator=", " /></value>
        <value><xsl:value-of select="StartTimes/T" separator=", " /></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="Schedule" mode="table-day">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="ScheduleProperties/Property[@Field='Description']"/></xsl:call-template></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="StartTimes/T" separator=", " /></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="Schedule" mode="table-hour">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s" select="ScheduleProperties/Property[@Field='Description']"/></xsl:call-template></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>


<xsl:template name="date-timeline-graphic">
    <xsl:param name="df-rows" />
    <xsl:param name="start-date" />
    <xsl:param name="end-date" />
    <xsl:param name="units" />
    <xsl:param name="date-format" />
    <xsl:param name="tick-units" />
    <xsl:param name="figure-description" />
    <xsl:param name="figure-id" />

```{.ggplot2 }

    library(lubridate)
    library(ggplot2)
    library(tidyverse)
    library(dplyr)

    source("~/projects/quest/OneIM/posh-exporter/schedules.R")
    source("~/projects/quest/OneIM/posh-exporter/timeline_plot.R")

    png('my_plot.png', width = 800, height = 500)

    df = data.frame(col = character(), col = character(), col = numeric(), col = numeric(), col = character(), col = character(), col = character(), col = character(), col = character(), col = character(), stringsAsFactors = FALSE)
    names(df) &lt;- c("Id", "Type", "Freq", "SubFreq", "TimeOfDay", "Offset", "ShortName", "StartDate", "LastRun", "NextRun")

    #  <xsl:value-of select="$figure-description" />
    s &lt;- df %&gt;%
    <xsl:value-of select="$df-rows" />
    {}

    range_start = <xsl:value-of select="$start-date" />
    range_end = <xsl:value-of select="$end-date" />

    k &lt;- calc_dates_for_schedule(s) %&gt;% filter(date &lt;= range_end) %&gt;% filter(date &gt;= range_start) %&gt;% arrange(desc(type))

    date_range &lt;- seq(range_start, range_end, by='<xsl:value-of select="$units"/>')    
    date_format &lt;- format(date_range, '<xsl:value-of select="$date-format" />')
    date_df &lt;- data.frame(date_range, date_format)

    ticks &lt;- seq(range_start, range_end, by='<xsl:value-of select="$tick-units"/>')

    plot &lt;- gen_timeline_plot(k, range_start, range_end, date_df, ticks)

```
![<xsl:value-of select="$figure-description"/>](single.png){#fig:<xsl:value-of select="$figure-id"/>}

</xsl:template>
<xsl:template match="Schedule" mode="data.frame">
    <xsl:variable name="value-template-char">_NAME_ = "_VALUE_",</xsl:variable>
    <xsl:variable name="value-template-num">_NAME_ = _VALUE_,</xsl:variable>
    <xsl:variable name="s" select="." />

    <xsl:variable name="short-name" select="ois:truncate-string(replace(@name, '&quot;', ''), 15, '...')" />
    <xsl:variable name="last-run" select="ois:is-null-string(@lastRun, '1900-01-01')" />
    <xsl:variable name="next-run" select="ois:is-null-string(@nextRun, '1900-01-01')" />

    <xsl:if test="string-length(@frequencyType) &gt; 0">

    <!-- start times, sub-times can be null in OneIM... -->
    <xsl:variable name="sub-types">
        <xsl:choose>
            <xsl:when test="SubTypes"> <xsl:copy-of select="SubTypes"/> </xsl:when>
            <xsl:otherwise><SubTypes><Type>0</Type></SubTypes></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="start-times">
        <xsl:choose>
            <xsl:when test="StartTimes"> <xsl:copy-of select="StartTimes"/> </xsl:when>
            <xsl:otherwise><StartTimes><T>0:0</T></StartTimes></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:for-each select="$sub-types/SubTypes/Type">
        <xsl:variable name="sub-type" select="." />
        <xsl:for-each select="$start-times/StartTimes/T">
            <xsl:value-of select="concat('# ', $s/@id, ' &#xa;')" />
            <xsl:value-of select="'add_row('" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Id'), '_VALUE_', $s/@id)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Type'), '_VALUE_', $s/@frequencyType)" />
            <xsl:value-of select="replace(replace($value-template-num, '_NAME_', 'Freq'), '_VALUE_', $s/@frequency)" />
            <xsl:if test="string-length($sub-type) &gt; 0">
                <xsl:value-of select="replace(replace($value-template-num, '_NAME_', 'SubFreq'), '_VALUE_', $sub-type)" />
            </xsl:if>
            <xsl:if test="string-length(.) &gt; 0">
                <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'TimeOfDay'), '_VALUE_', .)" />
            </xsl:if>
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Offset'), '_VALUE_', $s/TimeZone/@currentUTCOffset)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'ShortName'), '_VALUE_', $short-name)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'StartDate'), '_VALUE_', ois:is-null-string($s/@startDate, '1800-01-01'))" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'LastRun'), '_VALUE_', $last-run)" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'NextRun'), '_VALUE_', $next-run)" />
            <!--
            <xsl:value-of select="concat('Name=\"',      name,           ',')" />
            <xsl:value-of select="concat('Type=\"',      frequencyType,  '\",')" />
            <xsl:value-of select="concat('Freq=\"',      frequency,      '\",')" />
            <xsl:value-of select="concat('SubFreq=\"',   subFrequency,   '\",')" />
            <xsl:value-of select="concat('TimeOfDay=\"', startTime,      '\",')" />
            <xsl:value-of select="concat('TZ`=\"',       TimeZone/@name , '\",')" />
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'Date'), '_VALUE_', 'now()')" />
            -->
            <xsl:value-of select="') %&gt;% &#xa;'" />
        </xsl:for-each>
    </xsl:for-each>
</xsl:if>
</xsl:template>





<!-- ===== Schema ======================= -->

<xsl:template match="Tables">
    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Top tables by storage used'" />
        <xsl:with-param name="id" select="'table-storage-summary'" />
        <xsl:with-param name="header"   >| Table | Type | Storage (MB) | Rows | Resides in memory? |</xsl:with-param>
        <xsl:with-param name="separator">|:--------------|:---:|------:|------:|:---:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Table[@tableType='T']" mode="table-sizes"><xsl:sort select="@sizeMB" order="descending"  data-type="number" /></xsl:apply-templates> </rows>
        </xsl:with-param>
        <xsl:with-param name="max-size" select="10" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Custom or customized tables'" />
        <xsl:with-param name="id" select="'custom-table-summary'" />
        <xsl:with-param name="header"   >| Table | Description | Type | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:--------------|:-----------|:---:|:---|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Table[ois:has-custom(.)]" mode="table"><xsl:sort select="@name" /></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Table[ ois:has-custom(.) ]"  mode="section">
        <xsl:sort select="@name" />
    </xsl:apply-templates>
</xsl:template>
<xsl:template match="Table" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="@displayName"/></value>
        <value><xsl:value-of select="ois:oneim-table-type(@tableType)"/></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>
<xsl:template match="Table" mode="table-sizes">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ois:oneim-table-type(@tableType)"/></value>
        <value><xsl:value-of select="@sizeMB"/></value>
        <value><xsl:value-of select="@countRows"/></value>
        <value><xsl:value-of select="@isResident"/></value>
    </row>
</xsl:template>

<xsl:template match="Table" mode="section">

    <xsl:value-of select="ois:markdown-heading-2(concat('Table: ', @name))" />

    <xsl:value-of select="ois:markdown-definition('Display name', @displayName)" />
    <xsl:value-of select="ois:markdown-definition('Type', ois:oneim-table-type(@tableType))" />
    <xsl:value-of select="ois:markdown-definition('Usage Type', @usageType)" />

    <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'deleteDelayDays', 'Delete delay, in days (custom)')" />
    <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'isAssignmentWithEvent', 'Assignment with event (custom)')" />

    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'ViewWhereClause', 'View where clause (custom)', 'sql')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'SelectScript', 'Select script (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'InsertValues', 'Insert values (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'OnLoadedScript', 'On-Loaded script (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'OnSavingScript', 'On-Saving script (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'OnSavedScript', 'On-Saved script (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'OnDiscardingScript', 'On-Discarding script (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'OnDiscardedScript', 'On-Discarded script (custom)', 'monobasic')" />

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of processes for ', @name)" />
        <xsl:with-param name="id" select="concat('processes-', @id)" />
        <xsl:with-param name="header"   >| Process        | Not Generated? | Description         | Custom? | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:--------------|:-----:|:---------------------------|:--:|:--------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Processes/Process" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Columns" />

</xsl:template>
<xsl:function name="ois:oneim-table-type">
    <xsl:param name="t" as="xs:string?"/>
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="$t = 'T'">Table</xsl:when>
            <xsl:when test="$t = 'V'">View</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function>

<xsl:template match="Process" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="@noGenerate"/></value>
        <value><xsl:value-of select="normalize-space(replace(Description, '\n', ' '))" /></value>
        <value><xsl:value-of select="ois:has-custom(.)" /></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>

<xsl:template match="Processes">
    <xsl:if test="ois:has-custom(.)">
        <xsl:value-of select="ois:markdown-heading-1('Processes')" />
    </xsl:if>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of custom or customized processes'" />
        <xsl:with-param name="id" select="'custom-process-summary'" />
        <xsl:with-param name="header"   >| Process        | Not Generated? | Description              | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:--------------|:-----:|:---------------------------|:--------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Processes/Process[ois:has-custom(.)]" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="Process[ois:has-custom(.)]" />

</xsl:template>
<xsl:template match="Process">

    <xsl:value-of select="ois:markdown-heading-2(concat('Process: ', @name))" />

    <xsl:apply-templates select="." mode="diagram" />

    <xsl:value-of select="ois:markdown-definition('Description', Description)" />

    <xsl:choose>
        <xsl:when test="@noGenerate='true'">
            <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'noGenerate', 'Do not generate (custom)')" />
        </xsl:when>
        <xsl:otherwise>

            <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'PreCode', 'PreCode (custom)', 'monobasic')" />
            <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'GenCondition', 'Generating condition (custom)', 'monobasic')" />

            <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'limitationCount', 'Concurrent process limit (custom)')" />
            <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'limitationWarning', 'Warn at oncurrent process count (custom)')" />

            <xsl:value-of select="ois:markdown-definition('First step', InitialStep/@name)" />

            <xsl:choose>
                <xsl:when test="count(JobEventGens/JobEventGen/JobAutoStarts/JobAutoStart) &gt; 0">
                    <xsl:call-template name="ois:generate-table">
                        <xsl:with-param name="summary" select="concat('Summary of trigger events for ', @name)" />
                        <xsl:with-param name="id" select="concat('events-', @id)" />
                        <xsl:with-param name="header"   >| Event | AutoStart | Schedule | Last Modified |</xsl:with-param>
                        <xsl:with-param name="separator">|:--------------|:-----------:|:-----------|:-------|</xsl:with-param>
                        <xsl:with-param name="values">
                            <rows> <xsl:apply-templates select="JobEventGens/JobEventGen" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="ois:generate-markdown-list">
                        <xsl:with-param name="header" select="'Events'" />
                        <xsl:with-param name="values">
                            <items> <xsl:apply-templates select="JobEventGens/JobEventGen" mode="list" /> </items>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="ois:generate-table">
                <xsl:with-param name="summary" select="concat('Summary of jobs in process ', @name)" />
                <xsl:with-param name="id" select="concat('jobs-', @id)" />
                <xsl:with-param name="header"   >| Job | Description | Task | Custom? | Last Modified |</xsl:with-param>
                <xsl:with-param name="separator">|:--------------|:-----------|:--------|:-:|:---------|</xsl:with-param>
                <xsl:with-param name="values">
                    <rows> <xsl:apply-templates select="Jobs/Job" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
                </xsl:with-param>
            </xsl:call-template>


            <xsl:apply-templates select="Jobs/Job" mode="section" />
        </xsl:otherwise><!-- not noGenerate -->
    </xsl:choose>

</xsl:template>
<xsl:template match="JobEventGen" mode="list">
    <value>
        <xsl:value-of select="ois:escape-for-markdown(Event/@name)"/>
    </value>
</xsl:template>
<xsl:template match="JobEventGen" mode="table">
    <xsl:choose>
        <xsl:when test="count(JobAutoStarts/JobAutoStart) &gt; 0">
            <xsl:apply-templates select="JobAutoStarts/JobAutoStart" mode="table" />
        </xsl:when>
        <xsl:otherwise>
            <row>
                <value><xsl:value-of select="@name"/></value>
                <value><xsl:value-of select="'-'"/></value>
                <value><xsl:value-of select="'-'"/></value>
                <value><xsl:value-of select="ois:last-modified(JobEventGenObject)" /></value>
            </row>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="JobAutoStart" mode="table">
    <row>
        <value><xsl:value-of select="../../Event/@name"/></value>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="Schedule/@name"/></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>
<xsl:template match="Job" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="normalize-space(Description)"/></value>
        <value><xsl:value-of select="concat(JobTask/Component/@name,'/', JobTask/@name)"/></value>
        <value><xsl:value-of select="ois:has-custom(.)" /></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>

<xsl:template match="Job" mode="section">

    <xsl:value-of select="ois:markdown-heading-3(concat('Job: ', @name))" />

    <xsl:value-of select="ois:markdown-definition('Description', Description)" />

    <xsl:variable name="task">
        <xsl:apply-templates select="JobTask" mode="text" />
    </xsl:variable>
    <xsl:value-of select="ois:markdown-definition('Task', $task)" />

    <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'priority', 'Priority (custom)')" />
    <xsl:value-of select="ois:markdown-definition('Next step, on success', NextStepSuccess/@name)" />
    <xsl:value-of select="ois:markdown-definition('Next step, on error', NextStepError/@name)" />


    <xsl:value-of select="ois:patched-markdown-definition-attribute( ServerTag, 'name', 'Server selection tag (custom)')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'ServerDetectScript', 'Server selection script (custom)', 'monobasic')" />

    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'PreCode', 'PreCode (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'GenCondition', 'Generating condition (custom)', 'monobasic')" />

    <xsl:if test="  ois:property-is-custom(., 'isToFreezeOnError')
                    or
                    ois:property-is-custom(., 'ignoreErrors')
                    or
                    ois:property-is-custom(., 'isSplitOnly')
                    or
                    ois:property-is-custom(., 'deferOnError')
                    or
                    (
                        @deferOnError='true'
                        and
                        (
                          ois:property-is-custom(., 'minutesToDefer')
                          or
                          ois:property-is-custom(., 'retries')
                        )
                    )
                    or
                    ois:property-is-custom(., 'isErrorLogToJournal')
        ">
        <xsl:value-of select="ois:markdown-heading-4('Error Handling')" />

        <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'isToFreezeOnError', 'Freeze on error (custom)')" />
        <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'ignoreErrors', 'Ignore errors (custom)')" />
        <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'isSplitOnly', 'Is split only (custom)')" />
        <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'deferOnError', 'Defer on error (custom)')" />
        <xsl:if test="@deferOnError='true'">
            <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'minutesToDefer', 'Minutes to defer (custom)')" />
            <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'retries', 'Retries (custom)')" />
        </xsl:if>
        <xsl:value-of select="ois:patched-markdown-definition-attribute( ., 'isErrorLogToJournal', 'Log errors to journal (custom)')" />
    </xsl:if>


    <xsl:apply-templates select="JobRunParameters" mode="section" />

</xsl:template>
<xsl:template match="JobTask" mode="text">
    <xsl:value-of select="concat(Component/@name, '/', @name, ' (', @executionType, ')')" />
</xsl:template>
<xsl:template match="JobRunParameters" mode="section">
    <xsl:if test="count(JobRunParameter[ois:job-run-parameter-has-custom(.)]) &gt; 0">
        <xsl:value-of select="ois:markdown-heading-4('Custom Parameters')" />
    </xsl:if>

    <xsl:apply-templates select="JobRunParameter[ois:job-run-parameter-has-custom(.)]" mode="section">
        <xsl:sort select="@name"    order="ascending"/>
    </xsl:apply-templates>
</xsl:template>
  <xsl:function name="ois:job-run-parameter-has-custom" as="xs:boolean">
    <xsl:param name="o"/>
    <xsl:sequence select="
                    ois:has-custom($o)
                    or
                    normalize-space($o/ValueTemplate) != normalize-space($o/Parameter/ValueTemplateDefault)
    " />
  </xsl:function>
<xsl:template match="JobRunParameter" mode="section">
    <xsl:choose>
        <xsl:when test="@isCrypted = 'true'">
            <xsl:value-of select="ois:markdown-definition(@name, '[encrypted]')" />
        </xsl:when>
        <xsl:when test="@isHidden = 'true'">
            <xsl:value-of select="ois:markdown-definition(@name, '[hidden]')" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="ois:generate-markdown-code-block">
                <xsl:with-param name="header" select="concat('**', @name, '**')" />
                <xsl:with-param name="code" select="ValueTemplate" />
                <xsl:with-param name="code-type" select="'monobasic'" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ************ job chain graphic ************************ -->
<xsl:template match="Process" mode="xml">
    <jobchain>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="initialStep" select="InitialStep/@id" />
        <xsl:apply-templates select="Jobs/Job" mode="xml" />
    </jobchain>
</xsl:template>
<xsl:template match="Job" mode="xml">
    <job>
        <xsl:attribute name="name" select="@name" />
        <xsl:attribute name="id" select="@id" />
        <xsl:attribute name="splitOnly" select="@splitOnly" />
        <xsl:attribute name="task" select="JobTask/@name" />
        <xsl:attribute name="executionType" select="JobTask/@executionType" />
        <xsl:attribute name="serverTag" select="Servertag/@name" />

            <xsl:attribute name="nextStepSuccess" select="NextStepSuccess/@id" />
            <xsl:attribute name="nextStepError" select="NextStepError/@id" />
    </job>
</xsl:template>
<xsl:template match="Process" mode="diagram">
    <xsl:variable name="xml">
        <xsl:apply-templates select="." mode="xml" />
    </xsl:variable>
    <xsl:variable name="initialStep" select="$xml/jobchain/@initialStep" />

    <xsl:call-template name="ois:generate-plantuml-C4">
        <xsl:with-param name="summary" select="concat('Overview of process _', @name, '_')" />
        <xsl:with-param name="id" select="concat('process-overview-', @id)" />
        <xsl:with-param name="content">
            <xsl:value-of select="'circle &quot; &quot; as start_box&#xa;'" />
            <xsl:apply-templates select="$xml/jobchain/job" mode="uml-component"><xsl:sort select="@name" /></xsl:apply-templates>
            <xsl:value-of select="ois:c4-rel-common(
                        'Rel_R',
                        'start_box',
                        ois:clean-for-plantuml-name(concat('JOB_', $initialStep)),
                        '',
                        'OneIM_Approval'
            )" />
            <xsl:apply-templates select="$xml/jobchain/job" mode="uml-connections"><xsl:sort select="@name" /></xsl:apply-templates>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="job" mode="uml-component">
    <xsl:value-of select="ois:c4-component(
            ois:clean-for-plantuml-name(concat('JOB_', @id)),
            ois:clean-for-plantuml(ois:truncate-string(@name, 40, '...')),
            ois:clean-for-plantuml(concat(@task, ' [', @executionType, ']')),
            'OneIM_Job'
    )" />
</xsl:template>
<xsl:template match="job" mode="uml-connections">
    <xsl:if test="string-length(@nextStepSuccess) &gt; 0">
        <xsl:value-of select="ois:c4-rel(
                ois:clean-for-plantuml-name(concat('JOB_', @id)),
                ois:clean-for-plantuml-name(concat('JOB_', @nextStepSuccess)),
                if ( @splitOnly='true' ) then 'true' else 'success',
                if ( @splitOnly='true' ) then 'OneIM_JobSplit' else 'OneIM_JobSuccess'
        )" />
    </xsl:if>
    <xsl:if test="string-length(@nextStepError) &gt; 0">
        <xsl:value-of select="ois:c4-rel(
                ois:clean-for-plantuml-name(concat('JOB_', @id)),
                ois:clean-for-plantuml-name(concat('JOB_', @nextStepError)),
                if ( @splitOnly='true' ) then 'false' else 'error',
                if ( @splitOnly='true' ) then 'OneIM_JobSplit' else 'OneIM_JobError'
        )" />
    </xsl:if>
</xsl:template>



<!-- ===== templates ================================ -->
<xsl:template match="Columns">
    <xsl:if test="ois:has-custom(.)">
        <xsl:value-of select="ois:markdown-heading-3('Templates')" />
    </xsl:if>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of custom templates for ', ../@name)" />
        <xsl:with-param name="id" select="concat('templates-', ../@id)" />
        <xsl:with-param name="header"   >| Template       | Caption  | Type  | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:---------------|:---------|:-----:|:--------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Column[ois:has-custom(.)]" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Column[ois:has-custom(.)]" mode="section">
        <xsl:sort select="@name"    order="ascending" />
    </xsl:apply-templates>

</xsl:template>
<xsl:template match="Column" mode="table">
    <row>
        <value><xsl:value-of select="concat(../../@name, ':', @name)" /></value>
        <value><xsl:value-of select="normalize-space(@caption)" /></value>
        <value><xsl:value-of select="ois:oneim-column-type(@dataType)" /></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>
<xsl:template match="Column" mode="section">
    <xsl:value-of select="ois:markdown-heading-4(@name)" />

    <xsl:value-of select="ois:markdown-definition('Type', ois:oneim-column-type(@dataType))" />
    <xsl:value-of select="ois:markdown-definition('Schema type', 
                            ois:oneim-column-schema-type(@schemaDataType, @schemaDataLen))" />

    <xsl:value-of select="ois:patched-markdown-definition-attribute(., 'caption', 'Caption (custom)')" />
    <xsl:value-of select="ois:patched-markdown-definition-property(., 'Commentary', 'Comments (custom)')" />

    <xsl:value-of select="ois:patched-markdown-definition-attribute(., 'isToWatch', 'Audit changes (custom)')" />
    <xsl:value-of select="ois:patched-markdown-definition-attribute(., 'isToWatchDelete', 'Audit values on delete (custom)')" />

    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'Template', 'Value template (custom)', 'monobasic')" />
    <xsl:value-of select="ois:patched-markdown-definition-codeblock( ., 'FormatScript', 'Format script (custom)', 'monobasic')" />

</xsl:template>
<xsl:function name="ois:oneim-column-type">
    <xsl:param name="t" as="xs:integer?"/>
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="$t = 0">Boolean</xsl:when>
            <xsl:when test="$t = 1">Integer</xsl:when>
            <xsl:when test="$t = 2">Long</xsl:when>
            <xsl:when test="$t = 3">Double</xsl:when>
            <xsl:when test="$t = 4">Decimal</xsl:when>
            <xsl:when test="$t = 5">Date</xsl:when>
            <xsl:when test="$t = 6">String</xsl:when>
            <xsl:when test="$t = 7">Binary</xsl:when>
            <xsl:when test="$t = 8">Byte</xsl:when>
            <xsl:when test="$t = 9">Short</xsl:when>
            <xsl:when test="$t = 10">Text</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function>
<xsl:function name="ois:oneim-column-schema-type">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="size" as="xs:integer?"/>
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="$size &gt; 0">
                <xsl:value-of select="concat($type, '(', $size, ')' )" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$type" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function>


<!-- ===== Mail Templates ======================= -->

<xsl:template match="MailTemplates">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of mail templates.'" />
        <xsl:with-param name="id" select="'summary-mail-templates'" />
        <xsl:with-param name="header"   >| Name        | Description | Format | Table | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:---:|:-----|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="MailTemplate" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="MailTemplate[ois:has-custom(.)]">
        <xsl:sort select="@name" />
    </xsl:apply-templates>

</xsl:template>

<xsl:template match="MailTemplate" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="Description"/></value>
        <value><xsl:value-of select="@targetFormat" /></value>
        <value><xsl:value-of select="BaseTable/@name" /></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>

<xsl:template match="MailTemplate">
    <xsl:value-of select="ois:markdown-heading-2(@name)" />
    <xsl:value-of select="ois:markdown-definition('Description', Description)" />
    <xsl:value-of select="ois:markdown-definition('Base table', BaseTable/@name)" />
    <xsl:value-of select="ois:markdown-definition('Format', @targetFormat)" />
    <xsl:value-of select="ois:markdown-definition('Importance', @importance)" />
    <xsl:value-of select="ois:markdown-definition('Sensitivity', @sensitivity)" />
    <xsl:apply-templates select="MailBodies/MailBody" />
</xsl:template>

<xsl:template match="MailBody">
    <xsl:value-of select="ois:markdown-heading-3(Culture/@displayName)" />
    <xsl:value-of select="ois:markdown-definition('Subject', @subject)" />
    <xsl:value-of select="ois:markdown-definition('Modified', ois:last-modified(.) )" />

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="code" select="RichMailBody" />
        <xsl:with-param name="code-type" select="'html'" />
    </xsl:call-template>
</xsl:template>


<!-- ===== Scripts ======================= -->

<xsl:template match="Scripts">
    <xsl:if test="ois:has-custom(.)">
        <xsl:value-of select="ois:markdown-heading-1('Custom Scripts')" />

Table: Summary of custom scripts {#tbl:summary-scripts}

| Script        | Locked? | Description              | Last Modified |
|:--------------|:-----:|:---------------------------|:--------------|
<xsl:for-each select="Script[ois:has-custom(.)]"
       ><xsl:sort select="@name"    order="ascending"
     />| **<xsl:value-of select="@name"
  />** | <xsl:value-of select="@isLocked" 
    /> | <xsl:value-of select="normalize-space(Description)" 
    /> | <xsl:value-of select="ois:last-modified(.)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="Script[ois:has-custom(.)]" />
</xsl:if>

</xsl:template>
<xsl:template match="Script">

    <xsl:value-of select="ois:markdown-heading-2(@name)" />

    <xsl:value-of select="ois:markdown-definition('Description', Description)" />

    <xsl:call-template name="ois:generate-markdown-code-block">
        <!-- <xsl:with-param name="header" select="'**View where clause**'" /> -->
        <xsl:with-param name="code" select="ScriptCode" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
</xsl:template>


<!-- ===== Limited SQL ======================= -->

<xsl:template match="LimitedSQLScripts">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of predefined SQL scripts.'" />
        <xsl:with-param name="id" select="'summary-sql-scripts'" />
        <xsl:with-param name="header"   >| Name        | Description | Type |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:---:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="LimitedSQLScript" mode="table"> 
                    <xsl:sort select="@name" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="LimitedSQLScript[ois:has-custom(.)]" />

</xsl:template>
<xsl:template match="LimitedSQLScript" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="Description"/></value>
        <value><xsl:value-of select="@type" /></value>
    </row>
</xsl:template>

<xsl:template match="LimitedSQLScript">
    <xsl:value-of select="ois:markdown-heading-2(concat('SQL: ', @name))" />
    <xsl:value-of select="ois:markdown-definition('Description', Description)" />
    <xsl:call-template name="ois:generate-markdown-code-block">
        <!-- <xsl:with-param name="header" select="'**View where clause**'" /> -->
        <xsl:with-param name="code" select="SQLContent" />
        <xsl:with-param name="code-type" select="'sql'" />
    </xsl:call-template>
</xsl:template>

<!-- ===== Change Labels ======================= -->

<xsl:template match="ChangeLabels">
    <xsl:if test="ChangeLabel">
        <xsl:value-of select="ois:markdown-heading-1('Change Labels')" />
    </xsl:if>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of change labels.'" />
        <xsl:with-param name="id" select="'summary-change-labels'" />
        <xsl:with-param name="header"   >| Name        | Description | Type | Closed? | Changes | Date |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:---:|:---:|:--:|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="ChangeLabel" mode="table"> 
                    <xsl:sort select="@name" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="ChangeLabel">
        <xsl:sort select="@name" />
    </xsl:apply-templates>

</xsl:template>
<xsl:template match="ChangeLabel" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="Description"/></value>
        <value><xsl:value-of select="@type" /></value>
        <value><xsl:value-of select="@isClosed" /></value>
        <value><xsl:value-of select="count(TaggedChanges/TaggedChange) + count(TaggedItems/TaggedItem)" /></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>
<xsl:template match="ChangeLabel">
    <xsl:value-of select="ois:markdown-heading-2(@name)" />

    <xsl:if test="count(distinct-values(TaggedChanges/TaggedChange/@XDateInserted)) gt 2">
        <xsl:variable name="events">
            <xsl:apply-templates select="." mode="events" />
        </xsl:variable>
        <xsl:value-of select="ois:generate-SVG-timeline(
                concat('Timeline of changes in label ', @name), 
                concat('change-label-', @id), 
                800, 200, 
                '', 
                $events
            )" />
    </xsl:if>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of tagged changes.'" />
        <xsl:with-param name="id" select="concat('tagged-changes-', @id)" />
        <xsl:with-param name="header"   >| Table | Object | Date |</xsl:with-param>
        <xsl:with-param name="separator">|:------|:------|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="TaggedChanges/TaggedChange[Object]" mode="table"> 
                    <xsl:sort select="@sortOrder"  data-type="number" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of tagged objects.'" />
        <xsl:with-param name="id" select="concat('tagged-references-', @id)" />
        <xsl:with-param name="header"   >| Table | Object | Date |</xsl:with-param>
        <xsl:with-param name="separator">|:------|:------|:-----|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> 
                <xsl:apply-templates select="TaggedItems/TaggedItem[Object]" mode="table"> 
                    <xsl:sort select="@sortOrder"  data-type="number" />
                </xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    </xsl:template>
    <xsl:template match="TaggedChange|TaggedItem" mode="table">
        <row>
            <value><xsl:value-of select="Object/@table"/></value>
            <value><xsl:value-of select="concat(Object/@name , Object/@scriptName , Object/@columnName , Object/@tableName, Object/@fileName, Object/@relationID, Object/@configParm, Object/@DisplayName)"/></value>
            <value><xsl:value-of select="ois:last-modified(.)" /></value>
        </row>
    </xsl:template>

    <xsl:template match="ChangeLabel" mode="events">
        <events>
            <xsl:apply-templates select="TaggedChanges/TaggedChange" mode="event" />
            <xsl:apply-templates select="TaggedItems/TaggedItem" mode="event" />
        </events>
    </xsl:template>
    <xsl:template match="TaggedChange|TaggedItem" mode="event">
        <event>
            <xsl:attribute name="date" select="substring(@XDateInserted, 1, 10)" />
            <xsl:value-of select="concat(Object/@name , Object/@scriptName , Object/@columnName , Object/@tableName)" />
        </event>
    </xsl:template>




    <!-- ===== generic functions ======================= -->

      <!-- Function to extract last modified string -->
      <xsl:function name="ois:last-modified" as="xs:string">
        <xsl:param name="o"/>

        <xsl:variable name="result">
            <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown($o/@XUserUpdated), 15, '...')" /> - <xsl:value-of select="$o/@XDateUpdated" />
        </xsl:variable>
        <xsl:value-of select="$result" />

      </xsl:function>


      <xsl:function name="ois:has-custom" as="xs:boolean">
        <xsl:param name="o"/>
        <xsl:sequence select="
                starts-with($o/@id, 'CCC')
                or
                count($o/descendant-or-self::Patches/Patch) &gt; 0
                or
                count($o/descendant-or-self::*[starts-with(@id, 'CCC')]) &gt; 0
        " />
      </xsl:function>
      <xsl:function name="ois:property-is-custom" as="xs:boolean">
        <xsl:param name="o"/>
        <xsl:param name="n" as="xs:string" />
        <xsl:sequence select="
                starts-with($o/@id, 'CCC')
                or
                count($o/Patches/Patch[upper-case(@columnName)=upper-case($n)]) &gt; 0
        " />
      </xsl:function>

      <xsl:function name="ois:patched-markdown-definition-attribute" as="xs:string?">
          <xsl:param name="o"/>
          <xsl:param name="attr" as="xs:string" />
          <xsl:param name="label" as="xs:string"/>
          <xsl:if test="ois:property-is-custom($o, $attr)">
              <xsl:value-of select="ois:markdown-definition( $label, $o/@*[name()=$attr])" />
          </xsl:if>
      </xsl:function>
      <xsl:function name="ois:patched-markdown-definition-boolean" as="xs:string?">
          <xsl:param name="o"/>
          <xsl:param name="attr" as="xs:string" />
          <xsl:param name="label" as="xs:string"/>
          <xsl:if test="ois:property-is-custom($o, $attr)">
              <xsl:value-of select="ois:markdown-definition-bool( $label, $o/@*[name()=$attr])" />
          </xsl:if>
      </xsl:function>
      <xsl:function name="ois:patched-markdown-definition-property" as="xs:string?">
          <xsl:param name="o"/>
          <xsl:param name="prop" as="xs:string" />
          <xsl:param name="label" as="xs:string"/>
          <xsl:if test="ois:property-is-custom($o, $prop)">
              <xsl:value-of select="ois:markdown-definition( $label, $o/*[name()=$prop])" />
          </xsl:if>
      </xsl:function>
      <xsl:function name="ois:patched-markdown-definition-codeblock" as="xs:string?">
          <xsl:param name="o"/>
          <xsl:param name="prop" as="xs:string" />
          <xsl:param name="label" as="xs:string"/>
          <xsl:param name="language" as="xs:string?"/>
          <xsl:if test="ois:property-is-custom($o, $prop)">
              <xsl:value-of select="ois:markdown-definition-codeblock( $label, $o/*[name()=$prop], $language)" />
          </xsl:if>
      </xsl:function>

</xsl:stylesheet>
