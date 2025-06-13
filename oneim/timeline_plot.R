

library(sys)
library(scales)
library(lubridate)
library(ggplot2)
library(tidyverse)
library(knitr)
library(timevis)
library(dplyr)




# -------------------------

gen_timeline_plot <- function(k, range_start, range_end, df_dates, ticks) {

    #positions <- c(0.20, -0.25, 0.35, -0.40, .50, -0.55, 0.65, -0.70, 0.8, -0.85, 0.95, -1.00, 1.10, -1.15, 1.25, -1.30, 1.40, -1.45, 1.55, -1.60, 1.70, -1.75, 1.85, -1.90)
    positions <- c(0.20, -0.25, 
                   0.35, -0.40, 
                   0.50, -0.55, 
                   0.65, -0.70, 
                   0.80, -0.85, 
                   0.95, -1.00, 
                   1.10, -1.15, 
                   1.25, -1.30, 
                   1.40, -1.45, 
                   1.55, -1.60, 
                   1.70, -1.75)
    directions <- c(1, -1)
    line_pos <- data.frame(
        "id"      = unique(k$id),
        "position"  = rep(positions, length.out=length(unique(k$id))) ,
        "direction" = rep(directions, length.out=length(unique(k$id))) )
    k <- merge(x=k, y=line_pos, by="id", all = TRUE)


    # OI_GREEN, OI_ORANGE, OI_BROWN, OI_LIGHT_BLUE
    colors <- c("#afcc9e", "#f79431", "#c8b483", "#9dcdda")
    point_color <- data.frame(
        "id"    = unique(k$id),
        "color" = rep(colors, length.out=length(unique(k$id))) )
    k <- merge(x=k, y=point_color, by="id", all = TRUE)



    timeline_plot <- ggplot(k, aes(x=date, y=position))
    timeline_plot <- timeline_plot+theme_classic()
    timeline_plot <- timeline_plot+geom_segment(data=k, aes(y=position,yend=0,xend=date), color='grey', size=0.2)

    timeline_plot <- timeline_plot+theme(axis.line.y=element_blank(),
        axis.text.y=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.text.x =element_blank(),
        axis.line.x =element_blank(),
        axis.ticks.x =element_blank(),
        legend.position = "bottom"
    )

    timeline_plot <- timeline_plot+geom_hline(yintercept=0, color = "black", size=0.3)

    timeline_plot <- timeline_plot+geom_point(aes(y=k$position), size=3, color=k$color)

    timeline_plot <- timeline_plot+geom_text( data=df_dates, aes(x=date_range,y=-0.07,label=date_format), size=3.5, vjust=0.5, color='black', angle=0)


    # position text above/below markers
    text_offset <- 0.07
    absolute_value <-(abs(k$position))
    text_position <- absolute_value + text_offset
    k$text_position <- text_position * k$direction

    timeline_plot <- timeline_plot+geom_text(aes(y=k$text_position,label=k$short_name),size=2.5, vjust=0.5)


   tick_frame <- data.frame(ticks, zero=0, name='') %>% subset(ticks != 0)
   timeline_plot <- timeline_plot + geom_segment(data = tick_frame, aes(x = ticks, xend = ticks, y = zero, yend = zero - 0.015))

   return (timeline_plot)
}
