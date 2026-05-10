####
# This r module should be run in the main final-project directory by calling
# source("code/filter-and-add-features.r")
# in an r session. Filters the data and adds features to create the final dataset for modeling.
####

library(tidyverse)
library(tis)
library(baseballr)
library(hoopR)

add_day_of_week_indicator <- function(df) {
    # Function to add a day of week indicator to the dataframe
    df <- df |> mutate(day = case_when(wday(date) %in% seq(2, 6) ~ "weekday",
                                            wday(date) == 1 ~ "sunday",
                                            wday(date) == 7 ~ "saturday")
                        )
    return(df)
}

add_line_indicator <- function(df) {
    # Function to add a line indicator for each BART origin/destination line
    # List of all BART Lines
    bart_lines <- list(
    green = c("BERY", "MLPT", "WARM", "FRMT", "UCTY", "SHAY", "HAYW", "BAYF",
            "SANL", "COLS", "FTVL", "LAKE", "WOAK", "EMBR", "MONT", "POWL", 
            "CIVC", "16TH", "24TH", "GLEN", "BALB", "DALY"),
            
    red = c("RICH", "DELN", "PLZA", "NBRK", "DBRK", "ASHB", "MCAR", "19TH", 
          "12TH", "WOAK", "EMBR", "MONT", "POWL", "CIVC", "16TH", "24TH", 
          "GLEN", "BALB", "DALY", "COLM", "SSAN", "SBRN", "SFIA", "MLBR"),
          
    yellow = c("ANTC", "PCTR", "PITT", "NCON", "CONC", "PHIL", "WCRK", "LAFY", 
             "ORIN", "ROCK", "MCAR", "19TH", "12TH", "WOAK", "EMBR", "MONT", 
             "POWL", "CIVC", "16TH", "24TH", "GLEN", "BALB", "DALY", "COLM", 
             "SSAN", "SBRN", "SFIA", "MLBR"),
             
    blue = c("DUBL", "WDUB", "CAST", "BAYF", "SANL", "COLS", "FTVL", "LAKE", 
           "WOAK", "EMBR", "MONT", "POWL", "CIVC", "16TH", "24TH", "GLEN", 
           "BALB", "DALY"),
           
    orange = c("BERY", "MLPT", "WARM", "FRMT", "UCTY", "SHAY", "HAYW", "BAYF", 
             "SANL", "COLS", "FTVL", "LAKE", "12TH", "19TH", "MCAR", "ASHB", 
             "DBRK", "NBRK", "PLZA", "DELN", "RICH")
             )

    
    for (color in names(bart_lines)) {
        origin_column <- paste0("origin_", color)
        destination_column <- paste0("destination_", color)
        df <- df %>%
        mutate(
        !!origin_column := origin %in% bart_lines[[color]],
        !!destination_column := destination %in% bart_lines[[color]]
        )
    }
    return(df)

}

add_holiday_indicator <- function(df) {
    # Function to add a holiday indicator to the dataframe
    holiday_dates <- as.Date(as.character(holidays(2018:2025, board = TRUE)), format = "%Y%m%d")
    df <- df %>% mutate(is_holiday = date %in% holiday_dates)
    return(df)
}

add_baseball_game_indicator <- function(df) {
    # Function to add a baseball game indicator to the dataframe

    # Gather Dates of Home Games for Giants and A's from 2018-2025
    get_home_games <- function(team_id, year) {
        mlb_schedule(year) %>%
        filter(teams_home_team_id == team_id) %>%
        pull(date) %>%
        as.Date()
    }
    years <- 2018:2025
    giants_home_dates <- map(years, ~get_home_games(137, .x)) %>% list_c()
    as_home_dates <- map(years, ~get_home_games(133, .x)) %>% list_c()

    df <- df %>%
    mutate(
      is_giants_home = date %in% giants_home_dates,
      is_as_home = date %in% as_home_dates
      )
    return(df)
}

add_warriors_game_indicator <- function(df) {
    # Function to add a warriors game indicator to the dataframe

    # Gather Dates of Home Games for Warriors from 2023-2025
    warriors_home_dates <- load_nba_schedule(2023:2025) %>%
    filter(home_id == 9) %>%
    pull(game_date) %>%
    as.Date()

    df <- df %>%
    mutate(
      warriors_at_chase = (date %in% warriors_home_dates) & (date >= as.Date("2019-10-05")) # Warriors first game (pre-season) at Chase
      )
    return(df)
}

add_season_indicator <- function(df) {
    # Function to add a season indicator to the dataframe
    df <- df %>% mutate(season = case_when(month(date) %in% c(12, 1, 2) ~ "winter",
                                            month(date) %in% c(3, 4, 5) ~ "spring",
                                            month(date) %in% c(6, 7, 8) ~ "summer",
                                            month(date) %in% c(9, 10, 11) ~ "fall")
                        )
    return(df)
}

# remove this one from the pipleline
filter_operational_hours <- function(df) {
    # Function to filter the dataframe to only include operational hours (5am-1am)
    df <- df %>% filter((day == "weekday") & !(hour %in% 0:4) |
                        (day == "saturday") & !(hour %in% 0:5) | 
                        (day == "sunday") & !(hour %in% 0:7))
    return(df)
}

add_all_features <- function(df) {
    # Function to filter the dataframe and add features
    df <- df %>%
    add_post_covid_indicator() %>%
    add_line_indicator() %>%
    add_holiday_indicator() %>%
    add_baseball_game_indicator() %>%
    add_warriors_game_indicator() %>%
    add_season_indicator()
    return(df)
}

cat("Loading OD Data...\n")
cat("Printing working directory: ", getwd(), "\n")
dat <- read_csv("./data/od-data.csv")

cat("Filtering...\n")
# Filter for only data from 2023 onward
dat <- dat %>% filter(year(date) >= 2023)
 
dat <- dat |> add_day_of_week_indicator()
# removed operational hours filter from pipeline
# dat_filtered <- filter_operational_hours(dat)

cat("Adding features...\n")
dat_final <- add_all_features(dat_filtered)

cat("Exporting final dataset...\n")
write_csv(dat_final, "./data/final-dataset.csv")
cat("Done!\n")