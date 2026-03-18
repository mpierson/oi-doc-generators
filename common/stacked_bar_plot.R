

library(ggplot2)
library(tidyverse)
library(dplyr)
library(scales)

source("OI_theme.R")


# -------------------------
#
# k = ( (name="x", dt=as_date("1999-01-01"), (name="b", dt=as_date(...)), ...)
#
gen_stacked_bar_plot <- function(k) {
  
    ndays <- interval(min(k$dt), max(k$dt)) / ddays(1)
    age <- interval(min(k$dt), today()) / dyears(1)
    
    date_format = waiver()
    date_breaks = waiver()
    minor_breaks = waiver()
    guide=waiver()
    if ( age > 1 ) {
        if (ndays < 10) {
            date_format = "%b %d, %Y"
            date_breaks = "day"
        } else if (ndays < 30) {
            minor_breaks = "day"
            guide = guide_axis(minor.ticks = TRUE)
        } else if (ndays < 100) {
            date_format = "%b %Y"
            date_breaks = "month"
            minor_breaks = "day"
            guide = guide_axis(minor.ticks = TRUE)
        } else if (ndays < 400) {
            date_format = "%b %Y"
            date_breaks = "month"
        } else if (ndays < 3000) {
            date_format = "%Y"
            date_breaks = "year"
            minor_breaks = "month"
            guide = guide_axis(minor.ticks = TRUE)
        }
    } else {
        if (ndays < 10) {
            date_format = "%d %b"
            date_breaks = "day"
        } else if (ndays < 30) {
            date_format = "%d %b"
        } else if (ndays < 100) {
            date_format = "%b"
            date_breaks = "month"
            minor_breaks = "day"
            guide = guide_axis(minor.ticks = TRUE)
        } else if (ndays < 400) {
            date_breaks = "month"
            date_format = "%b %Y"
        } else if (ndays < 3000) {
            date_format = "%Y"
            date_breaks = "year"
            minor_breaks = "month"
            guide = guide_axis(minor.ticks = TRUE)
        }
    }


    
    plot <- ggplot(k, aes(x=dt, fill=name)) + 
        geom_bar() + 
        labs(x="", y="") + 
        theme_oi(gridline_x = FALSE) + 
        scale_fill_manual(values = OI_palette_secondary_A) + 
        scale_y_continuous(expand = expansion(mult = c(0, .1)), labels=label_number(accuracy=1))  + 
        scale_x_date(date_labels=date_format, date_breaks=date_breaks,date_minor_breaks=minor_breaks, guide=guide) + 
        guides(fill=guide_legend(title=NULL)) + 
        theme(legend.position="top")

   return (plot)
}
