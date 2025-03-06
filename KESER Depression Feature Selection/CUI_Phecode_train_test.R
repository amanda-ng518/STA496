library(dplyr)
library(RSQLite)
library(stringr)
library(nlpembeds)
library(readr)

sqlite <- dbDriver("SQLite")
conn <- dbConnect(RSQLite::SQLite(), dbname = "mimic.db", synchronous = NULL)

#------------------------------CUI------------------------------------#
# Read data
entity <- dbReadTable(conn, "entities")
note <- dbReadTable(conn, "notes")
entity_merged <- merge(entity, note, by = "row_id")

# Extract admission and discharge dates
# The original text
text <- entity_merged$text_orig
# Extract the discharge date
discharge_date <- str_extract(text, "(?<=Discharge Date:   \\[\\*\\*)\\d{4}-\\d{1,2}-\\d{1,2}(?=\\*\\*\\])")

# Extract admission year-month
discharge_year_month <- str_extract(discharge_date, "\\d{4}-\\d{1,2}")
entity_merged <- cbind(entity_merged, discharge_year_month)

entity_merged = entity_merged%>%select(subject_id, discharge_year_month, entity_label)

# Train & Test
train_indices1 <- sample(seq_len(nrow(entity_merged)), size = 0.7 * nrow(entity_merged))
train_data1 <- entity_merged[train_indices1, ]
test_data1 <- entity_merged[-train_indices1, ]

test_table1 = test_data1%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
test_table1 <- na.omit(test_table1)

train_table1 = train_data1%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
train_table1 <- na.omit(train_table1)

#-----------------------Phecode-----------------------------#
# Read data
load("Phecode_Data_for_generating_embedding.Rdata") # I named the object as cleaned_data in the Phecode_transformation R script
data_merged = cleaned_data
data_merged = data_merged%>%select(subject_id, discharge_year_month, phecode)

# Train & Test
train_indices2 <- sample(seq_len(nrow(data_merged)), size = 0.7 * nrow(data_merged))
train_data2 <- data_merged[train_indices2, ]
test_data2 <- data_merged[-train_indices2, ]

test_table2 = test_data2%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
test_table2 <- na.omit(test_table2)

train_table2 = train_data2%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
train_table2 <- na.omit(train_table2)

#---------------------Co-occurence matrix--------------------------#
# Test CUI
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", test_table1, overwrite= TRUE)

# Optional
df_uniq_codes = unique(test_table1["Parent_Code"])
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
test_spm_cooc1 = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# Train CUI
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", train_table1, overwrite= TRUE)

# Optional
df_uniq_codes = unique(train_table1["Parent_Code"])
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
train_spm_cooc1 = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# Test Phecode
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", test_table2, overwrite= TRUE)

# Optional
df_uniq_codes = unique(test_table2["Parent_Code"])
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
test_spm_cooc2 = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# Train Phecode
# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", train_table2, overwrite= TRUE)

# Optional
df_uniq_codes = unique(train_table2["Parent_Code"])
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
train_spm_cooc2 = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

#---------------------PMI-SVD--------------------------#
# PMI matrix
test_m_pmi1 = get_pmi(test_spm_cooc1)
train_m_pmi1 = get_pmi(train_spm_cooc1)
test_m_pmi2 = get_pmi(test_spm_cooc2)
train_m_pmi2 = get_pmi(train_spm_cooc2)

# SVD embeddings
test_m_embeds_1500_1 = get_svd(test_m_pmi1, svd_rank = 1500) 
train_m_embeds_1500_1 = get_svd(train_m_pmi1, svd_rank = 1500) 
test_m_embeds_100_2 = get_svd(test_m_pmi2, svd_rank = 100) 
train_m_embeds_100_2 = get_svd(train_m_pmi2, svd_rank = 100) 

# Output CUI/Phecode embedding matrix
save(test_m_embeds_1500_1,file = "test_CUI_1500dim.Rdata")
save(train_m_embeds_1500_1,file = "train_CUI_1500dim.Rdata")
save(test_m_embeds_100_2,file = "test_Phecode_100dim.Rdata")
save(train_m_embeds_100_2,file = "train_Phecode_100dim.Rdata")
