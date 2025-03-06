library(dplyr)
library(RSQLite)
library(stringr)


sqlite <- dbDriver("SQLite")
conn <- dbConnect(RSQLite::SQLite(), dbname = "mimic.db", synchronous = NULL)

# Read data
entity <- dbReadTable(conn, "entities")
note <- dbReadTable(conn, "notes")
entity_merged <- merge(entity, note, by = "row_id")


# Extract admission and discharge dates

# The original text
text <- entity_merged$text_orig
# Extract the admission date
admission_date <- str_extract(text, "(?<=Admission Date:  \\[\\*\\*)\\d{4}-\\d{1,2}-\\d{1,2}(?=\\*\\*\\])")
# Extract the discharge date
discharge_date <- str_extract(text, "(?<=Discharge Date:   \\[\\*\\*)\\d{4}-\\d{1,2}-\\d{1,2}(?=\\*\\*\\])")
# Extract admission year-month
admission_year_month <- str_extract(admission_date, "\\d{4}-\\d{1,2}")
discharge_year_month <- str_extract(discharge_date, "\\d{4}-\\d{1,2}")
# Total stay length in days
stay_day <- as.numeric(difftime(discharge_date, admission_date, units="days"))
entity_merged <- cbind(entity_merged, admission_date,discharge_date, stay_day,admission_year_month,discharge_year_month)

# Summary statistics

# Global level (total count)
# Number of unique admission year-month
n_admission_year_month = length(unique(entity_merged$admission_year_month))
cat("Number of unique admission year-month:", n_admission_year_month, "\n")

# Number of unique discharge year-month
n_discharge_year_month = length(unique(entity_merged$discharge_year_month))
cat("Number of unique discharge year-month:", n_discharge_year_month, "\n")


# Subject level (total count)
# Number of entity for each subject
Total_count_for_each_subject = entity_merged%>%
  group_by(subject_id)%>%
  summarize(number_of_entity = n_distinct(entity_label),
            number_of_notes = n_distinct(text_orig),
            number_of_visit = n_distinct(hadm_id))

# Density histogram of number of entity for each subject
png(file="Number_of_entity_for_each_subject_histogram.png",width=600, height=350)
hist(Total_count_for_each_subject$number_of_entity, freq = FALSE, main = "Density histogram of number of entity for each subject", xlab = "Number of entity")
dev.off()
png(file="Number_of_notes_for_each_subject_histogram.png",width=600, height=350)
hist(Total_count_for_each_subject$number_of_notes, freq = FALSE, main = "Density histogram of number of notes for each subject", xlab = "Number of notes")
dev.off()
png(file="Number_of_visits_for_each_subject_histogram.png",width=600, height=350)
hist(Total_count_for_each_subject$number_of_visit, freq = FALSE, main = "Density histogram of number of visits for each subject", xlab = "Number of visits")
dev.off()

# Summary statistics
summary(Total_count_for_each_subject$number_of_entity)
summary(Total_count_for_each_subject$number_of_notes)
summary(Total_count_for_each_subject$number_of_visit)

# Output total count by subject table
write.csv(Total_count_for_each_subject, file = "Total_count_for_each_subject.csv", row.names = FALSE)


# Subject level (count of each admission year-month)
monthly_counts_for_each_subject = entity_merged%>%
  group_by(subject_id,admission_year_month)%>%
  summarize(n_entity_by_month = n_distinct(entity_label),
            n_notes_by_month = n_distinct(text_orig),
            n_visits_by_month = n_distinct(hadm_id))
write.csv(monthly_counts_for_each_subject, file = "monthly_counts_for_each_subject.csv", row.names = FALSE)



# Subject level (average monthly count)
average_monthly_counts_for_each_subject = monthly_counts_for_each_subject%>%
  group_by(subject_id)%>%
  summarize(avg_monthly_entity = mean(n_entity_by_month), # Number of entity for each subject
            avg_monthly_notes = mean(n_notes_by_month), # Number of notes for each subject
            avg_monthly_visits = mean(n_visits_by_month)) # Number of visits for each subject
# Density histogram 
png(file="Average_monthly_number_of_entity_for_each_subject_histogram.png",width=600, height=350)
hist(average_monthly_counts_for_each_subject$avg_monthly_entity, freq = FALSE, main = "Density histogram of average monthly number of entities for each subject", xlab = "Average monthly number of entities")
dev.off()
png(file="Average_monthly_number_of_notes_for_each_subject_histogram.png",width=600, height=350)
hist(average_monthly_counts_for_each_subject$avg_monthly_notes, freq = FALSE, main = "Density histogram of average monthly number of notes for each subject", xlab = "Average monthly number of notes")
dev.off()
png(file="Average_monthly_number_of_visits_for_each_subject_histogram.png",width=600, height=350)
hist(average_monthly_counts_for_each_subject$avg_monthly_visits, freq = FALSE, main = "Density histogram of average monthly number of visits for each subject", xlab = "Average monthly number of visits")
dev.off()

# Summary statistics
summary(average_monthly_counts_for_each_subject$avg_monthly_entity)
summary(average_monthly_counts_for_each_subject$avg_monthly_notes)
summary(average_monthly_counts_for_each_subject$avg_monthly_visits)

# Output subject level average monthly count table
write.csv(average_monthly_counts_for_each_subject, file = "average_monthly_counts_for_each_subject.csv", row.names = FALSE)

