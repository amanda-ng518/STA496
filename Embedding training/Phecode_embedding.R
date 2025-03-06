library(dplyr)
library(RSQLite)
library(stringr)
library(nlpembeds)
#library(remotes)
#remotes::install_github("jwood000/RcppAlgos@v2.4.0")
#remotes::install_git("https://gitlab.com/thomaschln/nlpembeds.git")

# Read data
getwd()
load("Phecode_Data_for_generating_embedding.Rdata") # I named the object as cleaned_data in the Phecode_transformation R script
data_merged = cleaned_data

# Prepare data
# Note: need to figure out a way to define "Month"
data_for_pmisvd = data_merged%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode)%>%
  summarize(Count = n())
data_for_pmisvd <- na.omit(data_for_pmisvd)

# Batching by patients
test_db_path = tempfile()
test_db = dbConnect(RSQLite::SQLite(), test_db_path)
dbWriteTable(test_db, "df_monthly", data_for_pmisvd, overwrite= TRUE)

# Optional
df_uniq_codes = unique(data_for_pmisvd["Parent_Code"])
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
spm_cooc = dbGetQuery(test_db, "select * from df_monthly;")
dbDisconnect(test_db)

# PMI matrix
m_pmi = get_pmi(spm_cooc)

# SVD embeddings
m_phecode_embeds_50 = get_svd(m_pmi, svd_rank = 50) 
m_phecode_embeds_100 = get_svd(m_pmi, svd_rank = 100)
m_phecode_embeds_150 = get_svd(m_pmi, svd_rank = 150)

save(m_phecode_embeds_50,file = "Phecode_50dim.Rdata")
save(m_phecode_embeds_100,file = "Phecode_100dim.Rdata")
save(m_phecode_embeds_150,file = "Phecode_150dim.Rdata")
