# Epidemiological Data from the COVID-19 Outbreak in Canada

The [**COVID-19 Canada Open Data Working Group**](https://opencovid.ca/) collects daily time series data on COVID-19 cases, deaths, recoveries, testing and vaccinations at the health region and province levels. Data are collected exclusively from publicly available sources including government reports and news media. Updates are made nightly between 21:30 and 22:00 ET. Our data collection is mostly automated; see [Covid19CanadaETL](https://github.com/ccodwg/Covid19CanadaETL)  and related projects for details.

## Accessing the data

Our datasets are available in three different formats:

* CSV format from this GitHub repository (to download all the latest data, select the green "Code" button and click "Download ZIP")
* JSON format from our [API](https://opencovid.ca/api/)
* [Google Drive](https://drive.google.com/drive/folders/1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP)

Note that retired datasets (`retired_datasets`) are only available on GitHub.

## Recent dataset changes

* As of 2021-09-07, active cases for ON should be correctly reported. Note that this has resulted in a major discontinuity for recovered and active cases for ON on 2021-09-07. Our case and mortality data from ON have been sourced from individual PHU websites (rather than the provincial MOH dataset) since April 1, 2020. However, the "recovered" number continued to be sourced from the MOH. As the PHU and MOH datasets diverged (several thousand cases were never confirmed and thus not included in the MOH datasets), this resulted in an inflated active case count for the province (daily differences were more or less reliable). On 2021-09-07, we transitioned to using recovered numbers directly from the PHUs; thus, active cases should now be correctly reported for ON. We regret the inconvenience.

## Data dashboard

We provide a public COVID-19 data dashboard at the following URL: [https://art-bd.shinyapps.io/covid19canada/](https://art-bd.shinyapps.io/covid19canada/).

## Citation

Below is the current citation for the dataset:

* Berry, I., O’Neill, M., Sturrock, S. L., Wright, J. E., Acharya, K., Brankston, G., Harish, V., Kornas, K., Maani, N., Naganathan, T., Obress, L., Rossi, T., Simmons, A. E., Van Camp, M., Xie, X., Tuite, A. R., Greer, A. L., Fisman, D. N., & Soucy, J.-P. R. (2021). A sub-national real-time epidemiological and vaccination database for the COVID-19 pandemic in Canada. Scientific Data, 8(1). doi: https://doi.org/10.1038/s41597-021-00955-2

Below is the previous citation for the dataset:

* Berry, I., Soucy, J.-P. R., Tuite, A., & Fisman, D. (2020). Open access epidemiologic data and an interactive dashboard to monitor the COVID-19 outbreak in Canada. Canadian Medical Association Journal, 192(15), E420. doi: https://doi.org/10.1503/cmaj.75262

## Datasets

The update date and time for our dataset is given in `update_time.txt`.

The following time series data are available at the health region level (as well as at the level of province and Canada-wide):

* cases (confirmed and probable COVID-19 cases)
* mortality (confirmed and probable COVID-19 deaths)

The following time series data are available at the province level (as well as Canada-wide):

* recovered (COVID-19 cases considered resolved that did not end in death)
* testing (definitions vary, see our [technical report](https://opencovid.ca/work/technical-report/)
* active cases (we use the formula *active cases = confirmed cases - recovered - deaths*, which explains the disrepecies between our active case numbers and those reported from official sources)
* vaccine distribution (total doses distributed)
* vaccine administration (total doses administered)
* vaccine completion (second doses distributed)

Note that definitions for each of these values differ between provinces. See our [technical report](https://opencovid.ca/work/technical-report/) for more details.

Several other important files are also available in the `other` folder:

* Correspondence between health region names used in our dataset and HRUID values given in Esri Canada's [health region map](https://resources-covid19canada.hub.arcgis.com/datasets/regionalhealthboundaries-1), with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401): `other/hr_map.csv`
* Correspondece between province names used in our dataset and full province names and two-letter abbreviations, with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401): `other/prov_map.csv`
* Correspondece between province names used in our dataset and full province names and two-letter abbreviations, with [2019 population values](https://www150.statcan.gc.ca/t1/tbl1/en/cv.action?pid=1710013401) and new Saskatchewan health regions: `other/prov_map_sk_new.csv`
    * The new Saskatchewan health regions (13 health regions versus 6 in the original data) use *unofficial estimates* of 2020 population values provided by Statistics Canada and may differ from official data released by Statistics Canada at a later date

We also have a case and mortality datasets which combine our dataset with the official SK provincial dataset using the new 13 reporting zones (our dataset continues to use the old 6 reporting zones) in the `hr_sk_new` folder. Data for SK are only available from August 4, 2020 and onward in this dataset.

Our individual-level case and mortality datasets are retired as of June 1, 2021 (see `retired_datasets`).

## Methodology & data notes

Detailed information about our [data collection methodology](https://opencovid.ca/work/dataset/) and [sources](https://opencovid.ca/work/data-sources/), answers to [frequently asked data questions](https://opencovid.ca/work/data-faq/) and the [technical report](https://opencovid.ca/work/technical-report/) for our dataset are available on our [website](https://opencovid.ca/). Note that some of this information is in the process of being updated and may currently be out-of-date.

The scripts used to prepare, update and validate the datasets in this repository are available in the `scripts` folder.

## Acknowledgements

We would like to thank all individuals and organizations across Canada who have worked tirelessly to provide data to the public during this pandemic.

Additionally, we thank the following organizations/individuals for their support:

[Public Health Agency of Canada](https://www.canada.ca/en/public-health.html) / Joe Murray ([JMA Consulting](https://jmaconsulting.biz/home))

## Contact us

You can learn more about the COVID-19 Canada Open Data Working Group at [our website](https://opencovid.ca/) and reach out to us via our [contact page](https://opencovid.ca/contact-us/).
