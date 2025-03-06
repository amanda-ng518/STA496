library(icd)
library(readr)
library(dplyr)
library(tidyr)
library(PheWAS)
library(kgraph)

# m_embeds: each row is a code embedding (rowname = code)
# df_cuis_pairs: known relationship matrix, each row is a relationship between two codes

#-----------------------Read data----------------------------#
load("white_CUI+Phecode_1500dim.Rdata") #white_m_embeds_1500
load("white_CUI+Phecode_2000dim.Rdata") #white_m_embeds_2000
load("white_CUI+Phecode_2500dim.Rdata") #white_m_embeds_2500
load("white_CUI+Phecode_3000dim.Rdata") #white_m_embeds_3000

load("nwhite_CUI+Phecode_1500dim.Rdata") #nwhite_m_embeds_1500
load("nwhite_CUI+Phecode_2000dim.Rdata") #nwhite_m_embeds_2000
load("nwhite_CUI+Phecode_2500dim.Rdata") #nwhite_m_embeds_2500
load("nwhite_CUI+Phecode_3000dim.Rdata") #nwhite_m_embeds_3000

load("private_CUI+Phecode_1500dim.Rdata") #private_m_embeds_1500
load("private_CUI+Phecode_2000dim.Rdata") #private_m_embeds_2000
load("private_CUI+Phecode_2500dim.Rdata") #private_m_embeds_2500
load("private_CUI+Phecode_3000dim.Rdata") #private_m_embeds_3000

load("nprivate_CUI+Phecode_1500dim.Rdata") #nprivate_m_embeds_1500
load("nprivate_CUI+Phecode_2000dim.Rdata") #nprivate_m_embeds_2000
load("nprivate_CUI+Phecode_2500dim.Rdata") #nprivate_m_embeds_2500
load("nprivate_CUI+Phecode_3000dim.Rdata") #nprivate_m_embeds_3000

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
# threshold_projs = 0.9 (default)
# White
white_fit_kg_1500_01= fit_embeds_kg(white_m_embeds_1500, 'cosine',df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(white_fit_kg_1500_01$roc, print.auc = TRUE)
white_fit_kg_2000_01= fit_embeds_kg(white_m_embeds_2000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(white_fit_kg_2000_01$roc, print.auc = TRUE)
white_fit_kg_2500_01= fit_embeds_kg(white_m_embeds_2500, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(white_fit_kg_2500_01$roc, print.auc = TRUE)
white_fit_kg_3000_01= fit_embeds_kg(white_m_embeds_3000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(white_fit_kg_3000_01$roc, print.auc = TRUE)

# Non-white
nwhite_fit_kg_1500_01= fit_embeds_kg(nwhite_m_embeds_1500, 'cosine',df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nwhite_fit_kg_1500_01$roc, print.auc = TRUE)
nwhite_fit_kg_2000_01= fit_embeds_kg(nwhite_m_embeds_2000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nwhite_fit_kg_2000_01$roc, print.auc = TRUE)
nwhite_fit_kg_2500_01= fit_embeds_kg(nwhite_m_embeds_2500, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nwhite_fit_kg_2500_01$roc, print.auc = TRUE)
nwhite_fit_kg_3000_01= fit_embeds_kg(nwhite_m_embeds_3000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nwhite_fit_kg_3000_01$roc, print.auc = TRUE)

# Private
private_fit_kg_1500_01= fit_embeds_kg(private_m_embeds_1500, 'cosine',df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(private_fit_kg_1500_01$roc, print.auc = TRUE)
private_fit_kg_2000_01= fit_embeds_kg(private_m_embeds_2000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(private_fit_kg_2000_01$roc, print.auc = TRUE)
private_fit_kg_2500_01= fit_embeds_kg(private_m_embeds_2500, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(private_fit_kg_2500_01$roc, print.auc = TRUE)
private_fit_kg_3000_01= fit_embeds_kg(private_m_embeds_3000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(private_fit_kg_3000_01$roc, print.auc = TRUE)

# Non-private
nprivate_fit_kg_1500_01= fit_embeds_kg(nprivate_m_embeds_1500, 'cosine',df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nprivate_fit_kg_1500_01$roc, print.auc = TRUE)
nprivate_fit_kg_2000_01= fit_embeds_kg(nprivate_m_embeds_2000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nprivate_fit_kg_2000_01$roc, print.auc = TRUE)
nprivate_fit_kg_2500_01= fit_embeds_kg(nprivate_m_embeds_2500, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nprivate_fit_kg_2500_01$roc, print.auc = TRUE)
nprivate_fit_kg_3000_01= fit_embeds_kg(nprivate_m_embeds_3000, 'cosine', df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(nprivate_fit_kg_3000_01$roc, print.auc = TRUE)

#----------------------TPR-FPR-------------------------------------#
roc = nprivate_fit_kg_1500_01$roc
fpr_values <- c(0.05, 0.1, 0.2)
tpr_at_fpr <- pROC::coords(roc, x = fpr_values, input = "1-specificity", ret = "sensitivity")
data.frame(FPR = fpr_values, TPR = tpr_at_fpr)
