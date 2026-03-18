library(ggplot2)

OI_palette_primary = c("#04aada", "#40535d", "#162c36", "#FFFFFF")
OI_palette_secondary_A = c("#3f2c69", "#77c8b3", "#ee8a54", "#82a7c5")
OI_palette_secondary_B = c("#cddb28", "#cad4d7", "#00969f", "#fb4f14")
OI_palette_secondary = append(OI_palette_secondary_A, OI_palette_secondary_B)
OI_palette_all = c("#04aada", "#40535d", "#3f2c69", "#77c8b3", "#ee8a54", "#82a7c5", "#cddb28", "#cad4d7", "#00969f", "#fb4f14")

oi_colours = list(
  primary = OI_palette_primary,
  secondary = OI_palette_secondary,
  secondary_A = OI_palette_secondary_A,
  secondary_B = OI_palette_secondary_B,
  all = OI_palette_all
)

oi_palettes = function(name, n, all_palettes = oi_colours, type = c("discrete", "continuous")) {
  palette = all_palettes[[name]]
  if (missing(n)) {
    n = length(palette)
  }
  type = match.arg(type)
  out = switch(type,
               continuous = grDevices::colorRampPalette(palette)(n),
               discrete = palette[1:n]
  )
  structure(out, name = name, class = "palette")
}

scale_fill_oi_d = function(name) {
  ggplot2::scale_fill_manual(values = oi_palettes(name, type = "discrete"))
}

theme_oi <- function(gridline_x = TRUE, gridline_y = TRUE) {
  gridline <- element_line(
    linetype = "39",
    linewidth = 0.15,
    color = OI_palette_primary[2]
  )
  
  gridline_x <- if (isTRUE(gridline_x)) {
    gridline
  } else {
    element_blank()
  }
  
  gridline_y <- if (isTRUE(gridline_y)) {
    gridline
  } else {
    element_blank()
  }
  
  # Set base theme and font family =============================================
  theme_minimal(
    base_family = "Verdana"
  ) +
    # Overwrite base theme defaults ============================================
  theme(
    # Text elements ==========================================================
    plot.title = element_text(
      size = 18,
      face = "bold",
      color = OI_palette_primary[2],
      margin = margin(b = 10)
    ),
    plot.subtitle = element_text(
      size = 14,
      color = OI_palette_primary[2],
      margin = margin(b = 10)
    ),
    plot.caption = element_text(
      size = 13,
      color = OI_palette_primary[2],
      margin = margin(t = 15),
      hjust = 0
    ),
    axis.text = element_text(
      size = 11,
      color = OI_palette_primary[2]
    ),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    # Line elements ==========================================================
    panel.grid.minor = element_blank(),
    panel.grid.major.x = gridline_x,
    panel.grid.major.y = gridline_y,
    axis.line.x.bottom = element_line(
      linetype = "solid",
      linewidth = 0.25,
      color = OI_palette_primary[2]
    ),
    axis.ticks.x = element_line(
      linetype = "solid",
      linewidth = 0.25,
      color = OI_palette_primary[2]
    ),
    axis.ticks.length.x = unit(5, units = "pt"),

    axis.minor.ticks.x.bottom = element_line(
      linetype = "solid",
      linewidth = 0.15,
      color = OI_palette_primary[2]
    ),
    axis.minor.ticks.length.x = unit(4, units = "pt"),

    # ===== facets ============================
    strip.text = element_text(color = "white", face="bold", size=rel(1.1), margin=margin(t=5, b=3)),
    strip.background = element_rect(fill = "#40535d", colour="white"),
  )
}
