

library(ggplot2)
library(tidyverse)
library(dplyr)
library(scales)

source("OI_theme.R")


#
# k = ( (event="x", count=10, index=1, dt=as_date("1999-01-01"), ...
#
gen_stacked_bar_plot_events <- function(k) {

    # add truncated labels
    k <- k %>% mutate(short_label=str_trunc(event, 20))

    plot <- ggplot(k) +
        aes(x=dt, y=count, fill=fct_rev(factor(index))) + 
        geom_bar(stat = "identity", width=0.99, show.legend=FALSE) + 
        labs(x="", y="") + 
        theme_oi(gridline_x = FALSE) + 
        scale_fill_oi_d("secondary") +
        scale_y_continuous(expand = expansion(mult = c(0, 0.2)), labels=label_number(accuracy=1))  + 
        guides(fill=guide_legend(title=NULL)) + 
        geom_text(aes(label = short_label), position = "stack", vjust=0, hjust="inward", check_overlap = TRUE) +
        geom_label(
                   aes(label = count), 
                   linewidth=0,
                   fill=NULL, 
                   position = position_stack(vjust = 0.5), 
                   check_overlap = TRUE, 
                   size=3) +
        theme(legend.position="top")

   return (plot)
}

# position_stack(vjust = 0.5)
#        geom_text(aes(label = short_label), nudge_y = 100, nudge_unit='px') +
