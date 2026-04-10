####
# This bash script should be run in the main final-project directory by calling
# bash scripts/get-station-names.sh
# in the terminal. It get the xls file for the station name abbreviations
####
url="https://www.bart.gov/sites/default/files/docs/station-names.xls"

cd data

wget -q $url

cd ..
