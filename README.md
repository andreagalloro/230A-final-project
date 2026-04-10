# STAT 230A Final Project

Bart Ridership prediction based on hourly OD data from Bart's General Transit Feed Specification (GTSF) publically available data.

From Bart's website: [Ridership Reports]{https://www.bart.gov/about/reports/ridership}

> Hourly Ridership Data
>
>For those of you looking to take a deeper dive into BART’s data - check out our hourly trip datasets. These files will allow you to analyze trips between all stations in the BART system by hour. The data is organized in the following columns: Date, Hour (24-hour clock), Origin Station, Destination Station, Number of Exits. All stations are abbreviated using the 4-Letter station codes, please refer to the station name abbreviations (.xls) for translation.

From the station name abbreviations: [Station Names]{https://www.bart.gov/sites/default/files/docs/station-names.xls}

| Two-Letter Station Code | Station Name                        |
| ----------------------- | ----------------------------------- |
| RM                      | Richmond                            |
| EN                      | El Cerrito Del Norte                |
| EP                      | El Cerrito Plaza                    |
| NB                      | North Berkeley                      |
| BK                      | Berkeley                            |
| AS                      | Ashby                               |
| MA                      | MacArthur                           |
| 19                      | 19th Street Oakland                 |
| 12                      | 12th Street / Oakland City Center   |
| LM                      | Lake Merritt                        |
| FV                      | Fruitvale                           |
| CL                      | Coliseum                            |
| SL                      | San Leandro                         |
| BF                      | Bayfair                             |
| HY                      | Hayward                             |
| SH                      | South Hayward                       |
| UC                      | Union City                          |
| FM                      | Fremont                             |
| CN                      | Concord                             |
| PH                      | Pleasant Hill                       |
| WC                      | Walnut Creek                        |
| LF                      | Lafayette                           |
| OR                      | Orinda                              |
| RR                      | Rockridge                           |
| OW                      | West Oakland                        |
| EM                      | Embarcadero                         |
| MT                      | Montgomery Street                   |
| PL                      | Powell Street                       |
| CC                      | Civic Center                        |
| 16                      | 16th Street Mission                 |
| 24                      | 24th Street Mission                 |
| GP                      | Glen Park                           |
| BP                      | Balboa Park                         |
| DC                      | Daly City                           |
| CM                      | Colma                               |
| CV                      | Castro Valley                       |
| ED                      | Dublin/Pleasanton                   |
| NC                      | North Concord                       |
| WP                      | Pittsburg/Bay Point                 |
| SS                      | South San Francisco                 |
| SB                      | San Bruno                           |
| SO                      | San Francisco International Airport |
| MB                      | Millbrae                            |
| WD                      | West Dublin/Pleasanton              |
| OA                      | Oakland International Airport       |
| WS                      | Warm Springs                        |
| AN                      | Antioch                             |
| PC                      | Pittsburg Center                    |
| ML                      | Milpitas                            |
| BE                      | Berryessa / North San José          |
