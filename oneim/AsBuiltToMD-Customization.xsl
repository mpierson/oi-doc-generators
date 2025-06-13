<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SSB config export to Markdown

  Author: M Pierson
  Date: Mar 2025
  Version: 0.90

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" 
                              exclude-result-prefixes="ois xs">
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:import href="OIS-JSONLib.xsl" />
  <xsl:import href="OIS-StringLib.xsl" />
  <xsl:import href="OIS-Markdown.xsl" />
  <xsl:import href="OIS-PlantUML.xsl" />
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
author: OneIM As Built Generator v0.90
abstract: |
    Schema customizations of the <xsl:value-of select="@name" /> instance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---


# Summary



# Schedules

<xsl:apply-templates select="Schedules"/> 



# Schema Customizations

<xsl:apply-templates select="Tables"/> 


# Custom Scripts

<xsl:apply-templates select="Scripts" />


# Mail Templates

<xsl:apply-templates select="MailTemplates" />


</xsl:template>


<!-- ===== Schedules ======================= -->

<xsl:template match="Schedules">


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and (
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
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Year']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
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
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Month']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>




    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
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
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Week']" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
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
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Day']" mode="table-day" /> </rows>
        </xsl:with-param>
    </xsl:call-template>


    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
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
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Hour']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
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
            <rows> <xsl:apply-templates select="Schedule[@enabled='True' and @frequencyType = 'Min']" mode="table-hour" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="date-timeline-graphic">
        <xsl:with-param name="df-rows">
            <xsl:apply-templates select="Schedule[@enabled='True' and 
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
        <value><xsl:value-of select="ScheduleObject/Property[@Name='Description']"/></value>
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
        <value><xsl:value-of select="ScheduleObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="@belongsTo"/></value>
        <value><xsl:value-of select="@frequency"/></value>
        <value><xsl:value-of select="StartTimes/T" separator=", " /></value>
        <value><xsl:value-of select="TimeZone/@name" /></value>
    </row>
</xsl:template>
<xsl:template match="Schedule" mode="table-hour">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ScheduleObject/Property[@Name='Description']"/></value>
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
            <xsl:value-of select="replace(replace($value-template-char, '_NAME_', 'StartDate'), '_VALUE_', $s/@startDate)" />
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
</xsl:template>





<!-- ===== Schema ======================= -->

<xsl:template match="Tables">
    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of customized Identity Manager table storage'" />
        <xsl:with-param name="id" select="'table-storage-summary'" />
        <xsl:with-param name="header"   >| Table | Type | Storage (MB) | Rows | Resides in memory? |</xsl:with-param>
        <xsl:with-param name="separator">|:--------------|:---:|:------|:----|:---:|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="Table[TableObject/Property[@Name='TableType'] = 'T']" mode="table"><xsl:sort select="TableObject/Property[@Name='SizeMB']" order="descending"  data-type="number" /></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="Table"  mode="section"/>
</xsl:template>
<xsl:template match="Table" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ois:oneim-table-type(TableObject/Property[@Name='TableType'])"/></value>
        <value><xsl:value-of select="TableObject/Property[@Name='SizeMB']"/></value>
        <value><xsl:value-of select="TableObject/Property[@Name='CountRows']"/></value>
        <value><xsl:value-of select="TableObject/Property[@Name='IsResident']"/></value>
    </row>
</xsl:template>

<xsl:template match="Table" mode="section">

    <xsl:value-of select="concat('&#xa;&#xa;## ', @name, '&#xa;&#xa;')" />
    <xsl:value-of select="concat('&#xa;&#xa;', TableObject/Property[@Name='DisplayName'], '&#xa;&#xa;')" />

    <xsl:value-of select="ois:markdown-definition('Type', ois:oneim-table-type(TableObject/Property[@Name='TableType']))" />
    <xsl:value-of select="ois:markdown-definition('Usage Type', TableObject/Property[@Name='UsageType'])" />
    <xsl:value-of select="ois:markdown-definition-int('Delete delay (days)', TableObject/Property[@Name='DeleteDelayDays'])"/>

    <xsl:value-of select="ois:markdown-definition-bool('Assignment with event', TableObject/Property[@Name='isAssignmentWithEvent'])" />

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**View where clause**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='ViewWhereClause']" />
        <xsl:with-param name="code-type" select="'sql'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**Select script**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='SelectScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**Insert values**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='InsertValues']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**On-Loaded script**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='OnLoadedScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**On-Saving script**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='OnSavingScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**On-Saved script**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='OnSavedScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**On-Discarding script**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='OnDiscardingScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**On-Discared script**'" />
        <xsl:with-param name="code" select="TableObject/Property[@Name='OnDiscardedScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>


    <xsl:apply-templates select="Processes" />
    <xsl:apply-templates select="Templates" />

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

