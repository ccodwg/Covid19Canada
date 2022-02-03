# load modules
from tableauscraper import TableauScraper as TS

# Southwestern (SWH)
url_swh = "https://public.tableau.com/views/COVID-19Dashboard-March2020/COVID-19Dashboard?:embed=y&amp;:showVizHome=no&amp;:host_url=https%3A%2F%2Fpublic.tableau.com%2F&amp;:embed_code_version=3&amp;:tabs=no&amp;:toolbar=yes&amp;:animate_transition=yes&amp;:display_static_image=no&amp;:display_spinner=no&amp;:display_overlay=yes&amp;:display_count=yes&amp;:language=en&amp;:loadOrderID=0"
ts_swh = TS()
ts_swh.loads(url_swh)
workbook_swh = ts_swh.getWorkbook()
# workbook_swh.getWorksheetNames()
ws_swh = workbook_swh.getWorksheet("Summary (2)")
def swh_cases():
    return ws_swh.data.iloc[5, 3]
def swh_mortality():
    return ws_swh.data.iloc[0, 3]
def swh_recovered():
    return ws_swh.data.iloc[1, 3]

# Waterloo (WAT)
url_wat = "https://public.tableau.com/views/WaterlooRegionCOVID-19Summary/COVID-19?:showVizHome=no&amp;:embed=true&amp;:linktarget= blank;:toolbar=no&amp;:display_count=yes&amp;:tabs=no&amp;wmode=transparent&amp;&amp;wmode=transparent:render=false&amp;&amp;wmode=transparent"
ts_wat = TS()
ts_wat.loads(url_wat)
workbook_wat = ts_wat.getWorkbook()
# workbook_wat.getWorksheetNames()
def wat_cases():
    return workbook_wat.getWorksheet("BANS0").data.iloc[0, 3]
def wat_mortality():
    return workbook_wat.getWorksheet("CaseStatus_byDate").data.query("`Case Status (LOD)-alias` == 'Deceased'")[["SUM(Cases)-value"]].iloc[-1, 0]
def wat_recovered():
    return workbook_wat.getWorksheet("BANS1").data.iloc[0, 3]
