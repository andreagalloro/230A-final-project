####
# This bash script should be run in the main final-project directory by calling
# bash scripts/get-data.sh
# in the terminal. It downloads the kml data from BART into the data directory.
# It does nothing to the MACOSX kmz file for the district boundaries data
####

cd data

wget https://www.bart.gov/sites/default/files/2025-12/BART-Stations-tracks-entrances-121025.kmz_.zip
unzip BART-Stations-tracks-entrances-121025.kmz_.zip -d stations-and-lines/

wget https://www.bart.gov/sites/default/files/2025-02/BART_District_Boundaries_2025.kmz_.zip
unzip BART_District_Boundaries_2025.kmz_.zip -d district-boundaries/

cd district-boundaries
unzip BART_District_Boundaries_2025.kmz
rm *.kmz

cd ..

rm *.zip

cd ..