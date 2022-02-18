# Epidemiological Data from the COVID-19 Outbreak in Canada

The [**COVID-19 Canada Open Data Working Group**](https://opencovid.ca/) collects daily time series data on COVID-19 cases, deaths, recoveries, testing and vaccinations at the health region and province levels. Data are collected from publicly available sources such as government datasets and news releases. Updates are made nightly at 22:00 ET. See [`data_notes.txt`](https://github.com/ccodwg/Covid19Canada/blob/master/data_notes.txt) for notes regarding the latest data update. Our data collection is mostly automated; see [`Covid19CanadaETL`](https://github.com/ccodwg/Covid19CanadaETL) for details.

Our data dashboard is available at the following URL: [https://art-bd.shinyapps.io/covid19canada/](https://art-bd.shinyapps.io/covid19canada/).

Table of contents:

* [Accessing the data](#accessing-the-data)
* [Recent dataset changes](#recent-dataset-changes)
* [Datasets](#datasets)
* [Recommended citation](#recommended-citation)
* [Methodology & data notes](#methodology--data-notes)
* [Acknowledgements](#acknowledgements)
* [Contact us](#contact-us)

## Accessing the data

❗ Before using our datasets, please read the [Datasets](#datasets) section below. ⚠️

Our datasets are available in three different formats:

* CSV format from this GitHub repository (to download all the latest data, select the green "Code" button and click "Download ZIP")
* JSON format from our [API](https://opencovid.ca/api/)
* [Google Drive](https://drive.google.com/drive/folders/1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP)

Note that retired datasets (`retired_datasets`) are only available on GitHub.

## Recent dataset changes

* Beginning 2022-02-07, Saskatchewan will only be reporting a limited set of data once per week on Thursdays. See the [news release](https://www.saskatchewan.ca/government/news-and-media/2022/february/03/living-with-covid-transition-of-public-health-management) for more details. This will affect the quality and timeliness of COVID-19 data updates for Saskatchewan.

## Datasets

**Usage notes and caveats**

The dataset in this repository was launched in March 2020 and has been maintained ever since. As a legacy dataset, it preserves many oddities in the data introduced by changes to COVID-19 reporting over time (see details below). A new, definitive COVID-19 dataset for Canada is currently being developed as [`CovidTimelineCanada`](https://github.com/ccodwg/CovidTimelineCanada), a part of the **[What Happened? COVID-19 in Canada](https://whathappened.coronavirus.icu/)** project. While the new `CovidTimelineCanada` dataset is not yet stable (and thus should not be relied upon), it fixes many of the aforementioned oddities present in the legacy dataset in this repository.

- ℹ️ See [`data_notes.txt`](https://github.com/ccodwg/Covid19Canada/blob/master/data_notes.txt) for notes regarding issues affecting the dataset.
- ℹ️ Ontario case, mortality and recovered data are retrieved from individual [public health units](https://www.health.gov.on.ca/en/common/system/services/phu/locations.aspx) (exceptions are listed [here](https://github.com/ccodwg/Covid19Canada/issues/97) and differ from values reported in the [Ontario Ministry of Health dataset](https://data.ontario.ca/dataset/confirmed-positive-cases-of-covid-19-in-ontario/resource/455fd63b-603d-4608-8216-7d8647f43350). For most public health units, we limit cases to confirmed cases (excluding probable cases).
- ⚠️ Impossible values, such as negative case or death counts
  - Our dataset preserves some "impossible" values such as negative daily case or death counts. This is because our dataset reports primarily the *cumulative* value reported each day by the public health authority. Since historical data are sometimes revised (e.g., cases reassigned to different regions, fixing data quality issues, etc.), this sometimes results in negative values reported for a particular date.
- ⚠️ Caution regarding testing numbers
  - For continuity, we generally report the first testing number that was reported by the province. For some provinces this was number of tests performed, for others this was number of unique people tested. For the purposes of calculating percent positivity, the number of tests performed should generally be used. The [Public Health Agency of Canada](https://health-infobase.canada.ca/covid-19/epidemiological-summary-covid-19-cases.html) provides a province-level time series of number of tests performed. We supply a compatible version of this dataset as in the [`official_datasets`](https://github.com/ccodwg/Covid19Canada/tree/master/official_datasets) directory as [`phac_n_tests_performed_timeseries_prov.csv`](https://github.com/ccodwg/Covid19Canada/blob/master/official_datasets/can/phac_n_tests_performed_timeseries_prov.csv). This dataset should be used over our dataset for inter-provincial comparisons.
- ⚠️ Recovered/active case counts are highly problematic
  - The defintion of "recovered" has changed over time and differs between provinces. For example, Quebec changed their defintion of recovered on July 17, 2020, which created a massive spike on that date. For this reason, these data should be interpreted with caution.
  - Recovered and active case numbers for Ontario (and thus Canada) are incorrectly estimated prior to 2021-09-07 and should not be considered reliable.
  - Recovered and active case numbers for British Columbia are no longer available as of 2021-02-10. Values for this province (and thus Canada) should be discarded after this date. Saskatchewan has also stopped reporting these values.

The update date and time for our dataset is given in [`update_time.txt`](https://github.com/ccodwg/Covid19Canada/blob/master/update_time.txt).

The following time series data are available at the health region level (as well as at the level of province and Canada-wide):

* cases (confirmed and probable COVID-19 cases)
* mortality (confirmed and probable COVID-19 deaths)

The following time series data are available at the province level (as well as Canada-wide):

* recovered (COVID-19 cases considered resolved that did not end in death)
* testing (definitions vary, see our [technical report](https://opencovid.ca/work/technical-report/)
* active cases (we use the formula *active cases = confirmed cases - recovered - deaths*, which explains the disrepecies between our active case numbers and those reported from official sources)
* vaccine distribution (total doses distributed)
* vaccine administration (total doses administered)
* vaccine completion (second doses administered)
* vaccine additional doses (third doses administered)

Note that definitions for each of these values differ between provinces. See our [technical report](https://opencovid.ca/work/technical-report/) for more details.

Several other important files are also available in the `other` folder:

* Correspondence between health region names used in our dataset and HRUID values given in Esri Canada's [health region map](https://resources-covid19canada.hub.arcgis.com/datasets/regionalhealthboundaries-1), with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401): `other/hr_map.csv`
* Correspondece between province names used in our dataset and full province names and two-letter abbreviations, with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401): `other/prov_map.csv`
* Correspondece between province names used in our dataset and full province names and two-letter abbreviations, with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401) and new Saskatchewan health regions: `other/prov_map_sk_new.csv`
    * The new Saskatchewan health regions (13 health regions versus 6 in the original data) use *unofficial estimates* of 2020 population values provided by Statistics Canada and may differ from official data released by Statistics Canada at a later date

We also have a case and mortality datasets which combine our dataset with the official SK provincial dataset using the new 13 reporting zones (our dataset continues to use the old 6 reporting zones) in the `hr_sk_new` folder. Data for SK are only available from August 4, 2020 and onward in this dataset.

Our individual-level case and mortality datasets are retired as of June 1, 2021 (see `retired_datasets`).

## Recommended citation

Below is the current citation for the dataset:

* Berry, I., O’Neill, M., Sturrock, S. L., Wright, J. E., Acharya, K., Brankston, G., Harish, V., Kornas, K., Maani, N., Naganathan, T., Obress, L., Rossi, T., Simmons, A. E., Van Camp, M., Xie, X., Tuite, A. R., Greer, A. L., Fisman, D. N., & Soucy, J.-P. R. (2021). A sub-national real-time epidemiological and vaccination database for the COVID-19 pandemic in Canada. Scientific Data, 8(1). doi: https://doi.org/10.1038/s41597-021-00955-2

Below is the previous citation for the dataset:

* Berry, I., Soucy, J.-P. R., Tuite, A., & Fisman, D. (2020). Open access epidemiologic data and an interactive dashboard to monitor the COVID-19 outbreak in Canada. Canadian Medical Association Journal, 192(15), E420. doi: https://doi.org/10.1503/cmaj.75262

## Methodology & data notes

Detailed information about our [data collection methodology](https://opencovid.ca/work/dataset/) and [sources](https://opencovid.ca/work/data-sources/), answers to [frequently asked data questions](https://opencovid.ca/work/data-faq/) and the [technical report](https://opencovid.ca/work/technical-report/) for our dataset are available on our [website](https://opencovid.ca/). Note that some of this information is out-of-date and will eventually be updated. Information on automated data collection is available in the [`Covid19CanadaETL`](https://github.com/ccodwg/Covid19CanadaETL) GitHub repository.

The scripts used to prepare, update and validate the datasets in this repository are available in the [`scripts`](https://github.com/ccodwg/Covid19Canada/tree/master/scripts) folder.

## Acknowledgements

We would like to thank all individuals and organizations across Canada who have worked tirelessly to provide data to the public during this pandemic.

Additionally, we thank the following organizations/individuals for their support:

[Public Health Agency of Canada](https://www.canada.ca/en/public-health.html) / Joe Murray ([JMA Consulting](https://jmaconsulting.biz/home))

## Contact us

You can learn more about the COVID-19 Canada Open Data Working Group at [our website](https://opencovid.ca/) and reach out to us via our [contact page](https://opencovid.ca/contact-us/).
