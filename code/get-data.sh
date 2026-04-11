####
# This bash script should be run in the main final-project directory by calling
# bash scripts/get-data.sh
# in the terminal. It creates a data folder and downloads the hourly OD data from BART
####

url="https://afcweb.bart.gov/ridership/origin-destination/date-hour-soo-dest-"

mkdir data
cd data

for ((i=2018;i<=2025; i++)); do
    wget -q "${url}${i}.csv.gz"
    #-f returns true if the file exists.
    if [ -f "date-hour-soo-dest-${i}.csv.gz" ]; then
        gunzip -q "date-hour-soo-dest-${i}.csv.gz"
        #force standard input so that wc returns only observations
        obs=$(wc -l < "date-hour-soo-dest-${i}.csv")
        echo "The number of observations in ${i} is: ${obs}"
    else
        echo "The number of observationsin ${i} is: 0"
    fi

done

cd ..
