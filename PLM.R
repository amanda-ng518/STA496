library(icd)
library(readr)
library(dplyr)
library(tidyr)
library(PheWAS)
library(kgraph)

# Load PLM embeddings
PLM_embeddings = read.csv("PLMembeddings.csv", header = FALSE)
definitions = read_csv("phecode_definitions1.2.csv")
rownames(PLM_embeddings) = definitions$name

# Load SVD embeddings
load("CUI+Phecode_1500dim.Rdata") #m_embeds_1500
m_embeds_1500_1 = m_embeds_1500
m_embeds_1500 = as.data.frame(m_embeds_1500)

load("white_CUI+Phecode_1500dim.Rdata") #white_m_embeds_1500
white_m_embeds_1500_1 = white_m_embeds_1500
white_m_embeds_1500 = as.data.frame(white_m_embeds_1500)

load("nwhite_CUI+Phecode_1500dim.Rdata") #nwhite_m_embeds_1500
nwhite_m_embeds_1500_1 = nwhite_m_embeds_1500
nwhite_m_embeds_1500 = as.data.frame(nwhite_m_embeds_1500)

load("private_CUI+Phecode_1500dim.Rdata") #private_m_embeds_1500
private_m_embeds_1500_1 = private_m_embeds_1500
private_m_embeds_1500 = as.data.frame(private_m_embeds_1500)

load("nprivate_CUI+Phecode_1500dim.Rdata") #nprivate_m_embeds_1500
nprivate_m_embeds_1500_1 = nprivate_m_embeds_1500
nprivate_m_embeds_1500 = as.data.frame(nprivate_m_embeds_1500)

# Convert row names to a new column called "RowNames"
PLM_embeddings$RowNames <- rownames(PLM_embeddings)
m_embeds_1500$RowNames <- rownames(m_embeds_1500)
white_m_embeds_1500$RowNames <- rownames(white_m_embeds_1500)
nwhite_m_embeds_1500$RowNames <- rownames(nwhite_m_embeds_1500)
private_m_embeds_1500$RowNames <- rownames(private_m_embeds_1500)
nprivate_m_embeds_1500$RowNames <- rownames(nprivate_m_embeds_1500)

# Concatenate
merged_embeddings_overall <- merge(PLM_embeddings, m_embeds_1500, by = "RowNames", all = FALSE) 
rownames(merged_embeddings_overall) = merged_embeddings_overall$RowNames 
merged_embeddings_overall <- merged_embeddings_overall %>% select(-"RowNames")
merged_embeddings_overall<- as.matrix(merged_embeddings_overall)

merged_embeddings_white <- merge(PLM_embeddings, white_m_embeds_1500, by = "RowNames", all = FALSE) 
rownames(merged_embeddings_white) = merged_embeddings_white$RowNames 
merged_embeddings_white <- merged_embeddings_white %>% select(-"RowNames")
merged_embeddings_white<- as.matrix(merged_embeddings_white)

merged_embeddings_nwhite <- merge(PLM_embeddings, nwhite_m_embeds_1500, by = "RowNames", all = FALSE) 
rownames(merged_embeddings_nwhite) = merged_embeddings_nwhite$RowNames 
merged_embeddings_nwhite <- merged_embeddings_nwhite %>% select(-"RowNames")
merged_embeddings_nwhite<- as.matrix(merged_embeddings_nwhite)

merged_embeddings_private <- merge(PLM_embeddings, private_m_embeds_1500, by = "RowNames", all = FALSE) 
rownames(merged_embeddings_private) = merged_embeddings_private$RowNames 
merged_embeddings_private <- merged_embeddings_private %>% select(-"RowNames")
merged_embeddings_private<- as.matrix(merged_embeddings_private)

merged_embeddings_nprivate <- merge(PLM_embeddings, nprivate_m_embeds_1500, by = "RowNames", all = FALSE) 
rownames(merged_embeddings_nprivate) = merged_embeddings_nprivate$RowNames 
merged_embeddings_nprivate <- merged_embeddings_nprivate %>% select(-"RowNames")
merged_embeddings_nprivate<- as.matrix(merged_embeddings_nprivate)

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
# d = 1500, threshold = 0.9
# Overall
fit_kg_plm= fit_embeds_kg(merged_embeddings_overall, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_plm$roc, print.auc = TRUE)
# AUC = 0.724

fit_kg= fit_embeds_kg(m_embeds_1500_1, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg$roc, print.auc = TRUE)
# AUC = 0.720

# White
fit_kg_plm_white= fit_embeds_kg(merged_embeddings_white, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_plm_white$roc, print.auc = TRUE)
# AUC = 0.716

fit_kg_white= fit_embeds_kg(white_m_embeds_1500_1, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_white$roc, print.auc = TRUE)
# AUC = 0.722

# Non-White
fit_kg_plm_nwhite= fit_embeds_kg(merged_embeddings_nwhite, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_plm_nwhite$roc, print.auc = TRUE)
# AUC = 0.732

fit_kg_nwhite= fit_embeds_kg(nwhite_m_embeds_1500_1, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_nwhite$roc, print.auc = TRUE)
# AUC = 0.736

# Private
fit_kg_plm_private= fit_embeds_kg(merged_embeddings_private, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_plm_private$roc, print.auc = TRUE)
# AUC = 0.722

fit_kg_private= fit_embeds_kg(private_m_embeds_1500_1, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_private$roc, print.auc = TRUE)
# AUC = 0.722

# Non-Private
# Overall
fit_kg_plm_nprivate= fit_embeds_kg(merged_embeddings_nprivate, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_plm_nprivate$roc, print.auc = TRUE)
# AUC = 0.722

fit_kg_nprivate= fit_embeds_kg(nprivate_m_embeds_1500_1, 'cosine', threshold_projs = 0.9, df_pairs = combined_pairs[c(1, 2)])
pROC::plot.roc(fit_kg_nprivate$roc, print.auc = TRUE)
# AUC = 0.711

#--------------------------------------Plot-------------------------------------------#
library(ggplot2)

# Create data frame with ordered factor levels
auc_data <- data.frame(
  Group = factor(rep(c("Overall", "White", "Non-White", "Private", "Non-Private"), each = 2),
                 levels = c("Overall", "White", "Non-White", "Private", "Non-Private")),
  Embedding = rep(c("PLM", "SVD"), times = 5),
  AUC = c(0.724, 0.720, 0.716, 0.722, 0.732, 0.736, 0.722, 0.722, 0.722, 0.711)
)

# Plot
ggplot(auc_data, aes(x = Group, y = AUC, fill = Embedding)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = round(AUC, 3)), 
            position = position_dodge(width = 0.7), 
            vjust = -0.5, size = 3) +
  theme_minimal() +
  labs(title = "Comparison of AUC Values Across Groups",
       x = "Group",
       y = "AUC values") +
  scale_fill_manual(values = c("PLM" = "blue", "SVD" = "red")) +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))
