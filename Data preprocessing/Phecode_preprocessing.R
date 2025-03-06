library(dplyr)
library(readr)
library(PheWAS)
library(icd)

#-----------------------Read data----------------------------#
getwd()
note <- read_csv("admissions.csv")
code <- read_csv("diagnoses_icd.csv")
# Extract discharge dates
note$discharge_date <-as.Date(note$dischtime)
note$discharge_year_month <- format(as.Date(note$dischtime), "%Y-%m")
# Merging data
data_merged <- merge(note, code, by = c("subject_id", "hadm_id"))
data_merged <- data_merged%>%select(subject_id,hadm_id,discharge_year_month,icd_code,icd_version)

# original number of obs = 6364488

#-----------------------ICD information----------------------------#
ICD_ver_def = read_csv("d_icd_diagnoses.csv")

# Join with ICD version information
data_merged <- data_merged %>%
  left_join(ICD_ver_def, by = c("icd_code" = "icd_code", "icd_version"= "icd_version"))%>%
  arrange(icd_version)

data_merged$icd_code = short_to_decimal(data_merged$icd_code)

#-------------------Transform ICD to Phecode----------------------#
data_merged <- data_merged %>%
  mutate(row_id = row_number())

n_icd9 = nrow(data_merged%>% filter(icd_version == 9))
n_icd10 = nrow(data_merged%>% filter(icd_version == 10))

icd_df = data.frame(id = data_merged$row_id, 
                    vocabulary_id= c(rep("ICD9CM", n_icd9),rep("ICD10CM", n_icd10)),
                    code=as.character(data_merged$icd_code))
Phecodes = mapCodesToPhecodes(icd_df, rollup.map = NULL)

# Number of Phecodes mapped = 4799011 (multiple ICDs can be mapped to same Phecode)

# Number of unique Phecodes left = 1709 (= # embeddings)

#-----------------Attach Phecode to data------------------------#

data_merged <- data_merged %>%
  left_join(Phecodes, by = c("row_id" = "id"))

# Number of ICD codes with missing Phecode
# sum(is.na(data_merged$phecode)) 
# 1634568
#--------------------Prepare data to make embedding------------------#

cleaned_data <- data_merged %>%
  filter(!is.na(phecode))%>%
  select(subject_id,discharge_year_month,phecode)

save(cleaned_data, file = "Phecode_Data_for_generating_embedding.Rdata")
