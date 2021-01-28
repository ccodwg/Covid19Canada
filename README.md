# Epidemiological Data from the COVID-19 Outbreak in Canada
The [**COVID-19 Canada Open Data Working Group**](https://opencovid.ca/) is collecting publicly available information on confirmed and presumptive positive cases during the ongoing COVID-19 outbreak in Canada. Data are entered in a spreadsheet with each line representing a unique case, including age, sex, health region location, and history of travel where available. Sources are included as a reference for each entry. All data are exclusively collected from publicly available sources including government reports and news media. We aim to continue making updates daily.

# Methodology, Data Notes & Dashboard 
Detailed information about our [data collection methodology](https://opencovid.ca/work/dataset/) and [sources](https://opencovid.ca/work/data-sources/), answers to [frequently asked data questions](https://opencovid.ca/work/data-faq/), specific data notes, and more information about the **COVID-19 Canada Open Data Working Group** is available on our [website](https://opencovid.ca/).

We have also created an interactive dashboard for up-to-date visual analytics and epidemiological analyses. This is available for public use at: [https://art-bd.shinyapps.io/covid19canada/](https://art-bd.shinyapps.io/covid19canada/)

# Citation
Berry I, Soucy J-PR, Tuite A, Fisman D. Open access epidemiologic data and an interactive dashboard to monitor the COVID-19 outbreak in Canada. CMAJ. 2020 Apr 14;192(15):E420. doi: https://doi.org/10.1503/cmaj.75262

# [PLEASE READ] Upcoming Changes, Recent Changes and Vaccine Datasets

## Recent Changes

2021-01-27: Due to the limit on file sizes in GitHub, we implemented some changes to the datasets today, mostly impacting individual-level data (cases and mortality). Changes below:

1) Individual-level data (cases.csv and mortality.csv) have been moved to a new directory in the root directory entitled “individual_level”. These files have been split by calendar year and named as follows: cases_2020.csv, cases_2021.csv, mortality_2020.csv, mortality_2021.csv. The directories “other/cases_extra” and “other/mortality_extra” have been moved into the “individual_level” directory.
2) Redundant datasets have been removed from the root directory. These files include: recovered_cumulative.csv, testing_cumulative.csv, vaccine_administration_cumulative.csv, vaccine_distribution_cumulative.csv, vaccine_completion_cumulative.csv. All of these datasets are currently available as time series in the directory “timeseries_prov”.
3) The file codebook.csv has been moved to the directory “other”.

We appreciate your patience and hope these changes cause minimal disruption. We do not anticipate making any other large scale updates to the datasets in the near future. If you have any further questions, please open an issue on GitHub or reach out to us by email at ccodwg [at] gmail [dot] com. Thank you for using the COVID-19 Canada Open Data Working Group datasets.

