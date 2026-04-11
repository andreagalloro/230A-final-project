######
# This code should be ran in the main final-project directory using
# source("code/generate-proposal-figures.r")
# to generate the graphics used in the project proposal and 
# store them in the report/proposal/figures directory.
######

cat("loading tidyverse and data\n")
library(tidyverse)
od_data <- read_csv("data/od-data.csv")
set.seed(230)

cat("Mutating data\n")
od_data <- od_data |> mutate(pair = paste(origin, destination, sep = " -> "))
stations <- od_data |> 
                distinct(pair) |>
                slice_sample(n = 6)

# Main Figure
cat("generating figure 1\n")
gg1 <- od_data |> 
    mutate(month_year = floor_date(date, unit = "month")) |>
    group_by(month_year) |>
    summarize(riders = sum(ridership)) |>
    ggplot(aes(x = month_year, y = riders)) + 
        geom_col(fill = "steelblue", color = "steelblue") +
        labs(title = "Sytem Usage Over Time",
            x = "Time",
            y = "Ridership")


ggsave("report/proposal/figures/figure1.png", plot = gg1)

# Appendix Figures

cat("generating figure 2\n")
gg2 <- od_data |> 
    filter(pair %in% stations$pair) |>
                ggplot() + 
                        geom_histogram(aes(x = ridership), bins = 30) + 
                        facet_wrap(~ pair) + 
                        labs(title = "Ridership for Random Sample of OD Pairs",
                            x = "Ridership",
                            y = "Counts")

ggsave("report/proposal/figures/figure2.png", plot = gg2)

cat("generating figure 3\n")
gg3 <- od_data |> 
    filter(pair %in% stations$pair & 
            wday(date) %in% seq(2, 6)) |>
    group_by(pair, hour) |>
    summarize(riders = sum(ridership)) |>
                ggplot(aes(x = hour, y = riders)) + 
                        geom_line() + 
                        facet_wrap(~ pair) + 
                        labs(title = "Ridership Patterns by Hour for Random Sample of OD Pairs",
                            x = "Hour of Day",
                            y = "Ridership")

ggsave("report/proposal/figures/figure3.png", plot = gg3)

cat("done\n")