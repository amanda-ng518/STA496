library(dplyr)
library(RSQLite)
library(stringr)
library(nlpembeds)
library(readr)

#library(remotes)
#remotes::install_github("jwood000/RcppAlgos@v2.4.0")
#remotes::install_git("https://gitlab.com/thomaschln/nlpembeds.git")

sqlite <- dbDriver("SQLite")
conn <- dbConnect(RSQLite::SQLite(), dbname = "mimic.db", synchronous = NULL)

#------------------------------CUI------------------------------------#
# Read data
entity <- dbReadTable(conn, "entities")
note <- dbReadTable(conn, "notes")
entity_merged <- merge(entity, note, by = "row_id")
CUI_demographics <- read_csv("EHR_demographic.csv")

# Extract admission and discharge dates
# The original text
text <- entity_merged$text_orig
# Extract the discharge date
discharge_date <- str_extract(text, "(?<=Discharge Date:   \\[\\*\\*)\\d{4}-\\d{1,2}-\\d{1,2}(?=\\*\\*\\])")

# Extract admission year-month
discharge_year_month <- str_extract(discharge_date, "\\d{4}-\\d{1,2}")
entity_merged <- cbind(entity_merged, discharge_year_month)

# Add demographic variables
entity_merged <- merge(entity_merged, CUI_demographics, by.x = "hadm_id", by.y = "HADM_ID", all.y = FALSE) 

# Prepare data by demographic groups
# white
white_entity = entity_merged%>%filter(ETHNICITY == "WHITE")%>%select(subject_id, discharge_year_month, entity_label)
white_table1 = white_entity%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
white_table1 <- na.omit(white_table1)
# non-white
nwhite_entity = entity_merged%>%filter(ETHNICITY != "WHITE")%>%select(subject_id, discharge_year_month, entity_label)
nwhite_table1 = nwhite_entity%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
nwhite_table1 <- na.omit(nwhite_table1)
# private insurance
private_entity = entity_merged%>%filter(INSURANCE == "Private")%>%select(subject_id, discharge_year_month, entity_label)
private_table1 = private_entity%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
private_table1 <- na.omit(private_table1)
# non-private insurance
nprivate_entity = entity_merged%>%filter(INSURANCE != "Private")%>%select(subject_id, discharge_year_month, entity_label)
nprivate_table1 = nprivate_entity%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
nprivate_table1 <- na.omit(nprivate_table1)

#-----------------------Phecode-----------------------------#
# Read data
load("Phecode_Data_for_generating_embedding.Rdata") # I named the object as cleaned_data in the Phecode_transformation R script
data_merged = cleaned_data
phecode_demographics = read_csv("admissions.csv")%>%select(subject_id, insurance, race)%>%unique()
data_merged <- merge(data_merged, phecode_demographics, by = "subject_id", all.x = TRUE, all.y = FALSE)

# Prepare data by demographic groups
# white
white_data = data_merged%>%filter(race == "WHITE")%>%select(subject_id, discharge_year_month, phecode)
white_table2 = white_data%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
white_table2 <- na.omit(white_table2)
# non-white
nwhite_data = data_merged%>%filter(race != "WHITE")%>%select(subject_id, discharge_year_month, phecode)
nwhite_table2 = nwhite_data%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
nwhite_table2 <- na.omit(nwhite_table2)
# private insurance
private_data = data_merged%>%filter(insurance == "Private")%>%select(subject_id, discharge_year_month, phecode)
private_table2 = private_data%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
private_table2 <- na.omit(private_table2)
# non-private insurance
nprivate_data = data_merged%>%filter(insurance != "Private")%>%select(subject_id, discharge_year_month, phecode)
nprivate_table2 = nprivate_data%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
nprivate_table2 <- na.omit(nprivate_table2)

#---------------------Co-occurence matrix--------------------------#
# Combine two preprocess tables
white_data_for_pmisvd <- rbind(white_table1, white_table2)
nwhite_data_for_pmisvd <- rbind(nwhite_table1, nwhite_table2)
private_data_for_pmisvd <- rbind(private_table1, private_table2)
nprivate_data_for_pmisvd <- rbind(nprivate_table1, nprivate_table2)

# white
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", white_data_for_pmisvd, overwrite= TRUE)

# Optional
df_uniq_codes = unique(white_data_for_pmisvd["Parent_Code"])
dbWriteTable(test_db, "df_uniq_codes", df_uniq_codes, overwrite= TRUE)
dbExecute(test_db, "CREATE INDEX patient_idx ON df_monthly (Patient)")

dbDisconnect(test_db)

# Coocurrence matrix
output_db_path = tempfile()
sql_cooc(dbpath = test_db_path,
         outpath = output_db_path,
         select_cuis = "all",
         n_batch = 300,
         n_cores = 6)

test_db = dbConnect(RSQLite::SQLite(), output_db_path)
white_spm_cooc = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# non-white
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", nwhite_data_for_pmisvd, overwrite= TRUE)

# Optional
df_uniq_codes = unique(nwhite_data_for_pmisvd["Parent_Code"])
dbWriteTable(test_db, "df_uniq_codes", df_uniq_codes, overwrite= TRUE)
dbExecute(test_db, "CREATE INDEX patient_idx ON df_monthly (Patient)")

dbDisconnect(test_db)

