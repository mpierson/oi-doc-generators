

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
    plot <- ggplot(k, aes(x=dt, fill=name)) + 
        geom_bar(width=0.9) + 
        labs(x="", y="") + 
        theme_oi(gridline_x = FALSE) + 
        scale_fill_manual(values = OI_palette_secondary_A) + 
        scale_y_continuous(expand = expansion(mult = c(0, .1)), labels=label_number(accuracy=1))  + 
        guides(fill=guide_legend(title=NULL)) + 
        theme(legend.position="top")
   return (plot)
}
# scale_x_date(date_labels=date_label_format, date_breaks=date_label_breaks, minor_breaks=date_label_minor_breaks) + 
