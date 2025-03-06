library(icd)
library(readr)
library(dplyr)
library(tidyr)
library(PheWAS)
library(kgraph)

#-----------------------Read embedding data----------------------------#
getwd()
load("Phecode_50dim.Rdata") # 1709 phecode embeddings m_phecode_embeds_50
load("Phecode_100dim.Rdata") # 1709 phecode embeddings m_phecode_embeds_100
load("Phecode_150dim.Rdata") # 1709 phecode embeddings m_phecode_embeds_150

#-----------------------Full ICD code version definition--------------------------#
ICD_ver_def = read_csv("d_icd_diagnoses.csv")

ICD_ver_def$icd_code = short_to_decimal(ICD_ver_def$icd_code)

n_icd9 = nrow(ICD_ver_def%>% filter(icd_version == 9))
n_icd10 = nrow(ICD_ver_def%>% filter(icd_version == 10))

# Number of ICD codes = 112107

ICD_ver_def <- ICD_ver_def %>%
  arrange(icd_version)%>%
  mutate(row_id = row_number())

icd_df = data.frame(id = ICD_ver_def$row_id, 
                    vocabulary_id= c(rep("ICD9CM", n_icd9),rep("ICD10CM", n_icd10)),
                    code=as.character(ICD_ver_def$icd_code))

# Number of Phecodes mapped = Number of unique Phecodes mapped = 29322
Phecodes = mapCodesToPhecodes(icd_df, rollup.map = NULL)

ICD_ver_def <- ICD_ver_def %>%
  left_join(Phecodes, by = c("row_id" = "id"))

# 407 ICDs are associated with 2 distinct phecodes

# Number of observations with missing Phecode = 83230
# sum(is.na(ICD_ver_def$phecode)) 

ICD_ver_def <- ICD_ver_def %>%
  filter(!is.na(phecode))

ICD_ver_def$phecode_parent = as.integer(ICD_ver_def$phecode)

save(ICD_ver_def, file ="ICD_Phecode.Rdata")

#-----------------------Define related pairs--------------------------#
load("ICD_Phecode.Rdata") # ICD_Phecode transformation: ICD_ver_def

# I defined related pairs by Phecode Hierarchy
Phecode_trim = ICD_ver_def%>%
  select(phecode,phecode_parent)%>%
  unique()

# Create Phecode pairs for the same phecode_parent group
phecode_pairs_data <- Phecode_trim %>%
  group_by(phecode_parent) %>%
  filter(n() > 1) %>%  # Keep groups with more than 1 observation
  summarize(phecode_pairs = list(combn(phecode, 2, simplify = FALSE)), .groups = "drop") %>%
  unnest(phecode_pairs) %>%
  transmute(phecode_1 = sapply(phecode_pairs, `[`, 1),
            phecode_2 = sapply(phecode_pairs, `[`, 2))

#---------------------------------------AUC------------------------------------------#
# FPR = 0.01
fit_kg_50_001= fit_embeds_kg(m_phecode_embeds_50, 'cosine', threshold_projs=0.99,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_50_001$roc, print.auc = TRUE)
fit_kg_100_001= fit_embeds_kg(m_phecode_embeds_100, 'cosine', threshold_projs=0.99,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_100_001$roc, print.auc = TRUE)
fit_kg_150_001= fit_embeds_kg(m_phecode_embeds_150, 'cosine', threshold_projs=0.99,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_150_001$roc, print.auc = TRUE)

# FPR = 0.05
fit_kg_50_005= fit_embeds_kg(m_phecode_embeds_50, 'cosine', threshold_projs=0.95,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_50_005$roc, print.auc = TRUE)
fit_kg_100_005= fit_embeds_kg(m_phecode_embeds_100, 'cosine', threshold_projs=0.95,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_100_005$roc, print.auc = TRUE)
fit_kg_150_005= fit_embeds_kg(m_phecode_embeds_150, 'cosine', threshold_projs=0.95,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_150_005$roc, print.auc = TRUE)

# FPR = 0.1
fit_kg_50_01= fit_embeds_kg(m_phecode_embeds_50, 'cosine', threshold_projs=0.9,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_50_01$roc, print.auc = TRUE)
fit_kg_100_01= fit_embeds_kg(m_phecode_embeds_100, 'cosine', threshold_projs=0.9,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_100_01$roc, print.auc = TRUE)
fit_kg_150_01= fit_embeds_kg(m_phecode_embeds_150, 'cosine', threshold_projs=0.9,df_pairs = phecode_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_150_01$roc, print.auc = TRUE)
