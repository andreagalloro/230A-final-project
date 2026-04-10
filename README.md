# STAT 230A Final Project

Bart Ridership prediction based on hourly OD data from Bart's General Transit Feed Specification (GTSF) publically available data.

From Bart's website: [Ridership Reports](https://www.bart.gov/about/reports/ridership)

> Hourly Ridership Data
>
>For those of you looking to take a deeper dive into BART’s data - check out our hourly trip datasets. These files will allow you to analyze trips between all stations in the BART system by hour. The data is organized in the following columns: Date, Hour (24-hour clock), Origin Station, Destination Station, Number of Exits. All stations are abbreviated using the 4-Letter station codes, please refer to the station name abbreviations (.xls) for translation.

From the legacy API documentation: [Bart Legacy API](https://api.bart.gov/docs/overview/abbrev.aspx)

| Code | Station Name                 |
| ---- | ---------------------------- |
| 12th | 12th St. Oakland City Center |
| 16th | 16th St. Mission (SF)        |
| 19th | 19th St. Oakland             |
| 24th | 24th St. Mission (SF)        |
| ashb | Ashby (Berkeley)             |
| antc | Antioch                      |
| balb | Balboa Park (SF)             |
| bayf | Bay Fair (San Leandro)       |
| bery | Berryessa / North San Jose   |
| cast | Castro Valley                |
| civc | Civic Center (SF)            |
| cols | Coliseum                     |
| colm | Colma                        |
| conc | Concord                      |
| daly | Daly City                    |
| dbrk | Downtown Berkeley            |
| dubl | Dublin/Pleasanton            |
| deln | El Cerrito del Norte         |
| plza | El Cerrito Plaza             |
| embr | Embarcadero (SF)             |
| frmt | Fremont                      |
| ftvl | Fruitvale (Oakland)          |
| glen | Glen Park (SF)               |
| hayw | Hayward                      |
| lafy | Lafayette                    |
| lake | Lake Merritt (Oakland)       |
| mcar | MacArthur (Oakland)          |
| mlbr | Millbrae                     |
| mlpt | Milpitas                     |
| mont | Montgomery St. (SF)          |
| nbrk | North Berkeley               |
| ncon | North Concord/Martinez       |
| oakl | Oakland Int'l Airport        |
| orin | Orinda                       |
| pitt | Pittsburg/Bay Point          |
| pctr | Pittsburg Center             |
| phil | Pleasant Hill                |
| powl | Powell St. (SF)              |
| rich | Richmond                     |
| rock | Rockridge (Oakland)          |
| sbrn | San Bruno                    |
| sfia | San Francisco Int'l Airport  |
| sanl | San Leandro                  |
| shay | South Hayward                |
| ssan | South San Francisco          |
| ucty | Union City                   |
| warm | Warm Springs/South Fremont   |
| wcrk | Walnut Creek                 |
| wdub | West Dublin                  |
| woak | West Oakland                 |

