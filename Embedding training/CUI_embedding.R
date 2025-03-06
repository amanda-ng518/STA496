library(dplyr)
library(RSQLite)
library(stringr)
library(nlpembeds)
#library(remotes)
#remotes::install_github("jwood000/RcppAlgos@v2.4.0")
#remotes::install_git("https://gitlab.com/thomaschln/nlpembeds.git")

sqlite <- dbDriver("SQLite")
conn <- dbConnect(RSQLite::SQLite(), dbname = "mimic.db", synchronous = NULL)

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

# Prepare data
# Note: need to figure out a way to define "Month"
data_for_pmisvd = entity_merged%>%
  group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label)%>%
  summarize(Count = n())
data_for_pmisvd <- na.omit(data_for_pmisvd)
#save(data_for_pmisvd, file = "data_for_pmisvd.Rdata")

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
m_embeds_1500 = get_svd(m_pmi, svd_rank = 1500) 
m_embeds_2000 = get_svd(m_pmi, svd_rank = 2000) 
m_embeds_2500 = get_svd(m_pmi, svd_rank = 2500) 
m_embeds_3000 = get_svd(m_pmi, svd_rank = 3000) 

# Output CUI embedding matrix
save(m_embeds_1500,file = "CUI_1500dim.Rdata")
save(m_embeds_2000,file = "CUI_2000dim.Rdata")
save(m_embeds_2500,file = "CUI_2500dim.Rdata")
save(m_embeds_3000,file = "CUI_3000dim.Rdata")
