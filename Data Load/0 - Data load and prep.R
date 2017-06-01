# Test load 10 years of IPEDS completions data
# 2017 May 31
# Matej

libs = c('bgtRpackage','data.table','WriteXLS','readxl','readr', 'tidyr')
sapply(libs, library, character.only = T)


# Data Load ---------------------------------------------------------------------------
doc_url = 'https://collegescorecard.ed.gov/data/documentation/'