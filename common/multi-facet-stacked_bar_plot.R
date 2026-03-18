

library(ggplot2)
library(tidyverse)
library(dplyr)
library(scales)

source("OI_theme.R")


# -------------------------
#
# add_row( cat="Appliance", event="NtpErrorDetected", count= 1, dt=as_date("2026-03-04")) %>%
#
gen_facet_stacked_bar_plot <- function(k) {

    # break alogorithm weights: (simplicity, coverage, density, and legibility
    plot <-  ggplot(k) + 
        aes(x=dt, y=count, fill=fct_rev(factor(index))) + 
        geom_bar(stat = "identity", show.legend = FALSE) + 
        facet_wrap(~cat, ncol=1, dir="v") +
        labs(x="", y="") + 
        theme_oi(gridline_x = FALSE) +
        scale_fill_oi_d("secondary") +
        scale_y_continuous(breaks = breaks_extended(n=3, only.loose=FALSE), expand = expansion(mult = c(0, .1)))  + 
        scale_x_date(minor_breaks=NULL)  + 
        guides(fill=guide_legend(title=NULL))
#        scale_y_continuous(expand = expansion(mult = c(0, .1)), labels=label_number(accuracy=1))  + 
#        scale_discrete_manual(values = OI_palette_secondary_A, aesthetics = c("colour", "fill")) + 
#        scale_y_discrete(labels=NULL)  + 
   return (plot)
}
# scale_x_date(date_labels=date_label_format, date_breaks=date_label_breaks, minor_breaks=date_label_minor_breaks) + 