<xsl:template match="Processes"><xsl:if test="count(Process) &gt; 0">

### Processes


Table: Summary of custom processes {#tbl:summary-processes-<xsl:value-of select="../@id"/>}

| Process        | Not Generated? | Description              | Last Modified |
|:--------------|:-----:|:---------------------------|:--------------|
<xsl:for-each select="Process"
       ><xsl:sort select="@name"    order="ascending"
    />| **<xsl:value-of select="@name"
 />** | <xsl:value-of select="ProcessObject/Property[@Name='NoGenerate']" 
   /> | <xsl:value-of select="normalize-space(replace(ProcessObject/Property[@Name='Description'], '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(ProcessObject)"
   /> |                 
</xsl:for-each>   

<xsl:apply-templates select="Process" />

</xsl:if></xsl:template>
<xsl:template match="Process">

    <xsl:value-of select="concat('&#xa;&#xa;#### Process: ', @name, '&#xa;&#xa;')" />

    <xsl:value-of select="ProcessObject/Property[@Name='Description']" />

    <xsl:if test="Graphic"><xsl:value-of select="ois:markdown-figure(
                    concat('Overview of process ', @name), 
                    concat('images/', Graphic/@fileName), 
                    concat('process-overview-', @id))" /></xsl:if>


    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**Pre Code**'" />
        <xsl:with-param name="code" select="ProcessObject/Property[@Name='PreCode']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**Generating Condition**'" />
        <xsl:with-param name="code" select="ProcessObject/Property[@Name='GenCondition']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>



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
            <xsl:with-param name="header"   >| Job | Description | Task | Priority | Last Modified |</xsl:with-param>
            <xsl:with-param name="separator">|:--------------|:-----------|:--------|:-:|:---------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> <xsl:apply-templates select="Jobs/Job" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
            </xsl:with-param>
        </xsl:call-template>


    <xsl:apply-templates select="Jobs/Job" mode="section" />

</xsl:template>
<xsl:template match="JobEventGen" mode="list">
    <value>
        <xsl:value-of select="ois:escape-for-markdown(@name)"/>
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
        <value><xsl:value-of select="../../@name"/></value>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="DialogSchedule/@name"/></value>
        <value><xsl:value-of select="ois:last-modified(JobAutoStartObject)" /></value>
    </row>
</xsl:template>
<xsl:template match="Job" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="normalize-space(replace(JobObject/Property[@Name='Description'], '\n', ' '))"/></value>
        <value><xsl:value-of select="concat(JobTask/Component/@name,':', JobTask/@name)"/></value>
        <value><xsl:value-of select="JobObject/Property[@Name='Priority']" /></value>
        <value><xsl:value-of select="ois:last-modified(JobObject)" /></value>
    </row>
</xsl:template>

<xsl:template match="Job" mode="section">

    <xsl:value-of select="concat('&#xa;&#xa;##### Job - ', @name, '&#xa;')" />

    <xsl:value-of select="ois:markdown-definition-bool('Freeze on error', JobObject/Property[@Name='IsToFreezeOnError'])" />

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'_Pre Code_'" />
        <xsl:with-param name="code" select="JobObject/Property[@Name='PreCode']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'_Generating Condition_'" />
        <xsl:with-param name="code" select="JobObject/Property[@Name='GenCondition']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>


    <!-- include non-OOTB parameters with a non-empty template -->
    <xsl:apply-templates select="JobRunParameters/JobRunParameter[
                                    string-length(normalize-space(EscapedValueTemplate)) &gt; 0
                                    and
                                    (
                                        QBMBufferConfig 
                                        or 
                                        normalize-space(EscapedValueTemplate) != normalize-space(JobParameter/EscapedValueTemplate)
                                    )
                                ]" mode="section">
        <xsl:sort select="@name"    order="ascending"/>
    </xsl:apply-templates>

</xsl:template>
<xsl:template match="JobRunParameter" mode="section">
    <xsl:choose>
        <xsl:when test="Property[@Name='IsCrypted'] = 'true'">
            <xsl:value-of select="ois:markdown-definition-bool(concat('&#xa;**Parameter**: ', @name), '_encrypted_')" />
        </xsl:when>
        <xsl:when test="Property[@Name='IsHidden'] = 'true'">
            <xsl:value-of select="ois:markdown-definition-bool(concat('&#xa;**Parameter**: ', @name), '_hidden_')" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="ois:generate-markdown-code-block">
                <xsl:with-param name="header" select="concat('**Parameter**: _', ois:escape-for-markdown(@name), '_')" />
                <xsl:with-param name="code" select="EscapedValueTemplate" />
                <xsl:with-param name="code-type" select="'monobasic'" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ===== templates ================================ -->
