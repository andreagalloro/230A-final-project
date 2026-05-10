####
# This r module should be run in the main final-project directory by calling
# source("code/merge-data-post-covid.r")
# in an r session. binds the data into a single csv.
####
library(tidyverse)

cat("Loading 2023 Data\n")
od_data <- read_csv("data/date-hour-soo-dest-2023.csv", 
                    col_names = c(
                        "date", 
                        "hour", 
                        "origin",
                        "destination",
                        "ridership"
                        )
                    )

for (i in seq(2024, 2025)) {
    path <- str_c("data/date-hour-soo-dest-", i, ".csv", sep = "")
    cat("Loading in and binding", i, "Data\n")
    od_data <- bind_rows(od_data, 
        read_csv(path, 
                    col_names = c(
                        "date", 
                        "hour", 
                        "origin",
                        "destination",
                        "ridership"
                        )
                    )
    )

}

cat("Exporting to one csv\n")
write_csv(od_data, "data/od-data-post-covid.csv")
cat("done\n")