#-----------------------Set up----------------------------#
library(dplyr)
library(readr)

#-----------------------Read data----------------------------#
note <- read_csv("admissions.csv")
code <- read_csv("diagnoses_icd.csv")

# Extract the admission date
note$admission_date <- as.Date(note$admittime)
# Extract discharge dates
note$discharge_date <-as.Date(note$dischtime)
# Extract admission year-month
note$admission_year_month <- format(as.Date(note$dischtime), "%Y-%m")
note$discharge_year_month <- format(as.Date(note$dischtime), "%Y-%m")
# Total stay length in days
note$stay_day <- as.numeric(difftime(note$discharge_date, note$admission_date, units="days"))

# Merging data
data_merged <- merge(note, code, by = c("subject_id", "hadm_id"))

#--------------------Prepare data to make embedding------------------#

data_merged <- data_merged%>%select(subject_id,discharge_year_month,icd_code)
  
save(data_merged, file = "ICD_Data_for_generating_embedding.Rdata")