<xsl:template match="Templates"><xsl:if test="count(Template) &gt; 0">

    <xsl:value-of select="'&#xa;&#xa;### Templates &#xa;&#xa;'" />

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="concat('Summary of custom templates for ', @name)" />
            <xsl:with-param name="id" select="concat('templates-', ../@id)" />
            <xsl:with-param name="header"   >| Template       | Caption  | Type  | Last Modified |</xsl:with-param>
            <xsl:with-param name="separator">|:---------------|:---------|:-----:|:--------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> <xsl:apply-templates select="Template" mode="table"><xsl:sort select="@name" order="ascending" /></xsl:apply-templates> </rows>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:apply-templates select="Template[string-length(Property[@Name='Template']) &gt; 0 or string-length(Property[@Name='FormatScript']) &gt; 0]" mode="section">
            <xsl:sort select="@name"    order="ascending" />
        </xsl:apply-templates>

</xsl:if></xsl:template>
<xsl:template match="Template" mode="table">
    <row>
        <value><xsl:value-of select="concat(@table, ':', @name)" /></value>
        <value><xsl:value-of select="normalize-space(Property[@Name='Caption'])" /></value>
        <value><xsl:value-of select="ois:oneim-column-type(Property[@Name='DataType'])" /></value>
        <value><xsl:value-of select="ois:last-modified(.)" /></value>
    </row>
</xsl:template>
<xsl:template match="Template" mode="section">
    <xsl:value-of select="concat('&#xa;&#xa;##### ', @table, ': ',  @name, '&#xa;')" />

    <xsl:value-of select="ois:markdown-definition('Type', Property[@Name='DataType'])" />
    <xsl:value-of select="ois:markdown-definition('Schema type', 
                            ois:oneim-column-schema-type(Property[@Name='SchemaDataType'], Property[@Name='SchemaDataLen']))" />
    <xsl:value-of select="ois:markdown-definition('Caption', Property[@Name='Caption'])" />
    <xsl:value-of select="ois:markdown-definition('Comments', Property[@Name='Commentary'])" />

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**Value Template**'" />
        <xsl:with-param name="code" select="Property[@Name='Template']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="'**Format Script**'" />
        <xsl:with-param name="code" select="Property[@Name='FormatScript']" />
        <xsl:with-param name="code-type" select="'monobasic'" />
    </xsl:call-template>

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

    <xsl:apply-templates select="MailTemplate[starts-with(@id, 'CCC')]" />

</xsl:template>

<xsl:template match="MailTemplate" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="MailTemplateObject/Property[@Name='Description']"/></value>
        <value><xsl:value-of select="MailTemplateObject/Property[@Name='TargetFormat']" /></value>
        <value><xsl:value-of select="Table/@name" /></value>
        <value><xsl:value-of select="ois:last-modified(MailTemplateObject)" /></value>
    </row>
</xsl:template>


<xsl:template match="MailTemplate">
##  <xsl:value-of select="@name" />
<xsl:text>

</xsl:text>

    <xsl:apply-templates select="MailContent" />
</xsl:template>

<xsl:template match="MailContent">
    <xsl:apply-templates select="Body" />
</xsl:template>

<xsl:template match="Body">
###  <xsl:value-of select="@name" />
<xsl:text>

</xsl:text>
```html
    <xsl:value-of select="Property[@Name='RichMailBody']" disable-output-escaping="yes" />
```
</xsl:template>


<!-- ===== Scripts ======================= -->

<xsl:template match="Scripts">

Table: Summary of custom scripts {#tbl:summary-scripts}

| Script        | Locked? | Description              | Last Modified |
|:--------------|:-----:|:---------------------------|:--------------|
<xsl:for-each select="Script"
       ><xsl:sort select="@name"    order="ascending"
     />| **<xsl:value-of select="@name"
  />** | <xsl:value-of select="Property[@Name='IsLocked']" 
    /> | <xsl:value-of select="normalize-space(replace(Property[@Name='Description'], '\n', ' '))" 
    /> | <xsl:value-of select="ois:last-modified(.)"
    /> |                 
</xsl:for-each>   

<xsl:apply-templates select="Script" />

</xsl:template>
<xsl:template match="Script">

## <xsl:value-of select="@name" />

```monobasic
<xsl:value-of select="Property[@Name='ScriptCode']" />

```
</xsl:template>



<!-- ===== generic functions ======================= -->

  <!-- Function to extract last modified string -->
  <xsl:function name="ois:last-modified" as="xs:string">
    <xsl:param name="o"/>

    <xsl:variable name="result">
        <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown($o/Property[@Name='XUserUpdated']), 15, '...')" /> - <xsl:value-of select="$o/Property[@Name='XDateUpdated']" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function> 



</xsl:stylesheet>
