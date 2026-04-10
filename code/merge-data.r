####
# This r module should be run in the main final-project directory by calling
# source("code/merge-data.r")
# in an r session. binds the data into a single csv.
####
library(tidyverse)

cat("Loading 2018 Data\n")
od_data <- read_csv("data/date-hour-soo-dest-2018.csv", 
                    col_names = c(
                        "date", 
                        "hour", 
                        "origin",
                        "destination",
                        "ridership"
                        )
                    )

for (i in seq(2019, 2025)) {
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
write_csv(od_data, "data/od-data.csv")
cat("done\n")