- 2021-01-24: The columns "additional_info" and "additional_source" in cases.csv and mortality.csv have been abbreviated similar to "case_source" and "death_source". See note in README.md from 2021-11-27 and 2021-01-08.
- 2021-01-08: The directories cases_extra and mortality_extra have been moved to other/cases_extra and other/mortality_extra.
- 2020-12-03: "Repatriated" now appears in the testing time series. For now, they are given 0 values. The correct values (from PHAC data) will be added soon. "Repatriated" now also appears in the mortality time series (all 0 values, which is correct).
- 2020-11-27: The columns "case_source" (cases.csv) and "death_source" (mortality.csv) are now abbreviated to reduce the file size. They can be joined to the full source links via cases_extra/cases_case_source.csv and mortality_extra/mortality_death_source.csv. Instructions can be found in [README.md](#individual-level-data---extra-columns).

## Vaccine Datasets

Sources for our vaccine data are summarized here: [https://docs.google.com/spreadsheets/d/1zebsxvOPw8gJ-38r9Wbs_tY0Sk5lvfr0khun9_p3gmY/htmlview](https://docs.google.com/spreadsheets/d/1zebsxvOPw8gJ-38r9Wbs_tY0Sk5lvfr0khun9_p3gmY/htmlview)

- 2021-01-19: Fully vaccinated data have been added (vaccine_completion_cumulative.csv, timeseries_prov/vaccine_completion_timeseries_prov.csv, timeseries_canada/vaccine_completion_timeseries_canada.csv). Note that this value is not currently reported by all provinces (some provinces have all 0s).
- 2021-01-11: Our Ontario vaccine dataset has changed. Previously, we used two datasets: the MoH Daily Situation Report (https://www.oha.com/news/updates-on-the-novel-coronavirus), which is released weekdays in the evenings, and the “COVID-19 Vaccine Data in Ontario” dataset (https://data.ontario.ca/dataset/covid-19-vaccine-data-in-ontario), which is released every day in the mornings. Because the Daily Situation Report is released later in the day, it has more up-to-date numbers. However, since it is not available on weekends, this leads to an artificial “dip” in numbers on Saturday and “jump” on Monday due to the transition betwen data sources. We will now exclusively use the daily “COVID-19 Vaccine Data in Ontario” dataset. Although our numbers will be slightly less timely, the daily values will be consistent. We have replaced our historical dataset with “COVID-19 Vaccine Data in Ontario” as far back as they are available.
- 2020-12-17: Vaccination data have been added as time series in timeseries_prov and timeseries_hr.
- 2020-12-15: We have added two vaccine datasets to the repository, vaccine_administration_cumulative.csv and vaccine_distribution_cumulative.csv.

# Datasets
The full dataset may be downloaded in CSV format from this repository. The full dataset is also available in JSON format from our [API](https://opencovid.ca/api/).

### Date and time of dataset update
* **Date and time of update**: update_time.txt

### Individual-level Data
* **Cases**: individual_level/cases_2020.csv and individual_level/cases_2021.csv
* **Mortality**: individual_level/mortality_2020.csv and individual_level/mortality_2021.csv

### Health Region-level Time Series
* **Daily and cumulative cases**: timeseries_hr/cases_timeseries_hr.csv
* **Daily and cumulative mortality**: timeseries_hr/mortality_timeseries_hr.csv

### Province-level Time Series
* **Daily and cumulative cases**: timeseries_prov/cases_timeseries_prov.csv
* **Daily and cumulative mortality**: timeseries_prov/mortality_timeseries_prov.csv
* **Daily and cumulative recovered**: timeseries_prov/recovered_timeseries_prov.csv
* **Daily and cumulative testing**: timeseries_prov/testing_timeseries_prov.csv
* **Current and change in active cases**: timeseries_prov/active_timeseries_prov.csv
* **Daily and cumulative vaccine doses delivered**: timeseries_prov/vaccine_distribution_timeseries_prov.csv
* **Daily and cumulative vaccine doses administered**: timeseries_prov/vaccine_administration_timeseries_prov.csv
* **Daily and cumulative people fully vaccinated**: timeseries_prov/vaccine_completion_timeseries_prov.csv

### Canada-level Time Series
* **Daily and cumulative cases**: timeseries_canada/cases_timeseries_canada.csv
* **Daily and cumulative mortality**: timeseries_canada/mortality_timeseries_canada.csv
* **Daily and cumulative recovered**: timeseries_canada/recovered_timeseries_canada.csv
* **Daily and cumulative testing**: timeseries_canada/testing_timeseries_canada.csv
* **Current and change in active cases**: timeseries_canada/active_timeseries_canada.csv
* **Daily and cumulative vaccine doses delivered**: timeseries_canada/vaccine_distribution_timeseries_canada.csv
* **Daily and cumulative vaccine doses administered**: timeseries_canada/vaccine_administration_timeseries_canada.csv
* **Daily and cumulative people fully vaccinated**: timeseries_canada/vaccine_completion_timeseries_canada.csv

### Other Files
* **Codebook**: other/codebook.csv
* **Correspondence between health region names used in our dataset and HRUID values given in Esri Canada's [health region map](https://resources-covid19canada.hub.arcgis.com/datasets/regionalhealthboundaries-1), with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401)**: other/hr_map.csv
* **Correspondece between province names used in our dataset and full province names and two-letter abbreviations, with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401)**: other/prov_map.csv
* **Correspondence between ages given in the individual-level case data and age groups displayed on the data dashboard**: other/age_map_cases.csv
* **Correspondence between ages given in the individual-level mortality data and age groups displayed on the data dashboard**: other/age_map_mortality.csv

### Other Files: Individual-level Data - Extra columns
* **Cases: case source**: individual_level/cases_extra/cases_case_source.csv (join with cases.csv by joining case_source with case_source_short)
* **Cases: additional info**: individual_level/cases_extra/cases_additional_info.csv (join with cases.csv by joining additional_info with additional_info_short)
* **Cases: additional source**: individual_level/cases_extra/cases_additional_source.csv (join with cases.csv by joining additional_source with additional_source_short)
* **Mortality: death source**: individual_level/mortality_extra/mortality_death_source.csv (join with mortality.csv by joining death_source with death_source_short)
* **Mortality: additional info**: individual_level/mortality_extra/mortality_additional_info.csv (join with mortality.csv by joining additional_info with additional_info_short)
* **Mortality: additional source**: individual_level/mortality_extra/mortality_additional_source.csv (join with mortality.csv by joining additional_source with additional_source_short)

### Scripts
* **Data update (script used to prepare the data update each day)**: scripts/data_update.R
* **Data update validation (script used to help check the data update each day prior to release)**: scripts/data_update_validation.R
* **Functions for data update validation**: scripts/data_update_validation_funs.R
* **API testing** (verify consistency between GitHub data and data returned by API): scripts/api_test.R

# Acknowledgements
We want to thank all individuals and organizations across Canada who have been willing and able to report data in as open and timely a manner as possible. 

Please see below for a recommended citation of this dataset. A number of individuals have contributed to the specific data added here and their names and details are listed below, as well as on our [website](https://opencovid.ca/about/). 

# Specific Contributors
Name | Role | Organization | Email | Twitter
--- | --- | --- | --- | ---
Isha Berry | Founder | University of Toronto  | isha.berry@mail.utoronto.ca | [@ishaberry2](https://twitter.com/ishaberry2)
Jean-Paul R. Soucy | Founder | University of Toronto | jeanpaul.soucy@mail.utoronto.ca | [@JPSoucy](https://twitter.com/JPSoucy)
Meghan O'Neill | Data Lead | University of Toronto | meghan.oneill@utoronto.ca | [@_MeghanONeill](https://twitter.com/_MeghanONeill)
Shelby Sturrock | Data Lead | University of Toronto | shelby.sturrock@mail.utoronto.ca| [@shelbysturrock](https://twitter.com/shelbysturrock)
James E. Wright | Data Lead | SickKids | jamese.wright@sickkids.ca | [@JWright159](https://twitter.com/JWright159)
Wendy Xie | Data Lead |  University of Guelph | xxie03@uoguelph.ca | [@XiaotingXie](https://twitter.com/XiaotingXie)
Kamal Acharya | Contributor | University of Guelph | acharyak@uoguelph.ca | [@Kamalraj_ach](https://twitter.com/Kamalraj_ach)
Gabrielle Brankston | Contributor |  University of Guelph | brankstg@uoguelph.ca | [@GBrankston](https://twitter.com/GBrankston)
Vinyas Harish | Contributor |  University of Toronto | v.harish@mail.utoronto.ca | [@VinyasHarish](https://twitter.com/VinyasHarish)
Kathy Kornas | Contributor | University of Toronto  | kathy.kornas@utoronto.ca | 
Nika Maani | Contributor | University of Toronto | nika.maani@mail.utoronto.ca |
Thivya Naganathan | Contributor |  University of Guelph |tnaganat@uoguelph.ca |
Lindsay Obress | Contributor |  University of Guelph | lobress@uoguelph.ca |
Tanya Rossi | Contributor |  University of Guelph | rossit@uoguelph.ca | [@DrTanyaRossi](https://twitter.com/DrTanyaRossi)
Alison Simmons | Contributor | University of Toronto | alison.simmons@mail.utoronto.ca | [@alisonesimmons](https://twitter.com/alisonesimmons)
Matthew Van Camp | Contributor |  University of Guelph | vancampm@uoguelph.ca | 
