library(icd)
library(readr)
library(dplyr)
library(tidyr)
library(PheWAS)
library(kgraph)

# m_embeds: each row is a code embedding (rowname = code)
# df_cuis_pairs: known relationship matrix, each row is a relationship between two codes

#-----------------------Read data----------------------------#
load("CUI+Phecode_1500dim.Rdata") #m_embeds_1500
load("CUI+Phecode_2000dim.Rdata") #m_embeds_2000
load("CUI+Phecode_2500dim.Rdata") #m_embeds_2500
load("CUI+Phecode_3000dim.Rdata") #m_embeds_3000

#-----------------------Define related pairs--------------------------#
data('df_cuis_pairs')
df_cuis_pairs=df_cuis_pairs[c(1, 3)]

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

colnames(phecode_pairs_data) <- colnames(df_cuis_pairs)  
combined_pairs <- rbind(df_cuis_pairs, phecode_pairs_data)

#---------------------------------------AUC------------------------------------------#
set.seed(518)
# threshold_projs = 0.99
fit_kg_1500_001= fit_embeds_kg(m_embeds_1500, 'cosine', threshold_projs=0.99,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_1500_001$roc, print.auc = TRUE)
fit_kg_2000_001= fit_embeds_kg(m_embeds_2000, 'cosine', threshold_projs=0.99,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_2000_001$roc, print.auc = TRUE)
fit_kg_2500_001= fit_embeds_kg(m_embeds_2500, 'cosine', threshold_projs=0.99,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_2500_001$roc, print.auc = TRUE)
fit_kg_3000_001= fit_embeds_kg(m_embeds_3000, 'cosine', threshold_projs=0.99,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_3000_001$roc, print.auc = TRUE)

# threshold_projs = 0.95
fit_kg_1500_005= fit_embeds_kg(m_embeds_1500, 'cosine', threshold_projs=0.95,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_1500_005$roc, print.auc = TRUE)
fit_kg_2000_005= fit_embeds_kg(m_embeds_2000, 'cosine', threshold_projs=0.95,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_2000_005$roc, print.auc = TRUE)
fit_kg_2500_005= fit_embeds_kg(m_embeds_2500, 'cosine', threshold_projs=0.95,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_2500_005$roc, print.auc = TRUE)
fit_kg_3000_005= fit_embeds_kg(m_embeds_3000, 'cosine', threshold_projs=0.95,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_3000_005$roc, print.auc = TRUE)

# threshold_projs = 0.9
fit_kg_1500_01= fit_embeds_kg(m_embeds_1500, 'cosine', threshold_projs=0.9,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_1500_01$roc, print.auc = TRUE)
fit_kg_2000_01= fit_embeds_kg(m_embeds_2000, 'cosine', threshold_projs=0.9,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_2000_01$roc, print.auc = TRUE)
fit_kg_2500_01= fit_embeds_kg(m_embeds_2500, 'cosine', threshold_projs=0.9,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_2500_01$roc, print.auc = TRUE)
fit_kg_3000_01= fit_embeds_kg(m_embeds_3000, 'cosine', threshold_projs=0.9,df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_3000_01$roc, print.auc = TRUE)