# Coocurrence matrix
output_db_path = tempfile()
sql_cooc(dbpath = test_db_path,
         outpath = output_db_path,
         select_cuis = "all",
         n_batch = 300,
         n_cores = 6)

test_db = dbConnect(RSQLite::SQLite(), output_db_path)
nwhite_spm_cooc = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# private
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", private_data_for_pmisvd, overwrite= TRUE)

# Optional
df_uniq_codes = unique(private_data_for_pmisvd["Parent_Code"])
dbWriteTable(test_db, "df_uniq_codes", df_uniq_codes, overwrite= TRUE)
dbExecute(test_db, "CREATE INDEX patient_idx ON df_monthly (Patient)")

dbDisconnect(test_db)

# Coocurrence matrix
output_db_path = tempfile()
sql_cooc(dbpath = test_db_path,
         outpath = output_db_path,
         select_cuis = "all",
         n_batch = 300,
         n_cores = 6)

test_db = dbConnect(RSQLite::SQLite(), output_db_path)
private_spm_cooc = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# non-private
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", nprivate_data_for_pmisvd, overwrite= TRUE)

# Optional
df_uniq_codes = unique(nprivate_data_for_pmisvd["Parent_Code"])
dbWriteTable(test_db, "df_uniq_codes", df_uniq_codes, overwrite= TRUE)
dbExecute(test_db, "CREATE INDEX patient_idx ON df_monthly (Patient)")

dbDisconnect(test_db)

# Coocurrence matrix
output_db_path = tempfile()
sql_cooc(dbpath = test_db_path,
         outpath = output_db_path,
         select_cuis = "all",
         n_batch = 300,
         n_cores = 6)

test_db = dbConnect(RSQLite::SQLite(), output_db_path)
nprivate_spm_cooc = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

#---------------------PMI-SVD--------------------------#
# PMI matrix
white_m_pmi = get_pmi(white_spm_cooc)
nwhite_m_pmi = get_pmi(nwhite_spm_cooc)
private_m_pmi = get_pmi(private_spm_cooc)
private_m_pmi = get_pmi(nprivate_spm_cooc)

# SVD embeddings
white_m_embeds_1500 = get_svd(white_m_pmi, svd_rank = 1500) 
white_m_embeds_2000 = get_svd(white_m_pmi, svd_rank = 2000) 
white_m_embeds_2500 = get_svd(white_m_pmi, svd_rank = 2500) 
white_m_embeds_3000 = get_svd(white_m_pmi, svd_rank = 3000) 
nwhite_m_embeds_1500 = get_svd(nwhite_m_pmi, svd_rank = 1500) 
nwhite_m_embeds_2000 = get_svd(nwhite_m_pmi, svd_rank = 2000) 
nwhite_m_embeds_2500 = get_svd(nwhite_m_pmi, svd_rank = 2500) 
nwhite_m_embeds_3000 = get_svd(nwhite_m_pmi, svd_rank = 3000) 
private_m_embeds_1500 = get_svd(private_m_pmi, svd_rank = 1500) 
private_m_embeds_2000 = get_svd(private_m_pmi, svd_rank = 2000) 
private_m_embeds_2500 = get_svd(private_m_pmi, svd_rank = 2500) 
private_m_embeds_3000 = get_svd(private_m_pmi, svd_rank = 3000)
nprivate_m_embeds_1500 = get_svd(private_m_pmi, svd_rank = 1500) 
nprivate_m_embeds_2000 = get_svd(private_m_pmi, svd_rank = 2000) 
nprivate_m_embeds_2500 = get_svd(private_m_pmi, svd_rank = 2500) 
nprivate_m_embeds_3000 = get_svd(private_m_pmi, svd_rank = 3000) 

# Output CUI embedding matrix
save(white_m_embeds_1500,file = "white_CUI+Phecode_1500dim.Rdata")
save(white_m_embeds_2000,file = "white_CUI+Phecode_2000dim.Rdata")
save(white_m_embeds_2500,file = "white_CUI+Phecode_2500dim.Rdata")
save(white_m_embeds_3000,file = "white_CUI+Phecode_3000dim.Rdata")
save(nwhite_m_embeds_1500,file = "nwhite_CUI+Phecode_1500dim.Rdata")
save(nwhite_m_embeds_2000,file = "nwhite_CUI+Phecode_2000dim.Rdata")
save(nwhite_m_embeds_2500,file = "nwhite_CUI+Phecode_2500dim.Rdata")
save(nwhite_m_embeds_3000,file = "nwhite_CUI+Phecode_3000dim.Rdata")
save(private_m_embeds_1500,file = "private_CUI+Phecode_1500dim.Rdata")
save(private_m_embeds_2000,file = "private_CUI+Phecode_2000dim.Rdata")
save(private_m_embeds_2500,file = "private_CUI+Phecode_2500dim.Rdata")
save(private_m_embeds_3000,file = "private_CUI+Phecode_3000dim.Rdata")
save(nprivate_m_embeds_1500,file = "nprivate_CUI+Phecode_1500dim.Rdata")
save(nprivate_m_embeds_2000,file = "nprivate_CUI+Phecode_2000dim.Rdata")
save(nprivate_m_embeds_2500,file = "nprivate_CUI+Phecode_2500dim.Rdata")
save(nprivate_m_embeds_3000,file = "nprivate_CUI+Phecode_3000dim.Rdata")