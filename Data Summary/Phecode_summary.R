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

#-------------------Summary statistics-----------------------#
#-----------Subject level (total count)--------------------#

# Number of entity for each subject
Total_count_for_each_subject = data_merged%>%
  group_by(subject_id)%>%
  summarize(number_of_codes = n_distinct(phecode),
            number_of_visit = n_distinct(hadm_id))

# Density histogram of number of Phecodes for each subject
png(file="Number_of_Phecodes_for_each_subject_histogram.png",width=600, height=350)
hist(Total_count_for_each_subject$number_of_codes, freq = FALSE, main = "Density histogram of number of codes for each subject", xlab = "Number of codes")
dev.off()

# Summary statistics
summary(Total_count_for_each_subject$number_of_codes)

#--------Subject level (count of each discharge year-month)----------------#

monthly_counts_for_each_subject = data_merged%>%
  group_by(subject_id,discharge_year_month)%>%
  summarize(n_codes_by_month = n_distinct(phecode),
            n_visits_by_month = n_distinct(hadm_id))
save(monthly_counts_for_each_subject, file = "monthly_counts_for_each_subject.Rdata")

#------------------Subject level (average monthly count)---------------------#

average_monthly_counts_for_each_subject = monthly_counts_for_each_subject%>%
  group_by(subject_id)%>%
  summarize(avg_monthly_codes = mean(n_codes_by_month), # Number of codes for each subject
            avg_monthly_visits = mean(n_visits_by_month)) # Number of visits for each subject
# Density histogram 
png(file="Average_monthly_number_of_Phecodes_for_each_subject_histogram.png",width=600, height=350)
hist(average_monthly_counts_for_each_subject$avg_monthly_codes, freq = FALSE, main = "Density histogram of average monthly number of codes for each subject", xlab = "Average monthly number of codes")
dev.off()

# Summary statistics
summary(average_monthly_counts_for_each_subject$avg_monthly_codes)

# Output subject level average monthly count table
save(average_monthly_counts_for_each_subject, file = "average_monthly_counts_for_each_subject.Rdata")
