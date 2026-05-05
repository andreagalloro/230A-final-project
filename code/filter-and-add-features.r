library(tidyverse)
library(tis)
library(baseballr)
library(hoopR)


cat("Loading OD Data\n")
dat <- read_csv("../data/od-data.csv")


cat("Filtering and Adding Features\n")
dat_filtered <- dat |> mutate()

add_day_of_week_indicator <- function(df) {
    # Function to add a day of week indicator to the dataframe
    df <- df |> mutate(day = case_when(wday(date) %in% seq(2, 6) ~ "weekday",
                                            wday(date) == 1 ~ "sunday",
                                            wday(date) == 7 ~ "saturday")
                        )
    return(df)
}

add_post_covid_indicator <- function(df) {
    # Function to add a post covid indicator to the dataframe
    df <- df |> mutate(post_covid = if_else(date > ymd("2020-03-19"), 1, 0))
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

add warriors_game_indicator <- function(df) {
    # Function to add a warriors game indicator to the dataframe

    # Gather Dates of Home Games for Warriors from 2018-2025
    warriors_home_dates <- load_nba_schedule(2018:2025) %>%
    filter(home_id == 9) %>%
    pull(game_date) %>%
    as.Date()

    years <- 2018:2025
    warriors_home_dates <- map(years, ~get_warriors_home_games(.x)) %>% list_c()

    df <- df %>%
    mutate(
      warriors_at_coliseum = (date %in% warriors_home_dates) & (date < as.Date("2019-10-05")),
      warriors_at_chase = (date %in% warriors_home_dates) & (date >= as.Date("2019-10-05")) # Warriors first game (pre-season) at Chase
      )
    return(df)
}