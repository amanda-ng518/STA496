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

#-------------------Summary statistics-----------------------#
  
#-------------------Global level (total count)---------------------#
# Number of subjects
n_patients = length(unique(data_merged$subject_id))
cat("Number of patients:", n_patients, "\n")

# Number of visits
n_visits = length(unique(data_merged$hadm_id))
cat("Number of visits:", n_visits, "\n")

# Number of unqiue ICD codes
n_codes = length(unique(data_merged$icd_code))
cat("Number of unqiue codes:", n_codes, "\n")

# Number of unique admission dates
n_admission = length(unique(data_merged$admission_date))
cat("Number of unique admission dates:", n_admission, "\n")

# Number of unique discharge dates
n_discharge = length(unique(data_merged$discharge_date))
cat("Number of unique discharge dates:", n_discharge, "\n")

# Number of unique stay days
n_stay = length(unique(data_merged$stay_day))
cat("Number of unique stay days:", n_stay, "\n")

# Number of unique admission year-month
n_admission_year_month = length(unique(data_merged$admission_year_month))
cat("Number of unique admission year-month:", n_admission_year_month, "\n")

# Number of unique discharge year-month
n_discharge_year_month = length(unique(data_merged$discharge_year_month))
cat("Number of unique discharge year-month:", n_discharge_year_month, "\n")

#-----------Subject level (total count)------------------#
  
# Number of entity for each subject
Total_count_for_each_subject = data_merged%>%
  group_by(subject_id)%>%
  summarize(number_of_codes = n_distinct(icd_code),
            number_of_visit = n_distinct(hadm_id))

# Density histogram of number of entity for each subject
png(file="Number_of_entity_for_each_subject_histogram.png",width=600, height=350)
hist(Total_count_for_each_subject$number_of_codes, freq = FALSE, main = "Density histogram of number of codes for each subject", xlab = "Number of codes")
dev.off()
png(file="Number_of_visits_for_each_subject_histogram.png",width=600, height=350)
hist(Total_count_for_each_subject$number_of_visit, freq = FALSE, main = "Density histogram of number of visits for each subject", xlab = "Number of visits")
dev.off()

# Summary statistics
summary(Total_count_for_each_subject$number_of_codes)
summary(Total_count_for_each_subject$number_of_visit)

# Output total count by subject table
save(Total_count_for_each_subject, file = "Total_count_for_each_subject.Rdata")

#--------Subject level (count of each discharge year-month)----------------#

monthly_counts_for_each_subject = data_merged%>%
  group_by(subject_id,discharge_year_month)%>%
  summarize(n_codes_by_month = n_distinct(icd_code),
            n_visits_by_month = n_distinct(hadm_id))
save(monthly_counts_for_each_subject, file = "monthly_counts_for_each_subject.Rdata")

#------------------Subject level (average monthly count)---------------------#

average_monthly_counts_for_each_subject = monthly_counts_for_each_subject%>%
  group_by(subject_id)%>%
  summarize(avg_monthly_codes = mean(n_codes_by_month), # Number of codes for each subject
            avg_monthly_visits = mean(n_visits_by_month)) # Number of visits for each subject
# Density histogram 
png(file="Average_monthly_number_of_codes_for_each_subject_histogram.png",width=600, height=350)
hist(average_monthly_counts_for_each_subject$avg_monthly_codes, freq = FALSE, main = "Density histogram of average monthly number of codes for each subject", xlab = "Average monthly number of codes")
dev.off()
png(file="Average_monthly_number_of_visits_for_each_subject_histogram.png",width=600, height=350)
hist(average_monthly_counts_for_each_subject$avg_monthly_visits, freq = FALSE, main = "Density histogram of average monthly number of visits for each subject", xlab = "Average monthly number of visits")
dev.off()

# Summary statistics
summary(average_monthly_counts_for_each_subject$avg_monthly_codes)
summary(average_monthly_counts_for_each_subject$avg_monthly_visits)

# Output subject level average monthly count table
save(average_monthly_counts_for_each_subject, file = "average_monthly_counts_for_each_subject.Rdata")

#---------------------Visit level: Stay days--------------------------#

stay_days_data <- data_merged %>%
  group_by(hadm_id) %>%
  summarize(visit_stay_days = first(stay_day)) 
# Density histogram of stay days for each visit
png(file="stay_days_histogram.png",width=600, height=350)
hist(stay_days_data$visit_stay_days, freq = FALSE, main = "Density histogram of stay days", xlab = "Stay days")
dev.off()
# Summary statistics
summary(stay_days_data$visit_stay_days)
# Output table
save(stay_days_data, file = "Stay_days_for_each_visit.Rdata")
