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

# Function to create bootstrapped tables and assign variable names
bootstrap_tables <- function(data, prefix, n_boot = 9) {
  for (i in 1:n_boot) {
    var_name <- paste0(prefix, i)  # Create dynamic variable name
    assign(var_name, data %>% sample_frac(replace = TRUE), envir = .GlobalEnv)
  }
}

# Prepare data by demographic groups
groups <- list(
  white = entity_merged %>% filter(ETHNICITY == "WHITE"),
  non_white = entity_merged %>% filter(ETHNICITY != "WHITE"),
  private_insurance = entity_merged %>% filter(INSURANCE == "Private"),
  non_private_insurance = entity_merged %>% filter(INSURANCE != "Private")
)

prefixes <- list(
  white = "white_table1",
  non_white = "nwhite_table1",
  private_insurance = "private_table1",
  non_private_insurance = "nprivate_table1"
)

for (group in names(groups)) {
  data <- groups[[group]] %>%
    select(subject_id, discharge_year_month, entity_label) %>%
    group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = entity_label) %>%
    summarize(Count = n(), .groups = "drop") %>%
    na.omit()
  
  bootstrap_tables(data, prefixes[[group]])
}

# This will create:
# - white_table11, white_table12, ..., white_table19
# - nwhite_table11, nwhite_table12, ..., nwhite_table19
# - private_table11, private_table12, ..., private_table19
# - nprivate_table11, nprivate_table12, ..., nprivate_table19

#-----------------------Phecode-----------------------------#
# Read data
load("Phecode_Data_for_generating_embedding.Rdata") # I named the object as cleaned_data in the Phecode_transformation R script
data_merged = cleaned_data
phecode_demographics = read_csv("admissions.csv")%>%select(subject_id, insurance, race)%>%unique()
data_merged <- merge(data_merged, phecode_demographics, by = "subject_id", all.x = TRUE, all.y = FALSE)

# Prepare data by demographic groups
groups <- list(
  white = data_merged %>% filter(race == "WHITE"),
  non_white = data_merged %>% filter(race != "WHITE"),
  private_insurance = data_merged %>% filter(insurance == "Private"),
  non_private_insurance = data_merged %>% filter(insurance != "Private")
)

prefixes <- list(
  white = "white_table2",
  non_white = "nwhite_table2",
  private_insurance = "private_table2",
  non_private_insurance = "nprivate_table2"
)

for (group in names(groups)) {
  data <- groups[[group]] %>%
    select(subject_id, discharge_year_month, phecode) %>%
    group_by(Month = discharge_year_month, Patient = subject_id, Parent_Code = phecode) %>%
    summarize(Count = n(), .groups = "drop") %>%
    na.omit()
  
  bootstrap_tables(data, prefixes[[group]])
}

# This will create:
# - white_table21, white_table22, ..., white_table29
# - nwhite_table21, nwhite_table22, ..., nwhite_table29
# - private_table21, private_table22, ..., private_table29
# - nprivate_table21, nprivate_table22, ..., nprivate_table29

#---------------------Co-occurence matrix--------------------------#
# Create empty lists to store combined tables
white_pmisvd_list <- list()
nwhite_pmisvd_list <- list()
private_pmisvd_list <- list()
nprivate_pmisvd_list <- list()

# Combine corresponding bootstrapped tables
for (i in 1:9) {
  white_pmisvd_list[[i]] <- rbind(get(paste0("white_table1", i)), get(paste0("white_table2", i)))
  nwhite_pmisvd_list[[i]] <- rbind(get(paste0("nwhite_table1", i)), get(paste0("nwhite_table2", i)))
  private_pmisvd_list[[i]] <- rbind(get(paste0("private_table1", i)), get(paste0("private_table2", i)))
  nprivate_pmisvd_list[[i]] <- rbind(get(paste0("nprivate_table1", i)), get(paste0("nprivate_table2", i)))
}

# Assign final combined datasets to variables in the global environment
for (i in 1:9) {
  assign(paste0("white_data_for_pmisvd", i), white_pmisvd_list[[i]], envir = .GlobalEnv)
  assign(paste0("nwhite_data_for_pmisvd", i), nwhite_pmisvd_list[[i]], envir = .GlobalEnv)
  assign(paste0("private_data_for_pmisvd", i), private_pmisvd_list[[i]], envir = .GlobalEnv)
  assign(paste0("nprivate_data_for_pmisvd", i), nprivate_pmisvd_list[[i]], envir = .GlobalEnv)
}

# This will create:
# - white_data_for_pmisvd1, ..., white_data_for_pmisvd9
# - nwhite_data_for_pmisvd1, ..., nwhite_data_for_pmisvd9
# - private_data_for_pmisvd1, ..., private_data_for_pmisvd9
# - nprivate_data_for_pmisvd1, ..., nprivate_data_for_pmisvd9

pmisvd_to_embeddings <- function(pmisvd) {
  # Batching by patients
  test_db_path = tempfile()
  test_db = dbConnect(RSQLite::SQLite(), test_db_path)
  dbWriteTable(test_db, "df_monthly", pmisvd, overwrite= TRUE)
  
  # Get unique parent codes
  df_uniq_codes <- unique(pmisvd["Parent_Code"])
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
  output_cooc = dbGetQuery(test_db, "select * from df_monthly;")
  dbDisconnect(test_db)
  
  # PMI matrix
  pmi = get_pmi(output_cooc) 
  
  # SVD embeddings
  m_embeds_1500 = get_svd(pmi, svd_rank = 1500) 
  
  return(m_embeds_1500)
}

#---------------------Output CUI embedding matrix--------------------------#
# Function to process and save embeddings with specified names
save_embeddings <- function(group_name) {
  for (i in 1:9) {  
    # Generate variable names dynamically
    input_table_name <- paste0(group_name, "_data_for_pmisvd", i)
    output_var_name <- paste0(group_name, "_m_embeds_1500_", i)
    
    # Run the function
    embeddings <- pmisvd_to_embeddings(get(input_table_name))
    
    # Assign dynamically created variable name in the global environment
    assign(output_var_name, embeddings, envir = .GlobalEnv)
    
    # Save the output
    save_file_name <- paste0(group_name, "_CUI+Phecode_1500dim_", i, ".Rdata")
    save(list = output_var_name, file = save_file_name)
  }
}

# Run the function for each group
save_embeddings("white")
save_embeddings("nwhite")
save_embeddings("private")
save_embeddings("nprivate")
