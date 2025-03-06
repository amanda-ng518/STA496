library(icd)
library(readr)
library(dplyr)
library(tidyr)
library(PheWAS)
library(kgraph)

#-----------------------Read data----------------------------#
load("ICD_50dim.Rdata") # ICD embeddings: m_icd_embeds_50
load("ICD_100dim.Rdata") # ICD embeddings: m_icd_embeds_100
load("ICD_150dim.Rdata") # ICD embeddings: m_icd_embeds_150

load("ICD_Phecode.Rdata") # ICD_Phecode transformation: ICD_ver_def

#-----------------------Define related pairs--------------------------#

# I defined related pairs by Phecode Hierarchy
ICD_trim = ICD_ver_def%>%
  select(icd_code,phecode_parent)%>%
  unique()

# Create ICD pairs for the same phecode_parent group
icd_pairs_data <- ICD_trim %>%
  group_by(phecode_parent) %>%
  filter(n() > 1) %>%  # Keep groups with more than 1 observation
  summarize(icd_pairs = list(combn(icd_code, 2, simplify = FALSE)), .groups = "drop") %>%
  unnest(icd_pairs) %>%
  transmute(icd_1 = sapply(icd_pairs, `[`, 1),
            icd_2 = sapply(icd_pairs, `[`, 2))

#---------------------------------------AUC------------------------------------------#
# FPR = 0.01
fit_kg_50_001= fit_embeds_kg(m_icd_embeds_50, 'cosine', threshold_projs=0.99,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_50_001$roc, print.auc = TRUE)
fit_kg_100_001= fit_embeds_kg(m_icd_embeds_100, 'cosine', threshold_projs=0.99,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_100_001$roc, print.auc = TRUE)
fit_kg_150_001= fit_embeds_kg(m_icd_embeds_150, 'cosine', threshold_projs=0.99,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_150_001$roc, print.auc = TRUE)

# FPR = 0.05
fit_kg_50_005= fit_embeds_kg(m_icd_embeds_50, 'cosine', threshold_projs=0.95,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_50_005$roc, print.auc = TRUE)
fit_kg_100_005= fit_embeds_kg(m_icd_embeds_100, 'cosine', threshold_projs=0.95,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_100_005$roc, print.auc = TRUE)
fit_kg_150_005= fit_embeds_kg(m_icd_embeds_150, 'cosine', threshold_projs=0.95,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_150_005$roc, print.auc = TRUE)

# FPR = 0.1
fit_kg_50_01= fit_embeds_kg(m_icd_embeds_50, 'cosine', threshold_projs=0.9,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_50_01$roc, print.auc = TRUE)
fit_kg_100_01= fit_embeds_kg(m_icd_embeds_100, 'cosine', threshold_projs=0.9,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_100_01$roc, print.auc = TRUE)
fit_kg_150_01= fit_embeds_kg(m_icd_embeds_150, 'cosine', threshold_projs=0.9,df_pairs = icd_pairs_data[c(1, 2)])
pROC::plot.roc(fit_kg_150_01$roc, print.auc = TRUE)
