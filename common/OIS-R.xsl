<?xml version='1.0' encoding="UTF-8"?>
<!--

R related utilities (stats/plots)

  Author: M Pierson
  Date: Dec 2025
  Version: 0.91

 -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >



<xsl:template name="ois:date-timeline-graphic">
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

    source("schedules.R")
    source("timeline_plot.R")

    png('my_plot.png', width = 800, height = 500)

    df = data.frame(
        col = character(), col = character(), col = numeric(), col = numeric(), col = character(), col = character(), col = character(), col = character(), col = character(), col = character(), stringsAsFactors = FALSE)
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


<!--
    stacked bar from
    <events>
    <event date="yyyy-mm-dd" user="jbloggs">description</event>
    ...
    </events>
-->
<xsl:function name="ois:stacked-bar-plot" as="xs:string">
    <xsl:param name="df-rows" />
    <xsl:param name="figure-description"  as="xs:string"/>
    <xsl:param name="figure-id"  as="xs:string"/>

    <xsl:variable name="dates" as="xs:date*" select="$df-rows/events/event/xs:date(@date)"/>
    <xsl:variable name="start-date" select="min($dates)" />
    <xsl:variable name="end-date" select="max($dates)" />

    <xsl:variable name="duration" select="days-from-duration($end-date - $start-date)" as="xs:integer" />

    <xsl:variable name="result">
```{.ggplot2 }

    library(lubridate)
    library(ggplot2)
    library(tidyverse)
    library(dplyr)

    source("OI_theme.R")
    source("stacked_bar_plot.R")

    png('my_plot.png', width = 800, height = 500)

    df &lt;- data.frame( name=c("empty"), dt=c(as_date("2025-01-01")) )

    k &lt;- df %&gt;% 
        <xsl:for-each select="$df-rows/events/event">
            <xsl:value-of select="concat('# ', @user, ', ', @date, ', ', ., '&#xa;')" />
            <xsl:value-of select="concat('add_row( name=&quot;', @user, '&quot;, dt=as_date(&quot;', @date, '&quot;) ) %&gt;%&#xa;')" />
        </xsl:for-each>
    {}

    # remove the placeholder first row
    k &lt;- k[-c(1), ]

    # TODO: custom based on duration?
    plot &lt;- gen_stacked_bar_plot(k)

```
![<xsl:value-of select="$figure-description"/>](single.png){#fig:<xsl:value-of select="$figure-id"/>}
</xsl:variable>

  <xsl:value-of select="if ($duration gt 1) then $result else ''" />

</xsl:function>

<!--
    stacked bar from
    <events>
    <event date="yyyy-mm-dd" count=3 event="jbloggs" />
    ...
    </events>
-->
<xsl:function name="ois:stacked-bar-plot-events" as="xs:string">
    <xsl:param name="df-rows" />
    <xsl:param name="figure-description"  as="xs:string"/>
    <xsl:param name="figure-id"  as="xs:string"/>

    <xsl:variable name="dates" as="xs:date*" select="$df-rows/events/event/xs:date(@date)"/>
    <xsl:variable name="start-date" select="min($dates)" />
    <xsl:variable name="end-date" select="max($dates)" />

    <xsl:variable name="duration" select="days-from-duration($end-date - $start-date)" as="xs:integer" />

    <xsl:variable name="result">
```{.ggplot2 }

    library(lubridate)
    library(ggplot2)
    library(tidyverse)
    library(dplyr)

    source("OI_theme.R")
    source("stacked_bar_plot_events.R")

    png('my_plot.png', width = 800, height = 500)

    df &lt;- data.frame( event=c("empty"), count=0, index=0, dt=c(as_date("2025-01-01")) )

    k &lt;- df %&gt;% 
        <xsl:for-each select="$df-rows/events/event">
            <xsl:value-of select="concat('# ', @event, ', ', @date, '&#xa;')" />
            <xsl:value-of select="concat(
                            'add_row( ',
                                'event=&quot;', @event, '&quot;, ', 
                                'count= ', @count, ', ', 
                                'index= ', @index, ', ', 
                                'dt=as_date(&quot;', @date, '&quot;)',
                            ') %&gt;%&#xa;'
            )" />
        </xsl:for-each>
    {}

    # remove the placeholder first row
    k &lt;- k[-c(1), ]

    # filter out small values
    k &lt;- k %&gt;% filter_out(count &lt; max(count)/90)

    plot &lt;- gen_stacked_bar_plot_events(k)

```
![<xsl:value-of select="$figure-description"/>](single.png){#fig:<xsl:value-of select="$figure-id"/>}
</xsl:variable>

  <xsl:value-of select="if ($duration gt 1) then $result else ''" />

</xsl:function>


<!--
    multi-facet stacked bar from:
        <events>
            <event category="cat-name" name="event-name" date="yyyy-mm-dd" count="n" />
            ...
        </events>
-->
<xsl:function name="ois:multi-stacked-bar-plot-with-category" as="xs:string">
    <xsl:param name="df-rows" />
    <xsl:param name="figure-description"  as="xs:string"/>
    <xsl:param name="figure-id"  as="xs:string"/>

    <xsl:variable name="dates" as="xs:date*" select="$df-rows/events/event/xs:date(@date)"/>
    <xsl:variable name="start-date" select="min($dates)" />
    <xsl:variable name="end-date" select="max($dates)" />

    <xsl:variable name="duration" select="days-from-duration($end-date - $start-date)" as="xs:integer" />

    <xsl:variable name="result">
        <xsl:if test="$duration gt 1">
```{.ggplot2 }

    library(lubridate)
    library(ggplot2)
    library(tidyverse)
    library(dplyr)

    source("OI_theme.R")
    source("multi-facet-stacked_bar_plot.R")

    png('my_plot.png', width = 800, height = 700)

    df &lt;- data.frame( cat=c("empty"), event=c("empty"), count=0, index=0, dt=c(as_date("2025-01-01")) )

    k &lt;- df %&gt;% 
        <xsl:for-each select="$df-rows/events/event">
            <xsl:value-of select="concat('# ', @category, ', ', @event, ', ', @date, '&#xa;')" />
            <xsl:value-of select="concat(
                            'add_row( ',
                                'cat=&quot;', @category, '&quot;, ', 
                                'event=&quot;', @event, '&quot;, ', 
                                'count= ', @count, ', ', 
                                'index= ', @index, ', ', 
                                'dt=as_date(&quot;', @date, '&quot;)',
                            ') %&gt;%&#xa;'
            )" />
        </xsl:for-each>
    {}

    # remove the placeholder first row
    k &lt;- k[-c(1), ]

    # filter out small values
    k &lt;- k %&gt;% filter_out(count &lt; max(count)/15)

    plot &lt;- gen_facet_stacked_bar_plot(k)

```
![<xsl:value-of select="$figure-description"/>](single.png){#fig:<xsl:value-of select="$figure-id"/>}
</xsl:if>
</xsl:variable>

  <xsl:value-of select="if ($duration gt 1) then $result else ''" />

</xsl:function>

</xsl:stylesheet>
