# Test load 10 years of IPEDS completions data
# 2017 May 31
# Matej

libs = c('bgtRpackage','data.table','RODBC', 'readxl', 'leaflet', 'geojsonio')
sapply(libs, library, character.only = T, verbose = F)

options(scipen = 50, digits = 3, datatable.auto.index = T, na.rm = T, stringsAsFactors = F)
`%notin%` <- function(x, y) !(x %in% y)

clear_slate()

# Data Load ---------------------------------------------------------------------------
# doc_url https://collegescorecard.ed.gov/data/documentation/
# useful_doc http://data.library.virginia.edu/using-data-gov-apis-in-r/
# access database source https://nces.ed.gov/ipeds/Section/accessdatabase/
# how to get access data - https://www.r-bloggers.com/getting-access-data-into-r/

dir_in = paste0(work_dir(), 'Downloads/IPEDS_2015-16_Provisional/')
tables_doc = paste0(dir_in, list.files(dir_in, pattern = '.xlsx'))

#Load documentation
excel_sheets(tables_doc)
d_tables = read_excel(tables_doc, sheet = 2) %>% as.data.table()
d_vartable = read_excel(tables_doc, sheet = 3) %>% as.data.table()
d_varsets = read_excel(tables_doc, sheet = 4) %>% as.data.table()

# Sample database load ----------------------------------------------------------------
# One has to tell Windows where to find the Access database - makes this not very portable
channel <- odbcConnect("IPEDS_2015_16")
Tables <- sqlTables(channel)
d_inst = sqlFetch(channel, "HD2015") %>% as.data.table()
d_comp = sqlFetch(channel, "C2015_A") %>% as.data.table()

# Summarize data by CIP2 & State for 2015
look_awlevel = d_varsets[TableName == 'C2015_A' & varName == 'AWLEVEL',.(AWLEVEL = as.numeric(Codevalue), Award_Name = valueLabel)]
summ_awlevel = d_comp[,.(Total_Completions = sum(CTOTALT,na.rm = T)), by = .(AWLEVEL)]
summ_awlevel = merge(look_awlevel, summ_awlevel, by = 'AWLEVEL')


summ_inst = d_comp[,.(Total_Completions = sum(CTOTALT,na.rm = T)), by = .(UNITID, AWLEVEL)]
summ_inst = summ_inst[AWLEVEL %notin% c(12,15)]
summ_inst[, BAPlus := 1*(AWLEVEL %in% c(5,6,7,8,14,17,18,19))]
summ_inst = summ_inst[,.(Total_Completions = sum(Total_Completions)), by = .(UNITID, BAPlus)]
summ_inst = merge(d_inst[,.(UNITID, INSTNM, CITY, STABBR, ZIP, COUNTYNM, COUNTYCD)],
                  summ_inst, by = 'UNITID', all.y = T)

summ_state = summ_inst[,.(Total_Completions = sum(Total_Completions,na.rm = T)), by = .(STABBR, BAPlus)]


# Leaflet ---------------------------------------------------------------------------------
data(states)
system.file("examples", "json/us-states.geojson", package = "geojsonio")
states <- geojsonio::geojson_read(states, lat = 'lat', long = 'long', what = 'sp')

bins <- c(0, 10, 20, 50, 100, 200, 500, 1000, Inf)
pal <- colorBin("YlOrRd", domain = states$density, bins = bins)

m <- leaflet(states) %>%
    setView(-96, 37.8, 4) %>%
    addProviderTiles(providers$CartoDB.PositronNoLabels)

m %>% addPolygons(
    fillColor = ~pal(density),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7)

