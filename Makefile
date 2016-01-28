input/WDI_Data.csv:
	mkdir -p input
	curl http://databank.worldbank.org/data/download/WDI_csv.zip -o input/WDI.zip
	cd input; unzip WDI.zip
input: input/WDI_Data.csv

output/Indicators.csv: input/WDI_Data.csv
	mkdir -p working
	mkdir -p output
	python src/process.py
output/Country.csv: output/Indicators.csv
output/CountryNotes.csv: output/Indicators.csv
output/Footnotes.csv: output/Indicators.csv
output/Series.csv: output/Indicators.csv
output/SeriesNotes.csv: output/Indicators.csv
csv: output/Indicators.csv

working/noHeader/Indicators.csv: output/Indicators.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/Country.csv: output/Country.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/CountryNotes.csv: output/CountryNotes.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/Footnotes.csv: output/Footnotes.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/Series.csv: output/Series.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/SeriesNotes.csv: output/SeriesNotes.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

output/database.sqlite: working/noHeader/Indicators.csv working/noHeader/Country.csv working/noHeader/CountryNotes.csv working/noHeader/Footnotes.csv working/noHeader/Series.csv working/noHeader/SeriesNotes.csv 
	-rm output/database.sqlite
	sqlite3 -echo $@ < working/import.sql
db: output/database.sqlite

output/hashes.txt: output/database.sqlite
	-rm output/hashes.txt
	echo "Current git commit:" >> output/hashes.txt
	git rev-parse HEAD >> output/hashes.txt
	echo "\nCurrent input/ouput md5 hashes:" >> output/hashes.txt
	md5 output/*.csv >> output/hashes.txt
	md5 output/*.sqlite >> output/hashes.txt
	md5 input/* >> output/hashes.txt
hashes: output/hashes.txt

release: output/hashes.txt
	cp -r output world-development-indicators
	zip -r -X output/world-development-indicators-release-`date -u +'%Y-%m-%d-%H-%M-%S'` world-development-indicators/*
	rm -rf world-development-indicators

all: csv db hashes release output-raw

clean:
	rm -rf working
	rm -rf output
